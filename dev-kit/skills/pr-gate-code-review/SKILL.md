---
name: pr-gate-code-review
description: >
  Gate skill: institutional code review. Invokes `code-review` in gate
  mode, maps its exit code to the gate protocol signal. Mandatory — no
  opt-out marker.
when_to_use: >
  Invoked only by `pr-orchestrator`, at gate position 1 of 3. Not
  triggered directly by the user.
model: sonnet
# persona: developer   — grouping metadata only; not read by Claude Code.
# cluster: pr-gates    — grouping metadata only; not read by Claude Code.
---

# PR Gate: Code Review

Gate skill invoked by `pr-orchestrator` at position 1 in the gate ladder. Runs the institutional rubber-duck code review against the final diff before the PR opens.

## Activation

Invoked only by the orchestrator. Not triggered directly by the user.

## Inputs

Gate protocol inputs per the "Gate protocol" section in [`pr-orchestrator`'s reference.md](${CLAUDE_SKILL_DIR}/../pr-orchestrator/reference.md).

## Steps

### 1. Check preconditions

- Confirm `code-review` exists. If missing: return `{ signal: 0, chat_output: "⚠ code-review not found; skipping gate." }`
- Confirm the working tree is clean (the child skill writes to `.github/audit-reports/` only).

### 2. Invoke code review

Invoke `code-review` with `--mode=gate`, passing `diff_context.base` and `diff_context.head`. The child skill handles its own `--minimal` whitelist short-circuit internally.

### 3. Map exit signal

| Child exit | Gate signal | Action |
|---|---|---|
| 0 (CLEAN) | 0 | Proceed |
| 1 (FINDINGS) | 1 | Surface filed-issue list as informational |
| 2 (BLOCKER) | 2 | Present operator choices (below) |

### 4. BLOCKER handling

Present two explicit choices (no default):
1. **Fix now and stop** — operator addresses findings locally, re-invokes. Recommended.
2. **File-and-stop** — keep filed issues open, exit without PR.

This gate has no opt-out marker — it is mandatory for every non-trivial PR. The only path to CLEAN without a rubber-duck call is `code-review`'s own `--minimal` whitelist.

### 5. Return result

```
{ signal: <0|1|2>, findings: [...], chat_output: "<summary>" }
```

## Outputs

Gate protocol output: `signal`, `findings`, `chat_output`.

## Success criteria

- The gate runs for every non-trivial PR.
- The only path to CLEAN without a rubber-duck call is the `--minimal` whitelist (delegated to the child skill).
- BLOCKER always halts; the operator picks the next action explicitly.
- Re-runs dedup via the body marker (ADR-0004).

## Out of scope

- The rubber-duck review logic itself (owned by `code-review`).
- Auto-filing findings (delegated to `code-review` via `backlog` auto-file).

## Cross-references

- `pr-orchestrator` — the invoker.
- `code-review` — the child skill that runs the actual review.
- [ADR-0004](${CLAUDE_SKILL_DIR}/../_docs/ADR-0004-auto-filed-issue-protocol.md) — auto-file dedup contract.
