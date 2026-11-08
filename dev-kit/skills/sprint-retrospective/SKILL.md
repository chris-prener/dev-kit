---
name: sprint-retrospective
description: >
  Closes a sprint issue. Refuses while any member in the task list is
  open; on the shipped path ticks the checkboxes, sets the status line
  to `shipped (closed DATE — see [Sprint Retrospective](url))`, posts a
  `## Sprint Retrospective`, and closes. On the descoped path applies
  the carve-out label, sets `descoped`, and posts no retro. Never closes
  the parent area.
when_to_use: >
  Use whenever a sprint is done or being abandoned — "close Sprint <N>",
  "sprint retro for #<N>", "wrap up the sprint", "descope Sprint <N>".
  Not for epics (`epic-retrospective`), ordinary issues
  (`backlog-retrospective`), or filing and editing a sprint (`sprint`).
model: sonnet
allowed-tools: Bash(gh *)
# persona: product-owner   — grouping metadata only; not read by Claude Code.
---

# Sprint Retrospective

You are about to close a sprint — the terminal counterpart of the `sprint` filer, analogous to `epic-retrospective` but scoped to the sprint only. Where the epic retro closes an *area*, this closes a *time-box*: a sprint finishing is **not** an epic finishing, so this skill never touches the parent Area (requirements R4 in `docs/requirements/epic-sprint-model.md`).

Status values and their wording come from [`_partials/sprint-status.md`](${CLAUDE_SKILL_DIR}/../_partials/sprint-status.md); do not restate or extend them here. The body layout read here is the one the filer defines in [`sprint`](${CLAUDE_SKILL_DIR}/../sprint/SKILL.md).

## Inputs

- **Required**: sprint issue number `N`.
- **Required**: path — `shipped` (default) or `descoped`.
- **Shipped path**: a retrospective draft, or willingness to compose it interactively.
- **Descoped path**: which carve-out label applies (default `not-planned`) and a 1–3 sentence rationale.

## Steps

### Phase 0: Pre-flight gates (fail closed)

1. `gh issue view <N> --json number,title,state,labels,body,comments,url`.
   - Must carry the `sprint` label and a `[Sprint <n>] <theme>` title. Halt otherwise. If it also carries `epic`, halt and name `epic-retrospective`.
2. **Reconcile prior state**:
   - Already `CLOSED` with a `## Sprint Retrospective` comment and a `shipped (…)` status line → nothing to do; report and stop (no double-post).
   - `CLOSED` but the status line is stale (still `planned` / `committed`) → skip the close, finish the remaining steps below to repair it.
   - A `## Sprint Retrospective` comment exists but the sprint is still open → reuse that comment's URL; skip posting.
3. **Parse membership** from the `## Membership` task list: every `- [ ] #<n>` / `- [x] #<n>`. Zero members → halt and ask; an empty sprint is closed by the descoped path, not shipped.
4. **Member gate (shipped path)** — for each member run `gh issue view <n> --json state,labels`.
   - **Completed** = `CLOSED` with no carve-out label; **descoped** = `CLOSED` carrying a carve-out label (set in [`_partials/retro-close-conventions.md`](${CLAUDE_SKILL_DIR}/../_partials/retro-close-conventions.md)); **open** = `OPEN`.
   - **Any open member → refuse to close**, and print the open members (number and title). The user closes or descopes each first (typically via `backlog-retrospective`); do not bypass.
5. Nothing at all to ship (every member descoped) → direct the user to the descoped path rather than a retro that has an empty "What shipped".

### Phase 1 (shipped): Compose the retrospective

Open the comment with exactly `## Sprint Retrospective` (the heading is registered in `_partials/retro-close-conventions.md`).

```markdown
## Sprint Retrospective

**Sprint:** [Sprint <n>] <theme> (#<N>)
**Area:** <Area link — unchanged by this close>
**Closed:** <YYYY-MM-DD>

### What shipped

- One bullet per member that shipped, with the issue number and the PR.

### Descoped or deferred

- One bullet per member closed with a carve-out label, with the reason. If empty: `_None._`

### Decisions

- Decisions made during the sprint (link ADRs). If empty: `_None._`

### Lessons

- 2–4 bullets: sequencing, scoping, tooling.
```

An empty `What shipped` halts the retro.

### Phase 2 (shipped): Post, update the sprint, close

The status line must link the retro comment, so the order is fixed:

1. **Post the retro** (skip if Phase 0 found one): `gh issue comment <N> --body-file <tempfile>`; capture the comment URL.
2. **Edit the body once**: tick every member checkbox whose issue is closed (`- [ ]` → `- [x]`), and set the status line to exactly
   `**Status:** shipped (closed <YYYY-MM-DD> — see [Sprint Retrospective](<comment-url>))`.
   Change nothing else in the body.
3. **Close**: `gh issue close <N> --reason completed` (no-op if already closed).
4. **Do not touch the Area.** No comment, edit, label change, or close on the parent epic.

If step 2 fails after step 1 succeeded, re-running reuses the existing retro comment (Phase 0) and finishes the edit and the close.

### Descoped path

1. Add the carve-out label **before** closing: `gh issue edit <N> --add-label not-planned` (or the label the user chose from the carve-out set).
2. Leave a 1–3 sentence rationale comment. **Post no `## Sprint Retrospective`.**
3. Set the status line to `**Status:** descoped`; leave member checkboxes as they are.
4. `gh issue close <N> --reason "not planned"`.
5. Do not touch the Area.

### Phase 3: Report

Print the sprint URL, the retro comment URL (shipped path), the close timestamp, and the member breakdown. Clean up tempfiles.

## Reference

- Outputs, success criteria, restartable semantics, scope boundary, and cross-references: [`reference.md`](${CLAUDE_SKILL_DIR}/reference.md)
