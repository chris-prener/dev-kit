---
name: sprint
description: >
  Files a sprint issue from the canonical body template — title
  `[Sprint <N>] <theme>`, the `sprint` label, an open `epic` as its Area,
  and membership as a body task list. Restartable; never writes the
  derived `active` status.
when_to_use: >
  Use to stand up a time-boxed sprint under an area epic, to add or
  reorder members on an existing sprint ("add #N to Sprint 9"), or to
  resume filing one that was interrupted. Not for a durable area of work
  (that is an `epic`), for closing a sprint (`sprint-retrospective`), or
  for a single piece of work (`backlog`).
model: sonnet
allowed-tools: Bash(gh *)
# persona: product-owner   — grouping metadata only; not read by Claude Code.
---

# Sprint Filer

You are about to file (or update) a sprint: a time-boxed unit of execution under an area epic ([ADR-0001](${CLAUDE_PROJECT_DIR}/docs/adr/ADR-0001-sprint-as-issue-backed-concept-mirroring-epic.md)). The area epic owns the *what stays true*; the sprint owns *what we do this stretch*. Membership is a **body task list, not native sub-issues** — an issue may have only one native parent, and the area epic claims that slot ([ADR-0003](${CLAUDE_PROJECT_DIR}/docs/adr/ADR-0003-area-uses-native-sub-issues-sprint-uses-body-task-list.md)).

This skill produces one GitHub issue with the `sprint` label, the title `[Sprint <N>] <theme>`, and the canonical body below. It does **not** link members as sub-issues, close the sprint (`sprint-retrospective`), or register the sprint on `docs/ROADMAP.md` (that contract belongs to the roadmap issue; until it lands this skill does not write to the roadmap).

## Inputs

- **Required**: `Area` — an issue number. Must be an **open issue carrying the `epic` label**.
- **Required**: theme — one line, used in the title.
- **Required**: goal — one short paragraph.
- **Required**: `Status` — `planned` or `committed` only. Values and meanings are defined in [`_partials/sprint-status.md`](${CLAUDE_SKILL_DIR}/../_partials/sprint-status.md); do not restate or extend them here.
- **Required for `committed`**: real start and end dates. `planned` accepts `_unscheduled_`.
- **Optional**: members (issue numbers), sequencing notes, definition of done.
- **Optional, for resume/update**: an existing sprint issue number `N`.

## Steps

### Phase 0: Pre-flight, duplicate check, resume

1. `gh repo view --json nameWithOwner -q .nameWithOwner` to resolve the repo.
2. **Resume / update mode** — if given an existing sprint number `N`: `gh issue view <N> --json number,title,state,labels,body,url`. Verify it carries the `sprint` label and a `[Sprint <n>] <theme>` title; halt otherwise. Refuse a closed sprint (closing is `sprint-retrospective`'s). Skip to Phase 3 and **edit in place** with `gh issue edit <N> --body-file`; never create a second issue.
3. **Duplicate detection** — `gh issue list --label sprint --state all --limit 200 --json number,title,state`. If the proposed sprint number or a near-identical theme already exists, surface the match and require explicit confirmation. Do not auto-create and do not auto-no-op.
4. **Sprint number** — suggest the highest existing `[Sprint <n>]` plus one; the user may override.

### Phase 1: Validate

1. **Area** — verify the chosen issue exists, is `OPEN`, and carries the `epic` label, exactly as Step 2 (epic-linked path) of [`_partials/epic-linkage.md`](${CLAUDE_SKILL_DIR}/../_partials/epic-linkage.md) validates a parent epic. **Refuse** if it is not an open `epic`; offer a different Area or the `epic` skill. There is no `standalone` path — a sprint always has an Area. Do not run that partial's Step 3 (native sub-issue linking).
2. **Status and Timebox** — refuse any status other than `planned` or `committed`. Refuse `active` outright: it is derived at read time and never written. Refuse `committed` unless both a start and an end date are given (`YYYY-MM-DD – YYYY-MM-DD`); refuse an end date before the start.
3. **Members** — for each, `gh issue view <n> --json state,title`. Warn on closed members; tick (`[x]`) only members that are already closed. A member may be in the task list of only one open sprint; warn if it appears in another.

### Phase 2: Compose the body

Use exactly this template. Header lines and section set must match the pilot sprints (see #86 as the reference example).

```markdown
# [Sprint <N>] <theme>
**Area:** [<area title>](<area url>)
**Timebox:** <YYYY-MM-DD – YYYY-MM-DD | _unscheduled_>
**Status:** <planned | committed>

> Membership below is a **task list, not native sub-issues** — an issue may have only one parent, and the area epic claims that dimension.

## Goal

One short paragraph. What is true when this sprint is done?

## Membership

- [ ] #<n> — <one-line description>

## Sequencing

Which member goes first and why; which are independent; what is deliberately **out of this sprint**.

## Definition of done

- Observable condition 1.
- Observable condition 2.
```

A missing Goal or an empty Membership halts filing.

### Phase 3: File or update

1. New sprint: `gh issue create --title "[Sprint <N>] <theme>" --body-file <tempfile> --label sprint`. Capture the URL and number. Do **not** call the sub-issues API.
2. Update: `gh issue edit <N> --body-file <tempfile>`; change only what the user asked (members, sequencing, `planned` → `committed` with dates).
3. A `planned` → `committed` change is the only status edit this skill makes after filing. Later statuses belong to `sprint-retrospective`.

### Phase 4: Report

Print the sprint URL, number, Area, Timebox, Status, and member count. Clean up tempfiles.

## Reference

- Outputs, success criteria, restartable semantics, scope boundary, and cross-references: [`reference.md`](${CLAUDE_SKILL_DIR}/reference.md)
