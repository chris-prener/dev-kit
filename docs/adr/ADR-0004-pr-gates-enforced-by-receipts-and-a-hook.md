---
status: accepted
date: 2026-11-08
source: "[#108](https://github.com/chris-prener/dev-kit/issues/108), [#109](https://github.com/chris-prener/dev-kit/issues/109), PR #107 (Sprint 9)"
---

# ADR-0004: PR gates are enforced by gate receipts and a PreToolUse hook

## Context

`pr-orchestrator`'s four gates are reference files the model reads and follows. In Sprint 9 (PR #107) some gate steps were satisfied by inline approximations while the PR still opened: no code-review report was written, the changelog entry was committed without the approval step, `run-repo-qc` was stubbed with a one-line report, `documentation-audit-changes` was never invoked, and the Step 1 pre-flight was not confirmed with the operator. Nothing outside the model's own discipline checked that the gates ran. [#103](https://github.com/chris-prener/dev-kit/issues/103) had already hit the same failure for the implementation-plan step and fixed it by letting the harness check, using hooks. This ADR extends that to the PR gates.

Note on numbering: `dev-kit/skills/_docs/ADR-0004-auto-filed-issue-protocol.md` is a skill-level document with the same number. It lives outside `docs/adr/` and is not indexed here; this repo-level series continues from ADR-0003.

## Decision

We will make each gate, and the Step 1 pre-flight, leave a **receipt**, and verify the receipts mechanically in two places that share one implementation.

- A receipt is a JSON file per gate at `.github/audit-reports/receipt-<gate>_<head-sha>.json`, listing the skills actually invoked (through the `Skill` tool), the report artifacts written, and a disposition for every finding. The contract is defined once, in `pr-orchestrator/reference/gate-receipts.md`.
- A single verifier, `pr-orchestrator/scripts/verify-gate-receipts.sh`, checks the receipts against the contract for the current HEAD.
- It is called by the orchestrator's Step 6b, which halts with a named gap, and by a `PreToolUse` hook, `.claude/hooks/pr-gate-guard.py`, which denies `gh pr create` and `gh pr edit` when the check fails.
- Receipts are keyed to HEAD, so a new commit means the gates run again. The one exception is a commit touching only `CHANGELOG.md`, which is the changelog gate's own and would otherwise invalidate the gate that ran before it.

### Alternatives considered

- **Harden the prose only.** Rejected: the existing prose was explicit and was still bypassed. It is the same failure mode, so a stronger sentence is not a different control.
- **Orchestrator-side verification without a hook.** Rejected: it depends on the model running the verification step, which is the discipline that failed.
- **Signed or externally attested receipts.** Rejected: the receipt is agent-written either way, and real attestation needs infrastructure out of proportion to a solo-plus-AI workflow.
- **Block at the gate files instead of at `gh`.** Rejected: the gates are prose; the `gh pr create` call is the one mechanical choke point.

## Consequences

- **Easier:** a skipped or partly run gate now halts with a named gap instead of passing silently; the failure is caught at Step 6b with a clear message and again at the tool call.
- **Harder:** every PR flow writes five small receipts, and a non-CHANGELOG fix-up commit after the gates forces a re-run of them.
- **Constraints:** receipts are written by the agent they constrain, so they can be thin or forged. The contract raises the cost of skipping (artifacts must exist inside `.github/audit-reports/` with the expected file-name prefix; every finding needs a disposition) but does not prevent a determined bypass, and artifacts are not checked for freshness. `DEVKIT_SKIP_GATE_CHECK=1` bypasses the hook by design and the block message shows it, so a bypassed PR should say so in its body.
- **Constraints:** Step 6b and the contract ship in the plugin and apply to every consumer; the hook is repo-local. A consuming repo gets the hook by copying `.claude/hooks/` and the `hooks` block of `.claude/settings.json`; shipping it in the plugin is deferred to the packaging epic. A consumer without `tests/` or a `CLAUDE.md` checklist records the missing sub-step under `skipped` with a reason rather than being blocked.
- **Revisit when:** the plugin can ship hooks (move the guard in), receipts prove too forgeable in practice (add freshness or SHA-embedded reports), or the receipt count becomes a drag on small PRs.

## References

- Related epic: [#13](https://github.com/chris-prener/dev-kit/issues/13)
- Related requirements doc: none
- Related ADRs: [ADR-0002](ADR-0002-skill-decomposition.md) (canonical-source rule: contract and verifier each live in one place); the plan-step hooks of #103 are the pattern this follows.
