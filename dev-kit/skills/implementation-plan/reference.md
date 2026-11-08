# Implementation Plan — reference

Contract and QA detail for the `implementation-plan` skill. `SKILL.md` holds the procedure; this file holds the schema, state machine, label mapping, outputs, success criteria, and cross-references.

## Schema parsing

Parse the body deterministically after the marker:

1. Strip the marker and following blank lines; the next line must be `## Implementation plan`.
2. The next two non-blank lines must be, in order: `_Last updated: <ISO-8601-UTC>_`, `_Status: <enum>_`.
3. Validate `Status:` against the five-value enum below.
4. Split the remainder on `^### ` headings.
5. Require these six sections, exactly once and in order: `Approach`, `Files to touch`, `Verification`, `Risks / open questions`, `Where I left off`, `Decisions made`.

Empty sections use `_TBD in drafting._` for `Files to touch` / `Verification` while drafting, `_None yet._` for `Risks / open questions` / `Decisions made`, and `_Not yet started._` for `Where I left off`. Never leave a section heading without body content.

## Status state machine

Five values: `drafting`, `in-progress`, `blocked`, `ready-for-pr`, `shipped`.

Legal transitions:

```
drafting → in-progress
in-progress ⇄ blocked
in-progress → ready-for-pr
blocked → ready-for-pr
ready-for-pr → shipped
in-progress → shipped   (casual path; note it in the transition message)
shipped → drafting      (reopen only, with explicit confirmation — see SKILL.md)
```

Any other requested transition is rejected with the current and legal-next states named.

## Label mapping

| Status | Labels |
|---|---|
| `in-progress` | `+in-progress`, `-blocked` |
| `blocked` | `+blocked`, `-in-progress` |
| `drafting` / `ready-for-pr` / `shipped` | `-in-progress`, `-blocked` |

See [`_partials/label-vocabulary.md`](${CLAUDE_SKILL_DIR}/../_partials/label-vocabulary.md) for the label's origin and repo-level resolution order.

## Outputs

- `Create` / `Update` / `Transition`: updated GitHub comment; label updates for `Transition`.
- `Read`: parsed plan printed or returned.
- `Reconcile labels`: label update only.
- One short success line per operation.

## Enforcement hooks

The plan step is enforced by two Claude Code hooks, configured in the repo's committed `.claude/settings.json` (not the gitignored `settings.local.json`) and implemented under `.claude/hooks/`. Both call [`scripts/plan-status.sh`](${CLAUDE_SKILL_DIR}/scripts/plan-status.sh) for the locator and `Status:` parse rather than reimplementing it. They are the *early* enforcement layer; `pr-orchestrator`'s implementation-plan gate (`reference/gate-implementation-plan.md`) is unchanged and remains the last backstop at PR time.

| Hook | Event | Behaviour |
|---|---|---|
| `plan-pickup.py` | `UserPromptSubmit` | A prompt with a pickup verb (pick up / work on / start) and `#N` refs injects a nudge for each issue lacking a plan at `in-progress` or later. Advisory; never blocks the prompt. |
| `plan-commit-guard.py` | `PreToolUse` on `Bash` | Blocks a `git commit` whose message has a keyword-qualified ref (`Closes` / `Fixes` / `Resolves` / `Refs` / `Part of` / `Implements #N`) to an issue with no plan, a duplicate plan, or a plan still at `drafting`. A commit with no such refs passes. |

Scope rules:

- Only ordinary issues are checked. Epics, sprints and PRs carry no plan and are skipped.
- Bare `#N` mentions in prose do not count as refs; only the keyword-qualified form does.
- Detection is by invocation, not by text: a `git commit` that only appears inside a heredoc body or a quoted string is not a commit.
- Edits are not hooked. Nothing links an `Edit`/`Write` to an issue at that point.

**Bypass.** For a deliberate `Refs #N` commit that has no plan, prefix the command with `DEVKIT_SKIP_PLAN_CHECK=1` (for example `DEVKIT_SKIP_PLAN_CHECK=1 git commit -m "Refs #N"`), or export it in the environment Claude Code runs in. The block message names this variable.

**Fail open.** If `gh` fails (offline, rate-limited, unauthenticated), the hooks allow the action and show a visible `failed open` warning; a network blip never blocks a commit.

**Scope of install.** Repo-local only. A consuming repo gets these hooks by copying `.claude/hooks/` and the `hooks` block of `.claude/settings.json`; shipping them in the plugin overlaps the packaging epic and is deferred. Tests: `bash tests/plan-hooks/run.sh`.

## Success criteria

- Exactly one comment matches the plan locator after every successful write.
- Every `Transition` either updates both comment and labels, or leaves the comment correct and surfaces the label failure loudly with a `Reconcile labels` pointer.
- Re-running an idempotent operation is a no-op with a clear message.
- `Create` is the only legal operation when no plan exists.
- Duplicate markers hard-fail all operations until manually fixed.

## Out of scope

- Filing or closing issues (`backlog`, `backlog-retrospective`).
- PR-body composition (`pr-orchestrator`).
- Cross-issue dashboards or plan aggregation.
- Concurrent-edit conflict resolution — this skill assumes one agent works one issue's plan at a time. If you're running multiple concurrent sessions against the same issue, that's a workflow choice outside this skill's scope, not a case it guards against.
- Migrating `-v1` plans to a future schema.

## Cross-references

- `pr-orchestrator` — invokes `Transition` (to `shipped`) inline when closing an issue.
- `code-review` — reads the plan's `### Approach`, `### Verification`, and `### Decisions made` sections as review context, when present.
- `backlog` (Groom / Triage operations) — read the `in-progress` label only.
- `_partials/label-vocabulary.md` — `in-progress` / `blocked` Status labels.
