---
name: triage
description: >
  Lifecycle step between filing and pickup. Routes incoming issues that
  carry the needs-triage Status label (set by backlog's auto-file mode
  and by backlog-grooming after promotion). Four operations: triage-one,
  triage-inbox, mark-as-not-planned, propose-promote-to-epic. Never
  directly mutates an issue into an epic — proposes and hands off to
  epic + roadmap. Read-and-confirm; no silent state mutation.
when_to_use: >
  Use to route freshly-filed or freshly-groomed issues carrying
  needs-triage. Not for picking up an already-triaged issue (no skill
  needed, just start), closing a worked issue (`backlog-retrospective`),
  filing a new issue (`backlog` or `quick-capture`), or curating older
  backlog items (`backlog-grooming`).
model: sonnet
allowed-tools: Bash(gh *)
# persona: product-owner   — grouping metadata only; not read by Claude Code.
---

# Triage

You route freshly-filed (or freshly-groomed) issues to the right next-step bucket. The triage queue is "issues with the `needs-triage` Status label." Auto-filed issues land here automatically (`backlog`'s auto-file mode injects `needs-triage` on file, and on dedup-hits-without-the-label). Quick-captured issues land here only after `backlog-grooming` promotes them out of `needs-grooming`. Manually-filed issues from `backlog`'s interactive mode skip triage entirely (they were authored with full DoR).

**Trust model.** Every state change is read-and-confirm: the skill prints the proposed action and asks `[y/N]` before running any `gh` command that mutates GitHub state. Batch operations confirm per-item, not as a batch.

This skill's `propose-promote-to-epic` operation runs on **freshly-filed `needs-triage`** items. `backlog-grooming`'s `propose-epic-promotion` operation runs on the **broader open backlog** as periodic curation. Both are propose-only and hand off to `epic` — same mechanic, different queue.

## Inputs

The operation drives the inputs:

| Operation | Inputs |
|---|---|
| `triage-one <N>` | Issue number `N`. |
| `triage-inbox [--limit N]` | Optional limit (default 10) on how many `needs-triage` issues to walk in this session. |
| `mark-as-not-planned <N>` | Issue number `N` + a one-line rationale. |
| `propose-promote-to-epic <N>` | Issue number `N`. The skill never mutates the issue itself; it presents an epic-promotion case to the user and recommends invoking `epic`. |

## State machine (clarifies overlap with grooming)

The lifecycle of a freshly-filed issue:

```
              ┌─────────────────┐                         ┌──────────────┐
quick-capture │ needs-grooming  │ ── grooming promotes ─▶ │ needs-triage │
              └─────────────────┘                         └──────────────┘
                       │                                          │
              grooming closes                              triage routes
              (not-planned, dup)                                   │
                       │                              ┌────────────┼────────────┐
                       ▼                              ▼            ▼            ▼
                  closed                        sub-issue of   standalone     not-planned
                                                   epic         (justified)    / duplicate
```

Auto-filed issues from `backlog`'s auto-file mode skip the `needs-grooming` stage and land directly in `needs-triage`.

**Label ownership:**
- `needs-grooming` is **owned by `backlog-grooming`** (set by quick-capture, removed by grooming or by close).
- `needs-triage` is **owned by this skill** (set by backlog auto-file or by grooming-promotion; removed by every triage exit path).
- Both labels are **always cleared on close** (whatever the close reason). Close-reason labels (`duplicate`, `wontfix`, `not-planned`, `invalid`) replace them.

## Steps

### A. Resolve the operation and the issue list

```bash
REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner')
```

For `triage-inbox`:

```bash
gh issue list --repo "$REPO" --state open --label needs-triage \
  --json number,title,labels,createdAt,body --limit "${LIMIT:-10}"
```

For `triage-one <N>` and `mark-as-not-planned <N>` and `propose-promote-to-epic <N>`:

```bash
gh issue view "$N" --repo "$REPO" --json number,title,labels,state,body
```

If the issue does not carry `needs-triage` for the `triage-one` / `triage-inbox` paths, surface a warning and ask the user whether to proceed anyway. Triage on an already-routed issue is unusual but not forbidden (e.g., re-routing after circumstances changed).

### B. For each issue, run the triage assessment

Compose a per-issue assessment block:

1. **DoR check (non-interactive).** Invoke `${CLAUDE_SKILL_DIR}/../_partials/dor-preflight.md` in non-interactive mode. List warnings.
2. **Dedup search.** Search for similar open + closed issues:
   ```bash
   gh issue list --repo "$REPO" --state all --search "<distilled keywords>" \
     --json number,title,state --limit 5
   ```
   Surface the top 3 candidates with a similarity assessment in chat. **Do not auto-close as duplicate** — propose, confirm.
3. **Epic-linkage check.** Read the body's `**Parent epic:** ...` line per `${CLAUDE_SKILL_DIR}/../_partials/epic-linkage.md`. If standalone, validate the justification reads. If linked, validate the parent epic still exists, is `OPEN`, and carries the `epic` label. Surface mismatches.
4. **Label completeness.** Verify the issue carries one Type label + (if non-trivial) one Priority label per `${CLAUDE_SKILL_DIR}/../_partials/label-vocabulary.md`. Surface gaps.

Print the assessment as one fenced block per issue. Then propose **one** of the following routes (Step C).

### C. Propose a route, confirm, execute

For each issue, present a numbered choice prompt. The five routes:

```
1) Route to epic <N> (sub-issue link via gh api ... /sub_issues)
2) Mark standalone (write Parent epic: standalone — <reason> into body)
3) Mark as duplicate of #<M> (close --reason "not planned"; label `duplicate`)
4) Mark as not-planned (close --reason "not planned"; label `not-planned`)
5) Propose-promote-to-epic (HAND OFF — see Step D; this skill does NOT promote directly)
6) Defer (leave needs-triage in place; revisit later)
```

For routes 1–4, get explicit `[y/N]` confirmation before running any `gh` command. On `y`:

- **Route 1.** Verify parent epic via `${CLAUDE_SKILL_DIR}/../_partials/epic-linkage.md` validation. Run the sub-issue link with the database-id-not-issue-number caveat from that partial. Then `gh issue edit <N> --remove-label needs-triage` (and add a Type + Priority label if missing).
- **Route 2.** Edit the body to insert / update the `**Parent epic:** standalone — <reason>` line per `${CLAUDE_SKILL_DIR}/../_partials/epic-linkage.md`. Then remove `needs-triage`.
- **Route 3.** `gh issue edit <N> --add-label duplicate --remove-label needs-triage` then `gh issue close <N> --reason "not planned" --comment "Duplicate of #<M>"`. Per the close-reason carve-out, the `duplicate` label is required *before* close.
- **Route 4.** See Step E (mark-as-not-planned).
- **Route 5.** See Step D (propose-promote-to-epic).
- **Route 6.** Print a one-line "deferred — re-runs of triage-inbox will surface this again." No mutation.

After every mutation, append a single comment to the issue documenting the triage decision:

```markdown
## Triage — <YYYY-MM-DD>

- **Route:** <route name>
- **Assessment:** <one-line summary of the assessment block from Step B>
- **Action taken:** <what was mutated>
```

This audit trail is what makes triage decisions auditable from the issue thread.

### D. propose-promote-to-epic — propose only

When the assessment suggests the issue is large enough to be a parent for sub-issues, **never** directly mutate the issue into an epic. Instead, present the case:

```
Issue #<N> looks epic-shaped:
  - <reason 1: e.g. "scope spans 4+ files / multiple skills">
  - <reason 2: e.g. "explicitly enumerates 3 sub-tasks">
  - <reason 3>

Proposed promotion: invoke `epic` to file a new epic with #<N>'s scope,
  then make #<N> a sub-issue of the new epic (or close #<N> if the new
  epic supersedes it entirely).

`epic` runs three lifecycle prompts (requirements / ADR / objective)
  that this skill cannot satisfy on the user's behalf.

Recommend invoking `epic` now? [y/N]
```

On `y`: print the explicit invocation hint (`Switch to the epic skill and pass scope from #<N>`) and exit the triage of this item. Do **not** auto-invoke. Do **not** add the `epic` label to `#<N>` directly. Do **not** create a new epic from inside this skill. The hand-off is to a separate user invocation.

On anything else: leave the issue with `needs-triage` and proceed to the next item (or exit).

### E. mark-as-not-planned

```bash
# CRITICAL: label MUST be added BEFORE close (per backlog-retrospective's carve-out).
gh issue edit <N> --add-label not-planned --remove-label needs-triage --remove-label needs-grooming
gh issue close <N> --reason "not planned" --comment "Closed as not-planned: <one-line rationale>"
```

The `not-planned` label is required before close — `--reason` alone does not satisfy `backlog-retrospective`'s carve-out. Strip both `needs-grooming` and `needs-triage` defensively (the issue may have either or both).

### F. Demotion guard (epic → non-epic)

If the user manually invokes triage on an issue that **carries the `epic` label** and proposes demoting it (route 2 or 4), refuse if the epic has any open native sub-issues:

```bash
gh api "repos/$REPO/issues/<N>/sub_issues" --jq 'map(select(.state == "open")) | length'
```

If the count is non-zero, print:

> ⚠ Cannot demote / close epic #<N>: it has <K> open sub-issues. Close or reparent them first, or invoke `epic-retrospective` to walk through the proper close.

Refuse the route. The user can override only by closing the sub-issues first.

## Reference

- Outputs, success criteria, scope boundary, and cross-references: [`reference.md`](${CLAUDE_SKILL_DIR}/reference.md)
