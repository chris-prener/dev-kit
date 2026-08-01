---
name: bootstrap-repo
description: >
  Audits and backfills the small set of canonical files dev-kit's other
  skills expect to find in a repo — CHANGELOG.md, docs/ROADMAP.md,
  docs/OBJECTIVES.md, docs/adr/, .github/ scaffolding, and similar.
  Files dev-kit ships a real canonical copy of (LABELS.md, issue/PR
  templates, .gitignore, CODE_OF_CONDUCT, CONTRIBUTING) are vendored
  verbatim from `assets/github/`; everything else gets a minimal stub.
  One-time create-only — no ongoing sync back to the source.
when_to_use: >
  Use right after installing dev-kit in a new repo ("bootstrap this
  repo", "what canonical files am I missing", "backfill repo
  scaffolding", "vendor the GitHub templates"), or any time a skill
  complains that a file it expects (docs/ROADMAP.md, docs/adr/README.md,
  .github/LABELS.md, …) doesn't exist yet. Not for scaffolding a new
  dataset, package, or app skeleton — that's the project's own tooling,
  not dev-kit's.
model: opus
allowed-tools: Bash(ls *), Bash(mkdir *), Bash(git *)
# persona: developer   — grouping metadata only; not read by Claude Code.
---

# Bootstrap Repo

Audits or backfills the canonical file set that dev-kit's other skills lean on. There's no central registry and no cross-repo sync here — each dev-kit skill just expects a handful of files to exist (or degrades gracefully if they don't), and this skill is the single place that checks for all of them at once instead of discovering the gaps one skill-failure at a time.

A handful of those files aren't just "expected to exist" — dev-kit ships a real, maintained copy of them under `${CLAUDE_SKILL_DIR}/../../assets/github/` (LABELS.md, the ISSUE_TEMPLATE set, PULL_REQUEST_TEMPLATE.md, CODE_OF_CONDUCT.md, CONTRIBUTING.md, and a baseline `.gitignore`). For those, `backfill` copies the real content in, not a one-line stub. This is still one-time and create-only: it never overwrites, and it never re-syncs a file the target repo has since customized.

## Activation

Activate this skill when the user asks to:

- Audit a repo for missing dev-kit scaffolding
- Backfill missing canonical files after installing dev-kit
- Understand what files a given skill expects before it errors on a missing one

## Inputs

- Target repo path (defaults to the current directory).

## Canonical file inventory

Two fill strategies. **Stub** — a minimal starter (heading + one sentence); the owning skill fills in real content on first use. **Vendor** — the real file, copied verbatim from `${CLAUDE_SKILL_DIR}/../../assets/github/<name>`; there's no "real content to fill in later" for a label vocabulary or a code of conduct, so a stub would just be wrong.

| Path | Used by | Strategy | If missing |
|---|---|---|---|
| `CHANGELOG.md` (with an `[Unreleased]` section) | `pr-gate-changelog`, `run-repo-qc` | Stub | Gate degrades to "no entry found, please draft one" every time |
| `docs/ROADMAP.md` | `roadmap`, `epic-dependency` | Stub | Those skills have nowhere to render output |
| `docs/OBJECTIVES.md` | `objectives` | Stub | Skill has nowhere to file OKRs |
| `docs/adr/README.md` + `docs/adr/_template.md` | `adr`, `epic` | Stub | `adr` creates these lazily on first file; this skill can pre-create them |
| `docs/GLOSSARY.md` | `glossary`, `architecture-overview` (optional) | Stub | Anchor checks in `architecture-overview` audit are skipped, not failed |
| `docs/ARCHITECTURE.md` | `architecture-overview` | Stub | Skill has nothing to refresh |
| `docs/qc-modifications.md` + `tests/` | `run-repo-qc` | — | Use `create-repo-qc` to scaffold these instead — not this skill's job |
| `.github/LABELS.md` | most issue-filing skills | Vendor | They fall back to the baseline in `_partials/label-vocabulary.md`, but the repo has no editable local copy to specialize |
| `.github/ISSUE_TEMPLATE/*.md` (6 files) | `backlog`'s auto-file mode (`template` must match a filename here); `dor-preflight.md`'s per-template heading matrix checks bodies against these | Vendor | GitHub falls back to a blank issue form; auto-file mode has no template to validate `template` against |
| `.github/PULL_REQUEST_TEMPLATE.md` | repo hygiene; no skill parses this | Vendor | GitHub falls back to a blank PR body |
| `.github/CODE_OF_CONDUCT.md` | repo hygiene | Vendor | No stated community standard |
| `.github/CONTRIBUTING.md` | repo hygiene | Vendor (with placeholder substitution) | No contribution guidance for outside contributors |
| `.gitignore` | every gate skill needs the `.github/audit-reports/` entry at minimum | Vendor if absent; patch if present | Gate reports would dirty the working tree; if the repo already has a `.gitignore`, just append the missing entry rather than replacing the file |

Not every repo needs every row — a repo with no epics doesn't need `docs/ROADMAP.md`. Treat this table as "here's what to check for, given which skills you actually use," not a mandatory checklist.

## Steps

### Op 1: `audit`

1. Check each row in the inventory for presence. For `CHANGELOG.md`, also confirm an `[Unreleased]` heading exists.
2. Check `.gitignore` for an entry covering `.github/audit-reports/`.
3. Print a structured report: present / missing, grouped by row. No mutations.

### Op 2: `backfill`

1. Run `audit` internally to find the gaps.
2. For each missing **Stub** row, show what will be created (path + a short description of the starter content) and prompt: `Create <path>? [y/N]` — default No. On confirm, write the minimal starter.
3. For each missing **Vendor** row, show the source (`assets/github/<name>`) and prompt: `Vendor <path> from dev-kit? [y/N]` — default No. On confirm, copy the file verbatim.
   - `.github/CONTRIBUTING.md` needs two placeholders filled: `{{PROJECT_NAME}}` (repo directory name, or ask) and `{{OWNER}}/{{REPO}}` (parse from `git remote get-url origin`; if no remote, ask or leave the placeholder and flag it in the summary).
   - `.gitignore`: if the file doesn't exist at all, vendor `assets/github/gitignore` wholesale. If it already exists, don't replace it — just check for the `.github/audit-reports/` line and prompt to append it if missing.
4. Print a summary: files created (stub), files vendored, files skipped.

**Safeguard**: never writes without explicit `[y/N]` confirmation per file. Vendoring never overwrites an existing file at the target path — if `.github/LABELS.md` (etc.) already exists, it's left alone; re-vendoring an updated copy is a manual, deliberate action outside this skill.

## Outputs

- **audit**: a structured present/missing report. No file writes.
- **backfill**: stub files created and vendor files copied, each with operator confirmation, plus a summary.

## Success criteria

- `audit` accurately reflects what's on disk — no false positives or negatives.
- `backfill` never overwrites an existing file (only creates what's missing).
- No file is written without explicit per-file confirmation.

## Out of scope

- **Ongoing sync.** Vendoring here is one-shot and create-only — if `assets/github/LABELS.md` changes upstream in dev-kit, this skill does not detect drift or re-vendor it into repos that already have a copy. That's a manual, deliberate action. This includes the 2026-08 `## `-heading rewrite of the `ISSUE_TEMPLATE` set (#23): repos already bootstrapped before that change keep their old bold-prompt templates and will fail `dor-preflight.md`'s heading check on every filed issue until someone manually re-vendors the six files. No automated migration path exists; re-vendoring is the same manual action as any other post-bootstrap drift.
- **Vendoring anything outside `assets/github/`.** This skill's vendor rows are exactly the files in dev-kit's `assets/github/` directory — it's not a general file-sync tool.
- **Scaffolding QC infrastructure** (`tests/`, `docs/qc-modifications.md`) — that's `create-repo-qc`.
- **Project/domain scaffolding** (a new dataset, package, or app skeleton) — outside dev-kit's scope; use the project's own tooling.
- **Populating the stub files with real content** — this skill creates the empty shell for the Stub rows; the owning skill (`roadmap`, `objectives`, `adr`, …) fills it in on first real use.

## Cross-references

- `create-repo-qc` — the QC-specific counterpart to this skill's file rows.
- `_partials/label-vocabulary.md` — the label baseline skills fall back to when `.github/LABELS.md` is absent; `assets/github/LABELS.md` is the vendorable file version of the same baseline — keep them in sync when one changes.
- `adr`, `roadmap`, `objectives`, `glossary`, `architecture-overview` — the skills that own each backfilled Stub doc going forward.
- `assets/github/` — the vendor source directory: `LABELS.md`, `gitignore`, `PULL_REQUEST_TEMPLATE.md`, `CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`, `ISSUE_TEMPLATE/*.md`.
