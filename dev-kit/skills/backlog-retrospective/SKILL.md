---
name: backlog-retrospective
description: >
  Bookends the lifecycle of a GitHub issue. Two operations: (1)
  close+retro — closes an issue and posts a structured Retrospective
  comment in one transaction (default; runs pre-`gh pr create` per the
  pr-orchestrator skill); (2) validate — posts a structured Outcome
  validation comment on an already-closed issue weeks/months later,
  recording whether the shipped change achieved the intent (achieved /
  partial / not-achieved / deferred). Required for any issue closed as
  "completed".
when_to_use: >
  Use close+retro whenever you are about to close an issue as completed
  — the user says "close #N" / "wrap up #N", a PR with `Closes #N` /
  `Fixes #N` is being opened, or you're about to call `gh issue close`.
  Use validate when the user says "validate #N" / "did it work?", or
  enough time has passed since close that the change's intent can be
  observed. Not for closes as duplicate / wontfix / not-planned / invalid
  (label first, then a short rationale comment, no full retro), or for
  re-closing an issue that already has a retro from a prior close.
model: sonnet
allowed-tools: Bash(gh *)
# persona: product-owner   — grouping metadata only; not read by Claude Code.
#   Re-tagged from the source suite's workflow-steward persona (dropped;
#   retrospectives are kept as a product-owner responsibility).
---

# Backlog Retrospective

You are completing the lifecycle of a GitHub issue. Two operations live here:

- **close+retro** (default) — close the issue and post a structured `## Retrospective` comment in one transaction. The retro comment is the durable record of *what shipped*, *how*, and *what to know later* — it lives on the issue itself, not in the PR body, so it stays discoverable from the issue tracker after PRs are merged and archived.
- **validate** — post a structured `## Outcome validation` comment on an *already-closed* issue weeks/months later, answering "did the shipped change actually achieve the intent?" with one of `achieved | partial | not-achieved | deferred` plus rationale. The validate op is the issue-level analog of the `objectives` skill's op H (KR cadence sweep).

Activate the **validate** operation whenever the issue's intent is observable (a metric moved, a downstream consumer adopted, a recurring failure stopped). If the intent isn't observable, post a `deferred` validation with a one-line reason rather than guessing.

## Out of scope (do NOT post a retro)

- Closes as **duplicate / wontfix / not-planned / invalid** — these require the matching close-reason **label** on the issue *before* close (`duplicate`, `wontfix`, `not-planned`, `invalid`). Add the label first, then leave a 1–3 sentence rationale comment, then close. The `--reason` flag alone is **not** sufficient — the label is the durable signal that gates this carve-out for the retro skill, the backlog skill, and any future tooling. See `${CLAUDE_PROJECT_DIR}/.github/LABELS.md` (or `${CLAUDE_SKILL_DIR}/../_partials/label-vocabulary.md` if absent) for the close-reason vocabulary.
- Re-closing an issue that already has a retro from a prior close (check `gh issue view <N> --comments` first).
- Session-end / pause workflows — out of scope for this skill.

## Inputs

- **Required**: issue number `N` and the repo (`gh repo view --json nameWithOwner -q .nameWithOwner` if not given).
- **Required**: at least one of (a) the merge/closing commit SHA(s) or (b) the PR number that resolved the issue. If neither exists, ask the user before proceeding — a retro with no implementation reference is a smell.
- **Optional**: a short title-line for the retro (defaults to the issue title).

> **Note (auto-filed issues).** Issues created by the `backlog` skill's auto-file mode (which carry an `<!-- autofile-id: ... -->` body marker) are closed via the standard `pr-orchestrator` skill's `Closes #N` flow, exactly like manually-filed issues. Auto-file mode itself never invokes this skill directly; the resolving PR is always the entry point. See [ADR-0004](${CLAUDE_SKILL_DIR}/../_docs/ADR-0004-auto-filed-issue-protocol.md) §5.

## Steps

The skill has two operations. **close+retro** runs Steps 1–7 below (the original behavior). **validate** runs Steps V1–V4. Pick the operation from the trigger / explicit operator instruction; default to close+retro if a `Closes #` / `Fixes #` reference is the entry point.

### close+retro (default)

1. **Pre-flight**.
   - `gh issue view <N> --json number,title,state,labels,closedAt,comments`.
   - If `state == "CLOSED"` and a comment beginning with `## Retrospective` already exists, stop — do not double-post.
   - **If labels include any of `duplicate`, `wontfix`, `not-planned`, `invalid`**, fall back to the out-of-scope path above (short rationale comment, then `gh issue close --reason <reason>`). Do not post a full retro.
   - **If the user is asking to close as duplicate/wontfix/etc. but the issue does not yet have the matching label**, prompt them to add it first (`gh issue edit <N> --add-label <label>`) before closing. The label is required by the label vocabulary and is what gates this carve-out for downstream tooling.

2. **Gather evidence**. Pull the data the retro needs:
   - Resolving PR(s): `gh pr list --search "<N> in:body" --state all --json number,title,mergedAt,mergeCommit --limit 10` (explicit `--limit` per `${CLAUDE_SKILL_DIR}/../_partials/gh-list-pagination.md`).
   - Commits that touched the relevant paths since the issue was opened (use `gh search commits` or `git log --oneline <since>..HEAD -- <paths>`).
   - Tests added/changed in those commits.

3. **Compose the retro comment** using exactly this template (markdown). Sections marked *required* must be present and non-empty; sections marked *optional* may be omitted entirely (do not leave empty headings). Keep it tight — typical retros are 200–400 words; long technical rationale belongs in commit messages, not here.

   ```markdown
   ## Retrospective

   **Resolved by**: <commit SHA(s) or PR #> on branch `<branch>` (merged <ISO date>).

   ### What shipped (required)

   1–3 sentences describing the user-visible or contract-level change. Past tense, declarative. Reference symbols/paths in backticks.

   ### How (required)

   3–8 bullets walking through the implementation at the level a future maintainer reading the issue would need. Mention the helpers added/changed, the rough mechanism, and any non-obvious design choice. Tables are fine for schema/option additions.

   ### Tests (required)

   Bullet list of test files added or extended, with a one-line note per file on what they cover. State explicitly if any expected coverage was deferred and why.

   ### Follow-ups (optional)

   Bullets, each linking to a filed follow-up issue (`#NNN`). Use this for known-deferred work surfaced during implementation. If there are none, omit the section.

   ### Notes for future readers (optional)

   Quirks, gotchas, surprising constraints, decisions you almost made differently. Omit if there are none.
   ```

4. **Post the comment**: `gh issue comment <N> --body-file <path>`. Use a tempfile under `/tmp/`, never inline `--body` for multi-paragraph content (shell quoting hazards).

5. **Close the issue** *after* the comment is confirmed posted: `gh issue close <N> --reason completed`. If the close fails, do NOT delete the comment — surface the error and ask.

6. **Detect last-sub-issue-closed → prompt epic retrospective** *(runs only after a successful close)*.

   This step runs after `gh issue close` succeeds, regardless of whether the close was a full-retro `completed` close or a carve-out `duplicate`/`wontfix`/`not-planned`/`invalid` close — the epic-close signal is "no open sub-issues remain", not "all sub-issues completed cleanly". Descoped sub-issues count toward the gate; `epic-retrospective` will surface them in the epic retro's "Descoped or deferred" section.

   1. **Look up the parent epic** via the GitHub native sub-issue REST endpoint:
      ```bash
      gh api "repos/$REPO/issues/<N>/parent" --jq '{number, state, labels: [.labels[].name]}' 2>/dev/null
      ```
      If the call returns 404 or the issue has no parent (the linkage was never made, or the issue carries `**Parent epic:** standalone — <reason>` per the `backlog` skill's Step C), this step is a no-op. Continue to cleanup. **Never** fall back to label-based parent inference.

   2. **Verify the parent is an epic.** Require `epic` in the parent's labels. If the linkage exists but the parent is not an epic, surface that as a data-quality finding (likely a sub-issue link to a non-epic parent) but do not fail the close — continue to cleanup.

   3. **Skip if the parent is already closed.** No prompt needed.

   4. **Enumerate sub-issues** with pagination:
      ```bash
      gh api --paginate "repos/$REPO/issues/<PARENT>/sub_issues" --jq '.[] | {number, state}'
      ```
      Count entries with `state == "OPEN"`. The just-closed issue `<N>` should be `CLOSED` by this point — if it appears as `OPEN`, GitHub's read-after-write may be lagging; retry once after 2 seconds before deciding.

   5. **If zero open sub-issues remain**, surface a prompt to the user:
      > 🎯 The last open sub-issue of [Epic <id>: <theme>](<parent-url>) just closed. Run `epic-retrospective` on `#<PARENT>` to wrap up the epic.

      Do **not** auto-invoke `epic-retrospective` — auto-closing an epic is risky and the user may have follow-on context (descoped scope to acknowledge, follow-on epics to file).

   6. **If open sub-issues remain**, no additional output.

7. **Cleanup**: remove the tempfile.

### validate

V1. **Pre-flight**.
   - `gh issue view <N> --json number,title,state,labels,closedAt,comments`.
   - If `state != "CLOSED"`, refuse: validate runs only on closed issues. Tell the operator to use close+retro first.
   - If a comment beginning with `## Outcome validation` already exists for this issue, surface it and ask whether to post a *new* validation (legitimate when more time has passed and the picture has changed) or stop. **Multiple validations are allowed**; each is dated and the most recent represents the current view.
   - Read the issue's Acceptance Criteria from the body and the `### What shipped` section from the existing `## Retrospective` comment. These define the intent being validated.

V2. **Determine the outcome.** Pick exactly one of the four values:
   - `achieved` — the shipped change produced the expected behavior; the AC is met in observable practice (not just in tests).
   - `partial` — some AC met, others not; or behavior is partially as expected.
   - `not-achieved` — the shipped change did not produce the expected behavior; rework or rethink needed.
   - `deferred` — the outcome is not yet observable (signal source not available, time horizon not reached, downstream consumer hasn't adopted). Schedule a re-validation; don't guess.

   Gather a one-line rationale and (when applicable) the signal source: test output, pipeline run, downstream usage check, metric query, operator observation.

V3. **Compose and post the validation comment** using exactly this template:

   ```markdown
   ## Outcome validation YYYY-MM-DD

   **Outcome:** `achieved | partial | not-achieved | deferred`

   **Signal source:** <test output | pipeline run | downstream usage | metric | operator observation | n/a (deferred)>

   **Rationale:** 1–3 sentences explaining the call against the issue's AC and the `### What shipped` from the close-time retro. Reference the prior retro comment by URL when useful.

   **Follow-up (required for `partial` / `not-achieved`; optional for `deferred`):** Issue link to the filed remediation, or "filed via auto-file mode (#XXX)".
   ```

   Post via `gh issue comment <N> --body-file <path>` (tempfile under `/tmp/`, never inline `--body`).

V4. **Hand off remediation** when outcome is `partial` or `not-achieved`:

   **Check-ID inventory:** `outcome-validation` — the single stable check-ID this op emits; the original issue's identity lives in `dedup_id`'s `<scope>` component (`#<N>`), not in a per-check-type ID, since every remediation issue from V4 is the same kind of finding.

   **Auto-file invocation contract:**

   | Input | Value |
   |---|---|
   | `template` | `tech_debt` |
   | `title` | `Outcome validation follow-up: #<N> <partial\|not-achieved>`. |
   | `body` | Template-conformant body. MUST include the original issue reference, the validation date, and the `## Outcome validation` comment URL. MUST include the `<!-- autofile-id: backlog-retrospective:#<N>:outcome-validation -->` marker on its own line. |
   | `labels` | `["tech-debt", "<priority/*>"]` per the mapping below. |
   | `dedup_id` | `backlog-retrospective:#<N>:outcome-validation` (the **outcome status is NOT part of the dedup key** — same rationale as the `objectives` skill's op H: a re-validation that finds the situation worsened should not spam if the prior follow-up is still open, but should re-file if the prior follow-up was closed and the issue regressed). This is a new dedup_id shape (fixing #32); no issue was ever filed under the old `outcome-validation:#<N>` form — every prior invocation errored at input validation before reaching the dedup search — so there is no historical marker to migrate. |
   | `parent_epic` | The issue's parent epic if it has one (`gh api repos/.../issues/<N>/parent`); else `standalone_reason` with "outcome-validation follow-up; original issue #<N> not in an epic". |

   **Severity → Priority mapping:**

   | Outcome | Priority label | Auto-filed? |
   |---|---|---|
   | partial | `priority/medium` | yes |
   | not-achieved | `priority/high` | yes |
   | achieved / deferred | — | no — not filed (deferred should be re-run later; it's not a remediation trigger) |

V5. **Cleanup**: remove the tempfile.

## Reference

- Outputs, success criteria, scope boundary, and cross-references: [`reference.md`](${CLAUDE_SKILL_DIR}/reference.md)
