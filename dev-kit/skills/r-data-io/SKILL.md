---
name: r-data-io
description: >
  Defines data reading/writing conventions for R projects: parquet (arrow),
  CSV, Excel, database connections (DBI/pool), and file path patterns.
when_to_use: >
  Use to read/write data files, connect to databases, choose data formats,
  or establish I/O conventions. Trigger phrases: "r read data", "r write
  data", "arrow", "parquet r", "r database", "DBI". Not for data validation
  after reading (`r-data-validation`), pipeline orchestration of I/O steps
  (`r-pipeline-patterns`), or dependency management for I/O packages
  (`r-dependencies`).
model: sonnet
# persona: r-developer   — grouping metadata only; not read by Claude Code.
---

# R Data I/O

You are reading or writing data in an R project. This skill defines the conventions for file-based I/O (parquet, CSV, Excel), database connections (DBI/pool), file path management, and data format selection.

## Activation

Activate when the user needs to read/write data files, connect to databases, choose data formats, or establish I/O conventions.

## Inputs

- **Required**: what data operation is needed (read, write, connect)
- **Optional**: data format or database type
- **Optional**: size/performance constraints

## Steps

### 1. Format selection guide

| Format | Best for | Package | Read | Write |
|---|---|---|---|---|
| Parquet | Large tabular data, cross-language | `arrow` | `arrow::read_parquet()` | `arrow::write_parquet()` |
| CSV | Small data, human-readable | `readr` | `readr::read_csv()` | `readr::write_csv()` |
| Excel | Business stakeholder exchange | `readxl`/`writexl` | `readxl::read_excel()` | `writexl::write_xlsx()` |
| RDS | Complex R objects (models, lists) | base | `readRDS()` | `saveRDS()` |
| QS | Fast R object serialization | `qs` | `qs::qread()` | `qs::qsave()` |
| Feather | Fast cross-language tabular | `arrow` | `arrow::read_feather()` | `arrow::write_feather()` |
| JSON | APIs, config files | `jsonlite` | `jsonlite::read_json()` | `jsonlite::write_json()` |

**Default choice:** Parquet for tabular data. It is columnar, compressed, type-preserving, and readable by Python/Spark/DuckDB.

### 2. File-based I/O patterns

#### Parquet (preferred for tabular data)

```r
# Read:
orders <- arrow::read_parquet("data/orders.parquet")

# Write:
arrow::write_parquet(orders, "data/orders.parquet")

# Read specific columns (efficient — only reads needed columns):
orders <- arrow::read_parquet(
  "data/orders.parquet",
  col_select = c("order_id", "amount", "status")
)

# Read with filtering (pushdown — only reads matching rows):
orders <- arrow::open_dataset("data/orders.parquet") |>
  dplyr::filter(amount >= 100) |>
  dplyr::collect()
```

#### CSV

```r
# Read with type detection:
data <- readr::read_csv("data-raw/input.csv",
  col_types = readr::cols(
    order_id = readr::col_character(),
    amount = readr::col_double(),
    order_date = readr::col_date(format = "%Y-%m-%d")
  )
)

# Write:
readr::write_csv(data, "data/output.csv")
```

**Rules:**
- Always specify `col_types` for production code (no guessing)
- Use `readr::problems()` to inspect parsing issues
- Never use `read.csv()` (base R) — use `readr::read_csv()`

#### Excel

```r
# Read (read-only — readxl has no write):
data <- readxl::read_excel("data-raw/report.xlsx",
  sheet = "Sheet1",
  range = "A1:G100",
  col_types = c("text", "numeric", "date", "text", "numeric", "text", "text")
)

# Write:
writexl::write_xlsx(data, "data/report.xlsx")
```

### 3. Database connections

#### DBI (single connection)

```r
# Connect:
con <- DBI::dbConnect(
  odbc::odbc(),
  dsn = "SnowflakeDSN",
  uid = Sys.getenv("DB_USER"),
  pwd = Sys.getenv("DB_PASSWORD")
)

# Query:
orders <- DBI::dbGetQuery(con, "SELECT * FROM orders WHERE amount >= 100")

# Parameterized query (SQL injection safe):
orders <- DBI::dbGetQuery(con,
  "SELECT * FROM orders WHERE store_id = ?",
  params = list(store_id)
)

# Write:
DBI::dbWriteTable(con, "output_table", data, overwrite = TRUE)

# Always disconnect:
DBI::dbDisconnect(con)
```

#### pool (connection pooling — preferred for long-running processes)

```r
# Create pool:
pool <- pool::dbPool(
  odbc::odbc(),
  dsn = "SnowflakeDSN",
  uid = Sys.getenv("DB_USER"),
  pwd = Sys.getenv("DB_PASSWORD"),
  minSize = 1,
  maxSize = 5
)

# Use (automatically manages checkout/return):
orders <- pool::dbGetQuery(pool, "SELECT * FROM orders")

# Close pool when done:
pool::poolClose(pool)
```

#### DuckDB (local analytical queries)

```r
# In-memory:
con <- DBI::dbConnect(duckdb::duckdb())

# Query parquet files directly (no loading into R):
result <- DBI::dbGetQuery(con,
  "SELECT store_id, COUNT(*) as n
   FROM read_parquet('data/*.parquet')
   GROUP BY store_id"
)

DBI::dbDisconnect(con, shutdown = TRUE)
```

### 4. File path conventions

**Always use `here::here()` or `fs::path()` for file paths:**

```r
# GOOD — portable, project-relative:
data <- arrow::read_parquet(here::here("data", "orders.parquet"))
output_path <- fs::path("data", "output", "results.parquet")

# BAD — fragile absolute paths:
data <- arrow::read_parquet("/Users/me/projects/data/orders.parquet")
data <- arrow::read_parquet("~/projects/data/orders.parquet")
```

**Directory operations with fs:**
```r
# Create directory (idempotent):
fs::dir_create("data/output")

# List files:
parquet_files <- fs::dir_ls("data/", glob = "*.parquet")

# File existence check:
if (fs::file_exists(output_path)) { ... }
```

### 5. Large dataset patterns

```r
# Arrow datasets (multi-file, partitioned):
dataset <- arrow::open_dataset("data/partitioned/",
  partitioning = c("year", "store_id")
)

# Lazy query (compute only what's needed):
result <- dataset |>
  dplyr::filter(year == 2024, store_id == "STORE01") |>
  dplyr::select(order_id, amount, order_date) |>
  dplyr::collect()

# Write partitioned:
arrow::write_dataset(
  data,
  "data/partitioned/",
  partitioning = c("year", "store_id"),
  format = "parquet"
)
```

### 6. Credential management

**Never hardcode credentials.** Use environment variables:

```r
# .Renviron (gitignored):
DB_USER=myuser
DB_PASSWORD=mypassword
DB_DSN=SnowflakeDSN

# In code:
Sys.getenv("DB_USER")
```

**For CI/production:** Use GitHub secrets or vault integration.

## Outputs

- Working data I/O code following conventions
- Proper format selection for the use case
- Secure credential handling

## Success criteria

- Parquet is used for tabular data exchange (not CSV/RDS)
- All file paths use `here::here()` or `fs::path()` (no hardcoded paths)
- Database credentials come from environment variables
- CSV reads specify `col_types` explicitly
- Connections are properly closed (DBI disconnect, pool close)

## Out of scope

- Data validation → `r-data-validation`
- Pipeline orchestration → `r-pipeline-patterns`
- Data format design decisions → project requirements

## Cross-references

- `r-pipeline-patterns` — I/O within targets
- `r-data-validation` — validating after read
- `r-project-scaffold` — data/ directory conventions
- `r-dependencies` — installing I/O packages
