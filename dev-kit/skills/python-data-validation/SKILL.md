---
name: python-data-validation
description: >
  Defines data validation conventions for Python projects: pandera/pydantic
  usage patterns, pipeline validation gates, and data quality reporting.
when_to_use: >
  Use to add data quality checks, validate pipeline inputs/outputs,
  configure validation frameworks, or establish data quality standards.
  Trigger phrases: "data validation python", "pandera", "pydantic
  validation", "validate data", "data quality". Not for unit testing
  Python functions (`python-testing`), reading/writing data
  (`python-data-io`), pipeline orchestration (`python-pipeline-patterns`),
  or static type checking (`python-typing`).
model: sonnet
# persona: python-developer   — grouping metadata only; not read by Claude Code.
---

# Python Data Validation

You are implementing data validation in a Python project. This skill defines validation frameworks, assertion patterns, pipeline integration, and quality reporting conventions.

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
| `pandera` | Dataframe schema validation (polars/pandas), pipeline gates | Declarative schema, raises or reports |
| `pydantic` | Structured records — API payloads, config files, CLI args, single rows | Declarative model, validates on construction |
| `assert` / manual | Simple preconditions inside a function | Stdlib, minimal dependencies |

**Recommendation:** Use `pandera` for dataframe-shaped data (this is the direct analog of R's `assertr`/`pointblank`). Use `pydantic` for individual structured records and any data crossing a process boundary (API responses, config, CLI input).

### 2. pandera patterns (dataframe validation)

#### Schema definition

```python
import pandera.polars as pa
from pandera.polars import DataFrameSchema, Column, Check

order_schema = DataFrameSchema(
    {
        "order_id": Column(str, Check.str_matches(r"^ORD-\d{6}$"), unique=True),
        "amount": Column(float, Check.in_range(0, 100_000)),
        "status": Column(str, Check.isin(["pending", "shipped", "delivered", "cancelled"])),
        "order_date": Column(pa.DateTime, Check.less_than_or_equal_to(pa.polars.Timestamp.now())),
    },
    strict=True,     # reject unexpected columns
    coerce=True,     # coerce dtypes to match schema before validating
)
```

#### Validating a dataframe

```python
# Fail-fast (raises pandera.errors.SchemaError on first violation category):
validated = order_schema.validate(orders)

# Collect all violations instead of raising:
try:
    validated = order_schema.validate(orders, lazy=True)
except pa.errors.SchemaErrors as exc:
    failure_report = exc.failure_cases  # DataFrame of every violation
```

#### Decorator-based validation on function boundaries

```python
from pandera.polars import check_input, check_output

@check_input(order_schema, obj_getter=0)
@check_output(order_schema)
def process_orders(orders: pl.DataFrame) -> pl.DataFrame:
    return orders.filter(pl.col("status") != "cancelled")
```

#### Custom checks

```python
def is_business_day(series: pl.Series) -> pl.Series:
    return series.dt.weekday() < 5

order_schema = order_schema.add_columns({
    "order_date": Column(pa.DateTime, Check(is_business_day, element_wise=False)),
})
```

### 3. pydantic patterns (record validation)

```python
from pydantic import BaseModel, Field, field_validator
from datetime import date


class Order(BaseModel):
    order_id: str = Field(pattern=r"^ORD-\d{6}$")
    amount: float = Field(gt=0, le=100_000)
    status: str
    order_date: date

    @field_validator("status")
    @classmethod
    def status_must_be_known(cls, v: str) -> str:
        allowed = {"pending", "shipped", "delivered", "cancelled"}
        if v not in allowed:
            raise ValueError(f"status must be one of {allowed}, got {v!r}")
        return v
```

```python
# Validates on construction — raises pydantic.ValidationError with all violations at once:
order = Order(order_id="ORD-000123", amount=59.97, status="pending", order_date=date.today())

# Parse from a raw dict (e.g., API payload):
order = Order.model_validate(raw_dict)

# Collect errors without raising:
try:
    order = Order.model_validate(raw_dict)
except ValidationError as exc:
    for error in exc.errors():
        logger.warning("validation failed: %s", error)
```

### 4. Pipeline integration

#### With Prefect

```python
from prefect import task

@task
def validate_orders(orders: pl.DataFrame) -> pl.DataFrame:
    """Validate order data; task fails (and the flow halts) on schema violation."""
    return order_schema.validate(orders, lazy=True)
```

#### Input validation (function preconditions)

```python
def process_orders(data: pl.DataFrame) -> pl.DataFrame:
    """Process order data.

    Args:
        data: Order records; must contain order_id, amount, status.

    Returns:
        Processed order records.
    """
    if data.is_empty():
        raise ValueError("data must not be empty")
    if "order_id" not in data.columns:
        raise ValueError("data must have an order_id column")

    # business logic...
    return data
```

### 5. Common validation patterns

| Check | pandera | pydantic |
|---|---|---|
| Non-null | `Column(..., nullable=False)` | field with no default, non-`Optional` type |
| Unique | `Column(..., unique=True)` | not applicable (per-record, not per-set) |
| Range | `Check.in_range(a, b)` | `Field(ge=a, le=b)` |
| Allowed values | `Check.isin([...])` | `Literal["a", "b"]` or custom validator |
| Regex | `Check.str_matches(r"...")` | `Field(pattern=r"...")` |
| Row count | `Check(lambda df: len(df) > n, element_wise=False)` on the whole schema | not applicable |
| Column exists | `strict=True` on the schema | not applicable (fields are the schema) |
| Type check | Column dtype declaration | field type annotation |

### 6. Reporting and monitoring

```python
import json
from datetime import datetime, timezone
from pathlib import Path

def log_validation_result(dataset_name: str, orders: pl.DataFrame, passed: bool) -> None:
    """Save validation results for audit trail."""
    result = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "dataset": dataset_name,
        "row_count": len(orders),
        "passed": passed,
    }
    log_path = Path("logs") / f"validation_{datetime.now(timezone.utc):%Y-%m-%d}.jsonl"
    with log_path.open("a") as f:
        f.write(json.dumps(result) + "\n")
```

## Outputs

- Validation code (pandera schemas or pydantic models)
- Validation reports (failure-case DataFrames, or log files)
- Clear pass/fail signals for pipeline gates

## Success criteria

- Every pipeline has at least input + output validation
- Validation failures produce clear, actionable error messages (pandera's `failure_cases`, pydantic's `.errors()`)
- Critical checks fail-fast; non-critical checks are logged and reviewed
- Validation results are logged for audit trail
- No silent data corruption passes through unchecked

## Out of scope

- Unit testing of Python functions → `python-testing`
- Data I/O mechanics → `python-data-io`
- Pipeline orchestration → `python-pipeline-patterns`
- Static type checking (development-time, not runtime) → `python-typing`
- Statistical validation (distribution tests, outlier detection)

## Cross-references

- `python-pipeline-patterns` — validation tasks in Prefect flows
- `python-data-io` — reading data before validation
- `python-typing` — the development-time counterpart to runtime validation
- `python-testing` — testing validation schemas/models themselves
- `python-code-style` — naming validation functions
