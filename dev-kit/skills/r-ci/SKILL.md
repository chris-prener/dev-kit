---
name: r-ci
description: >
  Defines CI/CD conventions for R projects: R CMD check, GitHub Actions
  workflow templates, renv caching, coverage reporting, and multi-OS testing.
when_to_use: >
  Use to set up CI for an R project, fix CI failures, add coverage
  reporting, or configure multi-OS testing. Trigger phrases: "r ci", "r
  cmd check", "r github actions", "rcmdcheck", "r workflow". Not for local
  testing only (`r-testing`), package structure questions
  (`r-package-structure`), dependency issues (`r-dependencies`), or CI for
  non-R projects.
model: sonnet
# persona: r-developer   — grouping metadata only; not read by Claude Code.
---

# R CI

You are configuring CI/CD for an R project. This skill defines GitHub Actions workflow templates, R CMD check configuration, renv caching strategies, coverage reporting, and multi-OS testing patterns.

## Activation

Activate when the user needs to set up CI for an R project, fix CI failures, add coverage reporting, or configure multi-OS testing.

## Inputs

- **Required**: what CI capability is needed (check, test, lint, coverage)
- **Optional**: whether multi-OS is needed
- **Optional**: whether this is a package or a project (pipeline)
- **Optional**: specific R version constraints

## Steps

### 1. Workflow templates

#### R CMD check (for packages)

```yaml
# .github/workflows/R-CMD-check.yaml
name: R-CMD-check

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  R-CMD-check:
    runs-on: ${{ matrix.config.os }}

    name: ${{ matrix.config.os }} (R ${{ matrix.config.r }})

    strategy:
      fail-fast: false
      matrix:
        config:
          - {os: ubuntu-latest, r: 'release'}
          - {os: windows-latest, r: 'release'}
          - {os: macos-latest, r: 'release'}

    env:
      GITHUB_PAT: ${{ secrets.GITHUB_TOKEN }}
      R_KEEP_PKG_SOURCE: yes

    steps:
      - uses: actions/checkout@v4

      - uses: r-lib/actions/setup-r@v2
        with:
          r-version: ${{ matrix.config.r }}
          use-public-rspm: true

      - uses: r-lib/actions/setup-r-dependencies@v2
        with:
          cache-version: 1
          extra-packages: any::rcmdcheck
          needs: check

      - uses: r-lib/actions/check-r-package@v2
        with:
          error-on: '"warning"'
          args: 'c("--no-manual", "--as-cran")'
```

#### Test + lint (for non-package projects)

```yaml
# .github/workflows/ci.yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test-and-lint:
    runs-on: ubuntu-latest

    env:
      GITHUB_PAT: ${{ secrets.GITHUB_TOKEN }}
      RENV_PATHS_ROOT: ~/.cache/R/renv

    steps:
      - uses: actions/checkout@v4

      - uses: r-lib/actions/setup-r@v2
        with:
          r-version: 'release'
          use-public-rspm: true

      - name: Cache renv
        uses: actions/cache@v4
        with:
          path: ${{ env.RENV_PATHS_ROOT }}
          key: ${{ runner.os }}-renv-${{ hashFiles('renv.lock') }}
          restore-keys: |
            ${{ runner.os }}-renv-

      - name: Restore renv
        run: |
          install.packages("renv")
          renv::restore()
        shell: Rscript {0}

      - name: Lint
        run: |
          lintr::lint_dir("R/")
          if (length(lintr::lint_dir("R/")) > 0) quit(status = 1)
        shell: Rscript {0}

      - name: Test
        run: |
          testthat::test_dir("tests/testthat/", reporter = "summary", stop_on_failure = TRUE)
        shell: Rscript {0}
```

#### Pipeline run (for targets projects)

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

    env:
      GITHUB_PAT: ${{ secrets.GITHUB_TOKEN }}
      RENV_PATHS_ROOT: ~/.cache/R/renv

    steps:
      - uses: actions/checkout@v4

      - uses: r-lib/actions/setup-r@v2
        with:
          r-version: 'release'
          use-public-rspm: true

      - name: Cache renv
        uses: actions/cache@v4
        with:
          path: ${{ env.RENV_PATHS_ROOT }}
          key: ${{ runner.os }}-renv-${{ hashFiles('renv.lock') }}
          restore-keys: |
            ${{ runner.os }}-renv-

      - name: Cache targets
        uses: actions/cache@v4
        with:
          path: _targets
          key: ${{ runner.os }}-targets-${{ hashFiles('_targets.R', 'R/functions/**') }}
          restore-keys: |
            ${{ runner.os }}-targets-

      - name: Restore renv
        run: |
          install.packages("renv")
          renv::restore()
        shell: Rscript {0}

      - name: Run pipeline
        run: |
          targets::tar_make()
        shell: Rscript {0}

      - name: Upload outputs
        uses: actions/upload-artifact@v4
        if: success()
        with:
          name: pipeline-outputs
          path: data/
```

### 2. renv caching strategy

```yaml
# Standard renv cache block:
- name: Cache renv
  uses: actions/cache@v4
  with:
    path: ${{ env.RENV_PATHS_ROOT }}
    key: ${{ runner.os }}-renv-${{ hashFiles('renv.lock') }}
    restore-keys: |
      ${{ runner.os }}-renv-

- name: Restore renv
  run: |
    install.packages("renv")
    renv::restore()
  shell: Rscript {0}
```

**Cache key strategy:**
- Primary key: OS + renv lockfile hash → exact match
- Restore key: OS + `renv-` prefix → partial match (reuses most packages)
- Cache invalidates when `renv.lock` changes

**For packages using r-lib/actions:** Use `setup-r-dependencies` which handles caching internally:
```yaml
- uses: r-lib/actions/setup-r-dependencies@v2
  with:
    cache-version: 1
```

### 3. Coverage reporting

```yaml
# Add to ci.yaml:
  coverage:
    runs-on: ubuntu-latest
    needs: test-and-lint

    steps:
      - uses: actions/checkout@v4

      - uses: r-lib/actions/setup-r@v2
        with:
          r-version: 'release'
          use-public-rspm: true

      - uses: r-lib/actions/setup-r-dependencies@v2
        with:
          extra-packages: any::covr
          needs: coverage

      - name: Test coverage
        run: |
          covr::codecov(
            quiet = FALSE,
            clean = FALSE,
            install_path = file.path(normalizePath(Sys.getenv("RUNNER_TEMP"), winslash = "/"), "package")
          )
        shell: Rscript {0}
```

### 4. Required status checks

| Check | Blocks merge? | Purpose |
|---|---|---|
| R-CMD-check (ubuntu) | Yes | Core correctness |
| R-CMD-check (windows) | Yes (if cross-platform) | Platform compatibility |
| R-CMD-check (macos) | No (advisory) | macOS-specific issues |
| Lint | Yes | Code quality gate |
| Test | Yes | Test suite passes |
| Coverage | No (advisory) | Track coverage trends |

### 5. System dependencies

Some R packages require system libraries. Handle them in CI:

```yaml
# For Ubuntu:
- name: Install system dependencies
  run: |
    sudo apt-get update
    sudo apt-get install -y libcurl4-openssl-dev libssl-dev libxml2-dev libfontconfig1-dev libharfbuzz-dev libfribidi-dev

# Or use r-lib/actions which auto-detects:
- uses: r-lib/actions/setup-r-dependencies@v2
  with:
    cache-version: 1
```

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
| Package not found | Check renv.lock is committed; add to DESCRIPTION |
| System library missing | Add `apt-get install` step |
| Timeout | Add `timeout-minutes: 60` to job |
| R version mismatch | Pin R version in workflow |
| Encoding issues | Ensure `Encoding: UTF-8` in DESCRIPTION |

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

- CI runs complete in < 10 minutes (typical R project)
- renv cache hit rate > 90% on repeat runs
- R CMD check (or test+lint) passes on every PR
- Coverage report generated and accessible
- Failed runs produce actionable error messages

## Out of scope

- Local testing → `r-testing`
- Deployment/release pipelines → project-specific
- Non-R CI steps → generic CI approach
- GitHub branch protection setup → `github-enforcement`

## Cross-references

- `r-testing` — test suite that CI runs
- `r-code-style` — lintr that CI enforces
- `r-dependencies` — renv lockfile that CI restores
- `r-package-structure` — R CMD check requirements
- `r-pipeline-patterns` — targets pipeline CI
- `github-enforcement` — required status checks
