---
name: create-repo-qc
description: >
  One-time scaffolding skill for repo-level QC infrastructure. Creates the
  `tests/` directory, a testing-framework stub, and a
  `docs/qc-modifications.md` overlay. After this runs, `run-repo-qc` can
  execute the audit on every subsequent invocation.
when_to_use: >
  Use to bootstrap repo-level QC infrastructure in a repo that does not
  yet have it. Not for a repo that already has a populated `tests/`
  directory and overlay — use `run-repo-qc` instead. Not for writing the
  tests themselves (incremental, dev-driven) or executing them
  (`run-repo-qc`'s job).
model: sonnet
allowed-tools: Bash(mkdir *), Bash(ls *)
disable-model-invocation: true
# persona: developer   — grouping metadata only; not read by Claude Code.
---

# Create Repo QC

You are about to bootstrap repo-level QC infrastructure for **a repository that does not yet have it**. This is a one-time setup skill. Do NOT run it on a repo that already has a populated `tests/` directory and a `docs/qc-modifications.md` overlay — use `run-repo-qc` instead.

## Activation

Activate when the user asks to "set up repo-level QC", "scaffold the QC suite", "bootstrap testing", or when `run-repo-qc` can't execute because no `tests/` exists.

## Scope vs. `run-repo-qc`

This skill **only creates assets**. It does NOT execute tests, file issues, or produce QC reports. Those belong to `run-repo-qc`.

| Concern | This skill | `run-repo-qc` |
|---|---|---|
| Create `tests/` dir | ✅ | ❌ |
| Choose test framework | ✅ | ❌ |
| Stub `docs/qc-modifications.md` | ✅ | ❌ (reads it) |
| Write tests | ❌ (dev writes these incrementally) | ❌ |
| Run tests + invariants | ❌ | ✅ |
| File issues for findings | ❌ | ✅ |

## Inputs

- The repo's primary language.
- Confirmation that no `tests/` directory exists, OR that the existing one is incomplete and the missing pieces should be stubbed.

## Steps

### Step 1 — Detect existing infrastructure

```bash
ls tests/ 2>/dev/null
ls docs/qc-modifications.md 2>/dev/null
```

If `tests/` is populated (≥ 1 test file) AND `docs/qc-modifications.md` exists, report that scaffolding is unnecessary and suggest `run-repo-qc` instead. **Stop.**

### Step 2 — Create `tests/` directory

If absent:

```bash
mkdir -p tests
```

Add a `tests/README.md` describing the suite's role — what it exercises, how to run it, and that `run-repo-qc` invokes it as part of the repo-level audit.

### Step 3 — Choose test framework

| Language | Framework | Runner |
|---|---|---|
| R | `testthat` | `testthat::test_dir("tests")` |
| Python | `pytest` | `pytest tests/` |
| JavaScript | `jest` / `vitest` | `npx jest` / `npx vitest` |
| Go | `testing` (stdlib) | `go test ./...` |

Do NOT install language dependencies in this skill — surface what's missing and ask the user to install it.

### Step 4 — Stub the modifications overlay

Create `docs/qc-modifications.md` if absent:

```markdown
# Repo QC modifications

This file overlays `run-repo-qc` with **repo-specific** additions and
divergences from the generic skill.

## Additional checks

(List repo-specific structural invariants this repo needs enforced.)

## Known exceptions (do NOT re-flag)

(Findings from prior QC runs that are intentional, not bugs. Each entry:
file/check-ID + 1-line rationale.)

## Divergences from the generic skill

(Any place this repo deliberately diverges from `run-repo-qc`'s default
behavior.)
```

### Step 5 — Stub a structural-invariant test file

Create a placeholder structural-checks test file (skipped, so the user extends it) in the chosen framework's idiom — e.g. for Python:

```python
import pytest


@pytest.mark.skip(reason="Implement or extend in run-repo-qc's overlay.")
def test_repo_structural_invariants():
    """TODO: adapt this check to the repo's own invariants."""
    ...
```

This file is intentionally minimal — the full battery of structural checks is `run-repo-qc`'s job.

### Step 6 — Confirm + report

Print the files created and suggest the next step: "extend the stubbed tests, then invoke `run-repo-qc`."

Do NOT commit. The user (or a follow-on PR) commits the scaffold.

## Reference

Outputs, success criteria, scope boundary, and cross-references: [`reference.md`](${CLAUDE_SKILL_DIR}/reference.md)
