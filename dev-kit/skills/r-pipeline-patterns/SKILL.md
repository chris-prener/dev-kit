---
name: r-pipeline-patterns
description: >
  Defines targets pipeline patterns, function-based design, branching,
  reproducibility contracts, and pipeline organization for R projects.
when_to_use: >
  Use to create a targets pipeline, add targets to an existing pipeline,
  debug pipeline failures, or understand targets conventions. Trigger
  phrases: "targets", "r pipeline", "targets pipeline", "reproducible
  workflow". Not for general project setup (`r-project-scaffold`), data
  validation within pipeline steps (`r-data-validation`), reading/writing
  data files (`r-data-io`), or CI for running pipelines (`r-ci`).
model: sonnet
# persona: r-developer   — grouping metadata only; not read by Claude Code.
---

# R Pipeline Patterns

You are designing or implementing a reproducible data pipeline in R using the targets framework. This skill defines pipeline organization, function-based design, branching patterns, and reproducibility conventions.

## Activation

Activate when the user needs to create a targets pipeline, add targets to an existing pipeline, debug pipeline failures, or understand targets conventions.

## Inputs

- **Required**: what the pipeline should do (data flow description)
- **Optional**: existing functions to wrap as targets
- **Optional**: whether dynamic branching is needed
- **Optional**: external dependencies (databases, APIs, files)

## Steps

### 1. Pipeline file structure

```
project/
├── _targets.R              # Pipeline definition (single entry point)
├── _targets/               # Cache directory (gitignored)
├── R/
│   └── functions/          # Target function definitions
│       ├── ingest.R        # Data loading functions
│       ├── transform.R     # Transformation functions
│       ├── validate.R      # Validation functions
│       └── report.R        # Output generation functions
├── data-raw/               # Raw input data
├── data/                   # Pipeline outputs (or gitignored if large)
└── docs/
    └── pipeline.md         # Pipeline documentation
```

### 2. The _targets.R file

```r
# _targets.R — pipeline definition
library(targets)

# Source all function files:
tar_source("R/functions")

# Set target-level options:
tar_option_set(
  packages = c("dplyr", "arrow", "DBI"),
  format = "qs",         # Fast serialization (or "parquet" for tabular data)
  error = "stop"         # Options: "stop", "continue", "null", "workspace"
)

# Define the pipeline:
list(
  # ─── Ingest ────────────────────────────────────────────────────────────

  tar_target(
    raw_orders,
    ingest_orders("data-raw/orders.csv"),
    format = "parquet"
  ),

  tar_target(
    raw_shipments,
    ingest_shipments(connection_params()),
    format = "parquet"
  ),

  # ─── Transform ─────────────────────────────────────────────────────────
  tar_target(
    clean_orders,
    transform_orders(raw_orders)
  ),

  tar_target(
    enriched_shipments,
    enrich_shipments(raw_shipments, clean_orders)
  ),

  # ─── Validate ──────────────────────────────────────────────────────────
  tar_target(
    validation_report,
    validate_output(enriched_shipments),
    error = "continue"
  ),

  # ─── Output ────────────────────────────────────────────────────────────
  tar_target(
    final_dataset,
    write_output(enriched_shipments, "data/final_dataset.parquet"),
    format = "file"
  )
)
```

### 3. Function-based design

**Every target wraps exactly one function.** The function lives in `R/functions/`, not inline.

```r
# R/functions/transform.R

#' Transform raw order data
#'
#' @param raw_orders Data frame of raw order records.
#' @return Cleaned and standardized order data frame.
transform_orders <- function(raw_orders) {
  raw_orders |>
    dplyr::filter(!is.na(order_id)) |>
    dplyr::mutate(
      amount = as.double(amount),
      order_date = as.Date(order_date)
    ) |>
    dplyr::distinct(order_id, .keep_all = TRUE)
}
```

**Rules:**
- Functions must be pure: same inputs → same outputs (no side effects)
- No `library()` calls inside functions — use `pkg::fun()` or declare in `tar_option_set(packages = ...)`
- Each function file groups related functions (e.g., all transform functions together)
- Document every function with roxygen2

### 4. Branching patterns

#### Static branching (known at definition time)

```r
# Process multiple files with the same function:
tar_target(
  raw_files,
  fs::dir_ls("data-raw/", glob = "*.csv"),
  format = "file"
),

tar_target(
  processed_data,
  process_file(raw_files),
  pattern = map(raw_files)  # One branch per file
)
```

#### Dynamic branching (determined at runtime)

```r
# Branch over groups discovered in data:
tar_target(
  site_ids,
  get_unique_sites(raw_data)
),

tar_target(
  site_reports,
  generate_site_report(raw_data, site_ids),
  pattern = map(site_ids)
)
```

#### Cross patterns (combinations)

```r
tar_target(
  model_results,
  fit_model(datasets, model_specs),
  pattern = cross(datasets, model_specs)
)
```

### 5. Format selection

| Format | Use when | Pros | Cons |
|---|---|---|---|
| `"qs"` | Default for R objects | Fast, compact | R-only |
| `"parquet"` | Tabular data shared across tools | Columnar, cross-language | Tabular only |
| `"file"` | External files (plots, reports) | Tracks file changes | Must return file path |
| `"rds"` | Fallback for complex R objects | Universal R support | Slower than qs |
| `"feather"` | Cross-language tabular | Fast read/write | Less compressed |

### 6. Running the pipeline

```r
# Run the full pipeline (only outdated targets recompute):
targets::tar_make()

# Visualize the pipeline graph:
targets::tar_visnetwork()

# Check what's outdated:
targets::tar_outdated()

# Read a completed target:
targets::tar_read(clean_orders)

# Destroy cache and start fresh:
targets::tar_destroy()

# Run in parallel (with crew):
# In _targets.R:
tar_option_set(
  controller = crew::crew_controller_local(workers = 4)
)
```

### 7. Reproducibility contracts

| Contract | Implementation |
|---|---|
| Deterministic outputs | Pure functions, fixed random seeds where needed |
| Dependency tracking | targets tracks function code + upstream targets |
| Version pinning | renv.lock ensures same package versions |
| Data versioning | Track raw data files with `format = "file"` |
| Environment isolation | `tar_option_set(envir = ...)` or renv |

**Invalidation rules:**
- A target reruns if: its function code changes, any upstream target changes, or its file dependencies change
- `tar_cue(mode = "always")` — force rerun every time
- `tar_cue(mode = "never")` — never rerun (manual override)

### 8. Error handling

```r
# Workspace for debugging failed targets:
tar_option_set(workspace_on_error = TRUE)

# After a failure:
targets::tar_workspace(failed_target_name)
# This loads the target's dependencies into your session for interactive debugging
```

## Outputs

- A complete `_targets.R` pipeline definition
- Function files in `R/functions/`
- Reproducible, cacheable data pipeline

## Success criteria

- `tar_make()` completes without errors
- `tar_visnetwork()` shows a connected DAG with no orphans
- All target functions are pure (no side effects, deterministic)
- Pipeline can be re-run from scratch and produce identical results
- `tar_outdated()` returns empty when nothing has changed

## Out of scope

- Data validation logic → `r-data-validation`
- Data I/O patterns → `r-data-io`
- CI/CD for running pipelines → `r-ci`
- drake (deprecated predecessor) — use targets exclusively

## Cross-references

- `r-project-scaffold` — project layout with targets stub
- `r-data-io` — reading/writing data in target functions
- `r-data-validation` — validation targets
- `r-testing` — testing target functions in isolation
- `r-ci` — running `tar_make()` in CI
- `r-dependencies` — renv for reproducibility
