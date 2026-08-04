---
name: documentation-audit-changes
description: >
  PR-scoped, read-only documentation freshness audit. Given a branch's
  changed files relative to its base, identifies docs that are stale
  relative to the changes — signature drift, README references to
  renamed files, broken local links. Files non-trivial findings via
  `backlog` auto-file mode.
when_to_use: >
  Use for a doc-staleness audit scoped to a branch's changed files.
  Trigger phrases: "audit doc changes", "audit-changes", "doc staleness
  audit", "pr doc audit". Not for full-repo doc passes (`documentation`),
  orchestrating multiple docs skills (`documentation-suite`), or
  docs-tree structure / placement / archival / orphan audits
  (`docs-organization`).
model: sonnet
allowed-tools: Bash(gh *), Bash(git *)
# persona: writer   — grouping metadata only; not read by Claude Code.
---

# Documentation Audit-Changes

You are about to audit a PR's docs for staleness — NOT to write or regenerate them. This skill is **read-only**. Findings become issues; fixes happen in caller PRs.

## Activation

Activate when the user (or `pr-orchestrator`, in `gate` mode) asks for a doc-staleness audit scoped to a branch's file list.

**Not for**: full-repo doc passes (`documentation`), orchestrating multiple docs skills (`documentation-suite`), or docs-tree structure/placement/archival/orphan audits (`docs-organization`).

## Inputs

- **Required**: a base ref (defaults to the repo's default branch via `gh repo view --json defaultBranchRef`).
- **Required**: working tree on the head branch (or a passed file list).
- **Optional**: invocation **mode**:
  - `interactive` (default) — full report at `docs/qc-reports/doc-audit-changes_<timestamp>.md`.
  - `gate` — invoked from a PR-prep flow. Report at `.github/audit-reports/doc-audit-changes_<timestamp>.md` (gitignored; must NOT dirty the working tree). Chat-surfaced summary only.

## Steps

### Step 1 — Compute the changed-files list

```bash
git diff --name-only <base>..HEAD
git diff --name-only --diff-filter=R <base>..HEAD  # renames
git diff --name-only --diff-filter=D <base>..HEAD  # deletions
```

Bucket changed files by kind:

- **Source files** — library/module code in whatever language(s) the repo uses.
- **Skills** — `.claude/skills/*/SKILL.md` (project-local skills), dev-kit skill files if this repo is dev-kit itself.
- **READMEs** — any `README.md`.
- **Docs** — anything under `docs/`.
- **Tests** — the repo's test directory.
- **CHANGELOG / CLAUDE.md** — repo-root governance docs.
- **Renamed/deleted** — special-case for cross-doc reference checks.

### Step 2 — Build owning-doc map

For each changed code file, identify the doc(s) that should reflect it:

| Code change | Owning doc(s) |
|---|---|
| A library/module function's signature changed | its own docstring block; any doc that mentions the function by name; `README.md` if listed in a function/API table |
| `docs/adr/*.md` added | `docs/adr/README.md` index row |
| File renamed | every link to the old path under `docs/`, `README.md`, `CLAUDE.md`, `.claude/skills/` |
| File deleted | every link to the deleted path |

### Step 3 — Run the staleness checks

Each check is namespaced as `<category>/<check-id>`.

#### `docstring/*` — function-signature freshness

- `docstring/signature-drift` — for each modified function (heuristic: its signature line changed), the docstring immediately above it should mention every named parameter. Missing or extra parameter docs → MEDIUM finding.
- `docstring/missing-block` — an exported/public helper modified that has no docstring at all → MEDIUM (HIGH if the helper is part of the repo's documented public surface).

#### `links/*` — local-link integrity

- `links/broken-local` — every Markdown `[label](relative/path.md)` link in changed/affected docs resolves to an existing file. Renamed/deleted source paths must not appear as broken targets in unchanged docs either (catches reverse-staleness) → MEDIUM.
- `links/anchor-broken` — `[label](path.md#anchor)` anchor resolves to an existing heading in the target file → MEDIUM.

#### `crossref/*` — skill ↔ doc ↔ CLAUDE.md consistency

- `crossref/skill-not-cited` — a newly added project-local skill (`.claude/skills/*/SKILL.md`) isn't referenced from `CLAUDE.md`, if that file exists and maintains a skill list → MEDIUM.
- `crossref/adr-not-indexed` — an added ADR file isn't indexed in `docs/adr/README.md` → HIGH.

#### `governance/*` — repo-root docs

- `governance/changelog-missing` — code changes are present but no `[Unreleased]` entry references any changed file or a `Closes #N` from the branch's commit messages → HIGH. (`pr-orchestrator`'s changelog gate runs a parallel check; this is the doc-side view and may overlap — if both fire, treat as one finding.)

### Step 4 — Classify, suppress, file

For each non-suppressed HIGH/MEDIUM finding, invoke `backlog` auto-file mode. The shape mirrors `code-review` and `run-repo-qc` — same input table, same severity → priority mapping. Only the skill-specific `template`, `dedup_id`, Type label, and `parent_epic`/`standalone_reason` rows differ.

**Auto-file invocation contract:**

| Input | Value |
|---|---|
| `template` | `tech_debt` (doc-staleness is paydown work; the only template this skill emits). |
| `title` | `Doc audit: <one-line description> in <path>`. |
| `body` | Template-conformant body. MUST include Category / Check-ID, affected files (with line ranges where applicable), detected drift evidence (git diff excerpt or grep output), suggested fix. MUST include the `<!-- autofile-id: documentation-audit-changes:<path>:<check-id> -->` marker on its own line — `<path>` is the **affected file's path**, not the skill's name, so dedup doesn't over-collapse unrelated findings. |
| `labels` | Exactly one Type label (`documentation`) and exactly one Priority label per the mapping below. |
| `dedup_id` | `documentation-audit-changes:<path>:<check-id>` (matches the body marker). |
| `parent_epic` | The epic the branch is working under, or `standalone_reason` with a non-empty justification. One-or-the-other; never both, never neither. |

**Severity → Priority mapping:**

| Doc-audit severity | Priority label | Auto-filed? |
|---|---|---|
| HIGH | `priority/high` | yes |
| MEDIUM | `priority/medium` | yes |
| LOW | — | **no** — surfaced in report only |

(No BLOCKER band for documentation findings — doc staleness never blocks a release outright; it always degrades to HIGH at most.)

### Step 5 — Generate the report

Mode-dependent path (see Inputs). Structure:

```markdown
# Documentation Audit-Changes Report

**Date:** YYYY-MM-DD HH:MM:SS
**Mode:** interactive | gate
**Base:** <base ref>
**Head:** <head ref>
**Files changed:** N

## Executive summary

- Owning-doc relationships analyzed: N
- Checks run: N (N pass, N finding)
- Findings filed: N (N HIGH, N MEDIUM)

## Findings

(One section per finding with category, check-ID, evidence, suggested-fix, filed-issue link.)

## Issues filed

| # | Severity | Check-ID | Path | URL |

## Issues already tracked (dedup)

| # | Check-ID | Path | URL |
```

In gate mode, ensure the report path is gitignored (`git check-ignore`) before writing; abort if it would dirty the working tree.

### Step 6 — Set exit signal

- `0` — CLEAN
- `1` — FINDINGS (HIGH/MEDIUM only; advisory)
- `2` — reserved for symmetry with `run-repo-qc`; never returned by this skill (no BLOCKER band for doc audits)

## Outputs

- A report at the mode-appropriate path.
- Zero or more auto-filed GitHub issues with the path-aware body marker.
- Zero or more "Still reproduces" comments on existing dedup'd issues.
- A structured exit signal.

## Success criteria

- Every changed file was bucketed and its owning-doc relationships analyzed.
- Every check namespaced as `<category>/<check-id>` was attempted.
- Findings classified per the severity table; no LOW findings file issues.
- Every filed issue has the path-aware `<!-- autofile-id: ... -->` body marker.
- Re-running on the same state files zero new issues.
- In gate mode, the working tree is unchanged after exit.

## Out of scope

- **Writing or regenerating docs.** That's `documentation`, `readme`, `walkthrough`, or `documentation-suite`.
- **Repo-wide audits.** This skill is PR-scoped (changed files only). For full-repo doc audits, run `documentation`.
- **Docstring generation.** Stale docstring → finding only; a follow-up regenerates it.
- **CI integration.**

## Cross-references

- `documentation` — full-repo doc pass; complementary, not overlapping.
- `documentation-suite` — orchestrator; may add this skill as a child.
- `readme`, `walkthrough` — sibling docs skills.
- `backlog` — auto-file mode.
- `run-repo-qc` — sister gate-mode read-only audit.
- `pr-orchestrator` — invokes this skill in `gate` mode.
- `pr-orchestrator`'s changelog gate — parallel changelog check; see `governance/changelog-missing` above.

## Check-ID inventory

| Check-ID | Severity | Notes |
|---|---|---|
| `docstring/signature-drift` | MEDIUM | Documented params match the function signature. |
| `docstring/missing-block` | MEDIUM (HIGH for documented public surface) | Exported/public helpers must have a docstring. |
| `links/broken-local` | MEDIUM | Local Markdown links resolve. |
| `links/anchor-broken` | MEDIUM | Local anchors resolve. |
| `crossref/skill-not-cited` | MEDIUM | New project-local skill referenced from `CLAUDE.md`, if that file maintains a skill list. |
| `crossref/adr-not-indexed` | HIGH | New ADR indexed in `docs/adr/README.md`. |
| `governance/changelog-missing` | HIGH | `[Unreleased]` entry exists for the branch's changes. |

Renames break dedup against historical issues — add freely, never silently rename.
