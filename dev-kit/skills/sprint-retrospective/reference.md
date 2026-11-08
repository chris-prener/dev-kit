# Sprint Retrospective — reference

Contract and QA detail for the `sprint-retrospective` skill. `SKILL.md` holds the procedure; this file holds outputs, success criteria, restartable semantics, scope, and cross-references.

## Outputs

**Shipped path:**
- One `## Sprint Retrospective` comment on the sprint.
- Completed members ticked, descoped members annotated and left unticked; the `**Status:**` line set to the `shipped` value in `_partials/sprint-status.md`.
- The sprint `CLOSED` with reason `completed`.

**Descoped path:**
- The carve-out label applied, a short rationale comment, `**Status:** descoped`, the sprint `CLOSED` as not planned. No retrospective.

## Success criteria

- The skill refuses to close while any member is open, and names the open members.
- On the shipped path the status line matches the wording in [`_partials/sprint-status.md`](${CLAUDE_SKILL_DIR}/../_partials/sprint-status.md) exactly, and its link resolves to the retro comment.
- On the descoped path the carve-out label is on the issue *before* the close, and no retro is posted.
- The parent Area epic is untouched in every path.
- Re-running on a closed, retro'd sprint is a no-op; re-running after a partial failure finishes the remaining steps without double-posting.

## Restartable semantics

Restartable, not transactional. The order retro → body edit → close means a failure leaves a state Phase 0 recognizes: a retro with an open sprint (finish the edit and close), or a closed sprint with a stale status line (repair the status line). The retro comment is never posted twice.

## Out of scope

- **Closing an epic or rolling up KR impact** — `epic-retrospective`; KR impact at sprint close is its own issue.
- **Closing ordinary issues** — `backlog-retrospective`, which refuses sprints and names this skill.
- **Filing or editing a sprint** — `sprint`.
- **Updating `docs/ROADMAP.md`** — the roadmap contract for sprints is a separate issue.
- **Writing `active`** — derived at read time, never stored.

## Cross-references

- `sprint` — the filer; defines the body this skill reads and rewrites.
- `epic-retrospective` — the area-level counterpart; never invoked from here.
- `backlog-retrospective` — closes the member issues first, and refuses a sprint.
- `session-start` — scans recently closed issues for a missing retrospective, including `## Sprint Retrospective`.
- Status vocabulary: [`_partials/sprint-status.md`](${CLAUDE_SKILL_DIR}/../_partials/sprint-status.md)
- Close conventions and heading registry: [`_partials/retro-close-conventions.md`](${CLAUDE_SKILL_DIR}/../_partials/retro-close-conventions.md)
