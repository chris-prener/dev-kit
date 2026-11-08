# Sprint Filer — reference

Contract and QA detail for the `sprint` skill. `SKILL.md` holds the procedure and the body template; this file holds outputs, success criteria, restartable semantics, scope, and cross-references.

## Outputs

- One open GitHub issue with the `sprint` label, a `[Sprint <N>] <theme>` title, and the canonical body.
- On update: the same issue, edited in place.

## Success criteria

- The `**Area:**` target is an open issue carrying the `epic` label.
- `**Status:**` is `planned` or `committed`; never `active`, `shipped`, or `descoped` (see [`_partials/sprint-status.md`](${CLAUDE_SKILL_DIR}/../_partials/sprint-status.md)).
- A `committed` sprint has both timebox dates.
- Membership is a task list; no native sub-issue link exists from the sprint to its members.
- The body has the header lines and the four sections Goal / Membership / Sequencing / Definition of done.
- Re-running on an existing sprint produces no second issue.

## Restartable semantics

Restartable, not transactional:

- **Resume / update** — pass the existing sprint number; the skill edits the body in place. Phase 0's duplicate check also runs on every fresh filing, so a re-run after a partial failure surfaces the already-created issue instead of duplicating it.
- **Partial failure** — filing is a single `gh issue create`; there is no second step to recover. If it succeeds but the terminal report is lost, re-run in resume mode.

## Out of scope

- **Closing or retro-ing a sprint** — `sprint-retrospective`.
- **Linking members as native sub-issues** — membership is a task list by design (ADR-0003).
- **Registering the sprint on `docs/ROADMAP.md`** — defined by the roadmap issue; this skill writes nothing there until it lands.
- **Writing `active`** — derived at read time from member `in-progress` labels.
- **Cross-repo sprints** — single-repo only.

## Cross-references

- `epic` — the area this skill's Area must be; the filer it mirrors.
- `sprint-retrospective` — closing counterpart; reads this skill's body template.
- `backlog` — files the member issues.
- `implementation-plan` — sets the `in-progress` labels that make a sprint derive as `active`.
- Status vocabulary: [`_partials/sprint-status.md`](${CLAUDE_SKILL_DIR}/../_partials/sprint-status.md)
- Area validation: [`_partials/epic-linkage.md`](${CLAUDE_SKILL_DIR}/../_partials/epic-linkage.md)
- Label vocabulary: [`_partials/label-vocabulary.md`](${CLAUDE_SKILL_DIR}/../_partials/label-vocabulary.md)
