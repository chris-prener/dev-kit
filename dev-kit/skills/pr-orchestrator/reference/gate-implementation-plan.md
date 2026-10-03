# Gate: Implementation plan

Read and followed directly by `pr-orchestrator` at its implementation-plan-gate step (fourth and final gate). Not a `Skill`-tool dispatch — per [ADR-0002](${CLAUDE_PROJECT_DIR}/docs/adr/ADR-0002-skill-decomposition.md)'s caller-class test, this gate has no independent trigger a human or the model would use to select it, so it does not earn its own listed skill.

Why it exists: `session-start` surfaces in-flight work from the `in-progress` label, and that label is only set by an `implementation-plan` `Transition`. Without a check, an issue can be implemented and closed with no plan, no label, and no durable record of the approach. This gate is the enforcement point; the Developer output styles are the advisory tier.

## Inputs

Gate protocol inputs per the "Gate protocol" section in [`../reference.md`](../reference.md).

## Steps

### 1. Check opt-out

If `opt_out_markers` contains key `no-plan-gate`:
- Return `{ signal: 0, chat_output: "Implementation-plan gate skipped: _no-plan-gate_ marker present." }`

If `issue_refs` is empty:
- Return `{ signal: 0, chat_output: "Implementation-plan gate skipped: PR closes no issues." }`

### 2. Locate each plan

For each issue `#N` in `issue_refs`, run `implementation-plan`'s Phase 0 (Locate) and, if exactly one plan is found, read its `Status:`.
- **0 plans** → finding: `#N has no ## Implementation plan comment.`
- **≥ 2 plans** → finding: `#N has duplicate plan comments (ids …); resolve before retrying.`
- **1 plan** → check its status.

### 3. Check status

A plan passes when its `Status:` is `in-progress`, `blocked`, `ready-for-pr`, or `shipped` — i.e. it reached at least `in-progress`. `drafting` fails: the plan exists but work was never marked started, so `session-start` never saw it.

`shipped` passes so re-running the gate in update mode, after step 8 already transitioned the plan, stays clean.

### 4. Return result

If no findings: `{ signal: 0, chat_output: "Implementation-plan gate passed: all of #<N>, … have a plan at in-progress or later." }`

Otherwise return signal 2 with one finding per failing issue, and a `chat_output` that names each issue and its remediation:
- No plan → `Run implementation-plan Create on #<N>, then Transition to in-progress.`
- `drafting` → `Run implementation-plan Transition on #<N> to in-progress.`

**BLOCKER handling** — present three explicit choices (no default):
1. **Fix now and stop** — operator posts or transitions the plan(s), re-invokes.
2. **File-and-stop** — exit without a PR.
3. **Proceed with marker** — append `_no-plan-gate: <justification>_` to `body_amendments`.

This gate files no issues and writes nothing: it only reads issue comments.

## Outputs

Gate protocol output: `signal`, `findings`, `body_amendments`, `chat_output`.

## Success criteria

- Every issue in `issue_refs` has exactly one plan at `in-progress` or later, or the opt-out marker is present.
- A missing plan or a `drafting` plan halts (signal 2) with a per-issue remediation message — never skipped silently.
- The gate never writes to an issue; it does not transition plans (step 8 of `pr-orchestrator` owns the `shipped` transition).

## Out of scope

- Plan content quality (that's `implementation-plan`'s schema).
- Transitioning or creating plans.

## Cross-references

- `pr-orchestrator` — the caller; `SKILL.md` reads this file at the implementation-plan-gate step.
- `implementation-plan` — owns the locator, schema, and status state machine this gate reads.
- `session-start` — consumes the `in-progress` label this gate keeps honest.
