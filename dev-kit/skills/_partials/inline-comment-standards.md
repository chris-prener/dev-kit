# Inline comment standards (shared partial)

Referenced by `python-code-style`, `python-documentation`, `r-code-style`, and
`r-documentation`. Examples below use R syntax; the "why not what" principle,
file header blocks, and comment density guidelines are language-agnostic —
adapt the concrete syntax to the file's language. The "Section header
standards" section below (RStudio `####` folding) is R-specific.

### Inline comment standards

Add or improve inline comments throughout all source files. Follow these rules:

**Comment placement:**
- Place comments on the line **above** the code they describe, not on the same line
  (unless the comment is very short and the line has room).
- Use a blank line before a comment that introduces a new logical block.

**Comment content — the "Why not What" rule:**

```r
# BAD — restates the code (what)
# filter to rows where year is greater than 2010
df <- filter(df, year > 2010)

# GOOD — explains the reasoning (why)
# sales data before 2011 uses inconsistent region codes
df <- filter(df, year > 2010)
```

```r
# BAD — obvious from the code
# left join with region table
df <- left_join(df, region_df, by = "region")

# GOOD — explains the purpose and potential pitfall
# attach store hierarchy; unmatched region codes become NA
df <- left_join(df, region_df, by = "region")
```

**When comments ARE warranted even if they seem to state "what":**
- Complex regex patterns — always explain what the pattern matches
- Non-obvious `case_when()` or `ifelse()` logic — explain the business rule
- Magic numbers — explain what the constant represents
- Workarounds — explain why the obvious approach doesn't work

### Section header standards

Use section headers to divide long scripts and function files into logical
blocks. Follow the project's established format:

```r
# Section Name ####
```

The four trailing hashes (`####`) enable code folding in RStudio. Use them
consistently.

**Typical section structure for pipeline scripts:**

```r
# Dependencies ####
library(dplyr)
library(sf)

# Load Data ####
raw_data <- readxl::read_excel(path)

# Clean & Normalize ####
clean_data <- raw_data |>
  tidy_na() |>
  normalize_region()

# Calculate Rates ####
rates <- clean_data |>
  mutate(rate = orders / population * 100000)

# Export ####
write_csv(rates, "data/output.csv")
```

**Typical section structure for function files:**

```r
# Main Function ####

#' @description ...
main_function <- function(...) { ... }

# Helper Functions ####

#' @description ...
helper_one <- function(...) { ... }
```

### File header blocks

Every file should begin with a brief header comment block (not roxygen2)
explaining:
- What the file contains or does
- Where it fits in the pipeline (if applicable)
- Any prerequisites (must be run after script X, requires trigger variable, etc.)

```r
# Sales Data — Initial Processing
#
# Reads raw Excel master files for each region, normalizes structure
# via normalize_region(), adds store hierarchy, and calculates
# order rates per 100k population.
#
# Part of the sales pipeline: run via 00_sales_all.R
# Requires: trigger variable set by the master script
```

For function library files, the header is simpler:

```r
# Geographic Hierarchy Functions
#
# Functions for building and validating the store-level geographic
# hierarchy used throughout the sales pipeline.
```

### Comment density guidelines

Not every line needs a comment. Aim for:
- **One comment per logical block** (a group of 2–8 lines that accomplish one task)
- **No comment for self-documenting code** — e.g., an import statement (R's
  `library(dplyr)`, Python's `import polars as pl`) needs no comment
- **Always comment** non-obvious joins, filters with business logic, regex,
  complex mutations, and workarounds
- **Always comment** the purpose of each file-sourcing call (R's `source()`,
  Python's module-level imports of local helper modules)
