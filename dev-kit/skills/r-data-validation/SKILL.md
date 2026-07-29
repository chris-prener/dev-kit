---
name: r-data-validation
description: >
  Defines data validation conventions for R projects: assertr/pointblank
  usage patterns, pipeline validation gates, and data quality reporting.
when_to_use: >
  Use to add data quality checks, validate pipeline inputs/outputs,
  configure validation frameworks, or establish data quality standards.
  Trigger phrases: "data validation r", "assertr", "pointblank", "validate
  data", "data quality". Not for unit testing R functions
  (`r-testing`), reading/writing data (`r-data-io`), or pipeline
  orchestration (`r-pipeline-patterns`).
model: sonnet
# persona: r-developer   — grouping metadata only; not read by Claude Code.
---

# R Data Validation

You are implementing data validation in an R project. This skill defines validation frameworks, assertion patterns, pipeline integration, and quality reporting conventions.

## Activation

Activate when the user needs to add data quality checks, validate pipeline inputs/outputs, configure validation frameworks, or establish data quality standards.

## Inputs

- **Required**: what data to validate (dataset description or sample)
- **Optional**: specific rules/expectations to enforce
- **Optional**: whether to fail-fast or collect all violations
- **Optional**: reporting format needed

## Steps

### 1. Framework selection

| Framework | Best for | Approach |
|---|---|---|
| `assertr` | Inline pipeline assertions, fail-fast | Pipe-based, throws errors |
| `pointblank` | Comprehensive validation reports, CI gates | Declarative agent, HTML reports |
| `stopifnot` / manual | Simple preconditions | Base R, minimal dependencies |

**Recommendation:** Use `assertr` for inline pipeline checks (tight feedback loop). Use `pointblank` for formal validation reports and CI gates.

### 2. assertr patterns

#### Basic assertions

```r
library(assertr)

orders |>
  verify(nrow(.) > 0) |>                              # Non-empty
  verify(has_all_names("order_id", "amount", "status")) |>  # Required columns
  assert(not_na, order_id) |>                          # No NAs in key
  assert(within_bounds(0, 100000), amount) |>          # Range check
  assert(in_set("pending", "shipped", "delivered", "cancelled"), status) |>  # Allowed values
  assert(is_uniq, order_id)                            # Uniqueness
```

#### Custom predicates

```r
# Define reusable predicates:
is_valid_date <- function(x) {
  !is.na(x) & x >= as.Date("2000-01-01") & x <= Sys.Date()
}

is_valid_id <- function(x) {
  grepl("^ORD-[0-9]{6}$", x)
}

# Use in assertions:
orders |>
  assert(is_valid_date, order_date) |>
  assert(is_valid_id, order_id)
```

#### Error handling strategies

```r
# Fail-fast (default — stops on first violation):
orders |>
  assert(not_na, order_id)

# Collect all errors (report everything, then fail):
orders |>
  chain_start() |>
  assert(not_na, order_id) |>
  assert(within_bounds(0, 100000), amount) |>
  assert(in_set("pending", "shipped"), status) |>
  chain_end()

# Warning instead of error (non-blocking):
orders |>
  assert(not_na, order_id, error_fun = warning_append)

# Custom error handler (log to file):
log_violation <- function(errors, data) {
  writeLines(
    paste(Sys.time(), errors$message, sep = " | "),
    con = "logs/validation_errors.log"
  )
  data  # Return data to continue pipeline
}

orders |>
  assert(not_na, order_id, error_fun = log_violation)
```

### 3. pointblank patterns

#### Agent-based validation

```r
library(pointblank)

# Define the validation agent:
agent <- orders |>
  create_agent(
    tbl_name = "orders",
    label = "Order data quality check"
  ) |>
  col_exists(columns = c("order_id", "amount", "status", "order_date")) |>
  rows_distinct(columns = "order_id") |>
  col_vals_not_null(columns = "order_id") |>
  col_vals_between(columns = "amount", left = 0, right = 100000) |>
  col_vals_in_set(columns = "status", set = c("pending", "shipped", "delivered", "cancelled")) |>
  col_vals_gte(columns = "order_date", value = as.Date("2000-01-01")) |>
  col_vals_lte(columns = "order_date", value = Sys.Date()) |>
  col_vals_regex(columns = "order_id", regex = "^ORD-[0-9]{6}$") |>
  interrogate()

# Check results:
all_passed(agent)  # TRUE/FALSE

# Generate HTML report:
export_report(agent, filename = "docs/validation_report.html")
```

#### Action levels (severity tiers)

```r
agent <- orders |>
  create_agent(
    actions = action_levels(
      warn_at = 0.01,   # Warn if > 1% of rows fail
      stop_at = 0.05,   # Stop if > 5% of rows fail
      notify_at = 0.10  # Notify if > 10% fail
    )
  ) |>
  col_vals_not_null(columns = "order_id") |>
  col_vals_between(columns = "amount", left = 0, right = 100000) |>
  interrogate()
```

#### Informant (data dictionary)

```r
# Document expected data shape:
informant <- orders |>
  create_informant(
    tbl_name = "orders",
    label = "Order dataset specification"
  ) |>
  info_tabular(description = "One row per order line.") |>
  info_columns(
    columns = "order_id",
    info = "Unique order identifier. Format: ORD-000001."
  ) |>
  info_columns(
    columns = "amount",
    info = "Order amount in dollars. Range: 0-100000."
  ) |>
  incorporate()
```

### 4. Pipeline integration

#### With targets

```r
# _targets.R — validation as a pipeline target:
tar_target(
  validated_orders,
  validate_orders(clean_orders),
  error = "stop"  # Pipeline halts on validation failure
)
```

```r
# R/functions/validate.R
validate_orders <- function(orders) {
  orders |>
    assertr::verify(nrow(.) > 0) |>
    assertr::assert(assertr::not_na, order_id, amount) |>
    assertr::assert(assertr::within_bounds(0, 100000), amount) |>
    assertr::assert(assertr::is_uniq, order_id)
}
```

#### Input validation (function preconditions)

```r
#' Process order data
#'
#' @param data Data frame with required columns.
#' @return Processed data frame.
process_orders <- function(data) {
  # Preconditions — fail fast with clear messages
  stopifnot(
    "data must be a data.frame" = is.data.frame(data),
    "data must have order_id column" = "order_id" %in% names(data),
    "data must not be empty" = nrow(data) > 0
  )

  # Business logic...
  data
}
```

### 5. Common validation patterns

| Check | assertr | pointblank |
|---|---|---|
| Non-null | `assert(not_na, col)` | `col_vals_not_null(col)` |
| Unique | `assert(is_uniq, col)` | `rows_distinct(col)` |
| Range | `assert(within_bounds(a, b), col)` | `col_vals_between(col, a, b)` |
| Allowed values | `assert(in_set(...), col)` | `col_vals_in_set(col, set)` |
| Regex | `assert(matches("^...$"), col)` | `col_vals_regex(col, regex)` |
| Row count | `verify(nrow(.) > N)` | `col_count_match(n)` |
| Column exists | `verify(has_all_names(...))` | `col_exists(columns)` |
| Type check | `verify(is.numeric(col))` | `col_is_numeric(col)` |

### 6. Reporting and monitoring

```r
# Save validation results for audit trail:
results <- list(
  timestamp = Sys.time(),
  dataset = "orders",
  row_count = nrow(orders),
  passed = all_passed(agent),
  summary = get_agent_report(agent, display_table = FALSE)
)
saveRDS(results, fs::path("logs", paste0("validation_", Sys.Date(), ".rds")))
```

## Outputs

- Validation code (assertr assertions or pointblank agent)
- Validation reports (HTML via pointblank, or log files)
- Clear pass/fail signals for pipeline gates

## Success criteria

- Every pipeline has at least input + output validation
- Validation failures produce clear, actionable error messages
- Critical checks fail-fast; non-critical checks warn
- Validation results are logged for audit trail
- No silent data corruption passes through unchecked

## Out of scope

- Unit testing of R functions → `r-testing`
- Data I/O mechanics → `r-data-io`
- Pipeline orchestration → `r-pipeline-patterns`
- Schema definition/evolution — currently ad-hoc per project
- Statistical validation (distribution tests, outlier detection)

## Cross-references

- `r-pipeline-patterns` — validation targets in pipelines
- `r-data-io` — reading data before validation
- `r-testing` — testing validation functions themselves
- `r-code-style` — naming validation functions
