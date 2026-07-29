# Run Repo QC — reference

Contract and QA detail for the `run-repo-qc` skill. `SKILL.md` holds the procedure; this file holds the report structure, outputs, success criteria, check-ID inventory, and cross-references.

## Report structure

```markdown
# Repo QC Report

**Date:** YYYY-MM-DD HH:MM:SS
**Mode:** interactive | gate
**Scope:** whole-repo | changed (with file list)
**Overlay:** present | absent

## Executive summary

- Modules audited: N
- Tests run: N (N pass, N fail, N warning, N skipped)
- Structural checks run: N (N pass, N fail)
- Findings filed: N (N CRITICAL, N HIGH, N MEDIUM)
- Findings suppressed by overlay: N
- Overall status: CLEAN | FINDINGS | BLOCKER

## Findings

(One subsection per finding with severity, check-ID, file, evidence, filed-issue link.)

## Suppressed by overlay

(Brief list; refer to overlay for rationale.)

## Test execution log

(Test runner output, abbreviated.)

## Issues filed

| # | Severity | Check-ID | URL |
|---|---|---|---|

## Issues already tracked (dedup)

| # | Check-ID | URL |
|---|---|---|
```

## Outputs

- A QC report at the mode-appropriate path.
- Zero or more auto-filed GitHub issues with the body marker.
- Zero or more "Still reproduces" comments on existing dedup'd issues.
- A structured exit signal for programmatic callers.

## Success criteria

- All tests in `tests/` were executed (no silent skips).
- Every check in the static-analysis battery + overlay was attempted.
- Findings classified per the severity table; no LOW findings file issues.
- Every filed issue has an `<!-- autofile-id: ... -->` body marker.
- Re-running the skill on the same state files zero new issues (dedup works).
- In gate mode, the working tree is unchanged (`git status --porcelain` empty) after the skill exits.

## Out of scope

- **Auto-fixing bugs.** Read-only gate. The caller handles fixes.
- **Writing new tests.** `create-repo-qc` scaffolds; devs extend incrementally. This skill only runs what exists.
- **CI integration.** Manual or PR-prep-skill invocation only.
- **Modifying the overlay.** This skill READS `docs/qc-modifications.md`; updates are manual.

## Check-ID inventory

| Check-ID | Severity | Scope | Notes |
|---|---|---|---|
| `tests/runner-clean` | CRITICAL | whole-repo | Exit code + zero failures. |
| `tests/no-silent-skips` | HIGH | whole-repo | Pattern grep. |
| `tests/coverage-gap` | MEDIUM | per-module | Module present without a matching test file. |
| `structure/gitignore-respected` | MEDIUM | whole-repo | `git ls-files --error-unmatch` cross-check. |
| `deps/no-secrets` | CRITICAL | whole-repo | Pattern-based heuristic. |
| `docs/changelog-shape` | MEDIUM | repo-root | `[Unreleased]` block present. |
| `docs/required-docs-present` | MEDIUM | repo-root | Overlay supplies the list. |
| `docs/decisions-indexed` | MEDIUM | `docs/adr/` | Every ADR file has a row in the index, if `adr` is in use. |
| `<overlay-namespace>/<check-id>` | varies | varies | Defined in `docs/qc-modifications.md`. |

Renames break dedup against historical issues — add freely, but never silently rename.

## Cross-references

- `create-repo-qc` — bootstraps the infrastructure this skill executes against.
- `backlog` — auto-file mode, called per finding.
- `docs/qc-modifications.md` — repo-specific overlay (additional checks, known exceptions, divergences).
- [ADR-0004](${CLAUDE_SKILL_DIR}/../_docs/ADR-0004-auto-filed-issue-protocol.md) — auto-file contract.
- `pr-gate-qc` — invokes this skill in `gate` mode as its first sub-step.
