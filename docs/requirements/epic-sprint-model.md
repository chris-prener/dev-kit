---
status: draft
owner: Chris Prener
date: 2026-07-30
last-updated: 2026-07-30
related-epic: '#13'
related-adr: ADR-0001
supersedes: none
superseded-by: none
---

# Epic vs. Sprint: separating durable ownership areas from time-boxed execution

## Background

dev-kit's current "epic" concept conflates two things that true agile practice keeps separate: an **area of ownership** (a durable theme someone owns, that persists across many increments of work) and a **time-boxed execution unit** (a sprint — a bounded chunk of delivery that starts, ends, and gets retrospected on a cadence).

As implemented today (audited 2026-07-30 against the live skill suite), an epic is a parent GitHub issue filed when work spans multiple PRs, involves an architectural decision, has a non-trivial sub-issue tree, or has a distinct trackable outcome — and it **closes permanently** once its sub-issues are done, moving to a "Recently Shipped" list on the roadmap (S1, S3, S5). There is no `owner` field anywhere in the epic body template, the label vocabulary, or any consuming skill. The roadmap's Now/Next/Later horizon track — the closest existing analog to a sprint board — is attached per-epic, not to any independent time-boxed object (S5). Cross-epic blocking relationships are modeled as a dependency graph between these closeable units (S4), which is initiative-shaped, not area-shaped. Objectives score Key Result impact at epic-close time (S6). Every new issue is required to link to exactly one parent epic or explicitly opt standalone — a single linkage dimension (S2). The word "sprint" has zero conceptual footprint anywhere in the skill suite; its only occurrence is a casual trigger phrase in `showcase`'s activation list, with no modeled object behind it (S8). The label vocabulary's `epic` entry describes it as a "parent issue for a thematic body of work," with no `sprint` label in the baseline (S7).

This document scopes **what** needs to be true of the resulting model — not how to implement it. The implementation decision (new skill vs. field addition vs. wholesale restructure) belongs in a follow-up ADR once this doc is approved.

## Sources

- **S1** — `dev-kit/skills/epic/SKILL.md` — current epic definition, filing bar ("≥2 of: multi-PR, architectural decision, ≥4 sub-issues, distinct KR"), body template (no owner field).
- **S2** — `dev-kit/skills/_partials/epic-linkage.md` — mandatory single-parent-epic-or-standalone linkage, consumed by `backlog`, `triage`, `quick-capture`, `backlog-grooming`.
- **S3** — `dev-kit/skills/epic-retrospective/SKILL.md` — terminal closure model: epic closes once all sub-issues resolve, retro is a one-time strategic wrap-up, entry moves to Recently Shipped.
- **S4** — `dev-kit/skills/epic-dependency/SKILL.md` — cross-epic "blocked by" dependency graph rendered to `docs/ROADMAP.md`.
- **S5** — `dev-kit/skills/roadmap/SKILL.md` — Now/Next/Later/Recently Shipped horizon track, one entry per epic, ending in permanent closure.
- **S6** — `dev-kit/skills/objectives/SKILL.md` and `dev-kit/skills/epic-retrospective/SKILL.md` §"KR impact" — Key Result progress is scored and persisted at epic-close time.
- **S7** — `dev-kit/assets/github/LABELS.md` — `epic` label purpose text ("Parent issue for a thematic body of work; sub-issues linked"); no `sprint` label in the 22-label baseline.
- **S8** — repo-wide grep for "sprint" across `dev-kit/skills/` and `dev-kit/assets/` (2026-07-30): single hit, a trigger phrase in `dev-kit/skills/showcase/SKILL.md`, no modeled concept.

## Requirements

### R1 — Epic is redefined as a durable, owned area of work

**Rationale:** The current epic template has no owner field and is filed/closed like a project phase, not an area someone is accountable for. True-agile epics are stable groupings owned by a person or role.

**Source(s):** S1, S7

**Acceptance criteria:**
- [ ] The epic body template includes a required `Owner` field.
- [ ] Epic filing criteria no longer key on delivery-shaped signals ("spans multiple PRs," "≥4 sub-issues") — those are sprint-shaped. Criteria reframe around durable ownership boundaries (a product area, subsystem, or workstream that will outlive any single increment of work).
- [ ] A migration path exists for epics filed under the old model (backfill an owner; no data loss).

### R2 — Sprint is introduced as the time-boxed execution unit

**Rationale:** No sprint concept exists anywhere in dev-kit today. Roadmap's Now/Next/Later horizon is the closest existing analog, but it's attached to the wrong object (the epic, not an independent timebox).

**Source(s):** S5, S8

**Acceptance criteria:**
- [ ] A `sprint` concept exists with its own lifecycle (filing, in-flight tracking, closing) — exact shape (dedicated skill, GitHub milestone reuse, or a lighter construct) is an implementation decision for the follow-up ADR, but the concept must exist as something distinct from an epic.
- [ ] A sprint has a defined start/end boundary (time-boxed), unlike an epic (open-ended, area-boxed).
- [ ] A sprint closes/retires on its time or scope boundary, independent of whether the areas it touched are "done."

### R3 — Every issue can express two independent linkage dimensions: area (epic) and timebox (sprint)

**Rationale:** `_partials/epic-linkage.md` today enforces exactly one linkage dimension. Under the new model, area and timebox are orthogonal — an issue belongs to a durable area and, optionally, to whichever sprint is currently pulling it into active work.

**Source(s):** S2

**Acceptance criteria:**
- [ ] The DoR gate validates epic-linkage and sprint-linkage as two independent checks; each is either linked or explicitly standalone, with no silent default (mirroring today's epic-linkage rigor).
- [ ] `backlog`, `triage`, `quick-capture`, and `backlog-grooming` — today's four consumers of the epic-linkage partial — all reflect the two-dimension model consistently rather than three of four getting updated and one drifting.
- [ ] An issue can change its sprint linkage over time (move between sprints) without needing to change its epic/area linkage, and vice versa.

### R4 — Epics do not terminally close when a unit of work under them is done

**Rationale:** `epic-retrospective` currently closes the epic permanently once all sub-issues resolve. An area of ownership should persist across many sprints; only a sprint (or a deliberate decision to retire the area) should close in that terminal sense.

**Source(s):** S3, S6

**Acceptance criteria:**
- [ ] A "sprint retrospective" (or equivalently-scoped ritual) exists for the time-boxed unit, covering what shipped / descoped / decisions / KR impact / lessons — the content `epic-retrospective` produces today — without requiring the parent epic to close.
- [ ] The epic-level ritual (whatever `epic-retrospective` becomes) is repositioned as either a periodic health-check on a still-open area (comparable to `objectives`' cadence sweep) or an explicit, rare area-retirement action — not something invoked on every completed increment of work.

### R5 — Cross-blocking relationships move to the unit that actually blocks

**Rationale:** `epic-dependency` models "Epic A blocked by Epic B." Under the new model, blocking is a property of discrete, finishable initiatives (sprints), not of durable ownership areas, which don't meaningfully block one another.

**Source(s):** S4

**Acceptance criteria:**
- [ ] Blocking-relationship tracking (the `## Dependencies` block and its rendered graph) is re-scoped to the time-boxed/initiative unit, not the area.
- [ ] Existing epic-to-epic dependency data has a defined migration path (re-attach to the corresponding sprint, or explicitly drop if no longer meaningful) rather than silently breaking.

### R6 — Roadmap's horizon model is reconciled with the area/timebox split

**Rationale:** `roadmap`'s Now/Next/Later/Recently-Shipped track is currently keyed per-epic and is the closest existing analog to a sprint board; it needs an explicit, single home in the new model rather than duplicating structure across an area object and a timebox object.

**Source(s):** S5

**Acceptance criteria:**
- [ ] A decision is recorded (in the follow-up ADR, not this doc) on whether Now/Next/Later tracks sprints instead of areas, tracks both on separate axes, or is restructured entirely.
- [ ] Whichever choice is made, `docs/ROADMAP.md`'s structure and every skill that writes to it (`roadmap`, `epic-dependency`, `epic-retrospective` or its replacement) stay mutually consistent — no skill assumes a structure another skill no longer produces.

### R7 — Objective-to-KR scoring reattaches to the unit that actually delivers increments

**Rationale:** `objectives` currently scores KR impact when an epic closes. If areas no longer close on a delivery cadence, KR scoring needs a delivery-shaped unit to attach to instead.

**Source(s):** S6

**Acceptance criteria:**
- [ ] KR-impact recording happens at sprint (or equivalent delivery-unit) close, not at area close.
- [ ] An area (epic) can still declare a "supporting objective" relationship at the strategic level, independent of the per-sprint KR scoring mechanics.

### R8 — Label vocabulary reflects both concepts

**Rationale:** `LABELS.md`'s `epic` label purpose text describes a closeable "parent issue for a thematic body of work" — inconsistent with the new area-of-ownership meaning — and no label exists for the time-boxed unit.

**Source(s):** S7

**Acceptance criteria:**
- [ ] `LABELS.md`'s Type table entry for `epic` is updated to describe an area of ownership, and a new label for the time-boxed unit is added to the baseline.
- [ ] `_partials/label-vocabulary.md` (the embedded fallback baseline read when a repo has no local `LABELS.md`) is kept in sync with the vendored `assets/github/LABELS.md` copy.

## Out of scope

- The exact implementation mechanism for "sprint" (new skill vs. GitHub milestone reuse vs. project-board integration) — that's an ADR decision, not a requirement.
- Migrating any specific repo's existing epics/roadmap data — this doc defines the target model; migration is implementation work scoped separately.
- Cross-repo rollout sequencing — dev-kit is a single-plugin distribution; how/when consuming repos adopt the new model is out of scope here.
