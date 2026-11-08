# Gate receipts

The evidence contract for `pr-orchestrator`'s four gates. A gate that ran leaves a **receipt**; `scripts/verify-gate-receipts.sh` checks the receipts against this file, and the `PreToolUse` hook `.claude/hooks/pr-gate-guard.py` denies `gh pr create` / `gh pr edit` when the check fails. This file is the single definition: the verifier, the hook and the gate reference files link here rather than restate it (ADR-0002, Rule 2).

Why it exists: the gate files are prose the model follows, and in Sprint 9 (PR #107) some gate steps were satisfied by inline approximations while the PR still opened. Nothing outside the model's own discipline checked that the gates ran. This is the same fix #103 applied to the plan step: let the harness check.

## Location and naming

One JSON file per gate, plus one `preflight` receipt for Step 1, in the gitignored report directory:

```
.github/audit-reports/receipt-<gate>_<head-sha>.json
```

`<gate>` is `preflight`, `code-review`, `changelog`, `qc` or `implementation-plan`. `<head-sha>` is the full `git rev-parse HEAD` the gate ran against. The `preflight` receipt is Step 1's, not a gate's, and cannot be opted out. A new commit changes HEAD and so invalidates every receipt: a fix-up commit after the gates means the gates run again. That is intended.

## Schema (version 1)

| Field | Type | Meaning |
|---|---|---|
| `schema` | integer | Always `1`. |
| `gate` | string | The gate name above. |
| `head_sha` | string | Full SHA; must equal the current HEAD. |
| `signal` | integer | The gate's result: `0` clean or `1` findings. `2` (BLOCKER) is never a valid receipt: a blocked gate halts the flow. |
| `invoked` | string[] | The skills and sub-steps that **actually ran**. A sub-step the gate describes as "invoke X" is listed only if X ran through the `Skill` tool; an inline equivalent is not listed. |
| `artifacts` | string[] | Repo-relative paths of the reports the sub-skills wrote. Each must exist on disk. |
| `findings` | object[] | `{ "id": string, "disposition": "fixed" \| "filed" \| "accepted" \| "n/a" }`. Every finding the gate surfaced has a disposition. |
| `written_at` | string | ISO-8601 UTC. |
| `opted_out` | string, optional | The opt-out marker name (`no-changelog`, `no-prep-gate`, `no-plan-gate`) with the justification. Satisfies the gate without `invoked`/`artifacts`. **Not accepted for `code-review`**, which is mandatory. |
| `confirmed_by_operator` | boolean | `preflight` receipt only; required `true`. Set after the operator confirms the detected `issue_refs`, the branch-shape signal and the mode shown to them in Step 1. |
| `issue_refs`, `branch_shape`, `mode` | integer[], string, string | `preflight` receipt only: what was shown to the operator. |
| `approved_by_operator` | boolean, optional | Required `true` on the `changelog` receipt when `invoked` contains `changelog` (a drafted entry needs approval before it is committed). |

## Required per gate

| Gate | `invoked` must include | Artifacts required |
|---|---|---|
| `preflight` | none (carries `confirmed_by_operator`) | none |
| `code-review` | `code-review` | at least 1 (the review report) |
| `changelog` | `changelog-check` | none |
| `qc` | `run-repo-qc`, `documentation-audit-changes`, `claude-md-checklist` | at least 2 (the repo-QC report and the doc-audit report) |
| `implementation-plan` | `implementation-plan-locate` | none |

Sub-step names beyond these (for example `xref`) may be recorded and are not required.

## Update-body-only mode

`pr-orchestrator --update --body-only` skips the gates by design. In that mode it writes `receipt-mode_<head-sha>.json` with `"gate": "mode"` and `"mode": "update-body-only"`. That receipt satisfies the check for `gh pr edit` only; it never satisfies `gh pr create`.

## What this does and does not prove

A receipt is written by the same agent it constrains, so it can be thin or forged. The contract raises the cost of skipping a gate: it demands artifacts the sub-skills write themselves and a disposition for every finding. It does not make skipping impossible, and a determined bypass (`DEVKIT_SKIP_GATE_CHECK=1`, or a forged file) is outside what it can stop. Treat a bypassed PR as something to state in the PR body.

## Bypass and failure behaviour

- **Bypass:** prefix the command with `DEVKIT_SKIP_GATE_CHECK=1` directly before `gh`, or export it where Claude Code runs.
- **Fail open:** if the verifier itself errors (exit 2: missing `python3`, unreadable directory), the hook allows the command and shows a visible `failed open` warning. A missing or incomplete receipt (exit 1) is a denial, not an error.

## Verifier

`scripts/verify-gate-receipts.sh [--edit] [--sha SHA] [--dir DIR]` prints one line per gap and exits `0` (all satisfied), `1` (gaps) or `2` (verifier error). `--edit` accepts the update-body-only mode receipt in place of the four gate receipts; without it, `--edit` requires the four gate receipts like a create.
