# Roadmap Curator — reference

Contract and QA detail for the `roadmap` skill. `SKILL.md` holds the procedure; this file holds outputs, success criteria, restartable semantics, scope, and cross-references.

## Outputs

- A modified `${CLAUDE_PROJECT_DIR}/docs/ROADMAP.md` (or unchanged if the operation was `validate` / no-op).
- A one-paragraph summary of what changed: operation, issue, source horizon, target horizon, milestone, any prune side-effects.
- A validation findings report from Phase 0 (always emitted; may be `all OK`).

## Success criteria

- `docs/ROADMAP.md`'s Epics block continues to have exactly the four canonical `###` subsections in order, each either populated or carrying `_None yet._`.
- Every entry validates against the canonical regex and links to a real `epic`-labeled issue.
- `Recently Shipped` is newest-first and ≤ 10 entries.
- No modifications outside the Epics block.
- Re-running the same operation is a no-op (idempotent).
- `epic` and `epic-retrospective` can call this skill and observe the postcondition they need (issue registered at horizon X / moved to Recently Shipped) without further action.

## Restartable semantics

The skill is restartable, not transactional:

- Re-running `add` for an issue already at the target horizon is a no-op.
- Re-running `move` from any source horizon to the target horizon is a no-op if already there; otherwise it completes the move.
- If a previous run wrote a partial change (e.g., removed from source but failed before inserting in target), Phase 0's validation will flag the missing entry; running the same `add`/`move` again will complete it.
- The skill never relies on in-memory state surviving across runs.

## Out of scope

- **Filing the epic issue itself** — that's `epic`. This skill assumes the issue exists.
- **Closing the epic issue** — that's `epic-retrospective`.
- **Editing anything outside the Epics block** in `docs/ROADMAP.md` (legacy Sequencing content, Where-we-are bullets, etc.).
- **Auto-syncing from GitHub on a schedule / via CI**. Manual invocation only.
- **Generating the roadmap from scratch** from issue labels — the document exists and is curated.
- **Cross-repo roadmap aggregation** — single-repo only.

## Cross-references

- `epic` — invokes `add` to register a newly-filed epic.
- `epic-retrospective` — invokes `move <N> 'Recently Shipped'` on epic close.
- Label vocabulary: [`../_partials/label-vocabulary.md`](${CLAUDE_SKILL_DIR}/../_partials/label-vocabulary.md); consuming-repo labels, if any, at `${CLAUDE_PROJECT_DIR}/.github/LABELS.md` — `epic` label is required on any issue this skill operates on.
- `${CLAUDE_PROJECT_DIR}/docs/ROADMAP.md` — the file this skill owns.
- Repo layout invariants: [`../_partials/repo-layout-note.md`](${CLAUDE_SKILL_DIR}/../_partials/repo-layout-note.md)
