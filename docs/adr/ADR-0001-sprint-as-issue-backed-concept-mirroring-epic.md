---
status: accepted
date: 2026-07-30
source: "[Epic A (#13)](https://github.com/chris-prener/dev-kit/issues/13), docs/requirements/epic-sprint-model.md (R1-R8)"
---

# ADR-0001: Sprint is a new issue-backed concept mirroring epic; roadmap horizons reattach to sprints

## Context

Epic A redefines dev-kit's "epic" as a durable, owned area of work and introduces "sprint" as the time-boxed execution unit beneath it. The epic was filed with `no-adr-needed`, deferring exactly two decisions until implementation direction was chosen: (1) the concrete mechanism for "sprint," and (2) how `docs/ROADMAP.md`'s Now/Next/Later/Recently-Shipped horizon model reconciles with the area/timebox split. Both are decided here.

Every existing dev-kit subsystem that models a trackable unit of work — `epic`, `epic-retrospective`, `roadmap`, `epic-dependency`, `objectives` — shares one invariant: the GitHub issue (body + labels) is the source of truth, and a hand-curated, git-tracked markdown file (`docs/ROADMAP.md`, `docs/OBJECTIVES.md`) is a derived, idempotently-regenerated rendering, diffable and reviewable in a PR. GitHub Milestones already have an established meaning in dev-kit (release versioning, `vX.Y.Z`, attached to epics) — reusing them for sprints would overload one object with two meanings. GitHub Projects (v2) offers a native Iteration field purpose-built for sprint semantics, but its state (field values, board position) lives outside git — not diffable, not recoverable from `git log` — which breaks the restartable, commit-on-change pattern every other subsystem relies on.

## Decision

We will implement **sprint as a new first-class GitHub-issue-backed concept that mirrors the existing `epic` pattern exactly**: its own label (`sprint`), its own canonical body template, and its own lifecycle skills (a `sprint` filer analogous to `epic`, and a `sprint-retrospective` closer analogous to `epic-retrospective`), with real start/end date fields carrying the time-box. `docs/ROADMAP.md`'s Now/Next/Later/Recently-Shipped horizon reattaches to sprints — the unit with an actual committed → active → done lifecycle — not to epics. Epics get a separate flat "Areas" listing (owner + open sub-issue count), since a durable area doesn't queue or complete the way a time-boxed unit does.

### Alternatives considered

- **Reuse GitHub Milestones as the sprint object.** Rejected — milestones are already claimed by dev-kit for release versioning (`vX.Y.Z`, attached to epics); overloading the same object for two meanings creates ambiguity, and milestones have no structured body suited to `## Dependencies`-style metadata the way an issue does.
- **Model sprints as a GitHub Projects (v2) board**, using its native Iteration field. Rejected — Project item state (field values, iteration assignment, board position) lives outside git: not diffable, not restorable via `git log`, breaking the idempotent-regeneration/commit-on-change pattern `epic`, `roadmap`, `objectives`, and `epic-dependency` all depend on today. It would also require per-repo Project/field IDs as new bootstrap config, and would split a sprint's narrative (issue body) from its schedule (Project item fields) into two sources of truth — the exact drift problem the epic/sprint dual-linkage model (R3) is meant to avoid. Its cross-repo reach is also moot here: cross-repo rollout is explicitly out of scope for Epic A.
- **Track both epics and sprints as parallel horizons in `docs/ROADMAP.md`.** Rejected — doubles the structure every roadmap-writing skill (`roadmap`, `epic-dependency`, `sprint-retrospective`) must keep mutually consistent, for no identified benefit over a single sprint-keyed horizon plus a flat area listing.
- **Restructure the horizon concept entirely** (drop Now/Next/Later for something new). Rejected for now — no concrete alternative shape has been proposed; higher churn with no identified benefit over adapting the existing horizon to key on sprints.

## Consequences

- **Easier:** Sprint filing, tracking, and closing follow the exact same restartable, git-native, diffable pattern as epics — no new skill architecture to design, no new external state to reconcile. The roadmap keeps a single horizon structure (now keyed on the unit that actually moves through it) instead of two parallel ones.
- **Harder:** Every issue must now express two independent linkage dimensions (area + timebox, per R3) instead of one — `backlog`, `triage`, `quick-capture`, and `backlog-grooming` all need updating in lockstep, or the two-dimension model drifts across skills. `epic-retrospective`'s terminal-close semantics must be repositioned as a rare area-retirement action rather than an every-completion ritual (R4), since epics no longer close when a sprint under them finishes.
- **Constraints:** Sprint reuses every issue-native mechanism epic already relies on (native sub-issues, `## Dependencies` block format, label vocabulary) rather than inventing a parallel mechanism — this locks future work on `epic-dependency` (R5) and objective KR scoring (R7) into re-scoping to sprint rather than introducing a third pattern.
- **Revisit when:** dev-kit needs true cross-repo sprint tracking, or GitHub Projects gains git-backed (diffable, restorable) item state — either would remove the primary objection to the Projects alternative.

## References

- Related epic: #13
- Related requirements doc: `docs/requirements/epic-sprint-model.md`
- Related ADRs: none
