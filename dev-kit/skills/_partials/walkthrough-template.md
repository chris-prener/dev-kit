# Walkthrough templates (shared partial)

Referenced by `walkthrough` under its "Standard walkthrough structure" and "Pipeline/step section template" headings.

## Standard walkthrough structure

The walkthrough should follow this structure (adapt section names and depth to fit the specific project — skip sections that don't apply, e.g. Data Model for a system with no persistent data shape):

```
1. Overview
   - What this system does (2–3 sentences)
   - What it produces
   - Who it's for

2. Architecture
   - Repository structure (directory map with descriptions)
   - Execution model (how components relate to each other)
   - Execution flow diagram (text-based or Mermaid)

3. Prerequisites
   - Required software and dependencies
   - Required data access (file paths, credentials, APIs)
   - Environment setup

4. Configuration & Setup
   - User-specific configuration
   - Expected counts / validation parameters, if applicable
   - Interactive prompts and what they control

5. Data Model (if applicable)
   - Primary key(s) and how they're constructed
   - Hierarchy or nesting model, if any
   - Key column reference (name, type, description, source)

6. Steps (one section per major stage)
   For each step:
   - Purpose (what this step accomplishes)
   - Inputs (what it reads / receives)
   - Process (what transformations occur, in order)
   - Validation (what inline checks verify)
   - Outputs (what it produces / passes downstream)
   - Data shape (key columns and approximate row counts at entry and exit), if applicable

7. Helper Function Reference
   - Organized by module/file
   - One-paragraph description per function
   - Input/output summary

8. Output Data Dictionary (if applicable)
   - For each output: format, location, schema, row-level description

9. Independent Sub-Systems (if any)
   - Same step-by-step treatment as the main system

10. How-To Guides
    - How to run the whole system
    - How to run a single step (if possible)
    - How to add a new input source
    - How to update expected validation counts, if applicable
    - Common errors and troubleshooting
```

## Pipeline/step section template

For each major step, write a section that follows this template:

```markdown
## Step N: [Step Name]

**Entry point:** `path/to/step_file`
**Trigger:** [How this step is invoked — orchestrator, manual, etc.]

### Purpose

[1–2 paragraphs explaining what this step accomplishes and why it's needed]

### Inputs

| Input | Source | Description |
|-------|--------|-------------|
| [name] | [file/upstream step/API] | [what it contains] |

### Process

1. **[Sub-step name]** — [Description of what happens]. The key operation is
   `function_name()`, which [does what]. After this step, the data has
   [N columns, ~N rows].

2. **[Sub-step name]** — [Description]. Note that [important caveat or
   design decision].

   [Include a brief code reference when helpful:]
   > `orders <- purrr::map_df(.x = files, .f = ~normalize_order(...))`

3. ...

### Validation Checkpoints

| Assertion | Expected Value | Purpose |
|-----------|---------------|---------|
| `expect_equal(length(files), N)` | N | Confirms all input files found |
| `expect_equal(nrow(df), N)` | N | Confirms no rows lost in join |

### Outputs

| Output | Format | Destination | Description |
|--------|--------|-------------|-------------|
| [name] | [tibble/CSV/JSON] | [file path or next step] | [schema summary] |

### Data Shape at Exit

Key columns at this stage:
- `order_id` (character) — composite order key, e.g., "ORD-000123"
- `order_date` (date) — order date
- `amount` (numeric) — order total
- ...

Approximate row count: ~[N] (varies with data updates)
```
