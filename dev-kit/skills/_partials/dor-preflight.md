# DoR pre-flight gate (shared partial)

Verifies the **structural** subset of an issue's Definition of Ready. This is the canonical source of DoR structural-check logic. `backlog` composes this partial (from its Create, Groom, Triage, and Auto-file operations) rather than re-implementing the same heuristics.

## Modes

The gate has two execution modes, distinguished by who's invoking:

- **Interactive mode** (default; used by `backlog`'s Create operation Step F.5, and by its Groom operation after groom-inbox fills the deferred sections of a `needs-grooming` issue): WARNING-level misses surface a single warning summary and an explicit `[y/N]` proceed prompt. INFO-level misses are listed but never block. Never silently fixes structure.
- **Non-interactive mode** (used by `backlog`'s Auto-file mode, and by its Triage operation against incoming issues before routing): runs the same checks and returns a structured pass/fail result to the caller. WARNING-level misses → caller error. The caller is responsible for assembling a conformant body or surfacing the failure.

## Exemption matrix

Two body markers downgrade specific checks. They are mechanically distinct:

| Marker | Semantics | What it downgrades |
|---|---|---|
| `<!-- autofile-id: <skill>:<scope>:<check-id> -->` | **Provenance** — a finding-producing skill filed this issue mechanically. | User-story header check downgraded to INFO (the autofile-id is the provenance). Other checks unchanged. |
| `needs-grooming` Status label (typically set by `backlog`'s Capture operation) | **Deferral** — the human author intentionally captured a half-formed idea. | Template-appropriate top-level headings, Type-label, Priority-label, and Epic-linkage checks downgraded to INFO. **User-story check stays WARNING** — it's the one invariant Capture guarantees, and the only field that distinguishes an honest deferral from a label-bypass. |

When **both** markers are present (rare), the union of downgrades applies, but the User-story check follows `needs-grooming` semantics (stays WARNING) — provenance does not override the deferral-time invariant.

## Checks

The gate verifies what is machine-checkable without semantic judgment.

| DoR item | What's checked | Severity if missing |
|---|---|---|
| User story header | The first content section heading is `## User story` (preceded only by the `**Parent epic:**` metadata line) and contains either an `As a` / `I want` / `so that` triple **or** the `**Mechanical change** — <one-line>` escape hatch. See [`user-story.md`](user-story.md). **Exempt** when the body contains an `<!-- autofile-id: ... -->` marker (auto-filed `qc` / `audit-finding` issues — provenance is the autofile-id). | WARNING (always — `needs-grooming` does NOT downgrade this) |
| Template-appropriate top-level headings | `feature_request.md` requires `## User story` + `## Problem` + `## Proposal` + `## Acceptance criteria`. `tech_debt.md` requires `## User story` + `## Current pain` + `## Motivation` + `## Acceptance criteria`. `bug_report.md` requires `## User story` + `## Problem` + `## Expected vs. actual` + `## Reprex`. `qc_finding.md` requires `## User story` + `## Finding` + `## Acceptance criteria`. `documentation.md` requires `## User story` + `## Gap` + `## Suggested fix` + `## Acceptance criteria`. `other_inquiry.md` requires `## User story` + `## Question` (no Acceptance criteria — a question isn't actionable work). **Downgraded to INFO under `needs-grooming`** (captured bodies use TODO placeholders, which still satisfy the heading-presence check in practice). | WARNING |
| One Type label | At least one of `bug`, `enhancement`, `documentation`, `tech-debt`, `epic`, `audit-finding`, `qc`, `spike` (per [`label-vocabulary.md`](label-vocabulary.md)). **Downgraded to INFO under `needs-grooming`** (Capture defaults to `enhancement`; refinement happens during Groom). | WARNING |
| One Priority label | At least one of `priority/blocker`, `priority/high`, `priority/medium`. May be skipped for low-stakes / speculative items. **Always INFO under `needs-grooming`**. | INFO (interactive) / WARNING (non-interactive) |
| Epic linkage *or* standalone justification | Either the epic-linkage step captured a parent epic number, or the body contains `**Parent epic:** standalone — <reason>`. See [`epic-linkage.md`](epic-linkage.md). **Downgraded to INFO under `needs-grooming`** (parent epic is a deferred grooming-checklist item). | WARNING |
| Worth-doing signal | Optional — `backlog`'s Create operation Step D judgment (now / later / no) was made and, on **now**, a priority label was applied. | INFO |

### Out of scope for this gate

Surfaced as agent guidance, not auto-verified:

- "Concrete and testable" Problem / Motivation statement
- "Falsifiable" Acceptance criteria
- "Specific" Codebase context

These qualities require semantic judgment; consumer skills prompt the agent to assess them and surface concerns to the user, but the gate does not block on them.

## Interactive-mode output

If any WARNING-level item is missing, print:

```
⚠ DoR pre-flight: <N> warnings
  - <issue>: <one-line description + suggested fix>
  ...
Proceed with `gh issue create` anyway? [y/N]
```

A `y` response continues; anything else returns the consumer skill to its draft-revision step.

INFO-level items are listed but never block.

## Non-interactive-mode contract

Returns one of:

- `{action: "pass"}` — all WARNING-level checks satisfied.
- `{action: "fail", warnings: [<list of strings>]}` — one or more WARNING-level checks failed. Caller MUST surface the warnings; MUST NOT silently fix or prompt.

INFO-level checks are reported in the result but do not change `action`.

## Composition

- `backlog`'s Create operation Step F.5 invokes this in interactive mode.
- `backlog`'s Auto-file mode invokes this in non-interactive mode.
- `backlog`'s Triage operation invokes this in non-interactive mode against incoming issues before routing.
- `backlog`'s Groom operation invokes this in interactive mode after groom-inbox fills the deferred sections of a `needs-grooming` issue.
