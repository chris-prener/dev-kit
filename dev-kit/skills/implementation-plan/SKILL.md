---
name: implementation-plan
description: >
  Owns the durable issue-comment-as-plan contract: creates, reads,
  updates, and transitions the single `## Implementation plan` comment
  on a GitHub issue, plus the `in-progress` / `blocked` label side
  effect. Self-contained — no session-mirror file, no multi-session
  conflict protocol.
when_to_use: >
  Use to start, read, edit, or transition the structured plan for an
  issue ("start a plan", "update the plan", "mark #N in-progress", "show
  me the plan for #N"). Not for scratch notes or chain-of-thought (the
  plan is a structured artifact), issue-body edits (the issue body stays
  the story/AC contract), or PR-body composition (`pr-orchestrator`).
model: opus
allowed-tools: Bash(gh *)
# persona: developer   — grouping metadata only; not read by Claude Code.
---

# Implementation Plan

This skill is the only sanctioned writer of the implementation-plan contract: a single `## Implementation plan` comment on a GitHub issue, its locator marker, its section schema, and its status state machine. It's deliberately simple — one agent, one session, one issue at a time — so there's no compare-and-swap protocol and no local mirror file to keep in sync. Read-then-write is enough.

## Activation

Use this skill to:

- Start a structured plan on an issue (`Create`).
- Read the current plan (`Read`).
- Edit one or more plan sections (`Update`).
- Move the plan through its status enum (`Transition`).
- Re-derive the `in-progress` / `blocked` labels from the live `Status:` (`Reconcile labels`).

**When NOT to use:**

- Scratch notes or chain-of-thought; the plan is a structured artifact.
- Issue-body edits; the issue body remains the story / AC contract.
- PR-body composition; use `pr-orchestrator`.
- Plans for issues not yet in active implementation.

## Inputs

- **All operations:** issue number `<N>`. Auto-detect from `git branch --show-current` when the branch starts with `<N>-`; prompt otherwise.
- **`Create`:** initial `Status:` (default `drafting`); non-empty `### Approach`; optional starter content for the other five sections. Defaults: `_TBD in drafting._` for `Files to touch` / `Verification`, `_None yet._` for `Risks / open questions` / `Decisions made`, `_Not yet started._` for `Where I left off`.
- **`Update`:** target section name(s) plus replacement content. `Status:` changes are rejected here; use `Transition`.
- **`Transition`:** target `Status:` enum value; the skill validates the move against the state machine in [`reference.md`](${CLAUDE_SKILL_DIR}/reference.md) before writing.
- **`Reconcile labels`:** only `<N>`.

## Steps

### Phase 0 — Locate (always; precedes every operation)

1. Run `gh issue view <N> --repo "$REPO" --json comments --jq '.comments[] | {id, body, updatedAt, author: .author.login}'`.
2. Walk comments oldest-first. A plan match requires: first non-blank line exactly `<!-- implementation-plan-v1 -->`, and the next non-blank line exactly `## Implementation plan`.
3. Resolve match count:
   - **0** → `plan_exists = false`; only `Create` is legal.
   - **1** → remember `comment_id`.
   - **≥ 2** → hard-fail, print all matching ids/timestamps, and ask the operator to manually delete the duplicate before retrying. Never pick one silently.

### Phase A — `Create`

Pre-condition: Phase 0 found no plan.

1. Prompt for `### Approach` (2–5 sentences); reject empty / placeholder text.
2. Optionally prompt for the other five sections, using the defaults listed in **Inputs**.
3. Compose the body from [`TEMPLATE.md`](${CLAUDE_SKILL_DIR}/TEMPLATE.md) with `Status: drafting` and the current UTC `Last updated`.
4. Post it with `gh issue comment <N> --repo "$REPO" --body-file <tmp>`.
5. Print `Created plan for #<N>. Status: drafting. Comment <comment-id>.`

`Create` never toggles `in-progress`; enter that state via `Transition`.

### Phase B — `Read`

Pre-condition: Phase 0 found exactly one plan.

1. Fetch the body with `gh api repos/$REPO/issues/comments/<comment-id>`.
2. Parse it into the structured fields in [`reference.md`](${CLAUDE_SKILL_DIR}/reference.md)'s schema; reject on missing / out-of-order metadata or section headings.
3. Print the plan (interactive) or return the parsed structure (machine caller).

### Phase C — `Update`

Pre-condition: Phase 0 found exactly one plan; caller supplies `(section, new-content)` pairs and none target `Status:`.

1. Re-read the live comment body immediately before writing, so the edit lands on current content rather than a stale in-memory copy.
2. Build the new body by replacing only the targeted `### <section>` blocks and refreshing `_Last updated:_`. Leave `Status:` unchanged.
3. PATCH the comment.
4. Print `Updated plan for #<N>. Sections changed: <section, …>.`

### Phase D — `Transition`

Pre-condition: Phase 0 found exactly one plan and a target `Status:` was supplied.

1. Read the current remote `Status:`. Reject if current is `shipped` unless **Reopen handling** applies.
2. Validate the transition against the state machine in [`reference.md`](${CLAUDE_SKILL_DIR}/reference.md).
3. **Comment write first:** PATCH the comment with the new `Status:`, refreshed `_Last updated:_`, unchanged sections.
4. **Label toggle second:** compute the add/remove set from the mapping in [`reference.md`](${CLAUDE_SKILL_DIR}/reference.md) and run `gh issue edit <N> --add-label … --remove-label …`.
   - On success: print `Transitioned plan for #<N>: <current> → <target>. Labels: +<x>, -<y>.`
   - On failure: print `WARNING: comment updated to Status: <target>, but label toggle failed: <error>. Run 'reconcile labels for #<N>' once the API is healthy.` and stop. Never roll back the comment — the comment is the source of truth.

#### Reopen handling (current `Status: shipped`)

Prompt the operator to confirm reopening explicitly, with a one-line rationale. On confirm: transition `shipped → drafting`, append `YYYY-MM-DD: reopened from shipped; rationale: <…>` to `### Decisions made`, and proceed. No confirmation, no reopen.

### Phase E — `Reconcile labels`

Pre-condition: Phase 0 found exactly one plan.

1. Read remote `Status:`.
2. Read issue labels with `gh issue view <N> --json labels --jq '.labels[].name'`.
3. Compute the expected labels from the mapping in [`reference.md`](${CLAUDE_SKILL_DIR}/reference.md).
4. If the delta is empty, no-op with `Labels for #<N> already match Status: <status>.`
5. Otherwise apply the delta via `gh issue edit`.
6. Print `Reconciled labels for #<N>. Now matches Status: <status>. +<x>, -<y>.`

`Reconcile labels` never touches the comment.

## Reference

Schema, status state machine, label mapping, outputs, success criteria, and cross-references: [`reference.md`](${CLAUDE_SKILL_DIR}/reference.md)
