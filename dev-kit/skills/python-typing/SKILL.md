---
name: python-typing
description: >
  Defines type hint conventions, mypy strict-mode configuration, py.typed
  packaging, generics, and Protocol usage for Python projects.
when_to_use: >
  Use to add type hints, configure mypy, resolve type errors, or design
  generic/protocol-based interfaces. Trigger phrases: "python typing",
  "mypy", "type hints", "pyright", "python generics", "protocol python".
  Not for runtime data validation (`python-data-validation`), general code
  style (`python-code-style`), or docstring content (`python-documentation`).
model: sonnet
# persona: python-developer   — grouping metadata only; not read by Claude Code.
---

# Python Typing

You are adding or maintaining type hints in a Python project. This skill defines annotation conventions, mypy configuration, generics/Protocol patterns, and the boundary between static typing and runtime validation.

## Activation

Activate when the user needs to add type hints, configure mypy, resolve type errors, or design generic/protocol-based interfaces.

## Inputs

- **Required**: what needs typing (function, class, module) or what error to resolve
- **Optional**: whether strict mode is already enabled
- **Optional**: whether the code is a library (ships `py.typed`) or an application

## Steps

### 1. Baseline: every public interface is typed

```python
# GOOD — fully typed public function
def calculate_order_total(unit_price: float, quantity: int, round_digits: int = 2) -> float:
    return round(unit_price * quantity, round_digits)

# BAD — untyped public function (mypy strict mode rejects this)
def calculate_order_total(unit_price, quantity, round_digits=2):
    return round(unit_price * quantity, round_digits)
```

**Rule:** every function/method in the public API (no leading `_`) must have parameter and return annotations. Private helpers should still be typed unless the inference is trivially obvious (e.g., a one-line lambda).

### 2. mypy configuration

```toml
# pyproject.toml
[tool.mypy]
python_version = "3.12"
strict = true
files = ["src"]
warn_unused_ignores = true
warn_redundant_casts = true

[[tool.mypy.overrides]]
module = ["some_untyped_lib.*"]
ignore_missing_imports = true
```

**What `strict = true` enables:** disallows untyped defs, disallows `Any` leaking from untyped calls, requires explicit `Optional`, flags unused `# type: ignore` comments, and more. Treat strict mode as the default for new projects; only relax it deliberately, module by module.

**Running mypy:**
```bash
uv run mypy src

# Check a single file:
uv run mypy src/mypackage/utils_data.py
```

**Editor-time alternative:** `pyright` (via the Pylance VS Code extension) gives faster, IDE-integrated feedback. Use mypy as the CI gate of record; pyright is fine as an editor supplement, but don't let the two disagree — if they do, mypy's config in `pyproject.toml` is authoritative.

### 3. Modern annotation syntax (3.10+)

```python
# GOOD — PEP 604 union syntax
def find_order(order_id: str) -> Order | None: ...

def process(items: list[str], counts: dict[str, int]) -> None: ...

# BAD — legacy typing module forms (still valid but unnecessarily verbose on 3.10+)
from typing import Optional, List, Dict
def find_order(order_id: str) -> Optional[Order]: ...
```

Use built-in generics (`list[int]`, `dict[str, int]`, `tuple[int, ...]`) instead of `typing.List`/`Dict`/`Tuple` — supported natively since Python 3.9.

### 4. Generics

```python
from typing import Generic, TypeVar

T = TypeVar("T")


class Cache(Generic[T]):
    """A simple typed cache keyed by string."""

    def __init__(self) -> None:
        self._store: dict[str, T] = {}

    def get(self, key: str) -> T | None:
        return self._store.get(key)

    def set(self, key: str, value: T) -> None:
        self._store[key] = value
```

On Python 3.12+, prefer the native generic syntax:

```python
class Cache[T]:
    def __init__(self) -> None:
        self._store: dict[str, T] = {}
```

### 5. Protocol for structural typing

Use `Protocol` when you want to accept "anything with this shape" rather than requiring inheritance:

```python
from typing import Protocol


class SupportsToParquet(Protocol):
    def to_parquet(self, path: str) -> None: ...


def save_dataset(data: SupportsToParquet, path: str) -> None:
    data.to_parquet(path)
```

Both `polars.DataFrame` and `pandas.DataFrame` satisfy `SupportsToParquet` without either inheriting from it — this is the idiomatic Python alternative to defining an abstract base class purely for a typing contract.

### 6. Dataclasses and typed records

```python
from dataclasses import dataclass, field


@dataclass(frozen=True, slots=True)
class Order:
    order_id: str
    amount: float
    status: str
    tags: list[str] = field(default_factory=list)
```

**Rules:**
- `frozen=True` for immutable value objects (mirrors R's functional-purity preference)
- `slots=True` for memory efficiency on high-volume records
- Never use a mutable default directly (`tags: list[str] = []`) — always `field(default_factory=list)`

### 7. Typing vs. runtime validation — the boundary

Type hints are **not** checked at runtime; they are erased. `mypy`/`pyright` catch mismatches at development time, but nothing stops `calculate_order_total("bad", "input")` from executing and failing downstream.

| Need | Tool |
|---|---|
| Development-time contract checking | mypy / pyright (this skill) |
| Runtime validation of external input (API payloads, CLI args, config files) | `pydantic` (`python-data-validation`) |
| Runtime validation of dataframes | `pandera` (`python-data-validation`) |

Don't reach for `isinstance()` checks to simulate runtime typing in application code — that's what `python-data-validation` is for at trust boundaries. Internal function calls should trust the type hints.

### 8. `Any` and `# type: ignore` discipline

```python
# BAD — silences the error without explaining why
result = untyped_library.process(data)  # type: ignore

# GOOD — narrow, explained
result: dict[str, int] = untyped_library.process(data)  # type: ignore[no-any-return]  # untyped-library has no stubs
```

**Rules:**
- Never use bare `Any` in a public signature unless the function is genuinely generic over any type (rare)
- Every `# type: ignore` must have an error code and a reason comment
- Prefer fixing the root cause (adding stubs via `types-<package>`, or a local `.pyi` stub) over suppressing

### 9. Shipping types in a library (`py.typed`)

```
src/mypackage/py.typed    # empty marker file
```

Add to `pyproject.toml`:
```toml
[tool.hatch.build.targets.wheel]
packages = ["src/mypackage"]
# py.typed is included automatically when present in the package dir
```

Without `py.typed`, consumers' type checkers treat your package as untyped (`Any` everywhere), even if your source has full annotations.

## Outputs

- Fully annotated public interfaces
- `[tool.mypy]` strict configuration
- `py.typed` marker for publishable packages

## Success criteria

- `uv run mypy src` passes with zero errors under `strict = true`
- No unexplained `# type: ignore` comments
- All public functions/classes have complete parameter and return annotations
- Generics use built-in syntax (`list[int]`, not `typing.List[int]`)
- Runtime input validation lives in `python-data-validation`, not ad-hoc `isinstance` checks

## Out of scope

- Runtime schema/data validation → `python-data-validation`
- General code style/formatting → `python-code-style`
- Docstring content → `python-documentation`

## Cross-references

- `python-code-style` — ruff enforces style alongside mypy's type checks
- `python-data-validation` — pydantic/pandera for runtime validation at trust boundaries
- `python-packaging` — `py.typed` and shipping typed libraries
- `python-ci` — running mypy in CI
