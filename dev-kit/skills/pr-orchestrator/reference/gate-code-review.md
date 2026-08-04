# Gate: Code Review

Read and followed directly by `pr-orchestrator` at its code-review-gate step (position 1). Not a `Skill`-tool dispatch — per [ADR-0002](${CLAUDE_PROJECT_DIR}/docs/adr/ADR-0002-skill-decomposition.md)'s caller-class test, this gate has no independent trigger a human or the model would use to select it, so it does not earn its own listed skill. `code-review` itself is unaffected — it stays a skill, invoked here the same way a user's ad hoc "review the diff" request would invoke it.

## Inputs

Gate protocol inputs per the "Gate protocol" section in [`../reference.md`](../reference.md).

## Steps

### 1. Check preconditions

- Confirm `code-review` exists. If missing: return `{ signal: 0, chat_output: "⚠ code-review not found; skipping gate." }`
- Confirm the working tree is clean (the child skill writes to `.github/audit-reports/` only).

### 2. Invoke code review

Invoke `code-review` with `--mode=review` — the same mode value `code-review`'s own Activation section names for this call ("Invoked by `pr-orchestrator`'s code-review gate as the pre-PR gate. Mode: `review`."). Pass `diff_context.base` and `diff_context.head`. The child skill handles its own `--minimal` whitelist short-circuit internally.

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
- `code-review` is invoked with the mode value it actually defines (`review`), not a value only this file used to invent (`gate`).
- The only path to CLEAN without a rubber-duck call is the `--minimal` whitelist (delegated to the child skill).
- BLOCKER always halts; the operator picks the next action explicitly.
- Re-runs dedup via the body marker (ADR-0004).

## Out of scope

- The rubber-duck review logic itself (owned by `code-review`).
- Auto-filing findings (delegated to `code-review` via `backlog` auto-file).

## Cross-references

- `pr-orchestrator` — the caller; `SKILL.md` reads this file at the code-review-gate step.
- `code-review` — the child skill that runs the actual review.
- [ADR-0004](${CLAUDE_SKILL_DIR}/../_docs/ADR-0004-auto-filed-issue-protocol.md) — auto-file dedup contract.
