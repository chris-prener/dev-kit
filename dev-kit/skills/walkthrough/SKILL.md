---
name: walkthrough
description: >
  Generates a comprehensive, narrative walkthrough document
  (docs/walkthrough.md) that explains how the system works from end to
  end — raw inputs through every transformation to final outputs.
  Written for a reader who has never seen the repository.
when_to_use: >
  Use to produce or refresh a technical, end-to-end explanation of how
  the system works internally. Trigger phrases: "create walkthrough",
  "explain the pipeline", "document the data flow", "pipeline
  walkthrough", "technical guide". Not for README-only work (`readme`),
  docstring/inline-comment work (`documentation`), or architecture
  documentation beyond this walkthrough's scope (`architecture-overview`).
model: sonnet
# persona: writer   — grouping metadata only; not read by Claude Code.
---

# Walkthrough

You are a technical writer producing one coherent document — `docs/walkthrough.md` — that explains how the system works from raw input to final output. Write for a reader who knows the language and tools but has never seen this repository.

## Critical Rules

1. Do not change code.
2. Verify every claim against the code; never infer behavior from names alone.
3. Trace the data (or control flow), not just the call graph.
4. Describe data shape at key stages when applicable: columns, row counts, types, and constraints.
5. Explain why each step exists, not only what it does.
6. Deliver one complete narrative, not disconnected file summaries.

## Activation

Activate when the user or another skill requests a walkthrough, technical guide, or end-to-end system explanation.

## Inputs

- Repository path (default: current working directory).
- Output path (default: `docs/walkthrough.md`).
- Existing walkthrough content, if any.
- Entry-point script(s)/module(s) plus supporting source files.
- If `${CLAUDE_SKILL_DIR}/../_partials/repo-layout-note.md` has been filled in for this repo, use it as the map of source/output/config locations instead of re-deriving layout from scratch.

## Steps

### Phase 1 — Deep Codebase Analysis

Understand the system fully before writing.

#### 1.1 Map the complete repository structure

List every directory and file, and classify each directory's role: source code, data, docs, config, or support tooling.

#### 1.2 Trace the execution order

Starting from the entry point(s), determine:

1. what happens before sub-components run
2. component execution order
3. function call order inside each component
4. which components are standalone vs. dependent on upstream state / triggers
5. which prompts or operator choices alter execution flow

#### 1.3 Trace the data lineage (if the system processes data)

For every major data structure or persisted artifact, record:

- origin
- transformations (joins, filters, mutations, pivots, aggregations)
- column/field additions, removals, renames
- row/record-count changes
- validation checkpoints such as `expect_equal()` / `stopifnot()` / assertions
- final destination

#### 1.4 Understand the primary key and hierarchy model (if applicable)

If the system uses composite or hierarchical keys, document how keys are built, how the hierarchy nests, and which code systems or conventions are involved.

#### 1.5 Catalog all inputs and outputs

Capture:

- raw data inputs and how they are accessed
- lookup / reference data
- external APIs or services
- operator-supplied configuration
- final outputs, intermediate outputs, and logs/reports

#### 1.6 Identify independent sub-systems

Record the main system, any side systems, shared infrastructure, and whether each side path is triggered by the main entry point or run independently.

#### 1.7 Catalog helper functions

For every helper used in the system, note its purpose, defining file, callers, inputs, outputs, and side effects.

### Phase 2 — Outline Construction

Build the outline before prose.

#### 2.1 Standard walkthrough structure

The standard outline lives in [`_partials/walkthrough-template.md`](${CLAUDE_SKILL_DIR}/../_partials/walkthrough-template.md) under **Standard walkthrough structure**.

#### 2.2 Verify outline completeness

Before Phase 3, verify:

- every major component has a section
- every helper function is referenced
- every output is documented
- every input source is documented
- the data model covers primary keys and hierarchy, if applicable
- the how-to section covers the common maintainer tasks

### Phase 3 — Writing the Walkthrough

#### 3.1 Voice and tone

Write in present tense, technical but approachable, and concrete rather than abstract. Use real file paths, function names, and column/field names.

#### 3.2 Overview section

Write 2–3 paragraphs covering the system's purpose, the problem it solves, its final outputs and consumers, and its scope (data sources spanned, supported inputs, etc., if applicable).

#### 3.3 Architecture section

Include:

- a repository structure map with one-line descriptions
- an execution-flow diagram (text-based or Mermaid)
- clear differentiation between sequential dependencies and independent sub-systems

#### 3.4 Data model section (if applicable)

Cover:

- primary key construction with real examples
- the hierarchy, if any
- key-source mapping by category/source, if relevant
- a hierarchy diagram when the nesting is non-trivial

#### 3.5 Step sections

Use the canonical per-step structure in [`_partials/walkthrough-template.md`](${CLAUDE_SKILL_DIR}/../_partials/walkthrough-template.md) under **Pipeline/step section template**.

#### 3.6 Helper function reference

For each helper, provide name + file, purpose, inputs, returns, callers, and any non-obvious behavior. Organize by functional area, not alphabetically.

#### 3.7 Output data dictionary (if applicable)

For each final output, document format, location, row-level grain, approximate row count, and schema fields with descriptions and examples.

#### 3.8 How-to guides

Write short guides for:

1. running the whole system
2. running a single step, if supported
3. adding a new input source
4. updating expected counts / validation parameters, if applicable
5. common errors and troubleshooting

Each guide should stay concrete and actionable.

### Phase 4 — Verification

#### 4.1 Fact-check every claim

Verify that every file path, function name, column/field name, expected count, execution-order statement, transformation claim, and output reference matches the code.

#### 4.2 Completeness check

Verify:

- every major component has a step section
- every shared helper is referenced
- every output is documented
- every input source is covered
- independent sub-systems get their own coverage
- the data model covers primary keys and levels, if applicable
- the how-to section covers running, extending, and troubleshooting

#### 4.3 Readability check

Read top-to-bottom as a new team member would. Confirm that concepts are introduced before they are used, domain terms are defined on first use, and detail level stays consistent.

#### 4.4 Cross-reference with existing documentation

Ensure the walkthrough does not contradict `README.md` or other docs. It may expand them, but it should not duplicate large sections or introduce conflicting statements.

### Phase 5 — Finalization

#### 5.1 Write the file

Save to `docs/walkthrough.md`. If a walkthrough already exists, read it first and keep any accurate content.

#### 5.2 Add a table of contents

Add a linked table of contents near the top, covering every major heading.

#### 5.3 Link from README (if appropriate)

If `README.md` does not already point to `docs/walkthrough.md`, add a short reference only when it fits naturally into the README's structure.

## Process Checklist — Do Not Skip Any Step

- [ ] Phase 1: repository, execution order, data lineage, inputs/outputs, and helpers analyzed.
- [ ] Phase 2: outline built and checked for completeness.
- [ ] Phase 3: overview, architecture, data model (if applicable), step sections, helper reference, outputs, and how-to guides written.
- [ ] Phase 4: claims, completeness, readability, and cross-doc consistency verified.
- [ ] Phase 5: `docs/walkthrough.md` written, TOC added, README linked if appropriate.

## Anti-Patterns — What NOT To Do

The anti-pattern list lives in [`_partials/walkthrough-anti-patterns.md`](${CLAUDE_SKILL_DIR}/../_partials/walkthrough-anti-patterns.md).

### Issue filing for non-trivial findings

After updating the walkthrough, file durable issues for findings that cannot be fixed in place: stale sections, contradictions with the code, broken diagrams, or other documentation debt.

For each finding with severity ≥ medium, invoke `backlog` auto-file mode with:

- `template = tech_debt`
- `labels = ["documentation", "<priority/*>"]` per the mapping below
- `dedup_id = walkthrough:<section-anchor>:<check-id>`
- a body containing `<!-- autofile-id: <dedup_id> -->` plus the `tech_debt` template's headings
- either `parent_epic` or `standalone_reason`

INFO / LOW findings stay in the walkthrough update only and are not filed.

### Check-ID inventory

| Check-ID | Trigger | Severity → Priority |
|---|---|---|
| `stale-section` | Walkthrough content no longer matches the code | medium → `priority/medium` |
| `outdated-diagram` | Diagram references files / modules / functions that no longer exist | medium → `priority/medium` |
| `missing-data-model` | No data-model section for a system with non-trivial keys / joins | high → `priority/high` |
| `contradicts-readme` | Walkthrough directly contradicts `README.md` | high → `priority/high` |
| `aspirational-content` | Walkthrough describes behavior the code does not implement | high → `priority/high` |
| `unverified-claim` | Claim could not be verified against code | medium → `priority/medium` |

## Outputs

- `docs/walkthrough.md` covering the system's steps, prerequisites, configuration, data model (if applicable), helper functions, outputs, and how-to guidance.
- One auto-filed issue per non-trivial finding.
- A summary of sections written / updated and issues filed.

## Success criteria

- Every major step has a section following the Phase 3 template.
- All walkthrough claims are verified against actual code.
- In-walkthrough cross-references resolve.
- The process checklist and issue-filing requirements are complete.

## Out of scope

- Modifying code.
- README-only work (`readme`).
- Docstring / inline-comment work (`documentation`).
- Architecture documentation beyond the walkthrough's scope (`architecture-overview`).

## Cross-references

- `backlog` — auto-file mode for non-trivial findings.
- `documentation-suite` — orchestrator; Phase 2 invokes this skill.
- `${CLAUDE_SKILL_DIR}/../_partials/repo-layout-note.md` — this repo's file-layout conventions, if filled in.
