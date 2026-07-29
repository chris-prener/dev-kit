---
name: python-ci
description: >
  Defines CI/CD conventions for Python projects: GitHub Actions workflow
  templates, uv caching, ruff/mypy/pytest gates, coverage reporting, and
  multi-OS testing.
when_to_use: >
  Use to set up CI for a Python project, fix CI failures, add coverage
  reporting, or configure multi-OS testing. Trigger phrases: "python ci",
  "python github actions", "uv ci", "python workflow". Not for local
  testing only (`python-testing`), package structure questions
  (`python-packaging`), dependency issues (`python-dependencies`), or CI
  for non-Python projects.
model: sonnet
# persona: python-developer   — grouping metadata only; not read by Claude Code.
---

# Python CI

You are configuring CI/CD for a Python project. This skill defines GitHub Actions workflow templates, uv caching strategies, ruff/mypy/pytest gates, coverage reporting, and multi-OS testing patterns.

## Activation

Activate when the user needs to set up CI for a Python project, fix CI failures, add coverage reporting, or configure multi-OS testing.

## Inputs

- **Required**: what CI capability is needed (test, lint, type-check, coverage, build)
- **Optional**: whether multi-OS is needed
- **Optional**: whether this is a publishable package or an application/pipeline
- **Optional**: specific Python version constraints

## Steps

### 1. Workflow templates

#### Test + lint + type-check (standard project)

```yaml
# .github/workflows/ci.yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Install uv
        uses: astral-sh/setup-uv@v3
        with:
          enable-cache: true
          cache-dependency-glob: "uv.lock"

      - name: Set up Python
        run: uv python install

      - name: Install dependencies
        run: uv sync --locked --all-extras

      - name: Lint
        run: uv run ruff check .

      - name: Format check
        run: uv run ruff format --check .

      - name: Type check
        run: uv run mypy src

      - name: Test
        run: uv run pytest --cov=src --cov-report=xml

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          files: coverage.xml
```

#### Multi-OS / multi-version matrix (for publishable packages)

```yaml
# .github/workflows/ci.yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        python-version: ["3.10", "3.11", "3.12"]

    runs-on: ${{ matrix.os }}

    steps:
      - uses: actions/checkout@v4

      - name: Install uv
        uses: astral-sh/setup-uv@v3
        with:
          enable-cache: true
          cache-dependency-glob: "uv.lock"

      - name: Set up Python ${{ matrix.python-version }}
        run: uv python install ${{ matrix.python-version }}

      - name: Install dependencies
        run: uv sync --locked --all-extras --python ${{ matrix.python-version }}

      - name: Test
        run: uv run pytest
```

#### Build + publish (for packages, on tag push)

```yaml
# .github/workflows/publish.yaml
name: Publish

on:
  push:
    tags: ["v*"]

jobs:
  publish:
    runs-on: ubuntu-latest
    permissions:
      id-token: write   # for PyPI trusted publishing

    steps:
      - uses: actions/checkout@v4

      - name: Install uv
        uses: astral-sh/setup-uv@v3

      - name: Build
        run: uv build

      - name: Check
        run: uv run twine check dist/*

      - name: Publish to PyPI
        run: uv publish
```

#### Pipeline run (for Prefect flow projects)

```yaml
# .github/workflows/pipeline.yaml
name: Pipeline

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  run-pipeline:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Install uv
        uses: astral-sh/setup-uv@v3
        with:
          enable-cache: true
          cache-dependency-glob: "uv.lock"

      - name: Install dependencies
        run: uv sync --locked

      - name: Run pipeline
        run: uv run python -m mypackage.flows.main_flow

      - name: Upload outputs
        uses: actions/upload-artifact@v4
        if: success()
        with:
          name: pipeline-outputs
          path: data/
```

### 2. uv caching strategy

`astral-sh/setup-uv` handles caching internally when `enable-cache: true` is set — no manual `actions/cache` block needed (unlike renv in R). Point `cache-dependency-glob` at `uv.lock` so the cache key follows lockfile changes.

```yaml
- name: Install uv
  uses: astral-sh/setup-uv@v3
  with:
    enable-cache: true
    cache-dependency-glob: "uv.lock"
```

**Always run `uv sync --locked`** in CI (not plain `uv sync`) — `--locked` fails the build if `pyproject.toml` and `uv.lock` have drifted, instead of silently re-resolving.

### 3. Coverage reporting

```yaml
  coverage:
    runs-on: ubuntu-latest
    needs: test

    steps:
      - uses: actions/checkout@v4

      - name: Install uv
        uses: astral-sh/setup-uv@v3
        with:
          enable-cache: true

      - name: Install dependencies
        run: uv sync --locked

      - name: Test with coverage
        run: uv run pytest --cov=src --cov-report=xml --cov-report=term-missing

      - name: Upload to Codecov
        uses: codecov/codecov-action@v4
        with:
          files: coverage.xml
          fail_ci_if_error: true
```

### 4. Required status checks

| Check | Blocks merge? | Purpose |
|---|---|---|
| Lint (`ruff check`) | Yes | Code quality gate |
| Format (`ruff format --check`) | Yes | Formatting consistency |
| Type check (`mypy`) | Yes | Static correctness |
| Test (`pytest`) | Yes | Test suite passes |
| Test — Windows/macOS | Yes (if cross-platform) | Platform compatibility |
| Coverage | No (advisory) | Track coverage trends |

### 5. System dependencies

Some Python packages require system libraries (e.g., `psycopg2` needs `libpq`, some parsers need `libxml2`). Handle them in CI:

```yaml
- name: Install system dependencies
  run: |
    sudo apt-get update
    sudo apt-get install -y libpq-dev libxml2-dev
```

Prefer packages with prebuilt wheels (`psycopg[binary]`, `lxml`) to avoid needing system deps at all — check PyPI's file listing for a wheel matching the CI runner's platform before adding an `apt-get` step.

### 6. Debugging CI failures

```yaml
# Add SSH debugging for hard-to-reproduce failures:
- name: Setup tmate session
  if: failure()
  uses: mxschmitt/action-tmate@v3
  timeout-minutes: 15
```

**Common CI failures:**

| Error | Fix |
|---|---|
| `uv sync --locked` fails | `pyproject.toml` and `uv.lock` are out of sync locally — run `uv lock` and commit |
| Package not found | Check the package is on PyPI/the configured index; verify spelling |
| Timeout | Add `timeout-minutes: 30` to the job |
| Python version mismatch | Confirm `requires-python` in `pyproject.toml` matches the CI matrix |
| Wheel build failure | Missing system library — add the `apt-get install` step, or switch to a package with a prebuilt wheel |

### 7. Workflow dispatch (manual runs)

```yaml
on:
  workflow_dispatch:
    inputs:
      refresh_data:
        description: 'Force data refresh'
        required: false
        default: 'false'
        type: choice
        options:
          - 'true'
          - 'false'
```

## Outputs

- GitHub Actions workflow files (`.github/workflows/`)
- Properly cached CI runs
- Coverage reports (when configured)

## Success criteria

- CI runs complete in < 5 minutes (typical Python project, thanks to uv's speed)
- uv cache hit rate > 90% on repeat runs
- Lint, format-check, type-check, and test all pass on every PR
- Coverage report generated and accessible
- Failed runs produce actionable error messages

## Out of scope

- Local testing → `python-testing`
- Deployment/release pipelines beyond PyPI publish → project-specific
- Non-Python CI steps → generic CI approach
- GitHub branch protection setup → `github-enforcement`

## Cross-references

- `python-testing` — test suite that CI runs
- `python-code-style` — ruff that CI enforces
- `python-typing` — mypy that CI enforces
- `python-dependencies` — uv.lock that CI restores
- `python-packaging` — build/publish workflow
- `python-pipeline-patterns` — Prefect flow CI
- `github-enforcement` — required status checks
