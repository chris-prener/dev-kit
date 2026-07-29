---
name: backlog-grooming
description: >
  Periodic curation of the backlog: groom the needs-grooming inbox, walk
  ROADMAP horizons, kill stale issues, regroup orphans, and propose epic
  promotion or demotion.
when_to_use: >
  Use for periodic backlog maintenance — weekly, monthly, or before a
  planning conversation — not for a single lifecycle step. Not for filing
  a single new issue (half-formed → `quick-capture`; ready → `backlog`),
  routing a single freshly-filed issue (`triage`), or closing a
  worked-through issue (`backlog-retrospective`).
model: sonnet
allowed-tools: Bash(gh *)
# persona: product-owner   — grouping metadata only; not read by Claude Code.
---

# Backlog Grooming

You curate the backlog periodically. This is **not** a lifecycle step (filing, triage, pickup, close are the steps); it is **cross-cutting maintenance** on a cadence the user chooses. Quick-captured issues with the `needs-grooming` Status label are the primary queue: this skill walks them, fills in deferred sections, and either promotes them to triage (`needs-triage`) or closes them as `not-planned`. Beyond intake-grooming, it walks ROADMAP horizons, kills stale issues, regroups orphans, and proposes epic promotions / demotions.

**Trust model.** Read-and-confirm at every state change. Batch operations confirm per-item. Never silently rewrite issue bodies, delete labels, or close issues. Reports go to chat (and optionally `${CLAUDE_PROJECT_DIR}/.github/grooming-reports/<date>.md` — gitignored).

## Routing

Before starting, if the request matches a signal below, offer to hand off with:

> This sounds like `<skill>` territory: `<one-line reason>`. Hand off there? [Y/n]

On `n`, continue here.

| Request shape | Owning skill |
|---|---|
| Filing a single new issue, half-formed | `quick-capture` |
| Filing a single new issue, ready | `backlog` |
| Routing a single freshly-filed issue | `triage` |
| Closing a worked-through issue | `backlog-retrospective` |

Pruning `### Recently Shipped` lives in `roadmap` — this skill recommends invoking it as part of the periodic cadence but does not duplicate the operation.

## Inputs

The operation drives the inputs:

| Operation | Inputs |
|---|---|
| `groom-inbox [--limit N]` | Default operation. Walks all `needs-grooming` issues (default limit 10). |
| `walk-horizon <Now\|Next\|Later>` | Walks all open epics under the named ROADMAP horizon and their open sub-issues. |
| `kill-stale [--age-days N]` | Surfaces open issues last updated > N days ago (default 90). |
| `regroup-orphans` | Surfaces open non-epic issues with no parent epic AND no `**Parent epic:** standalone — <reason>` line. Proposes parent-epic links for **existing** open issues that lack one — new issues get their link at filing time via `backlog` Step C. Both call the same partial; the difference is *when*. |
| `propose-epic-promotion <N>` | Mirror of the `triage` skill's Step D — hand-off to `epic`. Included here for the case where epic-shape becomes obvious during grooming. The distinction from triage's version: triage runs on `needs-triage`; this runs on the broader open backlog. |
| `propose-epic-demotion <N>` | Demoting an epic to a regular issue. **Refused** if any open sub-issues. Hand-off to `epic-retrospective` if appropriate. |
| `generate-grooming-report` | Read-only sweep producing a single chat report (and optional file artifact). |

## Steps

### A. Resolve the operation

```bash
REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner')
```

Each operation is a separate sub-routine; pick one per skill invocation. The user may chain operations in a single session (`groom-inbox` then `walk-horizon Now`), but each runs to completion (or user-deferral) before the next starts.

### B. groom-inbox — pick up `needs-grooming` issues

```bash
gh issue list --repo "$REPO" --state open --label needs-grooming \
  --json number,title,body,labels,createdAt,updatedAt --limit "${LIMIT:-10}"
```

For each issue:

1. **Parse the grooming checklist.** The body should contain a single `<!-- quick-capture-grooming-checklist ... -->` HTML comment block (per the `quick-capture` skill). Extract the checklist; tick off items as they're filled below. If the block is missing or malformed, surface that and offer to insert a fresh one.

2. **Collaborate on each unticked item.** For each `[ ]` item:

   - **Parent epic** → invoke `${CLAUDE_SKILL_DIR}/../_partials/epic-linkage.md` Steps 1–2 (prompt the user; validate). Record the choice; update body.
   - **Problem statement / Proposal / Acceptance criteria** → prompt the user; insert into the corresponding section. Replace the `TODO — fill during grooming.` placeholder with the real content.
   - **Codebase context** → prompt; offer to run an explore-style scan. Insert into the `## Codebase Context` section.
   - **Worth-doing judged** → ask the now/later/no question from the `backlog` skill's Step D. On **no**, exit this item into the close-as-`not-planned` path below instead of promoting it. The user may explicitly skip with a reason — record `skipped — <reason>` in the checklist instead.
   - **Type label refined** → prompt for one of `bug` / `enhancement` / `documentation` / `tech-debt` / `audit-finding` / `qc` per `${CLAUDE_SKILL_DIR}/../_partials/label-vocabulary.md`. Default stays `enhancement` if no clear alternative. **The `epic` Type is intentionally excluded here** — if the issue is epic-shaped, exit groom-inbox for this item and route via `propose-epic-promotion` (Step F), which hands off to `epic` (the only legitimate path through its own requirements / ADR / objective gates).
   - **Priority label** → prompt for `priority/blocker` / `priority/high` / `priority/medium` or skip for a low-stakes / speculative item.

3. **Run DoR pre-flight.** Once all items are ticked (or explicitly skipped), invoke `${CLAUDE_SKILL_DIR}/../_partials/dor-preflight.md` in interactive mode. WARNING-level misses surface a proceed prompt.

4. **Strip the checklist block.** If pre-flight passes, remove the entire `<!-- quick-capture-grooming-checklist -->` HTML comment block from the body — it has served its purpose.

5. **Promote — `needs-grooming` → `needs-triage`.** Edit the issue:

   ```bash
   gh issue edit <N> --repo "$REPO" \
     --body-file <updated-body> \
     --add-label needs-triage \
     --remove-label needs-grooming
   ```

   If a Type label was refined to something other than `enhancement` (and it is **not** `epic` — that path is forbidden here, see Step B.2 above), also `--add-label <new-type> --remove-label enhancement`. Add the chosen Priority label.

6. **Sub-issue link** (if epic-linked path was chosen). Per `${CLAUDE_SKILL_DIR}/../_partials/epic-linkage.md` Step 3 — uppercase `-F sub_issue_id=<INT>` with the database `id` (not the issue number). Soft error on link failure; the routing decision stands.

7. **Close-out comment** on the issue:

   ```markdown
   ## Grooming — <YYYY-MM-DD>

   - **Promoted:** `needs-grooming` → `needs-triage`
   - **Sections filled:** <comma-list of items ticked>
   - **Worth-doing:** now / later (or "skipped — <reason>")
   - **Parent epic:** #<N> (or `standalone — <reason>`)
   ```

**Alternative exit path: close as `not-planned`.** If during grooming the user decides the captured idea isn't worth pursuing:

```bash
# Defensively clear BOTH lifecycle labels — even though needs-grooming
# is the only one we expect on a quick-captured intake, we strip
# needs-triage too to guarantee the close path leaves no stale label.
gh issue edit <N> --add-label not-planned \
  --remove-label needs-grooming --remove-label needs-triage
gh issue close <N> --reason "not planned" --comment "Closed during grooming: <one-line>"
```

The `not-planned` label is required **before** close (per `backlog-retrospective`'s carve-out).

### C. walk-horizon — review epics under one ROADMAP horizon

Read `${CLAUDE_PROJECT_DIR}/docs/ROADMAP.md` and parse the `### <Horizon>` section under `## Epics`. For each listed epic issue number:

1. Fetch the epic and its native sub-issues (`gh api repos/$REPO/issues/<N>/sub_issues`).
2. Surface epic title, sub-issue counts (open / closed), age since creation, last update.
3. Propose one of: leave-in-place, move-to-different-horizon (delegate to `roadmap`), close (delegate to `epic-retrospective`), refile-as-non-epic (propose-epic-demotion below).
4. Get `[y/N]` for any state-changing route.

### D. kill-stale — surface long-stale open issues

```bash
STALE_DAYS=${AGE_DAYS:-90}
SINCE=$(date -u -v-${STALE_DAYS}d +%Y-%m-%d 2>/dev/null || date -u -d "-${STALE_DAYS} days" +%Y-%m-%d)
gh issue list --repo "$REPO" --state open \
  --search "updated:<${SINCE} -label:epic -label:blocked" \
  --json number,title,labels,updatedAt --limit 50
```

For each stale issue, surface the routes from Step C (with `mark-as-not-planned` as the most likely). The `blocked` label exclusion respects the explicit "waiting on something" status.

### E. regroup-orphans — surface issues with no parent epic

```bash
gh issue list --repo "$REPO" --state open \
  --search "-label:epic" \
  --json number,title,body,labels --limit 100 \
  | jq '[.[] | select((.body // "") | test("\\*\\*Parent epic:\\*\\*") | not)]'
```

For each orphan:

1. Surface title, current labels, body excerpt.
2. Invoke `${CLAUDE_SKILL_DIR}/../_partials/epic-linkage.md` Step 1 to prompt for a parent epic OR an explicit standalone justification.
3. Edit the body to insert the `**Parent epic:** ...` line at the top. If linked, add the sub-issue link via `${CLAUDE_SKILL_DIR}/../_partials/epic-linkage.md` Step 3.
4. Get per-issue confirmation before any mutation.

### F. propose-epic-promotion — hand-off only

Same propose-only contract as the `triage` skill's Step D. Never sets the `epic` label directly; never creates a new epic. Recommends invoking `epic`.

### G. propose-epic-demotion — guarded hand-off

For an issue carrying the `epic` label that the user wants to demote:

1. **Refuse if any open sub-issues:**

   ```bash
   open_subs=$(gh api "repos/$REPO/issues/<N>/sub_issues" --jq 'map(select(.state == "open")) | length')
   ```

   If `open_subs > 0`:

   > ⚠ Cannot demote epic #<N>: it has <K> open sub-issues. Either close / reparent them first, or invoke `epic-retrospective` to walk through the proper close (which moves the epic to Recently Shipped, not to "regular issue").

   Refuse and exit.

2. **Otherwise**, propose the demotion and hand off — **this skill never strips the `epic` label itself**:

   > Epic #<N> has zero open sub-issues. The legitimate paths are:
   >
   > - **`epic-retrospective`** (recommended) — the proper close: posts a rollup retro, moves the entry to `### Recently Shipped` in `docs/ROADMAP.md`, leaves the `epic` label intact (a closed epic stays an epic in the audit trail).
   > - **Direct demotion to a regular issue** — unusual; requires manual `gh issue edit <N> --remove-label epic` plus a `roadmap` invocation to strip the ROADMAP entry. Not automated here because there is no clean audit trail for this path.
   >
   > Recommend invoking `epic-retrospective`. No mutation performed by this skill.

   Exit. The user invokes the chosen follow-on skill.

### H. generate-grooming-report — read-only sweep

Run all of the above in **read-only** mode and compose a single chat report:

```markdown
# Grooming report — <YYYY-MM-DD>

## Inbox (`needs-grooming`)
- <N> issues, oldest <D> days

## ROADMAP horizons
- Now: <K> open epics, <X> open sub-issues
- Next: ...
- Later: ...

## Stale (>90d, open, non-epic, non-blocked)
- <K> issues; top 5 listed

## Orphans (open, no Parent epic line)
- <K> issues; top 5 listed

## Suggestions
- (sorted by impact)
- If `### Recently Shipped` is long, recommend invoking `roadmap` to prune.
```

Optionally write to `${CLAUDE_PROJECT_DIR}/.github/grooming-reports/<YYYY-MM-DD>.md` (the directory is gitignored — local artifact only).

## Reference

- Outputs, success criteria, out-of-scope boundary, and cross-references: [`reference.md`](${CLAUDE_SKILL_DIR}/reference.md)
