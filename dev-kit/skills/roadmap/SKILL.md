---
name: roadmap-curator
description: >
  Owns docs/ROADMAP.md's Epics section. Adds, moves, and prunes epic
  entries across the four horizons. Validates structure on every
  invocation; reformats only on explicit trigger.
when_to_use: >
  Use to add a newly-filed epic to the roadmap (typically invoked by
  `epic`), move an epic between horizons (typically invoked by
  `epic-retrospective` on close, or by the user when work begins or
  commitments shift), prune Recently Shipped, or validate/reformat the
  section's structure.
model: sonnet
allowed-tools: Bash(gh *)
# persona: product-manager   — grouping metadata only; not read by Claude Code.
---

# Roadmap Curator

You are about to manipulate `${CLAUDE_PROJECT_DIR}/docs/ROADMAP.md`'s Epics section. This file is hand-curated *outside* the Epics section (legacy Sequencing / Where-we-are content) and structured *inside* it. **Every edit this skill makes is strictly scoped to the block between `## Epics` and the next `##` heading.** Anything outside that block is off-limits.

Source-of-truth principle: a roadmap entry's authoritative state is the underlying GitHub issue, keyed by issue number / URL. Title and milestone are *derived* from the issue on every operation, not copied once and trusted forever.

## Inputs

- **Required**: at least one of (a) explicit operation (add / move / prune / validate / reformat), or (b) an epic issue number `N` that the skill can use to infer the operation from current state.
- **Required for `add`**: epic issue number `N`. Optional: target horizon (default `Later`); skill reads milestone from the issue itself.
- **Required for `move`**: epic issue number `N`, target horizon.
- **Required for `prune`**: none — defaults to the canonical cap of 10.
- **Required for `validate` / `reformat`**: none.

## Horizon model

The Epics section has exactly four `###` subsections in this order:

1. **Now** — actively in flight.
2. **Next** — committed-to-pick-up.
3. **Later** — identified, not yet committed.
4. **Recently Shipped** — newest 10 closed epics. Newest first. Older epics drop off and remain discoverable via `is:closed label:epic` on GitHub.

Movement: `Later` (default for new epics) → `Next` (when committed) → `Now` (when work begins) → `Recently Shipped` (on epic close, by `epic-retrospective`).

## Entry format (canonical)

```
- [Epic <id>: <Title>](<issue-url>) — <one-line goal> (milestone: <vX.Y.Z>|—)
```

- **Identity key**: `<issue-url>` (and equivalently `<N>` parsed from it). Title-text edits on the underlying issue do NOT create duplicate entries — the skill matches on issue URL.
- `<id>` and `<Title>` are derived from the issue title on every read (`gh issue view <N> --json title`). The issue title is expected to follow `[Epic <id>] <theme>`; the skill parses `<id>` and `<theme>` from it.
- `<one-line goal>` lives in the entry; the skill prompts for it on `add` if not supplied.
- `<milestone>` is derived from the issue's milestone field on every operation. If the issue has no milestone, the skill writes `—`.

When a horizon subsection is empty, it MUST contain exactly one line: `_None yet._`. The skill restores this placeholder when removing the last entry from a section.

## Steps

### Phase 0: Always — load and validate

1. **Read `${CLAUDE_PROJECT_DIR}/docs/ROADMAP.md`**. Locate the Epics block: from the line matching `^## Epics$` (exactly) through the line preceding the next `^## ` heading. If the block is missing, halt with a clear error.
2. **Parse the four `### Now`, `### Next`, `### Later`, `### Recently Shipped` subsections.** Reject any other `###` subsection inside the Epics block.
3. **Validate every entry** in each subsection:
   - Matches the canonical format (regex on `^- \[Epic [^:]+: [^\]]+\]\([^)]+\) — .+ \(milestone: (v\d+\.\d+\.\d+|—)\)$`).
   - Resolves to a real GitHub issue (`gh issue view <N> --json number,title,state,labels,milestone`).
   - Issue carries the `epic` label.
   - Issue's title parses cleanly into `[Epic <id>] <theme>`.
4. **Surface findings** as a structured report:
   - `OK` — entries that validate cleanly.
   - `DRIFT` — entries that fail format / linkage / label checks.
   - `STALE` — entries whose linked issue was closed (should be in Recently Shipped) or reopened (should be back in Now/Next/Later).
5. **If the operation is `validate`**: stop here, return the report. Do not modify the file.
6. **If the operation is `reformat`** (explicit trigger): apply minimal corrections to bring DRIFT/STALE entries into compliance, write the file, return a diff summary. Never invent content — if an entry can't be repaired (e.g., issue 404s, no `epic` label), surface it for human resolution.
7. **Otherwise** (add / move / prune): proceed to the operation phase below. Validation findings are surfaced but do NOT block the requested operation unless the operation itself targets a DRIFT/STALE entry.

### Phase 1a: `add <N> [horizon]`

1. **Verify the issue**: `gh issue view <N> --json number,title,state,labels,milestone,url`. Require `state == "OPEN"` and `epic` in labels. Halt with a clear error otherwise (point the user at `epic` if the label is missing).
2. **Parse the title**: extract `<id>` and `<theme>` from `[Epic <id>] <theme>`. Halt if the title doesn't match.
3. **Derive milestone**: from the issue's `milestone.title` field (or `—` if unset).
4. **Idempotency / duplicate check**: search the entire Epics block for any line containing the issue's URL or the literal `#<N>` reference.
   - If found in the *target* horizon: no-op with a clear "already present at <horizon>" message.
   - If found in a *different* horizon: prompt the user — this is most likely a `move` operation, not an `add`. Offer to convert.
   - If not found: continue.
5. **Prompt for `<one-line goal>`** if not supplied. Reject empty / placeholder strings.
6. **Render the entry** in the canonical format.
7. **Insert** under the target horizon (default `Later`). Order within `Now`/`Next`/`Later` is insertion order (newest at the bottom). For `Recently Shipped`: insert at the top (newest first).
8. **Remove the `_None yet._` placeholder** if present in the target subsection.
9. **Write `docs/ROADMAP.md`**. Report the change as a one-line summary plus the resulting entry.

### Phase 1b: `move <N> <horizon>`

1. **Locate the existing entry** by scanning all four subsections for the issue URL / `#<N>` reference.
   - If not found: prompt — should the operation be `add` instead? Halt without writing.
   - If found in multiple subsections (drift): halt and surface as a `validate` finding.
2. **Verify the source-of-truth state from the issue**: title, state, milestone. Re-derive the entry's `<id>`, `<theme>`, `<milestone>` from the live issue.
3. **Sanity-check the target horizon vs. issue state**:
   - Moving to `Recently Shipped` requires `state == "CLOSED"`. (`epic-retrospective` closes the issue *before* invoking this skill.)
   - Moving to `Now`/`Next`/`Later` requires `state == "OPEN"`.
4. **Remove from current subsection**. If the source subsection is now empty, restore `_None yet._`.
5. **Insert in target subsection** following the same ordering rules as `add`. Re-render with current title/milestone (do not preserve a stale snapshot).
6. **If target is `Recently Shipped` and the section now has > 10 entries**, prune the oldest (bottom of the list) — surface the pruned entry numbers as a side-effect note.
7. **Write the file** and report the move plus any prune side-effects.

### Phase 1c: `prune` (explicit)

1. Walk `Recently Shipped`. If ≤ 10 entries, no-op with a confirmation message.
2. If > 10, drop the bottom entries until exactly 10 remain. Report the pruned issue numbers.
3. Write the file.

## Reference

- Outputs, success criteria, restartable semantics, scope boundary, and cross-references: [`reference.md`](${CLAUDE_SKILL_DIR}/reference.md)
