---
name: run-repo-qc
description: >
  Recurring repo-level QC audit. Executes the existing test suite, runs a
  structural-invariant sweep, and files non-trivial findings as GitHub
  issues via `backlog` auto-file mode. Reads `docs/qc-modifications.md`
  for repo-specific additional checks and known exceptions. Read-only —
  does NOT auto-fix code.
when_to_use: >
  Use to run repo QC ("run repo qc", "audit the repo", "qc the repo"), or
  as a pre-PR gate (see `pr-orchestrator`'s QC gate). Requires `tests/`
  to already exist — if it doesn't, use `create-repo-qc` first.
model: sonnet
allowed-tools: Bash(gh *), Bash(git *)
# persona: developer   — grouping metadata only; not read by Claude Code.
---

# Run Repo QC

You are about to perform a repo-level quality control audit. Your job is to **execute** existing tests + structural invariants, classify findings by severity, and file durable, deduplicated GitHub issues for non-trivial findings via `backlog` auto-file mode (per [ADR-0004](${CLAUDE_SKILL_DIR}/../_docs/ADR-0004-auto-filed-issue-protocol.md)).

This skill is **read-only**. It does NOT modify code. Findings → issues; fixes happen in caller PRs.

## Activation

Activate when the user asks to "run repo QC", "audit the repo", "qc the repo", or when invoked as a gate by `pr-orchestrator`'s QC gate.

## Inputs

- **Required**: a repo with `tests/` populated and a reachable test runner. If absent, surface a clear error and recommend `create-repo-qc`.
- **Optional**: invocation **mode**:
  - `interactive` (default) — full report at `docs/qc-reports/repo-qc_<timestamp>.md`.
  - `gate` — invoked from the PR-prep flow. Report at `.github/audit-reports/repo-qc_<timestamp>.md` (gitignored — must NOT dirty the working tree).
- **Optional**: scope filter (default: whole repo). Gate-mode callers may scope structural checks to changed files only.

## Steps

### Step 1 — Read the modifications overlay

Read `docs/qc-modifications.md` if present. Capture:

- **Additional checks** to run on top of the generic battery.
- **Known exceptions** — findings to suppress (do NOT re-flag).
- **Divergences** from the generic skill's default behavior.

If the overlay does NOT exist, proceed with generic checks only and warn in the report.

### Step 2 — Discovery & inventory

1. **Map the repo.** List top-level directories; identify entry points, helpers, specs, tests, docs.
2. **Catalog tests** in `tests/`. Identify which modules have tests and which do not (gap report).
3. **Read existing open issues** via `gh issue list --state open --limit 500 --json number,title,body,labels` for dedup (Step 6).

### Step 3 — Static analysis sweep (structural invariants)

Run the generic battery. **All checks are namespaced** as `<category>/<check-id>`. The generic skill ships a small default set — most repo-specific structural checks belong in the overlay's "Additional checks" section, not hardcoded here.

#### `tests/*` — test-suite health

- `tests/runner-clean` — the project's test runner exits 0 with no failures and no warnings.
- `tests/no-silent-skips` — no conditional-skip patterns that silently pass when required inputs are missing.
- `tests/coverage-gap` — every module has at least one corresponding test file.

#### `structure/*` — repo layout invariants

- `structure/gitignore-respected` — files matching `.gitignore` patterns are not actually tracked.
- Overlay-supplied checks (e.g. path-composition rules, required-arg conventions) append here under their own namespace.

#### `deps/*` — dependency hygiene

- `deps/no-secrets` — no API keys, tokens, or credentials in tracked files.
- Overlay-supplied banned-import lists append here.

#### `docs/*` — repo-doc hygiene

- `docs/changelog-shape` — `CHANGELOG.md` exists and contains an `[Unreleased]` block.
- `docs/required-docs-present` — overlay-supplied required-docs list exists (e.g. `README.md`, `docs/ROADMAP.md`).
- `docs/decisions-indexed` — every `docs/adr/ADR-*.md` is indexed in `docs/adr/README.md` (if the `adr` skill is in use).

#### Overlay-supplied checks

Append every check from `docs/qc-modifications.md`'s "Additional checks" section, under the overlay's own namespace.

### Step 4 — Test execution & failure analysis

Run the test suite and capture pass/fail status, error messages, warnings (treat as potential bugs), and execution time. For each failure, confirm it is a real bug (not test-infra flake), classify it (Step 5), and identify the responsible file (best-effort).

**This skill does NOT fix bugs.** Findings flow to issues; fixes happen in caller PRs.

### Step 5 — Classify findings

| Severity | Trigger | Label |
|---|---|---|
| CRITICAL | Test failure, crash, data corruption, security leak | `priority/blocker` |
| HIGH     | Structural-invariant violation, banned-import found, missing required test | `priority/high` |
| MEDIUM   | Warning, stale doc reference, broken local link, coverage gap | `priority/medium` |
| LOW      | Nit (formatting, style) | (no issue — report-only) |

If the overlay specifies a different mapping for one of its own checks, honor the overlay.

### Step 6 — Apply known-exception filter

For each finding, check the overlay's "Known exceptions" list. If it matches a `<check-id>` + path pair there, drop it (do NOT file or report). Note in the report tail: "N findings suppressed by overlay."

### Step 7 — File issues for non-trivial findings

For each remaining CRITICAL / HIGH / MEDIUM finding, invoke `backlog` auto-file mode with:

| Input | Value |
|---|---|
| `template` | `qc_finding` |
| `title` | `QC: <one-line description>` |
| `body` | Must include Severity / Category / Check-ID, file + line range, failure detail, suggested fix (best-effort), the QC report path, and the `<!-- autofile-id: run-repo-qc:<file-or-root>:<check-id> -->` marker on its own line. |
| `labels` | Exactly one Type label (`qc`) and exactly one Priority label per the severity mapping. |
| `dedup_id` | `run-repo-qc:<file-or-root>:<check-id>` (matches the body marker). |
| `parent_epic` | The epic the calling session is working under, or `standalone_reason` with a non-empty justification. One-or-the-other; never both, never neither. |

The dedup search (`gh issue list --search 'in:body "autofile-id: ..."'`) prevents duplicate filings on re-runs. Re-running the skill posts a "Still reproduces in run `<timestamp>`" comment instead of opening a duplicate.

### Step 8 — Generate the QC report

Write to `docs/qc-reports/repo-qc_<YYYY-MM-DD_HH-MM-SS>.md` (interactive) or `.github/audit-reports/repo-qc_<YYYY-MM-DD_HH-MM-SS>.md` (gate — path is gitignored; verify with `git check-ignore` if uncertain).

**Critical**: in gate mode the report MUST land in a gitignored path. If it would dirty the working tree (`git status --porcelain` non-empty), abort and surface the error.

Report structure: see [`reference.md`](${CLAUDE_SKILL_DIR}/reference.md).

### Step 9 — Set exit signal

- `0` — CLEAN, no CRITICAL/HIGH findings
- `1` — FINDINGS (HIGH/MEDIUM only; advisory)
- `2` — BLOCKER (CRITICAL findings; PR-prep callers refuse to proceed)

## Reference

Report structure, outputs, success criteria, check-ID inventory, and cross-references: [`reference.md`](${CLAUDE_SKILL_DIR}/reference.md)
