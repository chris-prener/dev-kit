# Backlog — reference

Contract and QA detail for the `backlog` skill (six operations: Capture, Groom, Triage, Prioritize, Create, Auto-file mode). Loaded on demand; not needed for every run. `SKILL.md` holds the procedure; this file holds the input/output contract and the success bar, per operation.

## Inputs

| Operation | Inputs |
|---|---|
| Capture | User story per `../_partials/user-story.md`; optional one-line context; optional title. |
| Groom | Sub-operation (`groom-inbox` / `walk-horizon <horizon>` / `kill-stale` / `regroup-orphans` / `propose-epic-promotion <N>` / `propose-epic-demotion <N>` / `generate-grooming-report`) plus its sub-operation-specific arguments. |
| Triage | Sub-operation (`triage-one <N>` / `triage-inbox [--limit N]` / `mark-as-not-planned <N>` / `propose-promote-to-epic <N>`) plus issue number where applicable. |
| Prioritize | None required; enumerate open issues via `gh`. Optional subset filter such as `bugs only`. |
| Create | User story per `../_partials/user-story.md`; template choice; parent epic # **or** standalone justification per `../_partials/epic-linkage.md`; optional now/later/no worth-doing judgment (Step D). |
| Auto-file mode | `template`, `title`, `body`, `labels`, `dedup_id`, and exactly one of `parent_epic` XOR `standalone_reason`, plus severity and caller-provided finding content per `../_docs/ADR-0004-auto-filed-issue-protocol.md`. |

## Outputs

| Operation | Output |
|---|---|
| Capture | One new GitHub issue, labels `enhancement, needs-grooming`, with a `<!-- quick-capture-grooming-checklist -->` block. One confirmation line in chat. No local file writes. |
| Groom | Per-mutation confirmation prompts in chat; per-issue `## Grooming` audit comments; label changes via `gh issue edit`; issue closes via `gh issue close --reason "not planned"` (with `not-planned` label set first); optional report file in `${CLAUDE_PROJECT_DIR}/.github/grooming-reports/<date>.md`. |
| Triage | Per-issue assessment blocks in chat; per-mutation `## Triage` comments; label changes via `gh issue edit`; (route 1) sub-issue link; (routes 3–4) issue close with close-reason label. No local file writes. |
| Prioritize | Prioritized backlog summary and, for selected issues, a hand-off to `implementation-plan` `Create` (no locally-drafted plan artifact). |
| Create | New GitHub issue with Parent-epic line, `## User story`, template body, `Codebase Context`, required labels, and optional native sub-issue link. |
| Auto-file mode | Same durable issue contract plus `<!-- autofile-id: ... -->` dedup marker and source labels. |

## Success criteria

- **Capture**: the User-story block is always present and complete — the only invariant this operation guarantees. The grooming checklist block is present and parseable as a single fenced HTML comment. The issue carries exactly two labels at file time: `enhancement` + `needs-grooming`.
- **Groom**: every mutation has explicit per-item `[y/N]` confirmation — no batch close, no batch promote. Every promoted issue exits with `needs-grooming` removed and `needs-triage` added (and DoR pre-flight clean). Every closed-during-grooming issue exits with the appropriate close-reason label set **before** the close call. Epic promotion / demotion are always hand-offs — this operation never sets the `epic` label or creates an epic; demotion is always refused when any open sub-issues exist. `generate-grooming-report` is reproducible on the same state (modulo timestamps).
- **Triage**: every triaged issue exits with **either** `needs-triage` removed and a routing decision applied, **or** an explicit "deferred" outcome — no silent no-ops. The `## Triage` audit comment is posted on every routed issue. Epic promotion is always a hand-off to `epic`. Demotion of an epic with open sub-issues is always refused. Close-reason label is set before the close call.
- **Prioritize**: Step 4 hands off to `implementation-plan` `Create` rather than drafting a plan in a second schema; no locally-drafted `## Implementation Plan: #N` artifact is produced.
- **Create**: every new issue has at least one Type label, the Parent-epic metadata line, and `## User story` as the first content section. Non-trivial issues get a now/later/no worth-doing judgment (Step D); chores may use the `**Mechanical change**` escape hatch for the user story.
- **Auto-file mode**: never duplicates an open issue with the same `autofile-id`.
- Routing (top of `SKILL.md`) sends epic / plan-comment / retro / roadmap / implementation requests to the right external skill before any operation's heavy flow begins.

## Out of scope

- **Capture**: validating epic linkage, worth-doing judgment, DoR pre-flight gate, codebase analysis, closing/merging duplicates, picking a Type label other than `enhancement` — all deferred to Groom or Create.
- **Groom**: bulk close (all per-item-confirmed); auto-applying ROADMAP edits (delegated to `roadmap`); re-opening closed issues; direct epic creation/mutation (hand-offs only); non-grooming label maintenance; CI integration; cross-repo grooming.
- **Triage**: promoting to epic directly (propose-only, Triage-D); bulk closing; DoR remediation (surfaces gaps, doesn't fix them — that's Groom); re-judging worth-doing (Groom or Create Step D); auto-reopening closed dedup hits; Status labels other than `needs-triage` removal.
- **Prioritize / Create**: implementing, testing, or opening a PR (`pr-orchestrator`, `code-review`); drafting a competing implementation-plan schema (`implementation-plan` owns that contract exclusively).
- **All operations**: epics ("a bunch of issues" — `epic`); the `## Implementation plan` comment (`implementation-plan`); closing a worked issue / retro (`backlog-retrospective`).

## Cross-references

- [`../_partials/user-story.md`](${CLAUDE_SKILL_DIR}/../_partials/user-story.md) — canonical User-story format; Capture's only required input, also used by Create.
- [`../_partials/epic-linkage.md`](${CLAUDE_SKILL_DIR}/../_partials/epic-linkage.md) — parent-epic prompt, validation, sub-issue link; used by Groom, Triage, and Create.
- [`../_partials/dor-preflight.md`](${CLAUDE_SKILL_DIR}/../_partials/dor-preflight.md) — DoR structural checks; Capture's `needs-grooming` exemption, Groom's interactive-mode gate, Triage's non-interactive check, Create's soft pre-flight gate.
- [`../_partials/label-vocabulary.md`](${CLAUDE_SKILL_DIR}/../_partials/label-vocabulary.md) — Type / Priority / `needs-grooming` / `needs-triage` / close-reason label definitions; consuming-repo labels, if any, at `${CLAUDE_PROJECT_DIR}/.github/LABELS.md`.
- [`../_partials/backlog-autofile-mode.md`](${CLAUDE_SKILL_DIR}/../_partials/backlog-autofile-mode.md) — Auto-file mode's full input contract, dedup rules, severity → priority mapping.
- [ADR-0004](${CLAUDE_SKILL_DIR}/../_docs/ADR-0004-auto-filed-issue-protocol.md) — auto-file protocol.
- [ADR-0002](${CLAUDE_PROJECT_DIR}/docs/adr/ADR-0002-skill-decomposition.md) — the decision merging `quick-capture` / `backlog-grooming` / `triage` into this skill, and the rationale for keeping the `backlog` directory identity.
- `implementation-plan` — exclusive owner of the `## Implementation plan` comment contract; Prioritize's Step 4 hands off here rather than drafting a competing artifact.
- `backlog-retrospective` — close-reason carve-out (label MUST precede close); closes issues Create/Groom/Triage never close themselves except via the explicit not-planned/duplicate paths.
- `epic` / `epic-retrospective` / `roadmap` — hand-off targets for epic promotion, epic demotion/close, and horizon moves respectively.
- `${CLAUDE_PROJECT_DIR}/docs/ROADMAP.md` — read by Groom's `walk-horizon`; mutations delegated to `roadmap`.
- `${CLAUDE_PROJECT_DIR}/.github/grooming-reports/` — gitignored local artifact directory for Groom's `generate-grooming-report`.
