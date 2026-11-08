# Sprint status vocabulary (shared partial)

The `**Status:**` header line of a sprint issue takes exactly one of the values below. Defined once here so the sprint filer (`sprint`) and closer (`sprint-retrospective`) cannot drift (ADR-0002, Rule 2). Sprints are issue-backed per [ADR-0001](../../../docs/adr/ADR-0001-sprint-as-issue-backed-concept-mirroring-epic.md); the `sprint` label is in the baseline in [`label-vocabulary.md`](label-vocabulary.md).

| Status | Meaning | Set by |
|---|---|---|
| `planned` | Filed; membership drafted; not yet started | `sprint` (filer) |
| `committed` | Scope agreed and timebox set; work not begun | `sprint` (filer) |
| `active` | At least one member issue is `in-progress` | **derived**, never stored |
| `shipped (closed DATE — see [Sprint Retrospective](url))` | All members closed; retro posted | `sprint-retrospective` (closer) |
| `descoped` | Closed without completing; a carve-out label applies; no retro | `sprint-retrospective` (closer) |

`DATE` is `YYYY-MM-DD`. `url` is the permalink of the `## Sprint Retrospective` comment.

## `active` is derived, never written

`active` is computed at read time from the member issues' `in-progress` labels: a sprint is `active` when its status is `committed` (or `planned`) and at least one task-list member carries `in-progress`. **No skill writes `active` into a sprint body** — a stored value goes stale the moment the last member leaves `in-progress`. Readers (for example `session-start`, or a sprint view) compute it.

## Transitions

`planned` → `committed` → (`active`, derived) → `shipped` or `descoped`. A sprint may go from `planned` straight to `shipped` or `descoped`. `shipped` and `descoped` are terminal; both come with the issue closing.

`committed` requires a real start and end date in the `**Timebox:**` line; `planned` also accepts `_unscheduled_`.
