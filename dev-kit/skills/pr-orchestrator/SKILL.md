---
name: pr-orchestrator
description: >
  Opens or updates a GitHub PR with a consistent five-section body.
  Runs four gates (code review, changelog, QC, implementation plan) from reference files it
  reads and follows directly, and inline-closes each referenced issue
  with a retrospective and a plan-status transition. Owns mode dispatch,
  pre-flight, body composition, and `gh pr create` / `gh pr edit`.
when_to_use: >
  Use to open or update a PR ("open pr", "create pull request", "ship
  the branch", "update pr", "refresh pr body"). Not for reviewing or
  merging PRs (those happen on github.com) or for gate-specific logic
  (each gate's own reference file under `reference/` owns that).
model: sonnet
allowed-tools: Bash(gh *), Bash(git *)
# persona: developer   — grouping metadata only; not read by Claude Code.
---

# PR Orchestrator

Opens or updates a GitHub PR. Validation runs through four gates — reference files under `reference/` this skill reads and follows directly, each returning the standard protocol shape (signal 0/1/2 — see [`reference.md`](${CLAUDE_SKILL_DIR}/reference.md)); this skill halts on BLOCKER.

## Activation

Triggers: "open pr", "open a pr", "open pull request", "create pr", "create pull request", "draft pr", "ship the branch", "update pr", "refresh pr body", "update existing pr".

## Inputs

- Head branch (current branch), base branch (repo default).
- At least one issue reference (or a justification for none).
- Clean working tree, branch pushed to origin.

## Steps

### 0. Mode dispatch

Detect create vs. update mode per branch/PR state:
- No open PR on branch → **Create mode**
- One open PR → **Update mode** (confirm with operator)
- More than one open PR → refuse; ask the operator to disambiguate
- `--update --body-only` → skip the gate loop and the retro/plan step entirely (fast body-only refresh); write the `update-body-only` mode receipt (see [`reference/gate-receipts.md`](${CLAUDE_SKILL_DIR}/reference/gate-receipts.md))

Log `"=== pr-orchestrator mode: CREATE ==="` or `"=== pr-orchestrator mode: UPDATE (PR #N) ==="`.

### 1. Pre-flight

- Confirm a clean tree. Run the push-state check ([`reference.md`](${CLAUDE_SKILL_DIR}/reference.md)); push or halt before proceeding.
- Detect issue refs from `git log <base>..HEAD` using the closing-keyword grammar (`(Closes|Fixes|Resolves) #\d+` — see [`reference.md`](${CLAUDE_SKILL_DIR}/reference.md)).
- Scan all `_no-*:_` opt-out markers from the PR body (update mode) or the planned body.
- Emit the branch-shape signal: `"Branch shape: <N> files changed, +<A> -<D> LOC, <K> commits."` Surface split advice if the branch is substantial but thin on commits.
- **Confirm with the operator, explicitly.** Show the detected `issue_refs`, the branch-shape signal and the mode, and wait for a yes. Then write `receipt-preflight_<head-sha>.json` per [`reference/gate-receipts.md`](${CLAUDE_SKILL_DIR}/reference/gate-receipts.md) with `confirmed_by_operator: true`. No confirmation, no receipt, no PR. In `--update --body-only` mode write the mode receipt instead.
- Build the gate protocol input object (`issue_refs`, `diff_context`, `opt_out_markers`, `mode`, `pr_number`, `pr_body_managed`) — see [`reference.md`](${CLAUDE_SKILL_DIR}/reference.md).

### 2. Body composition

Compose the five-section PR body (Summary / Implementation / Testing / Closes / Notes) wrapped in the `<!-- pr-skill-managed-start/end -->` fence. Update mode carries forward operator-authored prose verbatim and regenerates only `## Closes` and the `_updated:` marker. Full detail: [`reference.md`](${CLAUDE_SKILL_DIR}/reference.md).

### 3. Gate 1 — Code review

Read and follow [`reference/gate-code-review.md`](${CLAUDE_SKILL_DIR}/reference/gate-code-review.md). Mandatory, no opt-out marker.

### 4. Gate 2 — Changelog

Read and follow [`reference/gate-changelog.md`](${CLAUDE_SKILL_DIR}/reference/gate-changelog.md). Opt out with the `no-changelog` marker or label.

### 5. Gate 3 — QC

Read and follow [`reference/gate-qc.md`](${CLAUDE_SKILL_DIR}/reference/gate-qc.md). Opt out with the `no-prep-gate` marker.

### 6. Gate 4 — Implementation plan

Read and follow [`reference/gate-implementation-plan.md`](${CLAUDE_SKILL_DIR}/reference/gate-implementation-plan.md). Opt out with the `no-plan-gate` marker. Runs last so the cheaper local gates fail first; it blocks when a closing issue has no plan, or a plan still at `drafting`.

None of the four gates are separately listed or `Skill`-tool-dispatchable skills — they're reference files this skill reads and follows inline, per [ADR-0002](${CLAUDE_PROJECT_DIR}/docs/adr/ADR-0002-skill-decomposition.md).

For each gate in steps 3, 4, 5, 6:
1. Check the reference file exists → if missing, log `"⚠ Gate reference <path> not found; skipping."`, effective signal 0.
2. Follow its steps with the gate protocol inputs.
3. Read the signal: **0** (CLEAN) → proceed. **1** (FINDINGS) → display `chat_output`, proceed. **2** (BLOCKER) → display `chat_output`, halt. Do not proceed to remaining gates. Do not create/update the PR. Do not run step 8 (retro + plan close-out) — it has not run yet at any gate position, so the halt is satisfiable from all four.
4. Collect any `body_amendments` for insertion into `## Notes`.

**Steps 3–6 are skipped entirely** in `--update --body-only` mode.

### 6b. Verify the receipts

Run [`scripts/verify-gate-receipts.sh`](${CLAUDE_SKILL_DIR}/scripts/verify-gate-receipts.sh) (add `--edit` in update mode). Do not reimplement its checks. If it exits non-zero, print each gap, **halt**, and do not run Step 7: go back and run the named gate properly. The `PreToolUse` hook `pr-gate-guard.py` repeats this check at the `gh` call; this step exists so the failure is caught here, with a clear message, rather than as a hook denial. Skipped in `--update --body-only` mode, where the mode receipt stands in.

### 7. Open or update the PR

- **Re-run the push-state check** ([`reference.md`](${CLAUDE_SKILL_DIR}/reference.md)) immediately before either `gh` call below. Gates 3–6 may have produced local fix-up commits since pre-flight ran; push state can only be trusted at the point of use, not carried forward from Step 1.
- **Create**: `gh pr create --base <base> --head <head> --title "<prefix>: <title>" --body-file <tmp>`
- **Update**: `gh pr edit <#> --body-file <tmp>`

### 8. Retro + plan close-out (inline, not a gate)

Runs only after all four gates have passed (or been opted out) and the PR exists. For each issue in `issue_refs`:

1. **Post retrospective.** If the issue carries `sprint` or `epic`, do not invoke `backlog-retrospective` (it refuses both): require that it is already `CLOSED` with its own retrospective (`sprint-retrospective` / `epic-retrospective`), else halt with `"#<N> is a sprint/epic: close it with its retrospective skill first."` before any issue is closed. Otherwise invoke `backlog-retrospective` with the issue number. It no-ops if a retrospective comment (any heading in `_partials/retro-close-conventions.md`'s registry) already exists, and closes the issue as part of its flow. On error: halt with `"Retro failed for #<N>: <error>"`.
2. **Transition the plan, if one exists.** Search the issue's comments for the `implementation-plan` locator. If found and not already `shipped`, invoke `implementation-plan` `Transition` with target `shipped` (allowed from `ready-for-pr` or `in-progress`). If no plan comment exists, skip silently — nothing to transition.

This step runs for every issue regardless of gate markers; there's no opt-out, because closing the loop on an issue you're about to ship is not optional ceremony. It's skipped entirely in `--update --body-only` mode (see Step 0).

### 9. Confirm + cleanup

Report the PR URL. Remove tempfiles.

## Reference

Gate protocol, PR-body marker grammar, the managed-fence contract, outputs, and success criteria: [`reference.md`](${CLAUDE_SKILL_DIR}/reference.md)
