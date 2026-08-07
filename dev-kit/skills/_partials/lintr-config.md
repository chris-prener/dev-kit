# .lintr configuration (shared partial)

Referenced by `r-code-style` and `r-project-scaffold`.

Create `.lintr` at the project root:

```r
linters:
  linters_with_defaults(
    line_length_linter(120),
    object_name_linter(styles = "snake_case"),
    commented_code_linter = NULL,
    cyclocomp_linter(complexity_limit = 15),
    function_argument_linter = NULL
  )
exclusions:
  list(
    "renv" = list(linters = "all"),
    "data-raw" = list(linters = "all")
  )
```

**Key linters enabled by default:**
- `line_length_linter(120)` — max 120 characters per line
- `object_name_linter("snake_case")` — enforce snake_case
- `cyclocomp_linter(15)` — flag overly complex functions
- `assignment_linter` — use `<-` not `=` for assignment
- `spaces_inside_linter` — no spaces inside `[` or `(`
- `trailing_whitespace_linter` — no trailing spaces
- `no_tab_linter` — spaces only (2-space indent)

**Linters explicitly disabled:**
- `commented_code_linter` — too many false positives with examples in comments
- `function_argument_linter` — conflicts with tidyverse-style pipelines

**Exclusions:**
- `renv` — package management internals, not project code
- `data-raw` — raw source data scripts, excluded from style linting
