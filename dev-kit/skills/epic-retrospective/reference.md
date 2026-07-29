# Epic Retrospective — reference

Contract and QA detail for the `epic-retrospective` skill. `SKILL.md` holds the procedure; this file holds outputs, success criteria, restartable semantics, scope, and cross-references.

## Outputs

- An `## Epic Retrospective` comment on the epic.
- The epic closed with `--reason completed`.
- The roadmap entry moved to `Recently Shipped` (newest first), with prune side-effects if the cap is exceeded.
- A one-paragraph summary for the user's records.

## Success criteria

- Every native sub-issue is closed (completed or descoped with a carve-out label).
- Descoped sub-issues are explicitly called out in the retro's "Descoped or deferred" section.
- The retro lives under `## Epic Retrospective` (not `## Retrospective`) so it's discoverable distinct from per-issue retros.
- The epic issue is closed with `--reason completed`.
- The roadmap shows the epic at the top of `Recently Shipped`; it appears in no other horizon.
- Re-running the skill on a fully-closed epic is a no-op (idempotent).

## Restartable semantics

The skill is restartable, not transactional:

- **Reconcile from any partial state**: retro posted but not closed → close. Closed but retro missing → post. Closed and retro present but roadmap not moved → move. Any combination resolves cleanly on re-run.
- **Sub-issue gate runs every time** so a re-run after closing a previously-open sub-issue surfaces the now-clean state.
- The skill never bypasses the sub-issue gate, even on re-run.

## Out of scope

- **Filing the epic** — that's `epic`.
- **Closing individual sub-issues** — that's `backlog-retrospective` per sub-issue. This skill verifies they are *already* closed; it does not close them.
- **Filing follow-on epics** — that's `epic` invoked separately. This skill only *records* the follow-ons in the retro.
- **Editing roadmap horizons other than Recently Shipped** — delegated to `roadmap`.
- **Generating ADR documents** — deferred to `adr`. This skill summarizes decisions in prose for now.
- **Cross-repo epic close** — single-repo only.
- **Carve-out close path** (epic itself closed `wontfix`/`not-planned`) — those follow the regular close-rationale-comment path of `backlog-retrospective`'s carve-out, not this skill.

## Cross-references

- `epic` — opening counterpart of this skill.
- `roadmap` — invoked to move the entry to Recently Shipped.
- `backlog-retrospective` — per-sub-issue retros that must complete before this skill is invoked.
- `pull-request` — sub-issue retros are typically posted via the PR flow before this skill runs.
- `objectives` — invoked to persist KR-impact updates from the retro into `docs/OBJECTIVES.md`.
- `adr` — formal ADRs are linked from the `Architectural decisions` section.
- Label vocabulary: [`../_partials/label-vocabulary.md`](${CLAUDE_SKILL_DIR}/../_partials/label-vocabulary.md); consuming-repo labels, if any, at `${CLAUDE_PROJECT_DIR}/.github/LABELS.md` — carve-out label vocabulary (`duplicate`/`wontfix`/`not-planned`/`invalid`).
