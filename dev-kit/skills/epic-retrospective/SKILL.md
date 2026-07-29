---
name: epic-retrospective
description: >
  Closes an epic issue with a strategic retrospective comment, moves the
  entry to Recently Shipped on the roadmap, reconciles partial-completion
  state, and prompts for KR-impact on linked objectives.
when_to_use: >
  Use whenever the user wants to wrap up an epic — "close epic <N>",
  "epic retrospective for <N>", "wrap up the X epic", "ship epic <N>".
  Not for per-issue closes (`backlog-retrospective`), session-end / pause
  workflows, or cancelled-without-work epics that should carry a
  `wontfix` / `not-planned` close-reason label and a short rationale
  comment instead of a full retro (carve-out mirrored from
  `backlog-retrospective`).
model: sonnet
allowed-tools: Bash(gh *)
# persona: product-owner   — grouping metadata only; not read by Claude Code.
#   Re-tagged from the source suite's workflow-steward persona (dropped;
#   retrospectives are kept as a product-owner responsibility).
---

# Epic Retrospective

You are about to close (or finish closing) an epic — the strategic counterpart of `backlog-retrospective`. Where the per-issue retro captures *what shipped and how* tactically, the epic retro captures *what theme of work was completed, what was descoped, what we learned, and what comes next*.

This skill writes a retrospective comment on the epic, closes the issue, and invokes `roadmap` to move the entry to `Recently Shipped`. It is restartable and reconciles partial state.

## Inputs

- **Required**: epic issue number `N`.
- **Required**: a retrospective draft (or willingness to compose one interactively) covering the five canonical sections below.
- **Optional**: list of follow-on epics filed in response to lessons learned.

## Steps

### Phase 0: Pre-flight gates (fail closed)

1. **Fetch the epic**: `gh issue view <N> --json number,title,state,labels,body,closedAt,url`.
   - Verify it has the `epic` label. Halt if not.
   - Title must parse as `[Epic <id>] <theme>`. Halt otherwise.
2. **Reconcile prior state** — note for downstream phases:
   - Already closed? → skip Phase 3's close step but still post the retro if missing, and still ensure roadmap is in `Recently Shipped`.
   - Already has a `## Epic Retrospective` heading on a comment? → Phase 2 becomes "verify and surface", not "post".
   - Already in `Recently Shipped`? → Phase 4 is a no-op.
3. **Sub-issue gate** — paginate `gh api repos/<owner>/<repo>/issues/<N>/sub_issues --paginate`:
   - **If zero native sub-issues AND the body contains a markdown checklist of issue references** (`- [ ] #NNN` or `- [x] #NNN` or links to `/issues/NNN`): **fail closed**. Surface a clear error: "This epic predates native sub-issue linking. Native links are required before close so descope/completion can be reconciled. Either link sub-issues via `gh api ... /sub_issues` or carry a `wontfix`/`not-planned` label and follow the carve-out path."
   - **If zero native sub-issues AND no checklist in body**: warn and confirm — this might be a genuinely scopeless / placeholder epic; continue only on explicit confirmation.
   - **Otherwise**: proceed with the native sub-issue list.
4. **Sub-issue completion check**: for each native sub-issue, fetch state and labels.
   - **Completed** = `state == "CLOSED"` AND no carve-out label (`duplicate` / `wontfix` / `not-planned` / `invalid`).
   - **Descoped** = `state == "CLOSED"` AND carries a carve-out label.
   - **Open** = `state == "OPEN"`.
   - **If any sub-issues are Open**: halt with the list. The user must close (or descope) each one — typically via `backlog-retrospective` — before closing the epic. Do not bypass this; descoping requires the carve-out label, which is the auditable signal.
5. **Surface the descoped list** so the user knows what must be called out in the retro before Phase 2 prompts them.

### Phase 1: Compose the retrospective

The retro lives as a comment on the epic, opened by exactly the heading `## Epic Retrospective` (distinct from per-issue `## Retrospective` so the two are easily discoverable on a thread).

Use exactly this template:

```markdown
## Epic Retrospective

**Epic:** [Epic <id>] <theme> (#<N>)
**Closed:** <YYYY-MM-DD>
**Milestone:** <vX.Y.Z or —>

### What shipped

- One bullet per significant outcome. Reference shipping PR or sub-issue.
- Bias toward user-visible / contract-visible changes.

### Descoped or deferred

- One bullet per sub-issue closed with a carve-out label
  (`duplicate`/`wontfix`/`not-planned`/`invalid`). Include the issue
  number, the carve-out reason, and a one-line rationale of *why*
  it didn't make this epic.
- If empty: write `_None._`

### Architectural decisions

- Cross-cutting decisions ratified during the epic. Link to ADRs under
  `docs/adr/` (filed via `adr`). For decisions that
  didn't warrant an ADR, summarize in 1–2 sentences each and explain
  why they stayed inline.

### KR impact

- For each KR on the linked supporting objective (read from the epic's
  `Supporting objective` field and `docs/OBJECTIVES.md`), record the
  delta this epic produced: e.g., "KR1.2: 4 → 7 ADRs filed; target met."
- If no objective is linked: write `_No supporting objective._`
- After posting the retro, hand off to `objectives` (update
  operation) so the same KR-progress edits are persisted in
  `docs/OBJECTIVES.md`. The retro comment is the narrative; the
  OBJECTIVES file is the canonical scoring.

### Lessons

- What we'd do differently. 2–4 bullets. Process, sequencing,
  scoping, tooling.

### Follow-on epics

- Epics filed in response to this retro (link by #N).
- If empty: write `_None._`
```

The skill prompts the user for each section interactively (or accepts a pre-supplied draft). Empty `What shipped` halts the retro — an epic with nothing shipped should be carve-out-closed, not retro-closed.

### Phase 2: Post the retro comment

1. **If a comment with `## Epic Retrospective` heading already exists on the epic**: surface it, ask whether to append an addendum or skip. Default: skip and proceed.
2. **Otherwise**: `gh issue comment <N> --body-file <tempfile>`.
3. Capture the comment URL for the final report.

### Phase 3: Close the epic issue

1. **If `state == "OPEN"`**: `gh issue close <N> --reason completed`.
2. **If already closed**: no-op. Verify `closedAt` exists; surface the timestamp.

### Phase 4: Move to Recently Shipped

1. **Invoke the `roadmap` skill** with operation `move <N> 'Recently Shipped'`.
2. The roadmap skill verifies the issue is now `CLOSED`, removes the entry from its current horizon (Now / Next / Later), inserts at the top of Recently Shipped, and prunes if necessary.
3. **If the `roadmap` skill reports the entry was already in Recently Shipped**: no-op (resumed run).
4. **If the `roadmap` skill reports the entry is missing entirely**: surface this — most likely the epic was filed manually before the roadmap skill existed. Offer to add it directly to Recently Shipped (a one-shot `add <N> 'Recently Shipped'` operation).

### Phase 5: Confirm + report

- Print: epic URL, retro comment URL, close timestamp, roadmap diff (which horizon → Recently Shipped, prune side-effects).
- Cleanup tempfiles.

## Reference

- Outputs, success criteria, restartable semantics, scope boundary, and cross-references: [`reference.md`](${CLAUDE_SKILL_DIR}/reference.md)
