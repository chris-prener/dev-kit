# dev-kit

## Commits

When a PR closes multiple issues, land each issue's changes as its own
commit — never squash unrelated issues into one commit. Reference the
issue number in the commit message body. This keeps history reviewable
per-issue and mirrors how `pr-orchestrator` inline-closes each
referenced issue individually.

Changes that don't belong to any single issue (e.g. this file) get
their own commit too, rather than riding along with an issue's commit.
