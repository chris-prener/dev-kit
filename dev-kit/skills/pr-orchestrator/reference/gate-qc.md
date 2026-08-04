# Gate: Pre-PR QC

Read and followed directly by `pr-orchestrator` at its QC-gate step (final position). Not a `Skill`-tool dispatch — per [ADR-0002](${CLAUDE_PROJECT_DIR}/docs/adr/ADR-0002-skill-decomposition.md)'s caller-class test, this gate has no independent trigger a human or the model would use to select it, so it does not earn its own listed skill.

## Inputs

Gate protocol inputs per the "Gate protocol" section in [`../reference.md`](../reference.md).

## Steps

### 1. Check opt-out

If `opt_out_markers` contains key `no-prep-gate`:
- Return `{ signal: 0, chat_output: "QC gate skipped: _no-prep-gate_ marker present." }`

### 2. Pre-flight

- Confirm the working tree is clean.
- Compute the `<base>..HEAD` file list from `diff_context`.

### 3. Sub-step a — Repo-level QC

Invoke `run-repo-qc` with `--mode=gate`.
- If missing: log WARNING, skip to sub-step b.
- Signal mapping: 0 → proceed, 1 → surface findings + proceed, 2 → BLOCKER.

### 4. Sub-step b — PR-scoped doc audit

Invoke `documentation-audit-changes` with `--mode=gate` and the changed-files list.
- If missing: log WARNING, skip to sub-step c.
- This sub-step cannot return signal 2 (no CRITICAL band for doc findings).

### 5. Sub-step c — Repo-specific extensions

Read `CLAUDE.md`'s "Pre-PR QC checklist" subsection, if present.
- If missing: skip silently.
- Execute whatever repo-specific checks it names.

### 6. Sub-step d — Skill cross-reference consistency (conditional)

**Trigger**: only runs when `diff_context.files_changed` includes any `dev-kit/skills/*/SKILL.md` (excluding `_partials/`).

If triggered, validate the touched skills:

1. Every sister-skill referenced by kebab-name in prose actually exists as a skill directory.
2. Every `# persona:` comment value is one of `product-owner` / `product-manager` / `developer` / `writer` / `python-developer` / `r-developer`, or the skill is deliberately ungated (no `# persona:` comment at all, like `session-start`).
3. Every skill directory has a `SKILL.md`.

**Severity: WARNING only.** Never returns signal 2. Findings are chat-surfaced, not auto-filed.

### 7. Aggregate and return

| Outcome | Signal |
|---|---|
| All sub-steps CLEAN | 0 |
| Any sub-step FINDINGS (no CRITICAL) | 1 |
| Any sub-step (a-c) BLOCKER | 2 |

**BLOCKER handling** — present three explicit choices (no default):
1. **Fix now and stop** — operator addresses findings, re-invokes.
2. **File-and-stop** — keep filed issues open, exit without PR.
3. **Proceed with marker** — append `_no-prep-gate: <justification>_` to `body_amendments`.

### 8. Return result

```
{ signal: <0|1|2>, findings: [...], body_amendments: [...], chat_output: "<summary>" }
```

## Outputs

Gate protocol output: `signal`, `findings`, `body_amendments`, `chat_output`.

## Success criteria

- All four sub-steps execute in order (skipping missing skills gracefully).
- BLOCKER from sub-steps a-c halts with three explicit choices.
- Sub-step d never produces BLOCKER.
- Sub-step d's persona enum matches the shipped persona set (six values, including the two language personas) — a conforming `python-*`/`r-*` skill never false-flags.
- Re-runs dedup findings via the ADR-0004 body marker.

## Out of scope

- QC logic itself (owned by `run-repo-qc` and `documentation-audit-changes`).
- Filing issues (delegated to child skills via auto-file mode).

## Cross-references

- `pr-orchestrator` — the caller; `SKILL.md` reads this file at the QC-gate step.
- `run-repo-qc` — sub-step a.
- `documentation-audit-changes` — sub-step b (writer group).
- [ADR-0004](${CLAUDE_SKILL_DIR}/../_docs/ADR-0004-auto-filed-issue-protocol.md) — auto-file dedup.
