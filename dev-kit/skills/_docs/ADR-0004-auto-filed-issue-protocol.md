# ADR-0004: Auto-filed issue protocol for QC and documentation skills

**Status:** accepted

## Context

Several skills (`run-repo-qc`, `documentation`, `readme`, `walkthrough`, `code-review`, `documentation-audit-changes`, `docs-organization`, `playbooks`, `objectives`, `backlog-retrospective`) surface findings mechanically — QC failures, doc staleness, review blockers, at-risk KRs, unresolved outcome validations — that should become tracked issues without a human retyping `gh issue create` by hand. Letting each skill invent its own filing logic invites drift: duplicate dedup heuristics, inconsistent labels, and fragile re-runs that silently double-file. The protocol needs to work for all of them plus the existing interactive `backlog` skill, without watering down the DoR contract the interactive skill already enforces (Type label, Priority label, parent-epic linkage, structural template conformance).

## Decision

A single shared **auto-filed issue protocol**, owned by the `backlog` skill's Auto-file mode, that every caller skill invokes. Six contract points:

### 1. Template choice is caller-supplied and bounded

Auto-file mode requires a `template` parameter from the caller, drawn from the existing `.github/ISSUE_TEMPLATE/*.md` files (typically `qc_finding` for QC callers, `tech_debt` for documentation callers). Bug reports and feature requests are not auto-filed — those require human framing.

### 2. The autofile-id body marker is the dedup key

Every auto-filed issue carries a hidden HTML comment marker in its body:

```html
<!-- autofile-id: <skill>:<scope>:<check-id> -->
```

- `<skill>` — the skill that filed it (matches the skill's directory name, kebab-case).
- `<scope>` — the targeted unit: a module/component name, or a file path (or `root`) for documentation findings.
- `<check-id>` — a stable identifier from the caller's check-ID inventory.

Dedup uses `gh issue list --search 'in:body "autofile-id: <id>"'` against **open** issues only. A match suppresses a new file and triggers a single comment on the existing issue instead. A closed match is reported back to the caller ("previously closed at #N") but does not auto-reopen — a human deciding to reopen is the right gate.

Each caller skill maintains a "Check-ID inventory" subsection listing all stable check-IDs it emits. These IDs are a contract — they may be added but never silently renamed (renames break dedup against historical issues).

### 3. Parent-epic linkage is mandatory, no silent default

Auto-file mode requires the caller to pass **either** `parent_epic` (a validated epic-issue number) **or** `standalone_reason` (a non-empty justification string). There is no default — this preserves the interactive mode's epic-linkage contract.

### 4. Severity → Priority mapping is the cross-skill standard

| Caller-skill severity | Priority label | File issue? |
|---|---|---|
| critical / blocker | `priority/blocker` | yes |
| high / failing test / missing required doc | `priority/high` | yes |
| medium / warning / stale doc / broken link | `priority/medium` | yes |
| low / info / nit | — | no — surfaced in caller's report only |

INFO/LOW findings are deliberately not filed — they would drown the tracker. They appear in the caller's own report only.

### 5. Auto-file is file-only; close happens via the normal PR flow

Auto-file mode does **not** invoke `backlog-retrospective` and does not close issues. The `backlog-retrospective` skill requires a resolving commit or PR and flags a retro-with-no-implementation-reference as a smell — auto-filed issues close the same way any other issue does, via the standard `pr-orchestrator` skill's `Closes #N` flow. This keeps the audit trail clean: every closed auto-filed issue has a real PR and retro behind it.

The `qc-fixed` label may be set on file when the caller fixed a finding in-place during the same run — it signals "already fixed, awaiting close" so reviewers don't re-investigate.

### 6. Every caller must document its invocation contract

Each caller skill includes an "Auto-file invocation contract" subsection at the step that invokes auto-file mode: a six-row input table (`template`, `title`, `body`, `labels`, `dedup_id`, `parent_epic`) followed by its own severity → priority mapping consistent with §4. The severity-vocabulary column may legitimately differ across callers (e.g. code review might use BLOCKER/HIGH/MEDIUM/NIT while a QC skill uses CRITICAL/HIGH/MEDIUM/LOW/INFO); the **priority column** stays fixed — severities mapping to filing always resolve to `priority/blocker`, `priority/high`, or `priority/medium`, and LOW/INFO/NIT/QUESTION never file. This makes the call site self-describing for anyone picking up the skill cold.

### Alternatives considered

- **Each skill calls `gh issue create` directly.** Rejected — independent dedup logic and independent label conventions drift within months.
- **Title-prefix dedup.** Rejected — title wording drifts on re-files, and generic check-IDs collide across skills if title is the only key. The body marker is exact-match.
- **Auto-file + auto-close in one transaction.** Rejected — anchoring a retro to a synthetic seconds-old issue with no commit reference defeats the purpose of mandatory retrospectives.
- **Auto-reopen of closed-but-still-reproducing findings.** Rejected — a human deciding to reopen is the right gate; the skill surfaces "previously closed at #N" in its report.

## Consequences

- **Easier:** findings from any caller skill become durable, labeled, deduplicated GitHub issues with no manual `gh issue create` step. Every closed auto-filed issue has a commit-anchored retro via the standard PR flow.
- **Harder:** each caller skill must maintain a stable Check-ID inventory; renaming a check-ID without comment migration breaks dedup against historical issues.
- **Constraints:** auto-file mode runs the full DoR structural check non-interactively — any WARNING-level miss is a caller error, not a user prompt. The autofile-id body marker MUST appear in every auto-filed issue body. Severity → priority mapping is fixed; individual skills do not redefine it. INFO/LOW findings are never auto-filed.
- **Revisit when:** a transactional file-then-close path becomes worth building; auto-filing volume gets high enough to need a roll-up "umbrella" issue mode; a new finding-producing skill is added (it should adopt this protocol rather than inventing its own); or GitHub's issue-search behavior changes such that body-marker dedup becomes unreliable.
