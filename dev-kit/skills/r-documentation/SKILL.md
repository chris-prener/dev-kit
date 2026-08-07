---
name: r-documentation
description: >
  Defines R documentation conventions: roxygen2 for functions, vignettes
  for workflows, README structure, and pkgdown site configuration.
when_to_use: >
  Use to document functions, create vignettes, structure a README, or
  configure pkgdown. Trigger phrases: "roxygen2", "r documentation", "r
  vignette", "pkgdown", "document r". Not for generic non-R-specific
  project documentation (`documentation`), code style/formatting
  (`r-code-style`), pipeline documentation (`r-pipeline-patterns`), or
  changelog maintenance (`changelog`).
model: sonnet
# persona: r-developer   — grouping metadata only; not read by Claude Code.
---

# R Documentation

You are writing or maintaining documentation for an R project or package. This skill defines roxygen2 conventions, vignette authoring, README structure, and pkgdown configuration.

## Activation

Activate when the user needs to document functions, create vignettes, structure a README, or configure pkgdown.

## Inputs

- **Required**: what to document (function, package, workflow)
- **Optional**: existing code to document
- **Optional**: target audience (developers, users, stakeholders)

## Steps

### 1. Roxygen2 function documentation

```r
#' Calculate Order Total
#'
#' @description
#' Computes the line total for an order from unit price and quantity.
#' Returns NA for missing or invalid inputs rather than erroring.
#'
#' @param unit_price Numeric. Price per unit in dollars. Must be positive.
#' @param quantity Numeric. Number of units ordered. Must be positive.
#' @param round_digits Integer. Number of decimal places to round to.
#'   Default: 2.
#'
#' @return Numeric order total (unit_price * quantity), or NA if inputs are invalid.
#'
#' @examples
#' calculate_order_total(19.99, 3)
#' #> [1] 59.97
#'
#' calculate_order_total(NA, 3)
#' #> [1] NA
#'
#' @export
#' @seealso [classify_order_size()] for size-tier assignment.
#' @family order-metrics
calculate_order_total <- function(unit_price, quantity, round_digits = 2L) {
  if (is.na(unit_price) || is.na(quantity)) return(NA_real_)
  if (unit_price <= 0 || quantity <= 0) return(NA_real_)
  round(unit_price * quantity, round_digits)
}
```

### 2. Required roxygen2 tags

| Tag | Required? | Purpose |
|---|---|---|
| `@description` | Yes | What the function does (1-3 sentences) |
| `@param` | Yes (all params) | Parameter name, type, meaning, constraints |
| `@return` | Yes | What the function returns (type + meaning) |
| `@export` | If public | Makes function available to users |
| `@examples` | Recommended | Runnable usage examples |
| `@seealso` | If related | Links to related functions |
| `@family` | If grouped | Groups related functions in docs index |
| `@importFrom` | If needed | Import specific external functions |
| `@keywords internal` | If private | Marks as internal (still documented) |

### 3. Documentation patterns by function type

#### Data transformation function

```r
#' Transform raw order records to analysis-ready format
#'
#' @description
#' Applies the standard cleaning pipeline: deduplication, type coercion,
#' date parsing, and derived column creation.
#'
#' @param raw_data Data frame. Raw order records with columns:
#'   `order_id` (character), `amount` (character or numeric),
#'   `order_date` (character in YYYY-MM-DD format).
#' @param remove_duplicates Logical. Whether to deduplicate on order_id.
#'   Default: TRUE.
#'
#' @return A tibble with columns: `order_id` (character), `amount` (double),
#'   `order_date` (Date), `order_year` (integer).
#'   Rows with NA order_id are dropped.
#'
#' @export
```

#### Validation function

```r
#' Validate order dataset against quality rules
#'
#' @description
#' Runs the standard validation suite on an order dataset. Checks for
#' completeness, value ranges, uniqueness, and referential integrity.
#'
#' @param data Data frame to validate.
#' @param strict Logical. If TRUE, any violation throws an error.
#'   If FALSE, violations are collected and returned as a report. Default: TRUE.
#'
#' @return If `strict = TRUE`: the input data (invisibly) on success, error on failure.
#'   If `strict = FALSE`: a list with `$data` (input) and `$violations` (data frame of issues).
#'
#' @export
```

### 4. Vignette conventions

```r
# Create a vignette:
usethis::use_vignette("getting-started", title = "Getting Started")
```

**Vignette structure:**

```yaml
---
title: "Getting Started with mypackage"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{Getting Started with mypackage}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---
```

```markdown
## Overview
Brief description of what this vignette covers.

## Prerequisites
What the user needs before starting.

## Basic Usage
Step-by-step walkthrough with code.

## Common Patterns
Frequently used patterns with examples.

## Troubleshooting
Known issues and solutions.
```

**Vignette naming:**
- `getting-started.Rmd` — first vignette every package should have
- `advanced-usage.Rmd` — complex patterns
- `data-pipeline.Rmd` — pipeline-specific workflows
- Keep vignettes under 500 lines; split if larger

### 5. README structure for R projects

```markdown
# packagename

<!-- badges: start -->
[![R-CMD-check](https://github.com/org/repo/actions/workflows/R-CMD-check.yaml/badge.svg)](...)
[![codecov](https://codecov.io/gh/org/repo/branch/main/graph/badge.svg)](...)
<!-- badges: end -->

Brief one-paragraph description of what this package/project does.

## Installation

\```r
# Install from GitHub:
remotes::install_github("org/repo")

# Or with renv:
renv::install("org/repo")
\```

## Quick Start

\```r
library(packagename)

# Minimal working example (3-5 lines):
result <- do_main_thing(input)
\```

## Features

- Feature 1: brief description
- Feature 2: brief description

## Documentation

- [Getting Started vignette](vignettes/getting-started.Rmd)
- [Function reference](reference/index.html) (pkgdown)

## Development

\```r
# Setup:
renv::restore()

# Run tests:
devtools::test()

# Check:
devtools::check()
\```

## License

[License type](LICENSE.md)
```

### 6. pkgdown configuration

```yaml
# _pkgdown.yml
url: https://org.github.io/packagename/

template:
  bootstrap: 5

reference:
  - title: "Data Processing"
    desc: "Functions for cleaning and transforming data."
    contents:
      - starts_with("transform_")
      - starts_with("clean_")
  - title: "Validation"
    desc: "Data quality checks."
    contents:
      - starts_with("validate_")
  - title: "Utilities"
    desc: "Helper functions."
    contents:
      - starts_with("utils_")

articles:
  - title: "Getting Started"
    contents:
      - getting-started
  - title: "Advanced"
    contents:
      - advanced-usage

navbar:
  structure:
    left: [intro, reference, articles]
    right: [search, github]
```

### 7. Inline code comments

Follow the `_partials/inline-comment-standards.md` conventions:

```r
# Section headers use this format:
# Data Ingestion ####

# Explain WHY, not WHAT (the code shows what):
# Filter to completed orders only because refunded orders use a separate pipeline
orders <- dplyr::filter(orders, status == "delivered")

# Complex logic deserves explanation:
# Reporting windows overlap by 30 days to capture late-arriving shipment
# updates that were recorded before the official window closed.
window_overlap <- 30
```

### 8. Generating documentation

```r
# Generate/update man/ pages from roxygen2 comments:
devtools::document()

# Build pkgdown site:
pkgdown::build_site()

# Check documentation coverage:
# Every exported function should have a .Rd file
tools::undoc(dir = ".")
```

## Outputs

- Complete roxygen2-documented functions
- Vignettes for workflows
- Package README
- pkgdown site (when applicable)

## Success criteria

- Every exported function has `@description`, `@param` (all), `@return`, `@export`
- `devtools::document()` runs without warnings
- README has installation + quick start + development sections
- Vignettes build without errors (`devtools::build_vignettes()`)
- No undocumented exported functions (`tools::undoc()` returns empty)

## Out of scope

- Generic documentation (non-R) → `documentation`
- Code style → `r-code-style`
- Changelog → `changelog`
- DESCRIPTION metadata → `r-package-structure`

## Cross-references

- `r-package-structure` — package-level docs setup
- `r-code-style` — naming and style for documented code
- `_partials/roxygen2-standards.md` (`${CLAUDE_SKILL_DIR}/../_partials/roxygen2-standards.md`) — detailed roxygen2 tag reference
- `_partials/inline-comment-standards.md` (`${CLAUDE_SKILL_DIR}/../_partials/inline-comment-standards.md`) — inline comment patterns
- `readme` — generic README maintenance
