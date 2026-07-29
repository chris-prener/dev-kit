# Epic Creator — reference

Contract and QA detail for the `epic` skill. `SKILL.md` holds the procedure; this file holds outputs, success criteria, restartable semantics, scope, and cross-references.

## Outputs

- One open GitHub issue with `epic` label and the canonical body.
- (Optionally) milestone attached.
- One new line in `${CLAUDE_PROJECT_DIR}/docs/ROADMAP.md` under the chosen horizon.
- A one-paragraph summary suitable for the user's records.

## Success criteria

- The epic issue exists with `epic` + at least one Priority label and a `[Epic <id>] <theme>` title.
- The body contains all required sections (Goal / Why now / AC / Decisions / Sub-issues / Related work / Out of scope), with `_TBD_` placeholders for forward-referenced fields.
- The roadmap has exactly one entry for this issue (validated by the `roadmap` skill's Phase 0).
- Re-running the skill in resume mode on the same issue is a no-op for filing and idempotent for roadmap registration.
- The chosen epic ID does not collide with any existing epic.

## Restartable semantics

The skill is restartable, not transactional:

- **Resume from an existing epic issue**: pass the issue number; the skill skips filing and reconciles the roadmap.
- **Partial-failure recovery**: if Phase 3 (file issue) succeeds but Phase 4 (roadmap registration) fails, the user can re-run with the just-created issue number to complete only Phase 4.
- **Duplicate detection** runs every time, so a re-run after a filing failure surfaces the partially-created issue rather than producing a duplicate.

## Out of scope

- **Closing or retro-ing an epic** — that's the `epic-retrospective` skill.
- **Linking sub-issues** — sub-issues are linked at *their* creation time via the `backlog` skill's epic-linkage step. This skill initializes `## Sub-issues` to `_None yet._` and stops there.
- **Cross-repo epics** — single-repo only.
- **GitHub Projects / board view** — defer.
- **Auto-creating ADRs / requirements docs / objective KRs** — those are forward-referenced and backfilled by their respective skills.
- **Re-using the issue templates in `${CLAUDE_PROJECT_DIR}/.github/ISSUE_TEMPLATE/`** — epics use this skill's template directly; the issue templates do not have an "epic" variant.

## Cross-references

- `roadmap` — invoked once per filing to register the epic.
- `epic-retrospective` — closing counterpart of this skill.
- `backlog` — used for filing sub-issues; carries the epic-linkage step.
- `pull-request` — when work on the epic begins, PRs cite epic sub-issues via `Closes #N` per the standard pull-request flow.
- `requirements` — invoked by the requirements gate (Phase 1.5a) when no requirements doc exists.
- `adr` — invoked by the ADR gate (Phase 1.5b) when an architectural decision needs recording.
- `objectives` — invoked by the objective prompt (Phase 1.5c) for linking or filing.
- `epic-dependency` — parses the `## Dependencies` block; renders the cross-epic dependency map to ROADMAP.
- Label vocabulary: [`../_partials/label-vocabulary.md`](${CLAUDE_SKILL_DIR}/../_partials/label-vocabulary.md); consuming-repo labels, if any, at `${CLAUDE_PROJECT_DIR}/.github/LABELS.md`
- Repo layout invariants: [`../_partials/repo-layout-note.md`](${CLAUDE_SKILL_DIR}/../_partials/repo-layout-note.md)
