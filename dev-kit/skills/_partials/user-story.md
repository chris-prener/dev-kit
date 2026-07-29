# User story format (shared partial)

Every issue body opens with a User story block. This partial documents the format, the standard roles, and the mechanical-change escape hatch. Enforced by [`dor-preflight.md`](dor-preflight.md).

## Format

Standard agile format. Position: **after** the `**Parent epic:**` metadata line (the first non-blank line of every issue body) and **before** the first content section heading (`## Problem`, `## Motivation`, `## Finding`, etc.). The `## User story` heading is the first **section heading** in the body.

```markdown
**Parent epic:** #<N>   (or `standalone — <reason>`)

## User story

**As a** <role>,
**I want** <capability>,
**so that** <outcome>.
```

All three components (`As a`, `I want`, `so that`) are required. Reject empty or placeholder values; prompt the user to refine if missing.

## Standard roles

The role is rarely an end-user for repo / pipeline work. Pick from the canonical list (or supply free text if none fit):

| Role | Use when… |
|---|---|
| `data consumer` | Downstream code or pipeline that consumes this repo's output. |
| `dataset owner` | Person responsible for a dataset or data product. |
| `repo maintainer` | Owns repo-level workflow / scaffolding. |
| `AI agent` | Claude Code operating in the repo. |
| `pipeline operator` | Runs the repo's pipelines or scheduled jobs. |
| `new contributor` | Onboarding a fresh contribution or first PR. |

If none fit, the consumer skill prompts: `"Other — <free text>"`. One-off roles are fine for one-off issues; if the same custom role appears on multiple issues, that's a signal to add it to this canonical list.

## Acceptance criteria pairing

Acceptance criteria continue to follow Given/When/Then style **or** simple checklists — both pair naturally with user stories. No dogmatic shift to BDD-style ACs.

## Mechanical-change escape hatch

For minor mechanical chores (filename renames, version bumps, label additions, etc.) where a full user story is overkill, allow:

```markdown
## User story

**Mechanical change** — <one-line description>. No primary user story; this is a chore enabling [linked issue / epic / standard].
```

This **explicit acknowledgment** is preferable to silently omitting the section. The DoR pre-flight gate ([`dor-preflight.md`](dor-preflight.md)) accepts either the full three-part format or this escape hatch.

## Backfill policy

Existing issues filed before this format was adopted lack User story blocks. Backfill is **opportunistic, not enforced**: when an issue is picked up for work, the agent adds a User story at the top as part of pickup. Automatic mass-backfill is out of scope.

## Composition

- Issue templates under `.github/ISSUE_TEMPLATE/` embed a `## User story` placeholder block in the canonical position.
- The `backlog` skill prompts for the User story before codebase analysis (Step A.5, between template selection in Step A and codebase analysis in Step B).
- The `quick-capture` skill makes the User story the **only** required input — everything else is deferred to grooming.
- [`dor-preflight.md`](dor-preflight.md) validates User story presence as a WARNING-level structural check **for human-authored issues**. Auto-filed issues (Type label `qc` or `audit-finding`, identified by the `<!-- autofile-id: ... -->` body marker) are **exempt** — their provenance is the autofile-id itself, not a hand-written user story. Caller skills MAY still inject a synthetic User story (e.g., `**As a** dataset owner, **I want** this QC check to pass, **so that** the dataset stays release-eligible.`) but it is not required.
