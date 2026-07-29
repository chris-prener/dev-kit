---
name: pr-gate-changelog
description: >
  Gate skill: changelog validation. Verifies CHANGELOG.md [Unreleased] has
  an entry referencing a closing issue. Invokes `changelog` to draft one
  if missing.
when_to_use: >
  Invoked only by `pr-orchestrator`, at gate position 2 of 3. Not
  triggered directly by the user.
model: sonnet
allowed-tools: Bash(gh *)
# persona: developer   — grouping metadata only; not read by Claude Code.
# cluster: pr-gates    — grouping metadata only; not read by Claude Code.
---

# PR Gate: Changelog

Gate skill invoked by `pr-orchestrator` at position 2 in the gate ladder. Ensures the changelog has an entry for this PR's work before creation/update proceeds.

## Activation

Invoked only by the orchestrator. Not triggered directly by the user.

## Inputs

Gate protocol inputs per the "Gate protocol" section in [`pr-orchestrator`'s reference.md](${CLAUDE_SKILL_DIR}/../pr-orchestrator/reference.md).

## Steps

### 1. Check opt-out

If `opt_out_markers` contains key `no-changelog`:
- Return `{ signal: 0, chat_output: "Changelog gate skipped: _no-changelog_ marker present." }`

If `mode` is `update` and the PR carries the `no-changelog` label (see [`_partials/label-vocabulary.md`](${CLAUDE_SKILL_DIR}/../_partials/label-vocabulary.md)):
- Return `{ signal: 0, chat_output: "Changelog gate skipped: no-changelog label on PR." }`

### 2. Read [Unreleased] block

Parse `CHANGELOG.md` for the `## [Unreleased]` section. Extract all bullet lines.

### 3. Verify entry exists

Check that at least one bullet under any Keep-a-Changelog category references **at least one** of `issue_refs` (as `#N` anywhere in the line).

**Multi-issue rule**: one entry referencing any single closed issue is sufficient. Entries do not need to enumerate every `Closes #N`.

For PRs with no `Closes` issues: at least one net-new bullet must exist (may reference the branch name or omit explicit refs).

### 4. Entry missing → draft

If no qualifying entry found:
- Invoke `changelog` (add operation) to draft an entry.
- Surface the draft to the operator for approval.
- If approved: the entry is committed, gate passes.
- If rejected: return `{ signal: 2, chat_output: "Changelog gate: operator rejected draft entry. Halting." }`

### 5. Return result

```
{ signal: 0, chat_output: "Changelog gate passed: entry found referencing #<N>." }
```

## Outputs

Gate protocol output: `signal`, `findings`, `chat_output`.

## Success criteria

- `[Unreleased]` contains at least one bullet referencing a closing issue (or opt-out is present).
- Missing entries trigger a `changelog` draft — never silently skipped.
- Without an entry or opt-out, the gate halts (signal 2).

## Out of scope

- Changelog entry content quality (that's `changelog`'s domain).
- Release cutting (a separate `changelog` operation).

## Cross-references

- `pr-orchestrator` — the invoker.
- `changelog` — drafts entries when missing.
- `_partials/label-vocabulary.md` — `no-changelog` Meta label.
