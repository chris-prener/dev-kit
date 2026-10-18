---
status: accepted
date: 2026-10-18
source: "[#56](https://github.com/chris-prener/dev-kit/issues/56), [Epic A (#13)](https://github.com/chris-prener/dev-kit/issues/13), docs/requirements/epic-sprint-model.md (R3, R5)"
---

# ADR-0003: Area linkage uses native sub-issues; sprint membership is a body task list

## Context

[R3](../requirements/epic-sprint-model.md) requires every issue to express two independent linkage dimensions, area (epic) and timebox (sprint). [ADR-0001](ADR-0001-sprint-as-issue-backed-concept-mirroring-epic.md)'s Constraints bullet says sprint "reuses every issue-native mechanism epic already relies on (native sub-issues, `## Dependencies` block format, label vocabulary)." Both dimensions cannot use native sub-issues. Verified against the live repo on 2026-08-01:

```
POST repos/chris-prener/dev-kit/issues/16/sub_issues  -F sub_issue_id=<id of #26>
→ HTTP 422  "Sub issue may only have one parent"
```

**An issue may have exactly one parent.** Neither R3 nor ADR-0001 accounted for it. The constraint also bounds R5's area-level "blocked by" mechanism, which R5 left open.

The sprint pilot has since run the split this ADR ratifies: Epic B (#16) holds its issues as native sub-issues, and Sprints 1-2 (#49, #50) hold membership as a `## Membership` task list in the sprint issue body. It held up: both sprints closed with retrospectives, and no member issue needed a pointer back to its sprint. Nothing drifted or failed, so this ADR records the original recommendation rather than a correction.

Because membership is a list in the sprint body and the member issue holds no pointer, two questions were left open: what the DoR gate can check for sprint linkage, and what mechanism carries area-level blocking.

## Decision

We will:

1. **Area (epic) linkage uses GitHub native sub-issues; sprint membership is a task list in the sprint issue's body.** The one-parent constraint is a hard platform limit, so the dimension that is durable and single-valued (an issue belongs to exactly one area) takes the native parent slot, and the dimension that is transient and multi-valued over time (an issue moves between sprints) takes the mechanism that is cheap to edit.
2. **The DoR gate checks sprint linkage by lookup, not by a pointer on the member issue.** The gate lists open issues labelled `sprint` and scans their `## Membership` task lists for `#N`. An issue is *linked* if found, and *explicitly standalone* only if its body carries a `**Sprint:** none` line. Anything else is a gate failure, with no silent default. The only sprint text that ever lives on a member issue is the standalone declaration, so there is no second copy of membership to drift. Moving an issue between sprints edits task lists only.
3. **Area-level "blocked by" uses the existing `## Dependencies` block in the epic body**, in the format `epic-dependency` already parses (`- Blocked by #NN — reason`), without the graph and cycle-detection machinery. It is body text, so it is git-renderable and diffable, and it is not a parent/child relationship, so the one-parent limit does not apply.

### Alternatives considered

For sprint membership:

- **Body task list (chosen).** Edit-in-place, renders progress as checkboxes, diffable via the roadmap rendering, and needs no new object. Cost: membership is one-directional, so the member issue cannot show its sprint without a lookup.
- **Per-sprint label (`sprint/N`).** Rejected: gives the member issue a pointer, but adds one label per sprint to a vocabulary that `LABELS.md` and `_partials/label-vocabulary.md` must keep identical, and labels have no body for goal, timebox, or sequencing.
- **GitHub Milestone.** Rejected: already claimed for release versioning (`vX.Y.Z`) per ADR-0001, and an issue holds one milestone, so overloading it would collide with release attachment.
- **Native sub-issues for sprint, task list for area.** Rejected: areas are the long-lived grouping whose membership is browsed in the GitHub UI and counted by the roadmap's Areas listing, so they get the first-class mechanism.

For the DoR sprint check:

- **`**Sprint:**` line on every member issue.** Rejected: a second copy of membership that drifts the first time an issue moves sprints.
- **GitHub "tracked in" back-reference.** Rejected: not something the gate can rely on from the API for body task lists.
- **Validate only when an issue is added to a sprint.** Rejected: leaves issues that were never added unchecked, which is the silent default R3 forbids.

For area-level blocking:

- **GitHub native issue dependencies (blocked-by).** Rejected as the source of truth: state lives outside git, the same objection ADR-0001 raised against Projects. Available as an optional mirror, but the body block wins on conflict.
- **A `blocked` label.** Rejected: says *that* an area is blocked, not *by what*.

## Consequences

- **Easier:** No unbuildable design reaches the `sprint` skill; the 422 is accounted for before build. Area-level blocking needs no new format. Epic B and the pilot sprints already conform, so no migration.
- **Harder:** The DoR gate's sprint check costs a search over open sprints per issue instead of a field read. The `sprint` skill must keep `## Membership` parseable and must be the only writer that moves issues between sprints.
- **Constraints:** One parent per issue is a platform fact. Any future mechanism needing a second parent-style link must use a non-parent relationship. `epic-dependency`'s re-scope (#100) builds on decision 3 and #97's DoR work on decision 2; neither needs another ADR.
- **Revisit when:** GitHub lifts the one-parent limit, or the lookup cost in the DoR gate becomes noticeable with many concurrent open sprints.

## References

- Related epic: #13
- Related requirements doc: `docs/requirements/epic-sprint-model.md` (R3, R5)
- Related ADRs: supersedes the "Constraints" bullet of ADR-0001 only
- Field report: https://github.com/chris-prener/dev-kit/issues/13#issuecomment-5153179276
