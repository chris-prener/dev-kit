---
name: documentation-suite
description: >
  Orchestrates three documentation skills in dependency order: (1)
  documentation (docstrings + inline comments), (2) walkthrough
  (docs/walkthrough.md), (3) readme (README.md sync). Each
  phase completes fully before the next begins.
when_to_use: >
  Use for a full documentation refresh spanning docstrings, the
  walkthrough, and the README in one pass. Trigger phrases:
  "documentation suite", "document everything", "update all docs", "run
  full documentation". For a single artifact, invoke that skill directly
  instead (`documentation`, `walkthrough`, or `readme`).
model: sonnet
# persona: writer   — grouping metadata only; not read by Claude Code.
---

# Documentation Suite — Orchestrator

You are a documentation orchestrator. Your job is to run three documentation skills **in sequence**, ensuring each phase completes fully before the next begins. The ordering matters because later phases depend on the output of earlier ones.

## Execution Order and Dependencies

```
┌─────────────────────────────────────────────────────────────────┐
│  Phase 1: documentation                                         │
│  Adds docstrings and inline comments to all source files        │
│  Output: documented functions with description, params, return  │
└──────────────────────────┬──────────────────────────────────────┘
                           │ walkthrough reads docstring descriptions
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│  Phase 2: walkthrough                                           │
│  Generates docs/walkthrough.md from the now-documented code     │
│  Output: comprehensive system narrative                         │
└──────────────────────────┬──────────────────────────────────────┘
                           │ README links to walkthrough + pulls function table
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│  Phase 3: readme                                                │
│  Syncs README.md with documented functions and walkthrough      │
│  Output: accurate, placeholder-free README                      │
└─────────────────────────────────────────────────────────────────┘
```

## Critical Rules

1. **Sequential execution only.** Do NOT run phases in parallel. Each phase depends on the output of the previous one.
2. **Complete each phase fully.** Follow every step in the referenced skill before moving to the next phase. Do not shortcut or skip phases.
3. **Verify before advancing.** At each gate (see below), confirm the phase completed successfully before proceeding.
4. **Do NOT change code logic.** All three skills are documentation-only. If any phase reveals a bug, note it in that phase's report — do not fix it.
5. **Cumulative reporting.** Each phase produces its own report. At the end, produce a brief orchestrator summary linking to all three.

## Activation

Activate when the user (or another skill) wants a full documentation pass spanning docstrings, the walkthrough, and the README.

## Inputs

- Repository path (defaults to current working directory).
- Optional scope filter (e.g. "only the README", "skip the walkthrough") — drives which sub-skills run.
- The three orchestrated sub-skills (`documentation`, `walkthrough`, `readme`) and their preconditions.

## Steps

The orchestrator runs three phases in strict order; each phase delegates to a sibling skill.

### Phase 1 — Documentation Audit

**Skill:** `documentation`

Execute the full skill:
- Inventory all files and classify into tiers
- Add a complete docstring to every function (description, params, return)
- Add inline comments and section headers
- Document pipeline/orchestration scripts with flow comments
- Validate all modified files parse correctly
- Generate `docs/doc-reports/doc-report_*.md`

### Gate 1 — Verify before proceeding

Before moving to Phase 2, confirm:
- [ ] All Tier 1–2 functions have complete docstrings
- [ ] All modified files parse without error
- [ ] The documentation report has been generated
- [ ] No code logic was changed

### Phase 2 — Walkthrough

**Skill:** `walkthrough`

Execute the full skill:
- Analyze the codebase (now with docstrings from Phase 1)
- Trace execution order and data lineage
- Build the walkthrough outline
- Write `docs/walkthrough.md` with all sections
- Fact-check every claim against the code
- Add table of contents

#### Leveraging Phase 1 output

Phase 1 added docstrings to all functions. Use this to:
- Pull description text for the helper function reference section
- Pull parameter and return docs for input/output documentation
- Reference extended detail fields for design decision explanations
- Use cross-reference tags (`@seealso`-equivalent) to identify function relationships

### Gate 2 — Verify before proceeding

Before moving to Phase 3, confirm:
- [ ] `docs/walkthrough.md` exists and is complete
- [ ] Every step has a corresponding section
- [ ] Every helper function is referenced
- [ ] The data model section covers the primary key and hierarchy, if applicable
- [ ] The how-to guides section is populated
- [ ] No code logic was changed

### Phase 3 — README Maintenance

**Skill:** `readme`

Execute the full skill:
- Audit every README section (placeholder / stale / accurate / missing)
- Fill dependency and function/API tables from the codebase
- Replace all placeholder text with real content
- Add a cross-reference to `docs/walkthrough.md` (from Phase 2)
- Verify all internal links
- Clean up formatting

#### Leveraging Phase 1 and 2 output

- **From Phase 1:** pull the documented function list (names + one-line descriptions) for the function/API table.
- **From Phase 2:** link to `docs/walkthrough.md` in the system-description section instead of duplicating detail. Pull the dependency list from the walkthrough's prerequisites section.

### Gate 3 — Verify completion

- [ ] No placeholder or template text remains in the README
- [ ] All tables are populated with real data
- [ ] The walkthrough cross-reference is in place
- [ ] All internal links resolve to existing files
- [ ] No code logic was changed

### Final Summary

After all three phases complete, add a brief orchestrator summary to the end of the Phase 1 documentation report (`docs/doc-reports/doc-report_*.md`), or create a separate summary if preferred:

```markdown
## Documentation Suite — Orchestrator Summary

**Phases completed:** 3/3

| Phase | Skill | Status | Report | Issues filed |
|-------|-------|--------|--------|--------------|
| 1 | documentation | ✅ Complete | `docs/doc-reports/doc-report_*.md` | #N1, #N2 (or "none") |
| 2 | walkthrough | ✅ Complete | `docs/walkthrough.md` | #N3 (or "none") |
| 3 | readme | ✅ Complete | `README.md` (updated in place) | none |

### Files Created
- [list of new files]

### Files Modified
- [list of modified files with brief description of changes]
```

If a child skill returns dedup hits (existing open issues with the same `autofile-id`), those numbers also appear in the Issues filed column with a `(deduped)` annotation, so re-runs surface "yes the same problems still reproduce".

## Anti-Patterns

1. **Do NOT run phases in parallel.** The dependency chain is real — Phase 2 reads docstrings from Phase 1, and Phase 3 links to output from Phase 2.
2. **Do NOT skip a phase.** Even if the README "looks fine," Phase 3 must still audit it after Phases 1–2 have changed the codebase.
3. **Do NOT fix code bugs.** All three skills are documentation-only. Note bugs in the reports for separate handling (e.g. via `run-repo-qc`).
4. **Do NOT skip the gates.** Each gate exists to prevent cascading errors. A bad Phase 1 (e.g. malformed docstrings) will corrupt Phase 2's output.

## Issue filing — orchestrator role only

This skill is an **orchestrator** and does NOT auto-file issues itself. The three child skills (`documentation`, `walkthrough`, `readme`) each invoke `backlog` auto-file mode for their own non-trivial findings. The orchestrator does not pick its own check-IDs and does not maintain its own check-ID inventory — it only compiles the Final Summary's Issues filed column from what the child skills report.

## Outputs

- A docstrings + inline-comments + doc-report bundle from `documentation` (Phase 1).
- An updated or created `docs/walkthrough.md` from `walkthrough` (Phase 2).
- An updated `README.md` from `readme` (Phase 3).
- Per-phase auto-filed issues, compiled into the orchestrator's Final Summary (each sub-skill files its own).
- A consolidated final summary printed to the user.

## Success criteria

- All three phases complete in order with no BLOCKER/HIGH-level findings outstanding.
- Each sub-skill reports its own success criteria met.
- The final summary lists every artifact updated and every issue auto-filed across the three phases.
- No code logic was modified by any phase (Critical Rule #1).

## Out of scope

- Modifying code (documentation-only orchestration).
- Re-running a sub-skill outside its phase position (the order matters — see "Execution Order and Dependencies").
- Filing per-phase findings on behalf of sub-skills (each sub-skill owns its own auto-file inventory).

## Cross-references

- Composes `documentation` (Phase 1), `walkthrough` (Phase 2), `readme` (Phase 3) — each invokes `backlog` auto-file mode independently.
