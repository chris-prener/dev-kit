---
name: python-packaging
description: >
  Defines publishable Python package conventions: pyproject.toml build
  metadata, src layout, versioning, hatchling builds, and PyPI publishing.
when_to_use: >
  Use to create a new publishable Python package, restructure an existing
  project into package form, or understand package build/release
  conventions. Trigger phrases: "python package", "create python package",
  "publish to pypi", "build a wheel", "python packaging". Not for
  non-published Python projects (`python-project-scaffold`), just writing
  tests (`python-testing`), or documentation content (`python-documentation`).
model: sonnet
# persona: python-developer   — grouping metadata only; not read by Claude Code.
---

# Python Packaging

You are creating or maintaining a publishable Python package. This skill defines the canonical package layout, `pyproject.toml`-driven build metadata, versioning, and release workflow.

## Activation

Activate when the user needs to create a new publishable Python package, restructure an existing project into package form, or understand package build/release conventions.

## Inputs

- **Required**: package name (must follow PyPI naming rules: lowercase, hyphens for the distribution name, underscores for the import name)
- **Optional**: whether the package will be published to PyPI or an internal index only
- **Optional**: whether to include compiled extensions

## Steps

### 1. Canonical package layout

```
<package-name>/
├── .github/
│   └── workflows/
│       └── ci.yaml
├── .gitignore
├── LICENSE
├── CHANGELOG.md              # User-facing changelog
├── pyproject.toml            # Package metadata, build system, tool config (required)
├── README.md                 # Package README (PyPI long description)
├── src/
│   └── <package_name>/       # Importable package (underscores)
│       ├── __init__.py       # Public API surface, __version__
│       ├── py.typed          # PEP 561 marker — required to ship type hints
│       └── *.py
├── tests/
│   ├── conftest.py
│   └── test_*.py
├── docs/                     # Long-form documentation (mkdocs)
└── uv.lock                   # Dev dependency lockfile
```

### 2. pyproject.toml

```toml
[project]
name = "mypackage"
version = "0.1.0"
description = "What the package does (one line)."
readme = "README.md"
requires-python = ">=3.10"
license = "MIT"
license-files = ["LICENSE"]
authors = [
    { name = "First Last", email = "first.last@example.com" },
]
classifiers = [
    "Programming Language :: Python :: 3",
]
dependencies = [
    "httpx>=0.27",
]

[project.urls]
Homepage = "https://github.com/yourusername/mypackage"
Issues = "https://github.com/yourusername/mypackage/issues"

[dependency-groups]
dev = [
    "pytest>=8.0",
    "pytest-cov>=5.0",
    "ruff>=0.6",
    "mypy>=1.11",
    "mkdocs-material>=9.5",
    "mkdocstrings[python]>=0.25",
]

[build-system]
requires = ["hatchling>=1.27"]
build-backend = "hatchling.build"

[tool.hatch.build.targets.wheel]
packages = ["src/mypackage"]
```

**Rules:**
- `dependencies` — packages required at runtime, minimum-version bounds only
- `dependency-groups.dev` — dev-only packages (testing, linting, type-checking, docs)
- Never pin exact runtime versions in `dependencies` — that's what `uv.lock` is for

### 3. Public API surface

**`__init__.py` defines what's public.** Everything else is internal by default.

```python
# src/mypackage/__init__.py
"""mypackage — what it does, in one line."""

from mypackage.core import process_orders
from mypackage.validation import validate_order

__version__ = "0.1.0"
__all__ = ["process_orders", "validate_order"]
```

**Rules:**
- Export only user-facing functions/classes via `__all__`
- Internal helpers: prefix module or function with `_` (`_internal_helper`)
- Use absolute imports within the package (`from mypackage.core import ...`), never relative beyond one level
- `__version__` is the single source of truth — read by `hatch version` or set manually

### 4. Versioning

Follow semantic versioning:
- `0.1.0` — first usable release
- `x.y.z` — MAJOR.MINOR.PATCH after first release
- Pre-releases: `0.2.0rc1`, `0.2.0.dev0`

```bash
# Bump version (edit pyproject.toml [project.version], or with hatch):
uv run hatch version minor   # 0.1.0 → 0.2.0
uv run hatch version patch   # 0.2.0 → 0.2.1
```

Keep `CHANGELOG.md` updated per release (see `changelog` skill for format).

### 5. Building and publishing

```bash
# Build sdist + wheel:
uv build

# Check the built artifacts:
uv run twine check dist/*

# Publish to PyPI (requires PYPI_API_TOKEN):
uv publish

# Publish to TestPyPI first for validation:
uv publish --publish-url https://test.pypi.org/legacy/
```

**Rules:**
- Always `uv build` before publishing — never publish from an unbuilt tree
- Tag the release in git (`git tag v0.1.0`) matching the published version
- Never republish an existing version number — PyPI rejects it, and it breaks reproducibility for consumers

### 6. Quality checks before release

```bash
# Full check sequence:
uv run ruff check .
uv run mypy src
uv run pytest --cov=src --cov-report=term-missing
uv build
uv run twine check dist/*
```

**All must pass with 0 errors before tagging a release.**

### 7. Editable installs for local development

```bash
# Install the package in editable mode with dev deps:
uv sync

# Verify the import works:
uv run python -c "import mypackage; print(mypackage.__version__)"
```

## Outputs

- A complete Python package directory meeting PyPI publishing standards
- Built sdist + wheel artifacts
- Configured test and docs infrastructure

## Success criteria

- `uv build` produces a valid sdist and wheel
- `uv run twine check dist/*` reports no issues
- `py.typed` is present and the package ships accurate type hints
- Public API (`__all__`) is intentional, not accidental (every export documented)
- Package installs cleanly via `uv add mypackage` (or `pip install`) in a fresh environment

## Out of scope

- Non-published project structure → `python-project-scaffold`
- Detailed testing patterns → `python-testing`
- CI workflow configuration → `python-ci`
- mkdocs site theming → `python-documentation`

## Cross-references

- `python-project-scaffold` — non-published projects
- `python-testing` — pytest conventions
- `python-documentation` — docstrings, mkdocs, README
- `python-dependencies` — uv + pyproject dependency management
- `python-code-style` — naming and style conventions
- `python-ci` — build/publish checks in CI
