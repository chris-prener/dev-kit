# Gate: Changelog

Read and followed directly by `pr-orchestrator` at its changelog-gate step. Not a `Skill`-tool dispatch — per [ADR-0002](${CLAUDE_PROJECT_DIR}/docs/adr/ADR-0002-skill-decomposition.md)'s caller-class test, this gate has no independent trigger a human or the model would use to select it, so it does not earn its own listed skill.

## Inputs

Gate protocol inputs per the "Gate protocol" section in [`../reference.md`](../reference.md).

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
- If approved: the entry is committed to the local branch — this is the tracked-file exception described below — and the gate passes.
- If rejected: return `{ signal: 2, chat_output: "Changelog gate: operator rejected draft entry. Halting." }`

**Tracked-file exception.** Every other gate in this suite writes only to gitignored `.github/audit-reports/`. This gate is the one exception: an approved draft is committed to `CHANGELOG.md`, a tracked file, and that commit can land after `pr-orchestrator`'s pre-flight push-state check already ran. This is why the push-state check re-runs immediately before `gh pr create` / `gh pr edit` (`pr-orchestrator/SKILL.md` Step 6) — it catches and pushes this commit before the PR opens, rather than relying on a claim that no gate dirties the tree.

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
- The one tracked-file commit this gate can produce is pushed before `gh pr create` / `gh pr edit`, via the push-state check re-run.

## Out of scope

- Changelog entry content quality (that's `changelog`'s domain).
- Release cutting (a separate `changelog` operation).

## Cross-references

- `pr-orchestrator` — the caller; `SKILL.md` reads this file at the changelog-gate step.
- `changelog` — drafts entries when missing.
- `_partials/label-vocabulary.md` — `no-changelog` Meta label.
