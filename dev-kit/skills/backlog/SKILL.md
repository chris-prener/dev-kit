---
name: backlog
description: >
  Triage, prioritize, file, and plan GitHub issues — interactive authoring
  plus machine-driven auto-file mode. Also covers capture (minimal-friction
  intake for half-formed ideas), groom (periodic backlog curation across
  the needs-grooming inbox, ROADMAP horizons, stale issues, and orphans),
  and triage (routing needs-triage issues to their next lifecycle step) as
  additional named operations.
when_to_use: >
  Use to create a backlog item, bug report, feature request, tech-debt
  item, or similar issue; to capture a half-formed idea before it's lost;
  to groom the backlog periodically; to route a freshly-filed or
  freshly-groomed needs-triage issue; to suggest implementation order for
  existing issues; or to file a durable finding from QC, doc-audit, or
  code-review output (auto-file mode). Not for epics ("a bunch of
  issues", "everything related to" — use `epic`), the implementation-plan
  comment (use `implementation-plan`), or closing issues (use
  `backlog-retrospective`).
model: opus
allowed-tools: Bash(gh *)
# persona: product-owner   — grouping metadata only; not read by Claude Code.
#   Filter all skills by this comment to regenerate each persona's owned-stable list.
---

# Backlog

## Operations

This skill covers six operations spanning the issue lifecycle, from first capture through routing, curation, and planning. Identify which one the request calls for before proceeding:

1. **Capture** a half-formed idea, minimal friction → Operation: Capture.
2. **Groom** the backlog periodically (inbox, ROADMAP horizons, stale issues, orphans, epic promotion/demotion) → Operation: Groom.
3. **Triage** a single freshly-filed or freshly-groomed `needs-triage` issue → Operation: Triage.
4. **Review & prioritize** an existing backlog → Operation: Prioritize.
5. **Create a new issue** (bug, feature, tech-debt, QC finding), fully baked → Operation: Create.
6. **Auto-file** a durable finding non-interactively → *Auto-file mode* — called by other skills, not run by hand.

These were four separate skills (`backlog`, `quick-capture`, `backlog-grooming`, `triage`) until [ADR-0002](${CLAUDE_PROJECT_DIR}/docs/adr/ADR-0002-skill-decomposition.md) merged them: all four share one trigger source (a GitHub issue moving through its lifecycle) and no distinct caller class from one another, so picking the wrong one used to cost a hand-off prompt. Now it costs picking the right heading below. `backlog` kept its directory identity rather than a new umbrella name specifically so [ADR-0004](${CLAUDE_SKILL_DIR}/../_docs/ADR-0004-auto-filed-issue-protocol.md)'s auto-file caller registry needs no amendment.

If none of these fit, check *Routing* first; another skill may own the request.

## Routing

Before starting, if the request matches a signal below, offer to hand off with:

> This sounds like `<skill>` territory: `<one-line reason>`. Hand off there? [Y/n]

On `n`, continue here. This is the skill's single routing surface — do not re-derive it mid-flow. (Capture / Groom / Triage / Prioritize / Create are operations of *this* skill, not hand-offs — see *Operations* above for picking between them.)

| Request shape | Owning skill |
|---|---|
| "A bunch of issues", "everything related to", "epic for …" | `epic` |
| Write or update the `## Implementation plan` comment | `implementation-plan` |
| Close a worked issue / post a retro | `backlog-retrospective` |
| Edit roadmap horizons | `roadmap` |
| Implement, test, or open a PR for the issue | `pr-orchestrator`, `code-review` |

---

## Operation: Capture

Minimal-friction front door for filing half-formed ideas. Captures only the User story (and optional one-line context), files a `feature_request` with the `needs-grooming` Status label, and defers the worth-doing judgment, parent-epic, acceptance-criteria, and codebase-context work to Operation: Groom.

You are acting as a low-friction intake path. The user has a thought they want to record **before** it's fully baked. Heavyweight authoring (codebase analysis, worth-doing judgment, epic linkage validation, DoR pre-flight) is the wrong tool here: it would either turn the user away ("not enough detail yet") or pretend to assess things it cannot yet assess. This operation captures the User story, marks the issue with `needs-grooming`, and gets out of the way. Operation: Groom picks it up later and either promotes it to a fully-baked issue (handing off to Operation: Triage) or closes it as `not-planned`.

**Trust model.** This operation assumes the user knows the idea is half-formed. It does not gate-keep, score, or refuse. If the user's idea is actually ready-to-file, suggest Operation: Create instead and let them decide.

### Capture inputs

The operation prompts for **only** these:

1. **User story** *(required)* — `**As a** <role>, **I want** <capability>, **so that** <outcome>.` per [`${CLAUDE_SKILL_DIR}/../_partials/user-story.md`](${CLAUDE_SKILL_DIR}/../_partials/user-story.md). The `**Mechanical change** — <one-line>` escape hatch is acceptable.
2. **Optional one-line context** — free text, written verbatim into a `## Context` block under the User story. Skipped silently if the user types nothing.
3. **Title** *(optional)* — if the user doesn't supply one, derive one from the user story's `I want <capability>` clause and prefix `[Capture]`.

This operation does **NOT** prompt for: codebase context, parent epic, worth-doing judgment, acceptance criteria, priority, type beyond the default. Each of those is a `needs-grooming` deferral.

### Capture steps

#### Capture-A. Prompt for the User story

Use the format from `${CLAUDE_SKILL_DIR}/../_partials/user-story.md`. Reject empty or placeholder values for any of the three components (`As a` / `I want` / `so that`); reprompt. The mechanical-change escape hatch is acceptable.

Pick a role from the canonical list (`data consumer`, `dataset owner`, `repo maintainer`, `AI agent`, `pipeline operator`, `new contributor`) or supply free text.

#### Capture-B. Prompt for optional one-line context

> Want to add one line of context (paths touched, suspected root cause, related issue, anything)? Press Enter to skip.

Capture verbatim if non-empty. Do **not** investigate; do **not** grep; do **not** call explore agents. The user-or-grooming-time investigation is what Operation: Groom is for.

#### Capture-C. Compose the body

Use the `feature_request.md` template's heading skeleton, but fill the deferred sections with explicit TODO markers so Operation: Groom can find them:

```markdown
**Parent epic:** TODO — set during grooming

## User story

**As a** <role>,
**I want** <capability>,
**so that** <outcome>.

## Context

<one-line context, or "_(none provided at capture time)_">

## Problem

TODO — fill during grooming.

## Proposal

TODO — fill during grooming.

## Acceptance criteria

TODO — fill during grooming.

## Codebase Context

TODO — fill during grooming.

<!-- quick-capture-grooming-checklist
- [ ] Parent epic chosen (or `standalone — <reason>`)
- [ ] Problem statement written
- [ ] Proposal written
- [ ] Acceptance criteria written (falsifiable)
- [ ] Codebase context filled
- [ ] Worth-doing judged (or explicit skip-rationale)
- [ ] Type label refined (current: `enhancement`)
- [ ] Priority label set (or explicitly skipped)
- [ ] `needs-grooming` label removed
-->
```

The single `<!-- quick-capture-grooming-checklist ... -->` block is the **machine-owned** record of what's deferred (the marker name is a fixed locator string — kept unchanged by the merge, since Operation: Groom parses it verbatim). Grooming reads + ticks items here, then strips the block when fully baked. This is the one-fenced-block pattern — do not scatter `<!-- needs-grooming: X -->` markers around the body.

#### Capture-D. Compose title and labels

- **Title.** If the user supplied one, use it verbatim. Otherwise: `[Capture] <one-line distilled from the I want clause>`.
- **Labels.** Always exactly: `enhancement`, `needs-grooming`. No Priority label, no parent-epic mechanics. Grooming will refine these.

#### Capture-E. Show the user the draft, get confirmation

Print:

```
## Title
<title>

## Labels
enhancement, needs-grooming

## Body
<full body>
```

Ask `[y/N]` to file. On anything other than `y`, return to Capture-A so the user can revise. **Do not silently file.**

#### Capture-F. File via gh

```bash
REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner')
gh issue create \
  --repo "$REPO" \
  --title "<title>" \
  --body "<body>" \
  --label "enhancement,needs-grooming"
```

Capture the new issue number and URL. **Do NOT** run the DoR pre-flight gate, **do NOT** invoke `${CLAUDE_SKILL_DIR}/../_partials/epic-linkage.md` Step 3 sub-issue link (no parent epic yet), **do NOT** compute a worth-doing judgment.

#### Capture-G. Confirm to the user and exit

Print one line:

> ✓ Captured as #<N>: <title> · `<url>` · `needs-grooming`. Operation: Groom will pick this up.

Exit. The user may continue with whatever they were doing; Capture is a single-shot intake, not a session pivot.

### Capture out of scope

- **Validating epic linkage.** No parent epic at capture time; that's a deferred field.
- **Worth-doing judgment.** Same — deferred.
- **DoR pre-flight gate.** The issue intentionally lacks DoR completeness; gating would defeat the purpose. `${CLAUDE_SKILL_DIR}/../_partials/dor-preflight.md` honors the `needs-grooming` exemption (User-story check stays enforced; the rest are downgraded to INFO).
- **Codebase analysis.** Heavyweight investigation belongs in Operation: Create's Step B or in Operation: Groom.
- **Closing or merging duplicates.** Operation: Triage owns dedup decisions.
- **Picking a Type label other than `enhancement`.** If the user clearly describes a bug or tech-debt item, gently suggest Operation: Create (which will pick the right template) and let them decide. Capture's default is always `enhancement`.

---

## Operation: Groom

Periodic curation of the backlog: groom the `needs-grooming` inbox, walk ROADMAP horizons, kill stale issues, regroup orphans, and propose epic promotion or demotion.

This is **not** a lifecycle step (filing, triage, pickup, close are the steps); it is **cross-cutting maintenance** on a cadence the user chooses. Capture-produced issues with the `needs-grooming` Status label are the primary queue: this operation walks them, fills in deferred sections, and either promotes them to Operation: Triage (`needs-triage`) or closes them as `not-planned`. Beyond intake-grooming, it walks ROADMAP horizons, kills stale issues, regroups orphans, and proposes epic promotions / demotions.

**Trust model.** Read-and-confirm at every state change. Batch operations confirm per-item. Never silently rewrite issue bodies, delete labels, or close issues. Reports go to chat (and optionally `${CLAUDE_PROJECT_DIR}/.github/grooming-reports/<date>.md` — gitignored).

Pruning `### Recently Shipped` lives in `roadmap` — this operation recommends invoking it as part of the periodic cadence but does not duplicate the operation.

### Groom inputs

The sub-operation drives the inputs:

| Sub-operation | Inputs |
|---|---|
| `groom-inbox [--limit N]` | Default sub-operation. Walks all `needs-grooming` issues (default limit 10). |
| `walk-horizon <Now\|Next\|Later>` | Walks all open epics under the named ROADMAP horizon and their open sub-issues. |
| `kill-stale [--age-days N]` | Surfaces open issues last updated > N days ago (default 90). |
| `regroup-orphans` | Surfaces open non-epic issues with no parent epic AND no `**Parent epic:** standalone — <reason>` line. Proposes parent-epic links for **existing** open issues that lack one — new issues get their link at filing time via Operation: Create's Step C. Both call the same partial; the difference is *when*. |
| `propose-epic-promotion <N>` | Mirror of Operation: Triage's Triage-D sub-step — hand-off to `epic`. Included here for the case where epic-shape becomes obvious during grooming. The distinction from Triage-D: Triage-D runs on **freshly-filed** `needs-triage` items; this runs on the **broader open backlog** as periodic curation. |
| `propose-epic-demotion <N>` | Demoting an epic to a regular issue. **Refused** if any open sub-issues. Hand-off to `epic-retrospective` if appropriate. |
| `generate-grooming-report` | Read-only sweep producing a single chat report (and optional file artifact). |

### Groom steps

#### Groom-A. Resolve the sub-operation

```bash
REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner')
```

Each sub-operation is a separate sub-routine; pick one per invocation. The user may chain sub-operations in a single session (`groom-inbox` then `walk-horizon Now`), but each runs to completion (or user-deferral) before the next starts.

#### Groom-B. groom-inbox — pick up `needs-grooming` issues

```bash
gh issue list --repo "$REPO" --state open --label needs-grooming \
  --json number,title,body,labels,createdAt,updatedAt --limit "${LIMIT:-10}"
```

For each issue:

1. **Parse the grooming checklist.** The body should contain a single `<!-- quick-capture-grooming-checklist ... -->` HTML comment block (per Operation: Capture). Extract the checklist; tick off items as they're filled below. If the block is missing or malformed, surface that and offer to insert a fresh one.

2. **Collaborate on each unticked item.** For each `[ ]` item:

   - **Parent epic** → invoke `${CLAUDE_SKILL_DIR}/../_partials/epic-linkage.md` Steps 1–2 (prompt the user; validate). Record the choice; update body.
   - **Problem statement / Proposal / Acceptance criteria** → prompt the user; insert into the corresponding section. Replace the `TODO — fill during grooming.` placeholder with the real content.
   - **Codebase context** → prompt; offer to run an explore-style scan. Insert into the `## Codebase Context` section.
   - **Worth-doing judged** → ask the now/later/no question from Operation: Prioritize's Step D. On **no**, exit this item into the close-as-`not-planned` path below instead of promoting it. The user may explicitly skip with a reason — record `skipped — <reason>` in the checklist instead.
   - **Type label refined** → prompt for one of `bug` / `enhancement` / `documentation` / `tech-debt` / `audit-finding` / `qc` per `${CLAUDE_SKILL_DIR}/../_partials/label-vocabulary.md`. Default stays `enhancement` if no clear alternative. **The `epic` Type is intentionally excluded here** — if the issue is epic-shaped, exit groom-inbox for this item and route via `propose-epic-promotion` (Groom-F), which hands off to `epic` (the only legitimate path through its own requirements / ADR / objective gates).
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

   If a Type label was refined to something other than `enhancement` (and it is **not** `epic` — that path is forbidden here, see Groom-B.2 above), also `--add-label <new-type> --remove-label enhancement`. Add the chosen Priority label.

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

#### Groom-C. walk-horizon — review epics under one ROADMAP horizon

Read `${CLAUDE_PROJECT_DIR}/docs/ROADMAP.md` and parse the `### <Horizon>` section under `## Epics`. For each listed epic issue number:

1. Fetch the epic and its native sub-issues (`gh api repos/$REPO/issues/<N>/sub_issues`).
2. Surface epic title, sub-issue counts (open / closed), age since creation, last update.
3. Propose one of: leave-in-place, move-to-different-horizon (delegate to `roadmap`), close (delegate to `epic-retrospective`), refile-as-non-epic (propose-epic-demotion below).
4. Get `[y/N]` for any state-changing route.

#### Groom-D. kill-stale — surface long-stale open issues

```bash
STALE_DAYS=${AGE_DAYS:-90}
SINCE=$(date -u -v-${STALE_DAYS}d +%Y-%m-%d 2>/dev/null || date -u -d "-${STALE_DAYS} days" +%Y-%m-%d)
gh issue list --repo "$REPO" --state open \
  --search "updated:<${SINCE} -label:epic -label:blocked" \
  --json number,title,labels,updatedAt --limit 50
```

For each stale issue, surface the routes from Groom-C (with `mark-as-not-planned` as the most likely). The `blocked` label exclusion respects the explicit "waiting on something" status.

#### Groom-E. regroup-orphans — surface issues with no parent epic

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

#### Groom-F. propose-epic-promotion — hand-off only

Same propose-only contract as Operation: Triage's Triage-D. Never sets the `epic` label directly; never creates a new epic. Recommends invoking `epic`.

#### Groom-G. propose-epic-demotion — guarded hand-off

For an issue carrying the `epic` label that the user wants to demote:

1. **Refuse if any open sub-issues:**

   ```bash
   open_subs=$(gh api "repos/$REPO/issues/<N>/sub_issues" --jq 'map(select(.state == "open")) | length')
   ```

   If `open_subs > 0`:

   > ⚠ Cannot demote epic #<N>: it has <K> open sub-issues. Either close / reparent them first, or invoke `epic-retrospective` to walk through the proper close (which moves the epic to Recently Shipped, not to "regular issue").

   Refuse and exit.

2. **Otherwise**, propose the demotion and hand off — **this operation never strips the `epic` label itself**:

   > Epic #<N> has zero open sub-issues. The legitimate paths are:
   >
   > - **`epic-retrospective`** (recommended) — the proper close: posts a rollup retro, moves the entry to `### Recently Shipped` in `docs/ROADMAP.md`, leaves the `epic` label intact (a closed epic stays an epic in the audit trail).
   > - **Direct demotion to a regular issue** — unusual; requires manual `gh issue edit <N> --remove-label epic` plus a `roadmap` invocation to strip the ROADMAP entry. Not automated here because there is no clean audit trail for this path.
   >
   > Recommend invoking `epic-retrospective`. No mutation performed by this operation.

   Exit. The user invokes the chosen follow-on skill.

#### Groom-H. generate-grooming-report — read-only sweep

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

### Groom out of scope

- **Bulk close.** All closes are per-item-confirmed.
- **Auto-applying ROADMAP edits.** Horizon moves and `### Recently Shipped` pruning go through the `roadmap` skill.
- **Re-opening closed issues.** A human decision to reopen is the right gate — same rationale as the auto-file protocol's no-auto-reopen rule ([ADR-0004](${CLAUDE_SKILL_DIR}/../_docs/ADR-0004-auto-filed-issue-protocol.md)).
- **Direct epic creation / mutation.** All hand-offs.
- **Non-grooming label maintenance.** `blocked` / `UAT` / `qc-fixed` labels are owned elsewhere.
- **CI integration.** Manual / on-demand only.
- **Cross-repo grooming.** Single-repo only.

---

## Operation: Triage

Lifecycle step between filing and pickup. Routes incoming issues that carry the `needs-triage` Status label (set by Auto-file mode and by Operation: Groom after promotion). Four sub-operations: `triage-one`, `triage-inbox`, `mark-as-not-planned`, `propose-promote-to-epic`. Never directly mutates an issue into an epic — proposes and hands off to `epic` + `roadmap`. Read-and-confirm; no silent state mutation.

The triage queue is "issues with the `needs-triage` Status label." Auto-filed issues land here automatically (Auto-file mode injects `needs-triage` on file, and on dedup-hits-without-the-label). Capture-produced issues land here only after Operation: Groom promotes them out of `needs-grooming`. Issues filed via Operation: Create skip triage entirely (they were authored with full DoR).

**Trust model.** Every state change is read-and-confirm: print the proposed action and ask `[y/N]` before running any `gh` command that mutates GitHub state. Batch operations confirm per-item, not as a batch.

Triage-D (`propose-promote-to-epic`) runs on **freshly-filed `needs-triage`** items. Groom-F (`propose-epic-promotion`) runs on the **broader open backlog** as periodic curation. Both are propose-only and hand off to `epic` — same mechanic, different queue.

### State machine (clarifies overlap between Groom and Triage)

The lifecycle of a freshly-filed issue:

```
              ┌─────────────────┐                         ┌──────────────┐
  Capture     │ needs-grooming  │ ── grooming promotes ─▶ │ needs-triage │
              └─────────────────┘                         └──────────────┘
                       │                                          │
              grooming closes                              triage routes
              (not-planned, dup)                                   │
                       │                              ┌────────────┼────────────┐
                       ▼                              ▼            ▼            ▼
                  closed                        sub-issue of   standalone     not-planned
                                                   epic         (justified)    / duplicate
```

Auto-filed issues (Auto-file mode) skip the `needs-grooming` stage and land directly in `needs-triage`.

**Label ownership:**
- `needs-grooming` is **owned by Operation: Groom** (set by Operation: Capture, removed by grooming or by close).
- `needs-triage` is **owned by Operation: Triage** (set by Auto-file mode or by grooming-promotion; removed by every triage exit path).
- Both labels are **always cleared on close** (whatever the close reason). Close-reason labels (`duplicate`, `wontfix`, `not-planned`, `invalid`) replace them.

### Triage inputs

The sub-operation drives the inputs:

| Sub-operation | Inputs |
|---|---|
| `triage-one <N>` | Issue number `N`. |
| `triage-inbox [--limit N]` | Optional limit (default 10) on how many `needs-triage` issues to walk in this session. |
| `mark-as-not-planned <N>` | Issue number `N` + a one-line rationale. |
| `propose-promote-to-epic <N>` | Issue number `N`. Never mutates the issue itself; presents an epic-promotion case to the user and recommends invoking `epic`. |

### Triage steps

#### Triage-A. Resolve the sub-operation and the issue list

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

#### Triage-B. For each issue, run the triage assessment

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

Print the assessment as one fenced block per issue. Then propose **one** of the following routes (Triage-C).

#### Triage-C. Propose a route, confirm, execute

For each issue, present a numbered choice prompt. The six routes:

```
1) Route to epic <N> (sub-issue link via gh api ... /sub_issues)
2) Mark standalone (write Parent epic: standalone — <reason> into body)
3) Mark as duplicate of #<M> (close --reason "not planned"; label `duplicate`)
4) Mark as not-planned (close --reason "not planned"; label `not-planned`)
5) Propose-promote-to-epic (HAND OFF — see Triage-D; never promotes directly)
6) Defer (leave needs-triage in place; revisit later)
```

For routes 1–4, get explicit `[y/N]` confirmation before running any `gh` command. On `y`:

- **Route 1.** Verify parent epic via `${CLAUDE_SKILL_DIR}/../_partials/epic-linkage.md` validation. Run the sub-issue link with the database-id-not-issue-number caveat from that partial. Then `gh issue edit <N> --remove-label needs-triage` (and add a Type + Priority label if missing).
- **Route 2.** Edit the body to insert / update the `**Parent epic:** standalone — <reason>` line per `${CLAUDE_SKILL_DIR}/../_partials/epic-linkage.md`. Then remove `needs-triage`.
- **Route 3.** `gh issue edit <N> --add-label duplicate --remove-label needs-triage` then `gh issue close <N> --reason "not planned" --comment "Duplicate of #<M>"`. Per the close-reason carve-out, the `duplicate` label is required *before* close.
- **Route 4.** See Triage-E (mark-as-not-planned).
- **Route 5.** See Triage-D (propose-promote-to-epic).
- **Route 6.** Print a one-line "deferred — re-runs of triage-inbox will surface this again." No mutation.

After every mutation, append a single comment to the issue documenting the triage decision:

```markdown
## Triage — <YYYY-MM-DD>

- **Route:** <route name>
- **Assessment:** <one-line summary of the assessment block from Triage-B>
- **Action taken:** <what was mutated>
```

This audit trail is what makes triage decisions auditable from the issue thread.

#### Triage-D. propose-promote-to-epic — propose only

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
  that this operation cannot satisfy on the user's behalf.

Recommend invoking `epic` now? [y/N]
```

On `y`: print the explicit invocation hint (`Switch to the epic skill and pass scope from #<N>`) and exit the triage of this item. Do **not** auto-invoke. Do **not** add the `epic` label to `#<N>` directly. Do **not** create a new epic from inside this operation. The hand-off is to a separate user invocation.

On anything else: leave the issue with `needs-triage` and proceed to the next item (or exit).

#### Triage-E. mark-as-not-planned

```bash
# CRITICAL: label MUST be added BEFORE close (per backlog-retrospective's carve-out).
gh issue edit <N> --add-label not-planned --remove-label needs-triage --remove-label needs-grooming
gh issue close <N> --reason "not planned" --comment "Closed as not-planned: <one-line rationale>"
```

The `not-planned` label is required before close — `--reason` alone does not satisfy `backlog-retrospective`'s carve-out. Strip both `needs-grooming` and `needs-triage` defensively (the issue may have either or both).

#### Triage-F. Demotion guard (epic → non-epic)

If the user manually invokes Operation: Triage on an issue that **carries the `epic` label** and proposes demoting it (route 2 or 4), refuse if the epic has any open native sub-issues:

```bash
gh api "repos/$REPO/issues/<N>/sub_issues" --jq 'map(select(.state == "open")) | length'
```

If the count is non-zero, print:

> ⚠ Cannot demote / close epic #<N>: it has <K> open sub-issues. Close or reparent them first, or invoke `epic-retrospective` to walk through the proper close.

Refuse the route. The user can override only by closing the sub-issues first.

### Triage out of scope

- **Promoting to epic directly.** See Triage-D — propose-only.
- **Bulk closing.** One-at-a-time even in inbox mode (per-item confirmation).
- **DoR remediation.** If the issue fails DoR, surface the gaps; routing is still allowed (the gap is on the picker-up's plate). Use Operation: Groom for systematic DoR remediation.
- **Re-judging worth-doing.** That lives in Operation: Groom (or Operation: Create's Step D for fresh issues).
- **Auto-reopening closed issues** that show up as dedup hits — Auto-file mode is also explicitly out of this; manual reopening required (per [ADR-0004](${CLAUDE_SKILL_DIR}/../_docs/ADR-0004-auto-filed-issue-protocol.md)).
- **Setting Status labels other than `needs-triage` removal** — `blocked` / `UAT` / `qc-fixed` are owned by other skills.

---

## Operation: Prioritize

### Step 1: Fetch issues

1. Auto-detect the repo from git remote context:

   ```bash
   REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner')
   ```

2. Fetch open issues with labels, body, and metadata:

   ```bash
   gh issue list --repo "$REPO" --state open --json number,title,labels,body,createdAt,assignees --limit 100
   ```

3. If the user requested a subset, filter via `--label` or post-fetch title/body filtering.

### Step 2: Classify and prioritize

For each open issue, determine:

- **Type** from title, labels, or body content:
  - **Bug** — broken behavior or visual defect; highest priority.
  - **Feature** — new capability; medium priority.
  - **Tech debt** — refactor / cleanup / optimization; lower than bugs/features unless blocking.
- **Effort** from scope:
  - **Small** — under 1 day; mechanical, single-file, or tightly scoped.
  - **Medium** — 1–3 days; multiple files and moderate design work.
  - **Large** — 3+ days; cross-cutting or architectural.
- **Dependencies** from explicit references, implicit sequencing, or shared-file conflict.

Apply prioritization rules in this order:

1. Bugs before features before tech debt.
2. Blockers before dependents.
3. Smaller before larger within a tier.
4. Group related issues.
5. Flag file-conflict or sequencing risks.

### Step 3: Present the prioritized backlog

1. Present a summary table with columns `Priority | # | Title | Type | Effort | Dependencies | Notes`.
2. Group issues into recommended phases such as quick wins, feature work, and refactoring.
3. Explain the ordering briefly and transparently.
4. Ask which issues need implementation plans.

### Step 4: Hand off to `implementation-plan` for selected issues

Selected issues get a **durable** implementation plan — the `## Implementation plan` issue comment `implementation-plan` owns exclusively (it declares itself "the only sanctioned writer" of that contract: six `###` sections, a `Status:` state machine, the `<!-- implementation-plan-v1 -->` locator). This operation does not draft plans in a competing schema; it stages the context and hands off.

For each selected issue:

1. Gather the same context an implementation plan needs: affected files/functions, a chosen approach, open risks — from the prioritization pass above plus any additional codebase investigation the user wants.
2. Invoke `implementation-plan` `Create` for that issue, passing a 2–5 sentence `### Approach` and, if ready, starter content for `Files to touch` / `Verification` / `Risks / open questions`.
3. Report the created plan's `Status: drafting` and comment URL back to the user; do not fabricate a second, local copy of the plan.

If the user wants pure chat-scratch planning with no durable artifact, that's fine — just don't call it an "implementation plan" in the issue body; that name is reserved for `implementation-plan`'s own comment.

General guidelines: auto-detect the repo (ask if detection fails); use `gh` for GitHub interactions; read full issue bodies, not just titles; cross-reference any `docs/backlog.md`-style planning docs if present; keep prioritization reasoning visible and repository-agnostic.

---

## Operation: Create

### Step A: Determine the issue template

1. Read `${CLAUDE_PROJECT_DIR}/.github/ISSUE_TEMPLATE/`.
2. Match the request to the best template:

| Template | Use when the user describes… |
|---|---|
| `bug_report.md` | broken behavior, regression, visual defect |
| `feature_request.md` | new capability, enhancement, UX improvement |
| `tech_debt.md` | refactor, cleanup, scaling crack, internal quality |
| `qc_finding.md` | explicit QC finding |
| `documentation.md` | missing, unclear, or stale docs |

3. If the request is thin, nudge toward Operation: Capture once:

   > This looks underspecified for the full Create flow. File it via Operation: Capture with `needs-grooming` and let Operation: Groom pick it up later? Proceed here anyway? [y/N]

4. If template choice is ambiguous, ask which template to use.

### Step A.5: Capture the user story *(required)*

1. Prompt for the canonical form from `${CLAUDE_SKILL_DIR}/../_partials/user-story.md`:

   > **As a** <role>, **I want** <capability>, **so that** <outcome>.

2. Use a canonical role from the partial when possible (`data consumer`, `dataset owner`, `repo maintainer`, `AI agent`, `pipeline operator`, `new contributor`), or free text.
3. All three parts are required unless the issue is a minor chore using the partial's `**Mechanical change**` escape hatch.
4. Record this block; it goes at the top of the issue body in Step E.

### Step B: Analyze the codebase for context

Before drafting, investigate the relevant code so the issue is immediately actionable:

1. Identify affected files and functions with explore / grep / glob.
2. Capture concrete references for the issue body: file paths and function names; current behavior and brief code excerpts when useful; related existing issues via `gh issue list --search "<keywords>"`. Never invent file names or line numbers.
3. Check for overlap or blockers among existing issues.

### Step C: Determine epic linkage *(required, no silent default)*

Follow `${CLAUDE_SKILL_DIR}/../_partials/epic-linkage.md` Steps 1–2:

1. Prompt for the parent epic or a standalone justification.
2. Validate that a chosen parent exists and carries the `epic` label.
3. Record the result for the issue body.
4. If epic-linked, use it again in Step H to create the native sub-issue relation.

### Step D: Judge whether it's worth doing *(recommended)*

1. Tiny chores, `qc` findings, and `audit-finding` items may skip this and go straight to Step E.
2. Otherwise ask a single worth-doing question: **now** (do it soon), **later** (worth doing, not urgent), or **no** (not worth doing).
3. On **now**, apply a priority label (`priority/blocker`, `priority/high`, or `priority/medium`) matching urgency.
4. On **later**, file without a priority label — grooming can prioritize it later.
5. On **no**, stop here rather than proceeding to Step E; tell the user why, and offer Operation: Capture instead if they still want a lightweight record.

### Step E: Draft the issue

Fill the chosen template with user input plus codebase context:

- Fill every template section; use `N/A` rather than deleting headings.
- Body line 1 is `**Parent epic:** #<N>` or `**Parent epic:** standalone — <reason>`.
- `## User story` is the first content heading; preserve the template's heading structure exactly.
- Add a final `Codebase Context` section with affected files/functions, clarifying excerpts, and related issues.
- Write clearly enough that the reader does not need the original chat prompt.

### Step F: Review with the user

Present the draft using the review format in [`TEMPLATES.md`](${CLAUDE_SKILL_DIR}/TEMPLATES.md), and require explicit approval before posting.

### Step F.5: DoR pre-flight gate *(soft prompt)*

Run `${CLAUDE_SKILL_DIR}/../_partials/dor-preflight.md` in interactive mode before `gh issue create`. WARNING-level misses surface one summary plus a `[y/N]` proceed prompt; INFO-level misses are listed but never block; the gate never silently fixes structure. A `y` continues to Step G; anything else returns to Step E.

### Step G: Post the issue to GitHub

Once approved, create the issue with `gh issue create` under a concise, descriptive title (usually `[Type]: Brief description`), capture the issue number and URL, and retain the chosen labels.

### Step H: Link as a sub-issue *(epic-linked path only)*

If Step C chose an epic parent, attach the new issue via the native sub-issue API per `${CLAUDE_SKILL_DIR}/../_partials/epic-linkage.md` Step 3. Two critical details from that partial still apply:

- use uppercase `-F sub_issue_id=<INT>`; lowercase `-f` returns 422
- `sub_issue_id` is the issue database **id**, not the issue **number**

Skip this step entirely for standalone issues.

---

## Auto-file mode

The non-interactive sibling of Operation: Create's Steps A–H, invoked by other skills (`run-repo-qc`, `documentation`, `readme`, `walkthrough`) when they surface findings worth durable tracking. It never prompts, never closes issues, never runs the worth-doing judgment, and always labels the issue `needs-triage`.

Do not restate the contract here. Follow the full input contract, dedup rules, and severity → priority mapping in [`../_partials/backlog-autofile-mode.md`](${CLAUDE_SKILL_DIR}/../_partials/backlog-autofile-mode.md) and the auto-file protocol [`../_docs/ADR-0004-auto-filed-issue-protocol.md`](${CLAUDE_SKILL_DIR}/../_docs/ADR-0004-auto-filed-issue-protocol.md).

## Reference

- Input/output contract and success criteria for every operation: [`reference.md`](${CLAUDE_SKILL_DIR}/reference.md)
- Label vocabulary: [`../_partials/label-vocabulary.md`](${CLAUDE_SKILL_DIR}/../_partials/label-vocabulary.md); consuming-repo labels, if any, at `${CLAUDE_PROJECT_DIR}/.github/LABELS.md`
- Shared partials (`user-story`, `epic-linkage`, `dor-preflight`) under `${CLAUDE_SKILL_DIR}/../_partials/`
- Related skills: `implementation-plan`, `backlog-retrospective`, `epic`, `epic-retrospective`, `roadmap`, `pr-orchestrator`
- [ADR-0002](${CLAUDE_PROJECT_DIR}/docs/adr/ADR-0002-skill-decomposition.md) — the decision merging `quick-capture` / `backlog-grooming` / `triage` into this skill.
