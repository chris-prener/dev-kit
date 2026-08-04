---
name: documentation
description: >
  Systematic, language-agnostic documentation audit. Ensures every
  function has a complete docstring block and that code is well-commented
  with clear inline explanations and section headers. Preserves existing
  documentation, fills gaps, produces a timestamped report.
when_to_use: >
  Use to audit a file or directory for docstring / inline-comment
  completeness, or to add documentation to undocumented functions.
  Trigger phrases: "add comments", "add docstrings", "audit
  documentation", "document functions". Not for PR-scoped stale-doc
  checks (`documentation-audit-changes`), multi-artifact doc runs
  spanning README + walkthrough + docstrings (`documentation-suite`),
  or R-specific roxygen2/vignette conventions (`r-documentation` — this
  skill covers the generic audit process; language packs own the exact
  tag/field conventions).
model: sonnet
# persona: writer   — grouping metadata only; not read by Claude Code.
---

# Documentation Audit

Add and improve docstrings, inline comments, section headers, and file-header blocks without changing code behavior. This skill owns the *process* (inventory, tiering, gap-filling, validation, reporting); it defers to a language-specific pack — e.g. `r-documentation` — for the exact docstring convention when one exists, and otherwise follows the ecosystem-standard convention for the language at hand.

## Critical Rules

1. Do not change code logic; if you find a bug, record it in the report instead.
2. Preserve existing documentation unless it is factually wrong.
3. Every Tier 1 / Tier 2 function gets a complete docstring.
4. Inline comments explain why, not what.
5. Match the repository's existing documentation style.
6. Validate touched files after documenting them.

## Activation

Activate when:

- auditing a file or directory for docstring / inline-comment completeness
- adding documentation to undocumented functions
- responding to requests like "add comments", "add docstrings", or "audit documentation"

**Not for**: PR-scoped stale-doc checks (`documentation-audit-changes`), multi-artifact doc runs (`documentation-suite`), or prose-only docs (that's `readme`, `walkthrough`, `glossary`, etc.).

## Inputs

- Repository path (default current directory).
- Optional file-scope filter.
- Existing documentation and any prior report under `docs/doc-reports/`.

## Steps

### Phase 1 — Discovery & Documentation Inventory

Understand the repository and current documentation state before editing.

### 1.1 Map the repository structure

List directories and files; identify languages, frameworks, and directory roles (shared helpers, per-module helpers, pipelines/orchestration, config). If `${CLAUDE_SKILL_DIR}/../_partials/repo-layout-note.md` has been filled in for this repo, use it instead of re-deriving layout from scratch.

### 1.2 Classify files into documentation tiers

| Tier | File type | Documentation strategy |
|---|---|---|
| **Tier 1 — Function libraries** | Shared or module-level helper files | Full docstring for every function plus inline comments |
| **Tier 2 — Script-embedded functions** | Scripts that define helper functions inline | Docstrings for embedded functions plus script-flow comments |
| **Tier 3 — Pipeline / orchestration scripts** | Sequential processing / orchestration scripts | Section headers + inline comments; no function docstrings needed |
| **Tier 4 — Configuration & setup** | Entry-point scripts, project config, environment setup | Header block comments; no docstrings |

### 1.3 Inventory current documentation state

For every file, record: docstring status (Yes / Partial / No), inline-comment status (Yes / Sparse / No), section-header presence, function count, and function count with complete vs. incomplete/missing docstrings.

### 1.4 Identify existing documentation conventions

Scan documented files first and copy the local style exactly: comment markers, section-header format, docstring tag/field order and convention (roxygen2, Python docstrings + type hints, JSDoc, etc.), line wrapping, and cross-reference style. For R projects, `r-documentation` and `${CLAUDE_SKILL_DIR}/../_partials/roxygen2-standards.md` define the canonical tag set — follow those rather than reinventing one.

### 1.5 Build the work queue

Prioritize in this order:

1. Tier 1 files with no docstrings
2. Tier 1 files with partial docstrings
3. Tier 2 files with embedded functions
4. Tier 3 scripts needing section comments
5. Tier 4 files needing header blocks

### Phase 2 — Function Documentation (Tier 1 & Tier 2 Files)

Write a complete docstring for every Tier 1/2 function: what it does, every parameter (name, type, meaning, constraints), and what it returns. For R, follow `${CLAUDE_SKILL_DIR}/../_partials/roxygen2-standards.md`. For other languages, follow that ecosystem's standard convention (e.g. Python: PEP 257 + type hints; keep tag/field order consistent within a file).

### Phase 3 — Inline Comments & Section Headers (All Tiers)

Detailed inline-comment and section-header rules live in [`_partials/inline-comment-standards.md`](${CLAUDE_SKILL_DIR}/../_partials/inline-comment-standards.md) (written with R examples; the "why not what" principle and section-header discipline apply regardless of language — adapt the concrete syntax to the file's language).

### Phase 4 — Pipeline-Specific Documentation (Tier 3)

Pipeline/orchestration scripts need flow-oriented comments instead of function docstrings.

#### 4.1 Document the data or control flow

Near the top of each pipeline script, summarize input, major transformations or stages, and output artifacts.

#### 4.2 Document inline assertions

When the script contains assertions or explicit validation calls, explain what is being validated and why that check matters.

#### 4.3 Document non-obvious branch logic

Explain the reason for conditional branches whose purpose isn't obvious from the code alone — differing input formats, historical quirks, environment-specific paths.

#### 4.4 Document entry-point guards

Explain any run-via-orchestrator guards, trigger flags, or early exits so maintainers know why direct execution fails or behaves differently.

### Phase 5 — Validation

#### 5.1 Parse check every modified file

After each edit, verify the file still parses. Fix malformed docstring or comment syntax before moving on.

#### 5.2 Verify docstring completeness

For every Tier 1 / Tier 2 file, confirm: every function has a description, every parameter is documented with type/meaning/constraints, and every function's return value is documented.

#### 5.3 Check for stale documentation

Update or remove documentation that no longer matches the code: stale parameter docs, stale usage examples, wrong return descriptions, or descriptions of old behavior.

#### 5.4 Spot-check inline comments

Verify comments explain why, are accurate, sit above the relevant block, and match the project's comment style.

### Phase 6 — Reporting

Create `docs/doc-reports/doc-report_YYYY-MM-DD_HH-MM-SS.md`, creating `docs/doc-reports/` if needed. The full report template lives in [`_partials/doc-report-template.md`](${CLAUDE_SKILL_DIR}/../_partials/doc-report-template.md).

## Process Checklist — Do Not Skip Any Step

- [ ] Phase 1: files inventoried, tiered, and style conventions identified.
- [ ] Phase 2: every Tier 1–2 function has a complete docstring.
- [ ] Phase 3: touched files have appropriate comments, section headers, and file headers.
- [ ] Phase 4: Tier 3 scripts have flow, assertion, branch, and guard documentation.
- [ ] Phase 5: parse checks passed and stale docs were corrected.
- [ ] Phase 6: report generated in `docs/doc-reports/`.

## Anti-Patterns — What NOT To Do

1. Do not change code logic.
2. Do not delete existing docs unless they are wrong.
3. Do not add comments that only restate the code.
4. Do not add function docstrings to Tier 3 / Tier 4 files.
5. Do not add runnable examples that require external data or network access unless wrapped appropriately.
6. Do not invent parameter constraints the code does not enforce.
7. Do not add boilerplate empty tags/fields.
8. Do not skip parse checks.
9. Do not document internal implementation detail when the contract is what matters.
10. Do not switch comment style away from the existing project convention.

### Phase 7 — Issue filing for non-trivial findings

Findings that cannot be fixed in place — or deserve durable tracking — are filed through `backlog`'s auto-file mode. The Phase 6 report still lists them; Phase 7 adds the durable issue.

For each finding with severity ≥ medium, invoke auto-file mode with:

- `template = tech_debt`
- `labels = ["documentation", "<priority/*>"]` per the severity mapping below
- `dedup_id = documentation:<file-path>:<check-id>`
- a body containing `<!-- autofile-id: <dedup_id> -->` near the top plus the `tech_debt` template's required headings
- either `parent_epic` or `standalone_reason`

INFO / LOW findings stay in the report only.

### Check-ID inventory

These IDs are stable dedup keys and must not be silently renamed.

| Check-ID | Trigger | Severity → Priority |
|---|---|---|
| `missing-docstring` | Tier 1–2 function has no docstring block | high → `priority/high` |
| `incomplete-docstring` | A required field (description / param / return) is missing | medium → `priority/medium` |
| `unmatched-param` | Documented parameter does not match the signature | medium → `priority/medium` |
| `stale-docstring` | Description or return doc no longer matches behavior | medium → `priority/medium` |
| `missing-return-doc` | Function returns a value but the return isn't documented | medium → `priority/medium` |
| `parse-failure` | Modified file fails to parse | high → `priority/high` |

## Outputs

- Complete docstrings on all Tier 1 / Tier 2 functions.
- Inline comments, section headers, and file-header blocks on touched files.
- Flow-oriented comments for Tier 3 scripts.
- A timestamped report in `docs/doc-reports/`.
- One auto-filed issue per non-trivial finding.

## Success criteria

- Every Tier 1 / Tier 2 function has a complete docstring.
- All modified files parse successfully.
- No stale documentation remains.
- The report is generated with all required sections.
- Phase 7 findings are fixed in place or filed with the correct check-id and severity-derived priority.

## Out of scope

- Code changes.
- Deleting existing documentation for style reasons.
- README updates (`readme`).
- Walkthrough updates (`walkthrough`).
- R-specific tag conventions and vignettes (`r-documentation`) — this skill covers the audit process and generic docstring/comment discipline.

## Cross-references

- `backlog` — auto-file mode for non-trivial findings.
- `documentation-suite`, `readme`, `walkthrough` — complementary documentation skills.
- `r-documentation`, `${CLAUDE_SKILL_DIR}/../_partials/roxygen2-standards.md` — R-specific docstring convention.
- `${CLAUDE_SKILL_DIR}/../_partials/inline-comment-standards.md` — inline comment and section-header discipline.
- `${CLAUDE_SKILL_DIR}/../_partials/repo-layout-note.md` — this repo's file-layout conventions, if filled in.
