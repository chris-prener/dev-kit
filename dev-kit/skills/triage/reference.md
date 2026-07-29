# Triage — reference

Contract and QA detail for the `triage` skill. `SKILL.md` holds the procedure; this file holds outputs, success criteria, scope, and cross-references.

## Outputs

- Per-issue assessment blocks in chat.
- Per-mutation `## Triage` comments on the issue.
- Label changes via `gh issue edit`.
- (Route 1) Sub-issue link via `gh api .../sub_issues`.
- (Route 3, 4) Issue close with appropriate close-reason label.
- No file writes locally.

## Success criteria

- Every triaged issue exits with **either** `needs-triage` removed and a routing decision applied, **or** an explicit "deferred" outcome. No silent no-ops.
- The `## Triage` audit comment is posted on every routed issue.
- Epic promotion is **always** a hand-off to `epic`. This skill never sets the `epic` label or creates a new epic.
- Demotion of an epic with open sub-issues is **always** refused.
- Close-reason label is set **before** the close call (per `backlog-retrospective`).

## Out of scope

- **Promoting to epic directly.** See Step D — propose-only.
- **Bulk closing.** Triage is one-at-a-time even in inbox mode (per-item confirmation).
- **DoR remediation.** If the issue fails DoR, surface the gaps; routing is still allowed (the gap is on the picker-up's plate). Use `backlog-grooming` for systematic DoR remediation.
- **Re-judging worth-doing.** That lives in `backlog-grooming` (or in `backlog` Step D for fresh issues).
- **Auto-reopening closed issues** that show up as dedup hits — `backlog`'s auto-file mode is also explicitly out of this; manual reopening required (per [ADR-0004](${CLAUDE_SKILL_DIR}/../_docs/ADR-0004-auto-filed-issue-protocol.md)).
- **Setting Status labels other than `needs-triage` removal** — `blocked` / `UAT` / `qc-fixed` are owned by other skills.

## Cross-references

- [`../_partials/dor-preflight.md`](${CLAUDE_SKILL_DIR}/../_partials/dor-preflight.md) — non-interactive DoR check used in Step B.
- [`../_partials/epic-linkage.md`](${CLAUDE_SKILL_DIR}/../_partials/epic-linkage.md) — parent-epic validation + sub-issue link (Step C route 1).
- [`../_partials/label-vocabulary.md`](${CLAUDE_SKILL_DIR}/../_partials/label-vocabulary.md) — Type / Priority completeness check; defines `needs-triage` + close-reason labels.
- [`../_partials/user-story.md`](${CLAUDE_SKILL_DIR}/../_partials/user-story.md) — assessment includes User-story presence.
- `backlog` — auto-file mode injects `needs-triage` (and patches the dedup-hit path); interactive mode skips this skill.
- `quick-capture` — upstream intake with `needs-grooming`; not a direct sender to triage.
- `backlog-grooming` — sets `needs-triage` when promoting a `needs-grooming` issue out.
- `epic` — hand-off target for propose-promote-to-epic (Step D). Enforces requirements / ADR / objective gates.
- `epic-retrospective` — proper close path for epics; Step F demotion guard refers users here.
- `backlog-retrospective` — carve-out gate that REQUIRES the close-reason label before close.
