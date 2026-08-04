---
name: pr-orchestrator
description: >
  Opens or updates a GitHub PR with a consistent five-section body.
  Dispatches to three independent gate skills (code review, changelog,
  QC) and inline-closes each referenced issue with a retrospective and a
  plan-status transition. Owns mode dispatch, pre-flight, body
  composition, and `gh pr create` / `gh pr edit`.
when_to_use: >
  Use to open or update a PR ("open pr", "create pull request", "ship
  the branch", "update pr", "refresh pr body"). Not for reviewing or
  merging PRs (those happen on github.com) or for gate-specific logic
  (each gate skill owns its own).
model: sonnet
allowed-tools: Bash(gh *), Bash(git *)
# persona: developer   — grouping metadata only; not read by Claude Code.
# cluster: pr-gates, cluster_role: orchestrator   — grouping metadata only.
---

# PR Orchestrator

Opens or updates a GitHub PR. Delegates validation to three independent gate skills, each following the standard protocol (signal 0/1/2 — see [`reference.md`](${CLAUDE_SKILL_DIR}/reference.md)); this skill halts on BLOCKER.

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
- `--update --body-only` → skip the gate loop and the retro/plan step entirely (fast body-only refresh)

Log `"=== pr-orchestrator mode: CREATE ==="` or `"=== pr-orchestrator mode: UPDATE (PR #N) ==="`.

### 1. Pre-flight

- Confirm a clean tree; push if needed.
- Detect issue refs from `git log <base>..HEAD` for `(Closes|Fixes|Resolves) #\d+`; confirm with the operator.
- Scan all `_no-*:_` opt-out markers from the PR body (update mode) or the planned body.
- Emit the branch-shape signal: `"Branch shape: <N> files changed, +<A> -<D> LOC, <K> commits."` Surface split advice if the branch is substantial but thin on commits.
- Build the gate protocol input object (`issue_refs`, `diff_context`, `opt_out_markers`, `mode`, `pr_number`, `pr_body_managed`) — see [`reference.md`](${CLAUDE_SKILL_DIR}/reference.md).

### 2. Body composition

Compose the five-section PR body (Summary / Implementation / Testing / Closes / Notes) wrapped in the `<!-- pr-skill-managed-start/end -->` fence. Update mode carries forward operator-authored prose verbatim and regenerates only `## Closes` and the `_updated:` marker. Full detail: [`reference.md`](${CLAUDE_SKILL_DIR}/reference.md).

### 3. Gate 1 — Code review

Invoke `pr-gate-code-review`. Mandatory, no opt-out marker.

### 4. Gate 2 — Changelog

Invoke `pr-gate-changelog`. Opt out with the `no-changelog` marker or label.

### 5. Gate 3 — QC

Invoke `pr-gate-qc`. Opt out with the `no-prep-gate` marker.

For each gate in steps 3, 4, 5:
1. Check the gate skill exists → if missing, log `"⚠ Gate <slug> not found; skipping."`, effective signal 0.
2. Invoke with the gate protocol inputs.
3. Read the signal: **0** (CLEAN) → proceed. **1** (FINDINGS) → display `chat_output`, proceed. **2** (BLOCKER) → display `chat_output`, halt. Do not invoke remaining gates. Do not create/update the PR. Do not run step 7 (retro + plan close-out) — it has not run yet at any gate position, so the halt is satisfiable from all three.
4. Collect any `body_amendments` for insertion into `## Notes`.

**Steps 3–5 are skipped entirely** in `--update --body-only` mode.

### 6. Open or update the PR

- **Create**: `gh pr create --base <base> --head <head> --title "<prefix>: <title>" --body-file <tmp>`
- **Update**: `gh pr edit <#> --body-file <tmp>`

### 7. Retro + plan close-out (inline, not a gate)

Runs only after all three gates have passed (or been opted out) and the PR exists. For each issue in `issue_refs`:

1. **Post retrospective.** Invoke `backlog-retrospective` with the issue number. It no-ops if a `## Retrospective` comment already exists, and closes the issue as part of its flow. On error: halt with `"Retro failed for #<N>: <error>"`.
2. **Transition the plan, if one exists.** Search the issue's comments for the `implementation-plan` locator. If found and not already `shipped`, invoke `implementation-plan` `Transition` with target `shipped` (allowed from `ready-for-pr` or `in-progress`). If no plan comment exists, skip silently — nothing to transition.

This step runs for every issue regardless of gate markers; there's no opt-out, because closing the loop on an issue you're about to ship is not optional ceremony. It's skipped entirely in `--update --body-only` mode (see Step 0).

### 8. Confirm + cleanup

Report the PR URL. Remove tempfiles.

## Reference

Gate protocol, PR-body marker grammar, the managed-fence contract, outputs, and success criteria: [`reference.md`](${CLAUDE_SKILL_DIR}/reference.md)
