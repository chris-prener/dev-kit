# Backlog Retrospective — reference

Contract and QA detail for the `backlog-retrospective` skill. `SKILL.md` holds the procedure; this file holds outputs, success criteria, scope, and cross-references.

## Outputs

**close+retro:**
- One `## Retrospective` comment on issue `<N>`.
- Issue state transitioned to `CLOSED` with reason `completed`.
- Tempfiles cleaned up.

**validate:**
- One `## Outcome validation YYYY-MM-DD` comment on issue `<N>` (issue stays `CLOSED`).
- For `partial` / `not-achieved`: one auto-filed remediation issue (deduped per `outcome-validation:#<N>`).
- Tempfiles cleaned up.

## Success criteria

**close+retro:**
- The retro comment is on the issue and renders cleanly (preview with `gh issue view <N> --comments` after posting).
- The four required sections (Resolved by, What shipped, How, Tests) are all present and non-empty.
- The issue is closed with reason `completed`.
- Re-running the skill on the same issue is a no-op (pre-flight detects the existing retro).

**validate:**
- The `## Outcome validation YYYY-MM-DD` comment is posted with `Outcome`, `Signal source`, and `Rationale` fields all populated.
- Issue remains `CLOSED` (validate never reopens).
- For `partial` / `not-achieved`: the linked follow-up issue exists or the auto-file dedup correctly skipped (a still-open prior follow-up).
- Re-running validate on a different date with a changed outcome posts a *new* dated comment; the prior comment is left intact.

## Out of scope

- Posting epic-level rollups across multiple issues (epic status stays in the PR body per the `pull-request` skill).
- Mutating other issues, milestones, or projects.
- Editing or reformatting prior retros.
- Filing follow-up issues — list them in the **Follow-ups** section but file them via `backlog` as a separate step.

## Cross-references

- `backlog` — for *opening* / triaging issues. The retro skill is the closing bookend. Its Step C is what creates the parent-epic linkage that this skill reads in Step 6. Its auto-file mode is invoked by the **validate** operation V4 for `partial` / `not-achieved` outcomes.
- `objectives` — op H (cadence sweep) is the cross-objective analog of the **validate** operation. Both close cycles in the "Outcome tracking" cross-cutting capability.
- `epic-retrospective` — invoked manually after this skill prompts (Step 6) when the last open sub-issue of an epic closes.
- `pull-request` — invokes this skill for every `Closes #` / `Fixes #` reference before opening a PR.
