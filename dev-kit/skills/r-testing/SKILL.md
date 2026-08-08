---
name: r-testing
description: >
  Defines testthat 3e conventions, test organization, snapshot testing,
  coverage thresholds, and test helper patterns for R projects.
when_to_use: >
  Use to create tests, configure the test framework, verify test coverage,
  or understand testing conventions for an R project. Trigger phrases: "r
  test", "testthat", "write r tests", "test coverage r". Not for running
  QC audits (`run-repo-qc`) or code review (`code-review`).
model: sonnet
# persona: r-developer   — grouping metadata only; not read by Claude Code.
---

# R Testing

You are working with the test suite for an R project. This skill defines the testing framework, test organization, naming conventions, coverage expectations, and patterns for writing effective tests in R.

## Activation

Activate when the user needs to create tests, configure the test framework, verify test coverage, or understand testing conventions for an R project.

## Inputs

- **Required**: what to test (function, module, data pipeline, etc.)
- **Optional**: existing code to generate tests for
- **Optional**: specific edge cases to cover
- **Optional**: desired coverage threshold

## Steps

### 1. Testing framework

| Layer | Framework | Purpose |
|---|---|---|
| Unit tests | `testthat` (3e) | Individual functions, pure logic, transformations |
| Integration tests | `testthat` | Multi-function workflows, data pipeline stages |
| Snapshot tests | `testthat::expect_snapshot()` | Output stability for reports, plots, complex objects |

**Edition:** Always use testthat 3rd edition. Declare in DESCRIPTION:
```
Config/testthat/edition: 3
```

### 2. Test directory structure

```
tests/
├── testthat/
│   ├── helper.R                    # Shared setup (runs before all tests)
│   ├── setup.R                     # Package-level setup (load fixtures, etc.)
│   ├── test-utils-data.R           # Tests for R/functions/utils_data.R
│   ├── test-utils-formatting.R     # Tests for R/functions/utils_formatting.R
│   ├── test-pipeline-ingest.R      # Tests for pipeline ingestion stage
│   ├── test-pipeline-transform.R   # Tests for pipeline transformation stage
│   ├── _snaps/                     # Snapshot output directory (auto-generated)
│   └── fixtures/                   # Test data fixtures
│       ├── sample-input.csv
│       └── expected-output.rds
└── testthat.R                      # Test runner
```

### 3. File naming convention

| Source file | Test file |
|---|---|
| `R/functions/utils_data.R` | `tests/testthat/test-utils-data.R` |
| `R/functions/transform_orders.R` | `tests/testthat/test-transform-orders.R` |
| `R/scripts/01_ingest.R` | `tests/testthat/test-pipeline-ingest.R` |

**Rule:** Test file name = `test-` + source file name (without `.R`), using hyphens.

### 4. Test structure patterns

#### Basic unit test

```r
test_that("clean_names() converts to snake_case", {
  input <- data.frame(`First Name` = "A", `Last.Name` = "B")
  result <- clean_names(input)

  expect_equal(names(result), c("first_name", "last_name"))
})
```

#### Using describe/it blocks for BDD style

```r
describe("calculate_order_total()", {
  it("returns correct total for valid inputs", {
    expect_equal(calculate_order_total(unit_price = 19.99, quantity = 3), 59.97, tolerance = 0.01)
  })

  it("returns NA for missing inputs", {
    expect_true(is.na(calculate_order_total(unit_price = NA, quantity = 3)))
  })

  it("errors on negative values", {
    expect_error(calculate_order_total(unit_price = -1, quantity = 3), "must be positive")
  })
})
```

#### Parameterized tests with withr

```r
test_that("date_parser handles multiple formats", {
  cases <- list(
    list(input = "2024-01-15", expected = as.Date("2024-01-15")),
    list(input = "01/15/2024", expected = as.Date("2024-01-15")),
    list(input = "15-Jan-2024", expected = as.Date("2024-01-15"))
  )

  for (case in cases) {
    expect_equal(
      parse_date_flexible(case$input),
      case$expected,
      label = paste("Input:", case$input)
    )
  }
})
```

#### Snapshot tests for complex output

```r
test_that("summary_table produces expected output", {
  data <- readRDS(testthat::test_path("fixtures", "sample-data.rds"))
  result <- generate_summary_table(data)


  expect_snapshot(print(result))
})

test_that("plot renders consistently", {
  skip_on_ci()  # Skip if rendering differs across platforms
  data <- readRDS(testthat::test_path("fixtures", "plot-data.rds"))

  expect_snapshot_file(
    save_plot(create_order_plot(data), "test-plot.png"),
    name = "order-plot"
  )
})
```

### 5. Test helpers and fixtures

#### helper.R — shared utilities

```r
# tests/testthat/helper.R
# Runs before all test files

# Helper to create a minimal test dataset
make_test_orders <- function(n = 10) {
  data.frame(
    order_id = seq_len(n),
    amount = round(runif(n, 5, 500), 2),
    status = sample(c("pending", "shipped", "delivered"), n, replace = TRUE),
    order_date = Sys.Date() - sample(1:365, n)
  )
}

# Helper to suppress expected warnings during testing
expect_warning_message <- function(expr, pattern) {
  expect_warning(expr, regexp = pattern)
}
```

#### fixtures/ — static test data

- Store small, representative datasets as `.rds` or `.csv`
- Use `testthat::test_path("fixtures", "filename.rds")` to reference
- Never use production data in fixtures — create synthetic data
- Keep fixtures small (< 1 MB each)

### 6. Coverage requirements

| Metric | Threshold | Enforcement |
|---|---|---|
| Line coverage | ≥ 80% | Advisory (tracked in CI, not blocking — see `r-ci`) |
| Function coverage | 100% exported functions | Every exported function has at least one test |
| Branch coverage | Best-effort | Not gated but reviewed in PRs |

**Running coverage:**
```r
covr::package_coverage(
  type = "tests",
  quiet = FALSE
)

# Generate HTML report:
covr::report()
```

### 7. Testing conventions

**DO:**
- Test one behavior per `test_that()` block
- Use descriptive test names: `"function_name() handles edge case X"`
- Use `withr::local_*()` for temporary side effects (files, env vars, options)
- Use `testthat::test_path()` for fixture file references
- Test error messages with `expect_error(expr, "expected message")`
- Use `skip_on_ci()`, `skip_on_cran()`, `skip_if_not_installed()` for conditional tests

**DON'T:**
- Don't use `library()` in test files — use `pkg::function()` or rely on DESCRIPTION
- Don't test internal implementation details — test behavior
- Don't write tests that depend on execution order
- Don't use `setwd()` — use `withr::local_dir()` instead
- Don't hardcode file paths — use `testthat::test_path()`
- Don't leave `browser()` or `debug()` calls in test code

### 8. Running tests

```r
# Run all tests:
testthat::test_dir("tests/testthat/")

# Run a specific test file:
testthat::test_file("tests/testthat/test-utils-data.R")

# Run with verbose reporter:
testthat::test_dir("tests/testthat/", reporter = "summary")

# Via devtools (if using package structure):
devtools::test()
```

## Outputs

- Test files following the naming convention
- Properly structured test directory
- Coverage report (when requested)

## Success criteria

- All test files follow the `test-*.R` naming convention
- Tests use testthat 3e (no `context()` calls, `describe()`/`it()` or `test_that()`)
- Each test function tests one behavior
- Coverage meets the 80% line-coverage threshold
- Tests run independently (no order dependence)
- `testthat::test_dir("tests/testthat/")` passes cleanly

## Out of scope

- CI pipeline configuration for running tests → `r-ci`
- Load testing / performance benchmarks
- Manual QA processes

## Cross-references

- `r-project-scaffold` — sets up the tests/ directory
- `r-code-style` — style conventions that apply to test code too
- `r-ci` — running tests in CI
- `_partials/roxygen2-standards.md` (`${CLAUDE_SKILL_DIR}/../_partials/roxygen2-standards.md`) — documenting test helpers
