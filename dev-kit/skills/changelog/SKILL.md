---
name: changelog-curator
description: >
  Maintains CHANGELOG.md in Keep a Changelog 1.1.0 format. Adds entries
  under [Unreleased], cuts releases, audits closed PRs without entries,
  and best-effort backfills.
when_to_use: >
  Use to add a changelog entry, cut a release, audit changelog coverage
  against recently merged PRs, or backfill entries for a batch of past
  PRs. Not for internal-only changes with no user-facing surface (skip
  via the `no-changelog` opt-out instead) or per-project changelog
  aggregation across repos.
model: sonnet
allowed-tools: Bash(gh *)
# persona: writer   — grouping metadata only; not read by Claude Code.
#   Filter all skills by this comment to regenerate each persona's owned-stable list.
---

# Changelog Curator

The changelog is the user-facing release narrative — what someone pulling this repo needs to know about between releases. It is distinct from commit history (dev-facing) and ADRs (architecture-facing).

## Operations

1. **Add** an entry under `## [Unreleased]` → Step B.
2. **Cut a release** — rename `[Unreleased]` to `[X.Y.Z] — YYYY-MM-DD` and open a fresh `[Unreleased]` → Step C.
3. **Audit** — list merged PRs since the last cut without a changelog entry → Step D.
4. **Backfill** — draft entries for a list of past PR numbers → Step E.

## Activation

- `pr-gate-changelog` invokes the add operation when a PR is missing an entry.
- The user is cutting a release, wants a coverage check, or needs a retroactive backfill.

**Not for**: internal-only changes with no user-facing surface (use the `no-changelog` opt-out on the PR instead, per [`_partials/label-vocabulary.md`](${CLAUDE_SKILL_DIR}/../_partials/label-vocabulary.md)).

## Inputs

- **Add**: category (`Added` / `Changed` / `Deprecated` / `Removed` / `Fixed` / `Security`); one-sentence user-facing description; issue or PR reference.
- **Cut-release**: target version (`X.Y.Z`); release date (defaults to today).
- **Audit**: optional `since` date; otherwise the date of the previous `[X.Y.Z]` block.
- **Backfill**: list of PR numbers; the skill drafts entries for the operator to review.

## Steps

### A. Determine the operation

add / cut-release / audit / backfill.

### B. Add an entry

1. Open `CHANGELOG.md`. Confirm the `## [Unreleased]` block exists at the top.
2. Find the matching category subsection (Added / Changed / Deprecated / Removed / Fixed / Security).
3. Append a bullet: `- <description>. (#NN)` where `#NN` is the PR or issue number.
4. Keep entries short and user-facing — a retro on the closed issue carries the long-form narrative.
5. If the category subsection currently reads `_None._`, replace that with the bullet rather than appending below it.

### C. Cut a release

1. Verify `## [Unreleased]` has at least one non-empty category. Halt if it's all `_None._` (nothing to release).
2. Rename `## [Unreleased]` → `## [X.Y.Z] — YYYY-MM-DD`.
3. Insert a fresh `## [Unreleased]` block above it, with all 6 categories set to `_None._`.
4. Cross-link from `docs/ROADMAP.md` if relevant — the Recently Shipped horizon may already reflect this via `epic-retrospective`.

### D. Audit

1. Determine the cutoff date: either user-supplied or the date of the most recent `[X.Y.Z]` block.
2. Query merged PRs since that date: `gh pr list --state merged --search "merged:>=<date>" --json number,title,url`.
3. For each, check whether `CHANGELOG.md`'s `[Unreleased]` block already references the PR number.
4. Output a markdown report listing PRs without entries.

### E. Backfill

1. For each supplied PR number, fetch title, body, and label set.
2. Heuristically map to a category (presence of `bug`/`fix`/`Fixes #` → Fixed; presence of `removes`/`drops` → Removed; default → Changed).
3. Draft a one-line entry per PR.
4. **Surface for human review** before writing — backfills are easy to get wrong.

## Outputs

- Edited `CHANGELOG.md`.
- Audit report (markdown text).
- Draft backfill entries (markdown text, for review).

## Success criteria

- Add: target category contains the new entry with a PR/issue reference.
- Cut-release: a new `[X.Y.Z] — YYYY-MM-DD` block exists; a fresh empty `[Unreleased]` sits above it.
- Audit: report enumerates merged PRs since cutoff without `[Unreleased]` references.
- Backfill: every supplied PR has a draft entry surfaced for review.

## Out of scope

- Auto-generating changelog entries from commits without human review.
- Cross-repo changelog aggregation.
- HTML / published changelog rendering — markdown only.
- Auto-bumping version numbers — the operator decides the version; this skill records it.

## Cross-references

- `pr-gate-changelog` — invokes this skill's add operation to enforce the PR-creation changelog gate.
- `roadmap` — the Recently Shipped horizon often correlates with cut-release entries.
- `${CLAUDE_PROJECT_DIR}/.github/LABELS.md` — `no-changelog` Meta label for opt-out.
- `${CLAUDE_PROJECT_DIR}/CONTRIBUTING.md` — "How to open a PR" section, if present, should name the changelog requirement.
