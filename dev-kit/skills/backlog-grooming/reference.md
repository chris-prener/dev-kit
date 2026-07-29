# Backlog Grooming — reference

Contract and QA detail for the `backlog-grooming` skill. `SKILL.md` holds the procedure; this file holds outputs, success criteria, scope, and cross-references.

## Outputs

- Per-mutation confirmation prompts in chat.
- Per-issue `## Grooming` audit comments.
- Label changes via `gh issue edit`.
- Issue closes via `gh issue close --reason "not planned"` (with required `not-planned` label set first).
- Optional grooming report file in `${CLAUDE_PROJECT_DIR}/.github/grooming-reports/<date>.md`.

## Success criteria

- Every mutation has explicit per-item `[y/N]` confirmation. No batch close, no batch promote.
- Every promoted issue exits with `needs-grooming` removed and `needs-triage` added (and DoR pre-flight clean).
- Every closed-during-grooming issue exits with the appropriate close-reason label set **before** the close call.
- Epic promotion / demotion are **always** hand-offs. This skill never sets the `epic` label or creates an epic. Demotion is **always** refused when any open sub-issues exist.
- Reports are reproducible: re-running `generate-grooming-report` on the same state produces the same output (modulo timestamps).

## Out of scope

- **Bulk close.** All closes are per-item-confirmed.
- **Auto-applying ROADMAP edits.** Horizon moves and `### Recently Shipped` pruning go through the `roadmap` skill.
- **Re-opening closed issues.** A human decision to reopen is the right gate — same rationale as the auto-file protocol's no-auto-reopen rule ([ADR-0004](${CLAUDE_SKILL_DIR}/../_docs/ADR-0004-auto-filed-issue-protocol.md)).
- **Direct epic creation / mutation.** All hand-offs.
- **Non-grooming label maintenance.** `blocked` / `UAT` / `qc-fixed` labels are owned elsewhere.
- **CI integration.** Manual / on-demand only.
- **Cross-repo grooming.** This skill is single-repo.

## Cross-references

- [`../_partials/dor-preflight.md`](${CLAUDE_SKILL_DIR}/../_partials/dor-preflight.md) — interactive-mode pre-flight after grooming a quick-captured item.
- [`../_partials/label-vocabulary.md`](${CLAUDE_SKILL_DIR}/../_partials/label-vocabulary.md) — Type / Priority / `needs-grooming` / `needs-triage` definitions.
- [`../_partials/epic-linkage.md`](${CLAUDE_SKILL_DIR}/../_partials/epic-linkage.md) — parent-epic prompt, validation, sub-issue link.
- `quick-capture` — upstream intake; produces `needs-grooming` items with the checklist block this skill reads.
- `triage` — downstream routing; receives issues this skill promotes from `needs-grooming` → `needs-triage`.
- `backlog` — auto-file mode injects `needs-triage` directly (skips `needs-grooming`); interactive mode skips both.
- `epic` — hand-off target for `propose-epic-promotion`.
- `epic-retrospective` — proper close path for epics; demotion guard refers users here.
- `roadmap` — horizon-move authority and `### Recently Shipped` prune; `walk-horizon` proposals delegate here for actual moves.
- `backlog-retrospective` — close-reason carve-out (label MUST precede close).
- `${CLAUDE_PROJECT_DIR}/docs/ROADMAP.md` — read by `walk-horizon`; mutations are delegated to the `roadmap` skill.
- `${CLAUDE_PROJECT_DIR}/.github/grooming-reports/` — gitignored local artifact directory.
