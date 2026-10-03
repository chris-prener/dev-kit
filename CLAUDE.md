# dev-kit

## Commits

When a PR closes multiple issues, land each issue's changes as its own
commit — never squash unrelated issues into one commit. Reference the
issue number in the commit message body. This keeps history reviewable
per-issue and mirrors how `pr-orchestrator` inline-closes each
referenced issue individually.

Changes that don't belong to any single issue (e.g. this file) get
their own commit too, rather than riding along with an issue's commit.

## Repo invariants

Rules this repo's own audit (Epic B, #16) showed were being broken because
nobody had written them down. `code-review` checks diffs against this list.

- **No duplicated content across sibling skills.** Shared content goes in
  a partial under `dev-kit/skills/_partials/`; skills link to it. (Origin:
  #6 ruff config, #10 inline-comment standards, #12 lintr config.)
- **Anything a skill names must exist.** Every template, partial, skill,
  and file path a `SKILL.md` references resolves to a real file in the
  repo. (Origin: #2, `qc_finding.md` referenced by six files, never
  vendored.)
- **Skill renames sweep cross-references.** Renaming a skill updates every
  reference to the old name across skills, docs, and output styles in the
  same change. (Origin: #1, `pull-request` → `pr-orchestrator` left nine
  stale references.)
- **`LABELS.md` and the label partial stay in sync.**
  `dev-kit/assets/github/LABELS.md` and
  `dev-kit/skills/_partials/label-vocabulary.md` describe one baseline;
  change both together.
- **ADRs supersede, never edit.** A changed decision gets a new ADR that
  supersedes the old one (the `adr` skill's rule).
- **Every `SKILL.md` carries a `# persona:` frontmatter comment**, except
  deliberately ungated skills like `session-start`.

## Pre-PR QC checklist

Read by `pr-gate-qc` sub-step c (`dev-kit/skills/pr-orchestrator/reference/gate-qc.md`).
Each check names the gate input it uses; a failed check is a FINDING
unless marked **BLOCKER**.

- **One commit per closed issue.** For each issue in `issue_refs`
  (the PR's `Closes` / `Fixes` / `Resolves` set), `git log <base>..HEAD`
  has at least one commit whose message references `#N`. When
  `issue_refs` has more than one issue, no single commit may reference
  all of them. Skip when `issue_refs` has fewer than two entries.
- **Label baseline in sync.** If `diff_context.files_changed` includes
  `dev-kit/assets/github/LABELS.md` or
  `dev-kit/skills/_partials/label-vocabulary.md`, it includes both.
- **No dangling references.** Every skill, partial, template, or file path
  a changed `SKILL.md` names exists (this is the repo-invariant check that
  sub-step d's cross-reference pass does not cover for partials and
  templates). **BLOCKER.**
