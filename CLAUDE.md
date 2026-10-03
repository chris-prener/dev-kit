# dev-kit

## Commits

When a PR closes multiple issues, land each issue's changes as its own
commit — never squash unrelated issues into one commit. Reference the
issue number in the commit message body. This keeps history reviewable
per-issue and mirrors how `pr-orchestrator` inline-closes each
referenced issue individually.

Changes that don't belong to any single issue (e.g. this file) get
their own commit too, rather than riding along with an issue's commit.

## Pre-PR QC checklist

Read by `pr-gate-qc` sub-step c (`dev-kit/skills/pr-orchestrator/reference/gate-qc.md`).
Each check names the gate input it uses; a failed check is a FINDING
unless marked **BLOCKER**.

- **One commit per closed issue.** For each issue in `issue_refs`
  (the PR's `Closes` / `Fixes` / `Resolves` set), `git log <base>..HEAD`
  has at least one commit whose message references `#N`. When
  `issue_refs` has more than one issue, no single commit may reference
  all of them. Skip when `issue_refs` has fewer than two entries.
