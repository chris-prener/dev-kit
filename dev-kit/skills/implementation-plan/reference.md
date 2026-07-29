# Implementation Plan — reference

Contract and QA detail for the `implementation-plan` skill. `SKILL.md` holds the procedure; this file holds the schema, state machine, label mapping, outputs, success criteria, and cross-references.

## Schema parsing

Parse the body deterministically after the marker:

1. Strip the marker and following blank lines; the next line must be `## Implementation plan`.
2. The next two non-blank lines must be, in order: `_Last updated: <ISO-8601-UTC>_`, `_Status: <enum>_`.
3. Validate `Status:` against the five-value enum below.
4. Split the remainder on `^### ` headings.
5. Require these six sections, exactly once and in order: `Approach`, `Files to touch`, `Verification`, `Risks / open questions`, `Where I left off`, `Decisions made`.

Empty sections use `_TBD in drafting._` for `Files to touch` / `Verification` while drafting, `_None yet._` for `Risks / open questions` / `Decisions made`, and `_Not yet started._` for `Where I left off`. Never leave a section heading without body content.

## Status state machine

Five values: `drafting`, `in-progress`, `blocked`, `ready-for-pr`, `shipped`.

Legal transitions:

```
drafting → in-progress
in-progress ⇄ blocked
in-progress → ready-for-pr
blocked → ready-for-pr
ready-for-pr → shipped
in-progress → shipped   (casual path; note it in the transition message)
shipped → drafting      (reopen only, with explicit confirmation — see SKILL.md)
```

Any other requested transition is rejected with the current and legal-next states named.

## Label mapping

| Status | Labels |
|---|---|
| `in-progress` | `+in-progress`, `-blocked` |
| `blocked` | `+blocked`, `-in-progress` |
| `drafting` / `ready-for-pr` / `shipped` | `-in-progress`, `-blocked` |

See [`_partials/label-vocabulary.md`](${CLAUDE_SKILL_DIR}/../_partials/label-vocabulary.md) for the label's origin and repo-level resolution order.

## Outputs

- `Create` / `Update` / `Transition`: updated GitHub comment; label updates for `Transition`.
- `Read`: parsed plan printed or returned.
- `Reconcile labels`: label update only.
- One short success line per operation.

## Success criteria

- Exactly one comment matches the plan locator after every successful write.
- Every `Transition` either updates both comment and labels, or leaves the comment correct and surfaces the label failure loudly with a `Reconcile labels` pointer.
- Re-running an idempotent operation is a no-op with a clear message.
- `Create` is the only legal operation when no plan exists.
- Duplicate markers hard-fail all operations until manually fixed.

## Out of scope

- Filing or closing issues (`backlog`, `backlog-retrospective`).
- PR-body composition (`pr-orchestrator`).
- Cross-issue dashboards or plan aggregation.
- Concurrent-edit conflict resolution — this skill assumes one agent works one issue's plan at a time. If you're running multiple concurrent sessions against the same issue, that's a workflow choice outside this skill's scope, not a case it guards against.
- Migrating `-v1` plans to a future schema.

## Cross-references

- `pr-orchestrator` — invokes `Transition` (to `shipped`) inline when closing an issue.
- `code-review` — reads the plan's `### Approach`, `### Verification`, and `### Decisions made` sections as review context, when present.
- `backlog-grooming` / `triage` — read the `in-progress` label only.
- `_partials/label-vocabulary.md` — `in-progress` / `blocked` Status labels.
