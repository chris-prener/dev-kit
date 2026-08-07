---
name: python-documentation
description: >
  Defines Python documentation conventions: Google-style docstrings,
  README structure, and mkdocs + mkdocstrings site configuration.
when_to_use: >
  Use to document functions, structure a README, or configure a mkdocs
  site. Trigger phrases: "python docstrings", "python documentation",
  "mkdocs", "mkdocstrings", "document python". Not for generic
  non-Python-specific project documentation (`documentation`), code
  style/formatting (`python-code-style`), pipeline documentation
  (`python-pipeline-patterns`), or changelog maintenance (`changelog`).
model: sonnet
# persona: python-developer   — grouping metadata only; not read by Claude Code.
---

# Python Documentation

You are writing or maintaining documentation for a Python project or package. This skill defines Google-style docstring conventions, README structure, and mkdocs configuration.

## Activation

Activate when the user needs to document functions, structure a README, or configure a mkdocs site.

## Inputs

- **Required**: what to document (function, package, workflow)
- **Optional**: existing code to document
- **Optional**: target audience (developers, users, stakeholders)

## Steps

### 1. Google-style docstrings

```python
def calculate_order_total(
    unit_price: float,
    quantity: int,
    round_digits: int = 2,
) -> float:
    """Compute the line total for an order from unit price and quantity.

    Returns 0.0 rather than raising for a zero-quantity order, since that's
    a valid (if unusual) line item in the source system.

    Args:
        unit_price: Price per unit in dollars. Must be positive.
        quantity: Number of units ordered. Must be non-negative.
        round_digits: Number of decimal places to round to. Defaults to 2.

    Returns:
        The order total (unit_price * quantity), rounded to round_digits.

    Raises:
        ValueError: If unit_price is not positive.

    Examples:
        >>> calculate_order_total(19.99, 3)
        59.97
    """
    if unit_price <= 0:
        raise ValueError("unit_price must be positive")
    return round(unit_price * quantity, round_digits)
```

### 2. Required docstring sections

| Section | Required? | Purpose |
|---|---|---|
| Summary line | Yes | One-line description, imperative mood, ends in a period |
| Extended description | If non-obvious | Why the function behaves this way, not just what it does |
| `Args:` | Yes (all params) | Parameter name, meaning, constraints (type comes from the annotation, not restated) |
| `Returns:` | Yes (unless `None`) | What's returned and what it means |
| `Raises:` | If it raises deliberately | Exception type and the condition that triggers it |
| `Examples:` | Recommended for public API | Runnable doctest-style usage |

**Rule:** don't restate the type annotation in the docstring (`unit_price (float): ...`) — the signature already carries the type. The docstring explains meaning and constraints the type can't express.

### 3. Documentation patterns by function type

#### Data transformation function

```python
def transform_orders(raw_data: pl.DataFrame, remove_duplicates: bool = True) -> pl.DataFrame:
    """Apply the standard cleaning pipeline to raw order records.

    Deduplicates, coerces types, parses dates, and derives the order_year
    column.

    Args:
        raw_data: Raw order records with columns order_id (str), amount
            (str or float), order_date (str, YYYY-MM-DD).
        remove_duplicates: Whether to deduplicate on order_id. Defaults to True.

    Returns:
        A DataFrame with columns order_id (str), amount (float),
        order_date (date), order_year (int). Rows with a null order_id
        are dropped.
    """
```

#### Validation function

```python
def validate_orders(data: pl.DataFrame, strict: bool = True) -> pl.DataFrame:
    """Run the standard validation suite on an order dataset.

    Checks completeness, value ranges, uniqueness, and referential integrity.

    Args:
        data: Order records to validate.
        strict: If True, any violation raises pandera.errors.SchemaError.
            If False, violations are collected and available via the
            returned schema's error report. Defaults to True.

    Returns:
        The validated data, unchanged, on success.

    Raises:
        pandera.errors.SchemaError: If strict is True and validation fails.
    """
```

### 4. README structure for Python projects

```markdown
# packagename

[![CI](https://github.com/org/repo/actions/workflows/ci.yaml/badge.svg)](...)
[![codecov](https://codecov.io/gh/org/repo/branch/main/graph/badge.svg)](...)

Brief one-paragraph description of what this package/project does.

## Installation

\```bash
uv add packagename
\```

## Quick Start

\```python
import packagename

# Minimal working example (3-5 lines):
result = packagename.do_main_thing(input_value)
\```

## Features

- Feature 1: brief description
- Feature 2: brief description

## Documentation

- [Full documentation](https://org.github.io/packagename/) (mkdocs)

## Development

\```bash
# Setup:
uv sync

# Run tests:
uv run pytest

# Lint and type-check:
uv run ruff check .
uv run mypy src
\```

## License

[License type](LICENSE)
```

### 5. mkdocs configuration

```yaml
# mkdocs.yml
site_name: packagename
theme:
  name: material
  palette:
    - scheme: default
      toggle:
        icon: material/brightness-7
        name: Switch to dark mode
    - scheme: slate
      toggle:
        icon: material/brightness-4
        name: Switch to light mode

nav:
  - Home: index.md
  - Getting Started: getting-started.md
  - API Reference: reference.md

plugins:
  - search
  - mkdocstrings:
      handlers:
        python:
          options:
            docstring_style: google
            show_source: true
```

```markdown
<!-- docs/reference.md — auto-generated API docs from docstrings -->
::: mypackage.core
::: mypackage.validation
```

**Rules:**
- `docs/index.md` mirrors the README's quick-start (mkdocs sites and the GitHub README serve different audiences)
- One page per major workflow under `docs/`; keep pages under ~500 lines, split if larger
- `mkdocstrings` pulls API reference directly from docstrings — keep docstrings accurate, they're now user-facing

### 6. Inline code comments

Follow the `_partials/inline-comment-standards.md` conventions:

```python
# BAD — restates the code (what)
# filter to rows where year is greater than 2010
df = df.filter(pl.col("year") > 2010)

# GOOD — explains the reasoning (why)
# sales data before 2011 uses inconsistent region codes
df = df.filter(pl.col("year") > 2010)
```

### 7. Building and checking documentation

```bash
# Build and serve locally:
uv run mkdocs serve

# Build static site:
uv run mkdocs build --strict   # --strict fails the build on broken links/refs

# Check docstring coverage (via ruff's D rules, already part of python-code-style):
uv run ruff check --select D .
```

## Outputs

- Complete Google-style docstrings on public functions
- Package README
- mkdocs site with auto-generated API reference

## Success criteria

- Every public function/class has a summary line, `Args:`, and `Returns:` (or `Raises:` where relevant)
- `uv run ruff check --select D .` reports no missing-docstring findings on public interfaces
- README has installation + quick start + development sections
- `uv run mkdocs build --strict` succeeds
- No undocumented public functions

## Out of scope

- Generic documentation (non-Python) → `documentation`
- Code style → `python-code-style`
- Changelog → `changelog`
- Package build metadata → `python-packaging`

## Cross-references

- `python-packaging` — package-level docs setup, README as PyPI long description
- `python-code-style` — ruff's `D` (pydocstyle) rules enforce docstring presence
- `readme` — generic README maintenance
- `_partials/inline-comment-standards.md` (`${CLAUDE_SKILL_DIR}/../_partials/inline-comment-standards.md`) — inline comment patterns
