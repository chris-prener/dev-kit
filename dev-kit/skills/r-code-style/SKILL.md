---
name: r-code-style
description: >
  Defines lintr configuration, styler conventions, naming rules (snake_case),
  roxygen2 documentation standards, and code organization patterns for R projects.
when_to_use: >
  Use to configure linting, apply formatting, establish naming conventions,
  or review code style for an R project. Trigger phrases: "r code style",
  "lintr", "styler", "r naming conventions", "r formatting". Not for writing
  roxygen2 documentation content (`r-documentation`), project structure
  (`r-project-scaffold`), or correctness review (`code-review`).
model: sonnet
# persona: r-developer   — grouping metadata only; not read by Claude Code.
---

# R Code Style

You are enforcing or applying code style conventions for an R project. This skill defines the formatting rules, naming conventions, documentation standards, and code organization patterns your R projects follow.

## Activation

Activate when the user needs to configure linting, apply formatting, establish naming conventions, or review code style for an R project.

## Inputs

- **Required**: what to lint/style (file, directory, or specific question)
- **Optional**: whether to auto-fix (styler) or just report (lintr)
- **Optional**: custom overrides to the default configuration

## Steps

### 1. Naming conventions

| Element | Convention | Example |
|---|---|---|
| Functions | snake_case, verb-first | `clean_order_data()`, `calculate_order_total()` |
| Variables | snake_case | `order_count`, `raw_data` |
| Constants | SCREAMING_SNAKE_CASE | `MAX_RETRY_COUNT`, `DEFAULT_THRESHOLD` |
| R6 classes | PascalCase | `OrderRegistry`, `DataValidator` |
| S4 classes | PascalCase | `OrderRecord`, `CustomerProfile` |
| File names | snake_case | `utils_data.R`, `transform_orders.R` |
| Test files | `test-` prefix, hyphenated | `test-utils-data.R`, `test-transform-orders.R` |
| Function files | descriptive, grouped | `utils_*.R`, `fct_*.R`, `transform_*.R` |

**Rules:**
- Never use `.` in names (except S3 methods): `data.frame` is base R, but your functions should be `data_frame_summary()`
- Boolean variables/parameters: prefix with `is_`, `has_`, `should_`, `can_`
- Function names: start with a verb (`get_`, `set_`, `calculate_`, `validate_`, `transform_`, `create_`, `parse_`)

### 2. lintr configuration

Follow `_partials/lintr-config.md` (`${CLAUDE_SKILL_DIR}/../_partials/lintr-config.md`)
for the canonical `.lintr` block to create at the project root — this is the
source of truth; `r-project-scaffold` follows the same partial.

### 3. styler configuration

Use `styler` for auto-formatting. Apply via:

```r
# Style a single file:
styler::style_file("R/functions/utils_data.R")

# Style all R files in a directory:
styler::style_dir("R/")

# Style the entire project:
styler::style_pkg()
```

**styler conventions (tidyverse style, the default):**
- 2-space indentation
- Spaces around operators: `x <- 1 + 2`, not `x<-1+2`
- Spaces after commas: `f(x, y)`, not `f(x,y)`
- Opening brace on same line: `if (x) {`
- Closing brace on its own line
- No spaces inside parentheses: `f(x)`, not `f( x )`

**When to run styler:**
- Before every commit (recommended: set up a pre-commit hook)
- After significant refactoring
- Never on auto-generated files (NAMESPACE, renv/)

### 4. Code organization within files

```r
# ─── Header ─────────────────────────────────────────────────────────────────
# File: utils_data.R
# Purpose: Data cleaning and transformation utilities
# ─────────────────────────────────────────────────────────────────────────────

#' Clean order data
#'
#' @description Standardizes column names, removes duplicates, and validates
#'   required fields in an order-level dataset.
#'
#' @param data A data.frame of raw order records.
#' @param required_cols Character vector of columns that must be non-NA.
#'
#' @return A cleaned data.frame with standardized names.
#' @export
clean_order_data <- function(data, required_cols = c("order_id", "amount")) {
  # Validate inputs

  stopifnot(is.data.frame(data))
  stopifnot(all(required_cols %in% names(data)))

  # Standardize column names
  data <- janitor::clean_names(data)

  # Remove exact duplicates

  data <- dplyr::distinct(data)

  # Validate required columns
  data <- data[stats::complete.cases(data[, required_cols, drop = FALSE]), ]

  data
}
```

**File organization rules:**
- One file header comment block (purpose, not boilerplate)
- Functions ordered by dependency (callees before callers) or alphabetically
- Group related functions in the same file
- Keep files under ~300 lines; split if larger
- Use section separators (`# ─── Section ───`) for files with multiple logical groups

### 5. Package namespacing

**Always use explicit namespacing in function code:**

```r
# GOOD — explicit namespace
result <- dplyr::filter(data, amount > 0)
path <- fs::path("data", "output.parquet")

# BAD — implicit namespace (requires library() call)
result <- filter(data, amount > 0)
path <- path("data", "output.parquet")
```

**Exceptions:**
- Base R functions: no namespace needed (`mean()`, `print()`, `data.frame()`)
- Pipe operators: `|>` (base pipe, preferred) or `%>%` (magrittr, acceptable)
- Within package code: functions from your own package don't need namespacing

### 6. Assignment and style rules

| Rule | Good | Bad |
|---|---|---|
| Assignment operator | `x <- 1` | `x = 1` |
| Return values | Implicit (last expression) | Explicit `return()` unless early exit |
| Pipe style | `\|>` (base, preferred) | `%>%` (acceptable) |
| String quotes | Double `"hello"` | Single `'hello'` (acceptable but be consistent) |
| TRUE/FALSE | `TRUE`, `FALSE` | `T`, `F` |
| NULL checks | `is.null(x)` | `x == NULL` |
| Empty vectors | `character(0)`, `numeric(0)` | `c()` |

**Early return pattern:**
```r
validate_input <- function(data) {
  if (is.null(data)) {
    return(NULL)  # Explicit return for early exit
  }
  if (nrow(data) == 0) {
    cli::cli_warn("Empty dataset provided")
    return(data)  # Explicit return for early exit
  }

  # Main logic...
  cleaned_data  # Implicit return for final value
}
```

### 7. Running linting

```r
# Lint a single file:
lintr::lint("R/functions/utils_data.R")

# Lint a directory:
lintr::lint_dir("R/")

# Lint the whole project (respects .lintr config):
lintr::lint_package()

# In CI (returns non-zero exit on findings):
# Rscript -e 'if (length(lintr::lint_dir("R/")) > 0) quit(status = 1)'
```

### 8. Editor integration

**RStudio:**
- Enable "Strip trailing whitespace on save"
- Set "Tab width" to 2
- Enable "Insert spaces for tabs"
- Enable "Ensure that source files end with newline"

**VS Code (with R extension):**
- `r.lsp.diagnostics` enables lintr integration
- Format-on-save with styler via languageserver

## Outputs

- `.lintr` configuration file
- Styled/linted R source files
- Style guide reference for the project

## Success criteria

- `lintr::lint_dir("R/")` returns zero findings
- All function and variable names follow snake_case
- All files use 2-space indentation, `<-` assignment, explicit namespacing
- styler produces no changes on already-formatted code
- Code passes both lintr and styler without conflict

## Out of scope

- Writing documentation content → `r-documentation`
- Enforcing test patterns → `r-testing`
- CI pipeline for linting → `r-ci`
- Package-specific conventions (NAMESPACE exports) → `r-package-structure`

## Cross-references

- `r-project-scaffold` — scaffolds the project, including the shared .lintr config
- `r-testing` — style conventions apply to test code
- `r-documentation` — roxygen2 documentation details
- `r-ci` — running lintr in CI
- `_partials/roxygen2-standards.md` (`${CLAUDE_SKILL_DIR}/../_partials/roxygen2-standards.md`) — roxygen2 tag reference
- `_partials/inline-comment-standards.md` (`${CLAUDE_SKILL_DIR}/../_partials/inline-comment-standards.md`) — commenting guidelines
- `_partials/lintr-config.md` (`${CLAUDE_SKILL_DIR}/../_partials/lintr-config.md`) — canonical `.lintr` config block
