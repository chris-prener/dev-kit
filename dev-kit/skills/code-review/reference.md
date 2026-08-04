# Code Review — reference

Contract and QA detail for the `code-review` skill. `SKILL.md` holds the procedure and the review prompt; this file holds the report structure, the auto-file contract, outputs, success criteria, the check-ID inventory, and cross-references.

## Review comment structure (the report file)

```markdown
# AI code review (rubber-duck pass)

_Reviewed: <ISO-date> · Branch: <branch> · Head SHA: `<sha>` · Mode: <full | minimal>_
_Diff: <N> files, <M> lines added, <K> lines removed_
_Issues: <Closes #NN, #MM>_
_Verdict: **<CLEAN | ADVISORY | BLOCKED>**_

## Blockers (must address before PR)
<filtered to BLOCKER, or "None.">

## Important (should address; auto-filed)
<filtered to HIGH, or "None.">

## Medium (advisory; auto-filed)
<filtered to MEDIUM, or "None.">

## Nits / Questions (informational only)
<filtered to NIT/QUESTION, or "None.">

## Verification I ran
- [x] Diff fully read (N lines / M files)
- [<x|>] AC traceability against issue body
- [<x|>] ADRs surfaced and cross-referenced
- [<x|>] No secrets in diff (pattern grep)
- [<x|>] Repo invariants checked

## Issues filed
<bullet list of issue URLs for each non-trivial auto-filed finding, or "None — review was CLEAN.">

## Issues already tracked (dedup)
<bullet list for findings whose autofile-id markers matched existing open issues, or "None.">
```

The same structure is used by `--mode=review` (report at `.github/audit-reports/code-review_<ts>.md`) and `--mode=self-review`.

## Auto-file invocation contract

For each BLOCKER/HIGH/MEDIUM finding, invoke `backlog` auto-file mode:

| Input | Value |
|---|---|
| `template` | `bug_report` for BLOCKER; `tech_debt` for HIGH/MEDIUM. |
| `title` | `[Code review] <path>: <one-line summary>` (human-readable; not the dedup key). |
| `body` | Template-conformant body. MUST include the `<!-- autofile-id: code-review:<file-path>:<check-id> -->` marker on its own line, and an `## Acceptance criteria` section. |
| `labels` | Exactly one Type label (`bug` for BLOCKER, `tech-debt` for HIGH/MEDIUM) and exactly one Priority label per the severity mapping below. |
| `dedup_id` | `code-review:<file-path>:<check-id>` (matches the body marker). |
| `parent_epic` | The epic the PR is working under, or `standalone_reason` with a non-empty justification. One-or-the-other; never both, never neither. |

**Severity → Priority mapping:**

| Review severity | Priority label | Auto-filed? |
|---|---|---|
| BLOCKER | `priority/blocker` | yes |
| HIGH | `priority/high` | yes |
| MEDIUM | `priority/medium` | yes |
| NIT / QUESTION | — | **no** — surfaced in report only |

On any backlog auto-file error, this skill aborts with exit signal `2`; the operator addresses it before re-invoking. The primary report file is already written, so partial state is recoverable.

## Outputs

- A code-review report at `.github/audit-reports/code-review_<timestamp>.md` (gitignored).
- Zero or more auto-filed GitHub issues with the `<!-- autofile-id: code-review:<path>:<check-id> -->` body marker.
- Zero or more "Still reproduces" comments on existing dedup'd issues.
- A structured exit signal (`0` / `1` / `2`) for programmatic callers.
- A one-paragraph chat summary including the verdict and the filed-issues list.

## Success criteria

- The subagent was invoked exactly once per `review` invocation (never zero, never twice — re-runs on the same SHA dedup via marker).
- Every finding has a severity tag. NIT/QUESTION findings appear in the report but file zero issues.
- Every BLOCKER/HIGH/MEDIUM finding has either a file:line anchor or an explicit "(no anchor)" note.
- The report exists and uses the canonical structure.
- The working tree is unchanged (`git status --porcelain` empty) after the skill exits — gate mode must not dirty the tree.
- Auto-filed issues all carry the `<!-- autofile-id: ... -->` body marker.
- In `--minimal` mode, the operator confirmation was explicit; the report records the bypass justification.

## Out of scope

- **Merging the PR.** Happens on github.com under branch-protection rules.
- **Posting to the PR conversation as a GitHub comment.** The report is a local artifact.
- **Auto-fixing findings.** Read-only by design (parallels `run-repo-qc`).
- **Style / formatting / lint findings.** Out of scope; lint is a separate concern.
- **Reviewing PRs across repos.** Single-repo only.

## Check-ID inventory

| Check-ID | Severity | Scope | Notes |
|---|---|---|---|
| `code-review/bug` | BLOCKER | per-finding | Logic error, off-by-one, wrong assumption. |
| `code-review/edge-case-missed` | BLOCKER or HIGH | per-finding | Severity by impact (corruption → BLOCKER; advisory → HIGH). |
| `code-review/security` | BLOCKER | per-finding | Secrets, injection, unsafe shell, untrusted-input handling. |
| `code-review/invariant-violation` | BLOCKER | per-finding | Violates a stated repo invariant. |
| `code-review/design-flaw` | HIGH | per-finding | Works today; will hurt at scale. |
| `code-review/missing-test` | HIGH or MEDIUM | per-change | HIGH if the change is non-trivial (branch logic, error path). |
| `code-review/missing-adr` | HIGH | per-decision | Architectural shift made silently; needs an `adr` follow-up. |
| `code-review/doc-staleness-in-diff` | MEDIUM | per-file | Touched file's docstring / preamble / cross-reference is now wrong. |
| `code-review/naming-masks-correctness` | MEDIUM | per-finding | Variable / function name is misleading enough to invite future bugs. |

NITs and QUESTIONs are not in the inventory because they don't auto-file. Adding new severity-eligible check-IDs is non-breaking; renaming them breaks dedup against historical issues.

## Cross-references

- `pr-orchestrator` — its code-review gate (`reference/gate-code-review.md`) invokes this skill as the mandatory pre-PR gate.
- `backlog` — auto-file mode for non-trivial findings.
- `implementation-plan` — source of the plan-comment context, when present.
