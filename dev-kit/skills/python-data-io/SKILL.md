---
name: python-data-io
description: >
  Defines data reading/writing conventions for Python projects: parquet
  (polars), CSV, Excel, database connections (SQLAlchemy/DuckDB), and file
  path patterns.
when_to_use: >
  Use to read/write data files, connect to databases, choose data formats,
  or establish I/O conventions. Trigger phrases: "python read data",
  "python write data", "polars", "parquet python", "python database",
  "sqlalchemy". Not for data validation after reading
  (`python-data-validation`), pipeline orchestration of I/O steps
  (`python-pipeline-patterns`), or dependency management for I/O packages
  (`python-dependencies`).
model: sonnet
# persona: python-developer   — grouping metadata only; not read by Claude Code.
---

# Python Data I/O

You are reading or writing data in a Python project. This skill defines the conventions for file-based I/O (parquet, CSV, Excel), database connections (SQLAlchemy/DuckDB), file path management, and data format selection.

## Activation

Activate when the user needs to read/write data files, connect to databases, choose data formats, or establish I/O conventions.

## Inputs

- **Required**: what data operation is needed (read, write, connect)
- **Optional**: data format or database type
- **Optional**: size/performance constraints

## Steps

### 1. Format selection guide

| Format | Best for | Library | Read | Write |
|---|---|---|---|---|
| Parquet | Large tabular data, cross-language | `polars` | `pl.read_parquet()` | `df.write_parquet()` |
| CSV | Small data, human-readable | `polars` | `pl.read_csv()` | `df.write_csv()` |
| Excel | Business stakeholder exchange | `polars` (via `xlsx2csv`/`openpyxl`) | `pl.read_excel()` | `df.write_excel()` |
| JSON | APIs, config files | stdlib `json` / `pydantic` | `json.load()` | `json.dump()` |
| Pickle | Complex Python objects (models) | stdlib `pickle` | `pickle.load()` | `pickle.dump()` |

**Default choice:** Parquet for tabular data. It is columnar, compressed, type-preserving, and readable by R/Spark/DuckDB. Prefer `polars` over `pandas` for new tabular code — it's faster, has stricter typing of null handling, and its lazy API mirrors `dplyr`-style pipelines. `pandas` remains acceptable where an existing codebase or a dependency (e.g., certain plotting/ML libraries) requires it.

### 2. File-based I/O patterns

#### Parquet (preferred for tabular data)

```python
import polars as pl

# Read:
orders = pl.read_parquet("data/orders.parquet")

# Write:
orders.write_parquet("data/orders.parquet")

# Read specific columns (efficient — only reads needed columns):
orders = pl.read_parquet("data/orders.parquet", columns=["order_id", "amount", "status"])

# Lazy scan with filter pushdown (only reads matching rows):
orders = (
    pl.scan_parquet("data/orders.parquet")
    .filter(pl.col("amount") >= 100)
    .collect()
)
```

#### CSV

```python
# Read with explicit schema (no guessing in production code):
data = pl.read_csv(
    "data-raw/input.csv",
    schema_overrides={
        "order_id": pl.Utf8,
        "amount": pl.Float64,
        "order_date": pl.Date,
    },
)

# Write:
data.write_csv("data/output.csv")
```

**Rules:**
- Always specify `schema_overrides` (or a full `schema`) for production code — no dtype guessing
- Use `pl.read_csv(..., infer_schema_length=None)` only for exploratory work, never in shipped code
- Never use bare `csv.reader` for tabular data with a known shape — use polars

#### Excel

```python
# Read:
data = pl.read_excel("data-raw/report.xlsx", sheet_name="Sheet1")

# Write:
data.write_excel("data/report.xlsx")
```

### 3. Database connections

#### SQLAlchemy (general-purpose)

```python
from sqlalchemy import create_engine, text
import os

# Connect:
engine = create_engine(
    f"postgresql+psycopg://{os.environ['DB_USER']}:{os.environ['DB_PASSWORD']}"
    f"@{os.environ['DB_HOST']}/{os.environ['DB_NAME']}"
)

# Query (parameterized — SQL injection safe):
with engine.connect() as conn:
    result = conn.execute(
        text("SELECT * FROM orders WHERE store_id = :store_id"),
        {"store_id": store_id},
    )
    rows = result.fetchall()

# Read directly into polars:
orders = pl.read_database(
    "SELECT * FROM orders WHERE amount >= 100",
    connection=engine,
)

# Write:
orders.write_database("output_table", connection=engine, if_table_exists="replace")

# Engines pool connections automatically; dispose explicitly when done with the engine's lifetime:
engine.dispose()
```

**Rules:**
- Always use parameterized queries (`:param` placeholders) — never f-string SQL with user input
- Use a single module-level `engine` per database, not a new connection per call — SQLAlchemy engines already pool connections

#### DuckDB (local analytical queries)

```python
import duckdb

# In-memory:
con = duckdb.connect()

# Query parquet files directly (no loading into Python first):
result = con.sql("""
    SELECT store_id, COUNT(*) AS n
    FROM read_parquet('data/*.parquet')
    GROUP BY store_id
""").pl()  # .pl() returns a polars DataFrame, .df() returns pandas

con.close()
```

### 4. File path conventions

**Always use `pathlib.Path`, never string concatenation:**

```python
from pathlib import Path

# GOOD — portable, composable
data_dir = Path(__file__).resolve().parent.parent / "data"
orders = pl.read_parquet(data_dir / "orders.parquet")

# BAD — fragile, platform-dependent
orders = pl.read_parquet("/Users/me/projects/data/orders.parquet")
orders = pl.read_parquet("data" + "/" + "orders.parquet")
```

**Directory operations with pathlib:**
```python
# Create directory (idempotent):
(data_dir / "output").mkdir(parents=True, exist_ok=True)

# List files:
parquet_files = sorted(data_dir.glob("*.parquet"))

# File existence check:
if output_path.exists(): ...
```

Establish a project root reference once (e.g., in `src/mypackage/config.py`) rather than computing `Path(__file__).parent` repeatedly across modules.

### 5. Large dataset patterns

```python
# Lazy, multi-file, partitioned scan:
dataset = pl.scan_parquet("data/partitioned/**/*.parquet")

# Lazy query (compute only what's needed):
result = (
    dataset
    .filter((pl.col("year") == 2024) & (pl.col("store_id") == "STORE01"))
    .select("order_id", "amount", "order_date")
    .collect()
)

# Write partitioned:
orders.write_parquet(
    "data/partitioned/",
    partition_by=["year", "store_id"],
)
```

### 6. Credential management

**Never hardcode credentials.** Use environment variables loaded via `python-dotenv`:

```python
# .env (gitignored):
DB_USER=myuser
DB_PASSWORD=mypassword
DB_HOST=localhost

# In code (load once, at entry point):
from dotenv import load_dotenv
import os

load_dotenv()
os.environ["DB_USER"]
```

**For CI/production:** Use GitHub Actions secrets or a secrets manager (never `.env` files in deployed environments).

## Outputs

- Working data I/O code following conventions
- Proper format selection for the use case
- Secure credential handling

## Success criteria

- Parquet is used for tabular data exchange (not CSV as the default)
- All file paths use `pathlib.Path` (no hardcoded or string-concatenated paths)
- Database credentials come from environment variables, loaded via `python-dotenv`
- CSV reads specify a schema explicitly
- Database connections/engines are properly closed or disposed

## Out of scope

- Data validation → `python-data-validation`
- Pipeline orchestration → `python-pipeline-patterns`
- Data format design decisions → project requirements

## Cross-references

- `python-pipeline-patterns` — I/O within Prefect flows
- `python-data-validation` — validating after read
- `python-project-scaffold` — `data/` directory conventions
- `python-dependencies` — installing I/O packages
