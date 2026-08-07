# ruff configuration (shared partial)

Referenced by `python-code-style` and `python-project-scaffold`.

Add to `pyproject.toml`:

```toml
[tool.ruff]
line-length = 100
target-version = "py312"

[tool.ruff.lint]
select = [
    "E", "F",     # pycodestyle errors, pyflakes
    "I",          # isort (import sorting)
    "N",          # pep8-naming
    "UP",         # pyupgrade
    "B",          # bugbear (likely bugs)
    "D",          # pydocstyle (docstring presence/format)
    "SIM",        # flake8-simplify
]
ignore = [
    "D203",   # conflicts with D211
    "D213",   # conflicts with D212
]

[tool.ruff.lint.pydocstyle]
convention = "google"

[tool.ruff.lint.per-file-ignores]
"tests/*" = ["D"]   # tests don't need docstrings on every function
```

**Key rule groups enabled:**
- `E`/`F` — correctness and pycodestyle baseline
- `I` — import sorting (replaces isort as a separate tool)
- `N` — naming conventions (snake_case functions, PascalCase classes)
- `UP` — modernizes syntax to the target Python version
- `B` — catches common bugs (mutable default args, bare except)
- `D` — docstring presence and Google-style format
- `SIM` — flags code that can be simplified (e.g. nested ifs, redundant comprehensions)

**Per-file ignores:**
- `tests/*` exempts test files from `D` (docstring) rules — tests don't need
  docstrings on every function.
