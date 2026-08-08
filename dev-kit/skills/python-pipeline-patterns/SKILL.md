---
name: python-pipeline-patterns
description: >
  Defines Prefect flow/task patterns, function-based design, caching,
  reproducibility contracts, and pipeline organization for Python projects.
when_to_use: >
  Use to create a Prefect pipeline, add tasks to an existing flow, debug
  pipeline failures, or understand Prefect conventions. Trigger phrases:
  "prefect", "python pipeline", "prefect flow", "reproducible workflow".
  Not for general project setup (`python-project-scaffold`), data
  validation within pipeline steps (`python-data-validation`),
  reading/writing data files (`python-data-io`), or CI for running
  pipelines (`python-ci`).
model: sonnet
# persona: python-developer   — grouping metadata only; not read by Claude Code.
---

# Python Pipeline Patterns

You are designing or implementing a reproducible data pipeline in Python using Prefect. This skill defines pipeline organization, function-based design, caching patterns, and reproducibility conventions.

## Activation

Activate when the user needs to create a Prefect pipeline, add tasks to an existing flow, debug pipeline failures, or understand Prefect conventions.

## Inputs

- **Required**: what the pipeline should do (data flow description)
- **Optional**: existing functions to wrap as tasks
- **Optional**: whether dynamic mapping/branching is needed
- **Optional**: external dependencies (databases, APIs, files)

## Steps

### 1. Pipeline file structure

```
project/
├── src/<project_name>/
│   └── flows/
│       ├── __init__.py
│       ├── main_flow.py       # Flow definition (single entry point)
│       └── tasks/
│           ├── ingest.py      # Data loading tasks
│           ├── transform.py   # Transformation tasks
│           ├── validate.py    # Validation tasks
│           └── report.py      # Output generation tasks
├── data-raw/                  # Raw input data
├── data/                      # Pipeline outputs (or gitignored if large)
└── docs/
    └── pipeline.md            # Pipeline documentation
```

### 2. The flow definition

```python
# src/mypackage/flows/main_flow.py
from prefect import flow, task
from prefect.cache_policies import INPUTS

from mypackage.flows.tasks.ingest import ingest_orders, ingest_shipments
from mypackage.flows.tasks.transform import transform_orders, enrich_shipments
from mypackage.flows.tasks.validate import validate_output
from mypackage.flows.tasks.report import write_output


@flow(name="order-pipeline", log_prints=True)
def order_pipeline(orders_path: str = "data-raw/orders.csv") -> str:
    """Run the full order processing pipeline."""
    raw_orders = ingest_orders(orders_path)
    raw_shipments = ingest_shipments()

    clean_orders = transform_orders(raw_orders)
    enriched_shipments = enrich_shipments(raw_shipments, clean_orders)

    validate_output(enriched_shipments)

    return write_output(enriched_shipments, "data/final_dataset.parquet")


if __name__ == "__main__":
    order_pipeline()
```

### 3. Function-based task design

**Every pipeline step wraps exactly one `@task`-decorated function.** Tasks live in `flows/tasks/`, not inline in the flow.

```python
# src/mypackage/flows/tasks/transform.py
from prefect import task
import polars as pl


@task(name="transform-orders", retries=2, retry_delay_seconds=5)
def transform_orders(raw_orders: pl.DataFrame) -> pl.DataFrame:
    """Clean and standardize raw order data.

    Args:
        raw_orders: Raw order records.

    Returns:
        Cleaned and standardized order data.
    """
    return (
        raw_orders
        .filter(pl.col("order_id").is_not_null())
        .with_columns(
            amount=pl.col("amount").cast(pl.Float64),
            order_date=pl.col("order_date").cast(pl.Date),
        )
        .unique(subset="order_id")
    )
```

**Rules:**
- Tasks should be pure where practical: same inputs → same outputs, aside from declared I/O (reads/writes) or explicit side effects
- No global mutable state read inside a task — pass everything as parameters
- Each task file groups related tasks (e.g., all transform tasks together)
- Document every task with a Google-style docstring (`python-documentation`)

### 4. Mapping patterns (Prefect's analog to targets branching)

#### Static mapping (known at definition time)

```python
from prefect import flow, task

@task
def process_file(path: str) -> pl.DataFrame: ...

@flow
def process_all_files(paths: list[str]) -> list[pl.DataFrame]:
    # .map() fans out one task run per input — the Prefect equivalent of tar_target(pattern = map(...))
    futures = process_file.map(paths)
    return [f.result() for f in futures]
```

#### Dynamic mapping (determined at runtime)

```python
from prefect import unmapped

@task
def get_unique_sites(raw_data: pl.DataFrame) -> list[str]: ...

@task
def generate_site_report(raw_data: pl.DataFrame, site_id: str) -> pl.DataFrame: ...

@flow
def site_reports_flow(raw_data: pl.DataFrame) -> list[pl.DataFrame]:
    site_ids = get_unique_sites(raw_data)
    # .map() fans out over every iterable argument — wrap raw_data in unmapped()
    # so the same full frame is passed to every site's task run, instead of
    # Prefect iterating over it (or zipping it against site_ids by length).
    futures = generate_site_report.map(unmapped(raw_data), site_ids)
    return [f.result() for f in futures]
```

#### Subflows (composition, analogous to nested pipelines)

```python
@flow
def ingest_subflow() -> pl.DataFrame: ...

@flow
def main_flow() -> None:
    raw = ingest_subflow()   # runs as a tracked subflow, visible in the UI as its own unit
    ...
```

### 5. Caching (Prefect's analog to targets' automatic memoization)

```python
from prefect import task
from prefect.cache_policies import INPUTS, TASK_SOURCE
from datetime import timedelta

@task(
    cache_policy=INPUTS + TASK_SOURCE,   # cache invalidates on input change OR code change
    cache_expiration=timedelta(hours=24),
)
def expensive_transform(data: pl.DataFrame) -> pl.DataFrame:
    ...
```

| Cache policy | Invalidates when |
|---|---|
| `INPUTS` | Task's input arguments change |
| `TASK_SOURCE` | The task function's source code changes |
| `INPUTS + TASK_SOURCE` | Either changes — the closest match to `targets`' default behavior |
| `NO_CACHE` | Never cached — always reruns |

**This is the key reproducibility mechanism**: unlike `targets`, Prefect does not cache by default — declare `cache_policy` explicitly on any task where recomputation is expensive.

### 6. Running the pipeline

```bash
# Run directly:
uv run python -m mypackage.flows.main_flow

# Or via the Prefect CLI, after deployment:
prefect deployment run 'order-pipeline/production'

# Serve locally with a schedule (dev/local orchestration):
uv run python -c "from mypackage.flows.main_flow import order_pipeline; order_pipeline.serve(name='local', cron='0 6 * * *')"

# Inspect run history and DAG visually:
prefect server start   # then open the local UI
```

### 7. Reproducibility contracts

| Contract | Implementation |
|---|---|
| Deterministic outputs | Pure task functions, fixed random seeds where needed |
| Dependency tracking | `cache_policy=TASK_SOURCE` tracks function code changes |
| Version pinning | `uv.lock` ensures same package versions |
| Data versioning | Track raw data files' hashes as task inputs, or via DVC/`data-raw/` conventions |
| Environment isolation | `uv run` — every invocation resolves against the locked environment |

### 8. Error handling and retries

```python
@task(retries=3, retry_delay_seconds=[1, 5, 15])  # exponential-ish backoff
def fetch_from_api(url: str) -> dict: ...

@flow
def resilient_flow() -> None:
    try:
        result = fetch_from_api("https://api.example.com/orders")
    except Exception:
        # Prefect logs the full traceback automatically; add context here
        raise
```

Prefect's UI surfaces failed task state and logs directly — for interactive debugging of a failed run, re-invoke the underlying function directly with the same arguments (tasks are plain Python functions under the decorator).

## Outputs

- A complete flow definition (`main_flow.py`)
- Task files in `flows/tasks/`
- Reproducible, cacheable data pipeline

## Success criteria

- The flow runs end-to-end without errors
- Prefect's UI/DAG shows a connected graph with no orphaned tasks
- All tasks are pure where practical (explicit I/O only, no hidden global state)
- Pipeline can be re-run from scratch and produce identical results
- Expensive tasks declare an explicit `cache_policy`

## Out of scope

- Data validation logic → `python-data-validation`
- Data I/O patterns → `python-data-io`
- CI/CD for running pipelines → `python-ci`
- Airflow/Dagster (alternative orchestrators) — this skill standardizes on Prefect for solo/hobby-scale projects

## Cross-references

- `python-project-scaffold` — project layout with a flows/ stub
- `python-data-io` — reading/writing data in task functions
- `python-data-validation` — validation tasks
- `python-testing` — testing task functions in isolation (call the undecorated function directly)
- `python-ci` — running flows in CI
- `python-dependencies` — uv for reproducibility
