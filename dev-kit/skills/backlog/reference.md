# Backlog Manager — reference

Contract and QA detail for the `backlog` skill. Loaded on demand; not needed for every run. `SKILL.md` holds the procedure; this file holds the input/output contract and the success bar.

## Inputs

| Operation | Inputs |
|---|---|
| Review / prioritize (Steps 1–4) | None required; enumerate open issues via `gh`. Optional subset filter such as `bugs only`. |
| Create new item (Steps A–H) | User story per `../_partials/user-story.md`; template choice; parent epic # **or** standalone justification per `../_partials/epic-linkage.md`; optional now/later/no worth-doing judgment (Step D). |
| Auto-file mode | `template`, `title`, `body`, `labels`, `dedup_id`, and exactly one of `parent_epic` XOR `standalone_reason`, plus severity and caller-provided finding content per `../_docs/ADR-0004-auto-filed-issue-protocol.md`. |

## Outputs

| Operation | Output |
|---|---|
| Review / prioritize | Prioritized backlog summary, optional implementation plans, and optional sister-skill hand-off. |
| Interactive create | New GitHub issue with Parent-epic line, `## User story`, template body, `Codebase Context`, required labels, and optional native sub-issue link. |
| Auto-file mode | Same durable issue contract plus `<!-- autofile-id: ... -->` dedup marker and source labels. |

## Success criteria

- Every new issue has at least one Type label, the Parent-epic metadata line, and `## User story` as the first content section.
- Non-trivial issues get a now/later/no worth-doing judgment (Step D); chores may use the `**Mechanical change**` escape hatch for the user story.
- Auto-file mode never duplicates an open issue with the same `autofile-id`.
- Step 4 implementation plans are actionable without revisiting the original issue body.
- Routing sends triage / grooming / quick-capture requests to the right skill before the heavy flow begins.
