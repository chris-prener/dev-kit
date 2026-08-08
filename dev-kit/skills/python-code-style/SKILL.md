---
name: python-code-style
description: >
  Defines ruff configuration, naming rules (snake_case), docstring
  standards, and code organization patterns for Python projects.
when_to_use: >
  Use to configure linting/formatting, apply formatting, establish naming
  conventions, or review code style for a Python project. Trigger phrases:
  "python code style", "ruff", "python naming conventions", "python
  formatting", "black". Not for writing docstring content
  (`python-documentation`), project structure (`python-project-scaffold`),
  or correctness review (`code-review`).
model: sonnet
# persona: python-developer   — grouping metadata only; not read by Claude Code.
---

# Python Code Style

You are enforcing or applying code style conventions for a Python project. This skill defines the formatting rules, naming conventions, documentation standards, and code organization patterns your Python projects follow.

## Activation

Activate when the user needs to configure linting/formatting, apply formatting, establish naming conventions, or review code style for a Python project.

## Inputs

- **Required**: what to lint/format (file, directory, or specific question)
- **Optional**: whether to auto-fix (`ruff format`/`ruff check --fix`) or just report
- **Optional**: custom overrides to the default configuration

## Steps

### 1. Naming conventions

| Element | Convention | Example |
|---|---|---|
| Functions | snake_case, verb-first | `clean_order_data()`, `calculate_order_total()` |
| Variables | snake_case | `order_count`, `raw_data` |
| Constants | SCREAMING_SNAKE_CASE | `MAX_RETRY_COUNT`, `DEFAULT_THRESHOLD` |
| Classes | PascalCase | `OrderRegistry`, `DataValidator` |
| Modules | snake_case, short | `utils_data.py`, `transform_orders.py` |
| Test files | `test_` prefix | `test_utils_data.py`, `test_transform_orders.py` |
| Private/internal | leading underscore | `_internal_helper()`, `_CACHE` |
| Type variables | PascalCase, short | `T`, `TOrder` |

**Rules:**
- Boolean variables/parameters: prefix with `is_`, `has_`, `should_`, `can_`
- Function names: start with a verb (`get_`, `set_`, `calculate_`, `validate_`, `transform_`, `create_`, `parse_`)
- Never use single-letter names except loop indices (`i`, `j`) or well-known math symbols

### 2. ruff configuration

Follow `_partials/ruff-config.md` (`${CLAUDE_SKILL_DIR}/../_partials/ruff-config.md`)
for the canonical `[tool.ruff]` block to add to `pyproject.toml` — this is the
source of truth; `python-project-scaffold` follows the same partial.

### 3. ruff format (replaces black)

```bash
# Format a single file:
uv run ruff format src/mypackage/utils_data.py

# Format the whole project:
uv run ruff format .

# Check formatting without writing (CI mode):
uv run ruff format --check .
```

**ruff format conventions (black-compatible, the default):**
- 4-space indentation
- Double quotes for strings
- Trailing commas in multi-line collections
- Line length 100 (project override; ruff format respects `[tool.ruff] line-length`)
- One blank line between methods, two between top-level defs/classes

**When to run ruff format:**
- Before every commit (recommended: set up a pre-commit hook)
- After significant refactoring
- Never on generated files (`_version.py`, migrations)

### 4. Code organization within files

```python
"""Data cleaning and transformation utilities.

Functions for standardizing and validating order-level datasets.
"""

from __future__ import annotations

import re
from dataclasses import dataclass

import polars as pl

REQUIRED_COLUMNS = ("order_id", "amount")


def clean_order_data(
    data: pl.DataFrame,
    required_cols: tuple[str, ...] = REQUIRED_COLUMNS,
) -> pl.DataFrame:
    """Standardize column names, drop duplicates, and validate required fields.

    Args:
        data: Raw order records.
        required_cols: Columns that must be non-null.

    Returns:
        A cleaned DataFrame with standardized names.
    """
    data = data.rename({c: _to_snake_case(c) for c in data.columns})
    data = data.unique()
    return data.drop_nulls(subset=list(required_cols))


def _to_snake_case(name: str) -> str:
    """Convert a column name to snake_case."""
    return re.sub(r"(?<!^)(?=[A-Z])", "_", name).lower()
```

**File organization rules:**
- Module docstring at the top (purpose, not boilerplate)
- Standard-library imports, then third-party, then local — each group alphabetized (ruff's `I` rule enforces this)
- Constants after imports, before function definitions
- Functions ordered by dependency (callees before callers) or public-then-private
- Keep files under ~300 lines; split if larger
- One class or cohesive function group per module where practical

### 5. Import conventions

**Always use `from __future__ import annotations`** in modules targeting Python < 3.12 to defer annotation evaluation (harmless, still recommended, on 3.12+ too for consistency).

```python
# GOOD — explicit, sorted, grouped
from __future__ import annotations

import os
from pathlib import Path

import polars as pl
from prefect import flow

from mypackage.validation import validate_order

# BAD — wildcard imports (ruff F403 flags these)
from mypackage.validation import *
```

**Rules:**
- No wildcard imports outside of `__init__.py` re-exports
- Prefer absolute imports; relative imports only within a tightly-coupled subpackage
- One import per line for `from X import Y` when importing multiple names, unless they fit on one line cleanly

### 6. Style rules

| Rule | Good | Bad |
|---|---|---|
| String quotes | Double `"hello"` | Single `'hello'` (ruff format rewrites) |
| f-strings | `f"{name} total: {total}"` | `"%s total: %s" % (name, total)` |
| Type hints | `def f(x: int) -> str:` | Untyped public functions |
| Optional handling | `if value is None:` | `if not value:` (ambiguous with falsy) |
| Boolean checks | `if is_valid:` | `if is_valid == True:` |
| Path handling | `Path("data") / "output.csv"` | String concatenation `"data" + "/output.csv"` |
| Mutable defaults | `def f(items: list | None = None):` | `def f(items: list = []):` |

**Early return pattern:**
```python
def validate_input(data: pl.DataFrame | None) -> pl.DataFrame | None:
    if data is None:
        return None  # explicit early exit

    if data.is_empty():
        logger.warning("Empty dataset provided")
        return data  # explicit early exit

    # main logic...
    return cleaned_data
```

### 7. Running linting and formatting

```bash
# Lint a single file:
uv run ruff check src/mypackage/utils_data.py

# Lint the whole project:
uv run ruff check .

# Auto-fix what's safe to fix:
uv run ruff check . --fix

# Format:
uv run ruff format .

# In CI (non-zero exit on findings):
uv run ruff check . && uv run ruff format --check .
```

### 8. Editor integration

**VS Code:** install the `ruff` extension; enable "format on save" with ruff as the default formatter.

**Pre-commit hook** (`.pre-commit-config.yaml`):
```yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.16.2
    hooks:
      - id: ruff-check
        args: [--fix]
      - id: ruff-format
```

## Outputs

- `[tool.ruff]` configuration in `pyproject.toml`
- Formatted/linted Python source files
- Style guide reference for the project

## Success criteria

- `uv run ruff check .` returns zero findings
- `uv run ruff format --check .` reports no changes needed
- All function and variable names follow snake_case; classes follow PascalCase
- Public functions carry type hints and Google-style docstrings
- Code passes both `ruff check` and `ruff format` without conflict

## Out of scope

- Writing docstring content → `python-documentation`
- Enforcing test patterns → `python-testing`
- CI pipeline for linting → `python-ci`
- Package-specific conventions (public API surface) → `python-packaging`

## Cross-references

- `python-project-scaffold` — scaffolds the project, including the shared ruff config
- `python-testing` — style conventions apply to test code too
- `python-documentation` — Google-style docstring details
- `python-typing` — type hint conventions enforced alongside style
- `python-ci` — running ruff in CI
- `_partials/ruff-config.md` (`${CLAUDE_SKILL_DIR}/../_partials/ruff-config.md`) — canonical `[tool.ruff]` config block
- `_partials/inline-comment-standards.md` (`${CLAUDE_SKILL_DIR}/../_partials/inline-comment-standards.md`) — commenting guidelines
