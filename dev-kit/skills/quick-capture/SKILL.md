---
name: quick-capture
description: >
  Minimal-friction front door for filing half-formed ideas. Captures only
  the User story (and optional one-line context), files a feature_request
  with the needs-grooming Status label, and defers the worth-doing
  judgment, parent-epic, acceptance-criteria, and codebase-context work to
  backlog-grooming.
when_to_use: >
  Use when the user has a thought worth recording before it's fully
  baked. The intake of last resort when the heavyweight `backlog` flow
  would discard a thought before it gets recorded. Not for a complete
  bug report or feature description (use `backlog`), a finding-producing
  skill's output (use `backlog`'s auto-file mode), or scope the user is
  closing out (nothing to file — just say so).
model: haiku
allowed-tools: Bash(gh *)
# persona: product-owner   — grouping metadata only; not read by Claude Code.
---

# Quick Capture

You are a low-friction intake skill. The user has a thought they want to record **before** it's fully baked. Heavyweight authoring (codebase analysis, worth-doing judgment, epic linkage validation, DoR pre-flight) is the wrong tool here: it would either turn the user away ("not enough detail yet") or pretend to assess things it cannot yet assess. This skill captures the User story, marks the issue with `needs-grooming`, and gets out of the way. `backlog-grooming` will pick it up later and either promote it to a fully-baked issue (handing off to `triage`) or close it as `not-planned`.

**Trust model.** This skill assumes the user knows the idea is half-formed. It does not gate-keep, score, or refuse. If the user's idea is actually ready-to-file, suggest `backlog` instead and let them decide.

## Inputs

The skill prompts for **only** these:

1. **User story** *(required)* — `**As a** <role>, **I want** <capability>, **so that** <outcome>.` per [`${CLAUDE_SKILL_DIR}/../_partials/user-story.md`](${CLAUDE_SKILL_DIR}/../_partials/user-story.md). The `**Mechanical change** — <one-line>` escape hatch is acceptable.
2. **Optional one-line context** — free text, written verbatim into a `## Context` block under the User story. Skipped silently if the user types nothing.
3. **Title** *(optional)* — if the user doesn't supply one, derive one from the user story's `I want <capability>` clause and prefix `[Capture]`.

The skill **does NOT** prompt for: codebase context, parent epic, worth-doing judgment, acceptance criteria, priority, type beyond the default. Each of those is a `needs-grooming` deferral.

## Steps

### A. Prompt for the User story

Use the format from `${CLAUDE_SKILL_DIR}/../_partials/user-story.md`. Reject empty or placeholder values for any of the three components (`As a` / `I want` / `so that`); reprompt. The mechanical-change escape hatch is acceptable.

Pick a role from the canonical list (`data consumer`, `dataset owner`, `repo maintainer`, `AI agent`, `pipeline operator`, `new contributor`) or supply free text.

### B. Prompt for optional one-line context

> Want to add one line of context (paths touched, suspected root cause, related issue, anything)? Press Enter to skip.

Capture verbatim if non-empty. Do **not** investigate; do **not** grep; do **not** call explore agents. The user-or-grooming-time investigation is what `backlog-grooming` is for.

### C. Compose the body

Use the `feature_request.md` template's heading skeleton, but fill the deferred sections with explicit TODO markers so `backlog-grooming` can find them:

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

The single `<!-- quick-capture-grooming-checklist ... -->` block is the **machine-owned** record of what's deferred. Grooming reads + ticks items here, then strips the block when fully baked. This is the one-fenced-block pattern — do not scatter `<!-- needs-grooming: X -->` markers around the body.

### D. Compose title and labels

- **Title.** If the user supplied one, use it verbatim. Otherwise: `[Capture] <one-line distilled from the I want clause>`.
- **Labels.** Always exactly: `enhancement`, `needs-grooming`. No Priority label, no parent-epic mechanics. Grooming will refine these.

### E. Show the user the draft, get confirmation

Print:

```
## Title
<title>

## Labels
enhancement, needs-grooming

## Body
<full body>
```

Ask `[y/N]` to file. On anything other than `y`, return to Step A so the user can revise. **Do not silently file.**

### F. File via gh

```bash
REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner')
gh issue create \
  --repo "$REPO" \
  --title "<title>" \
  --body "<body>" \
  --label "enhancement,needs-grooming"
```

Capture the new issue number and URL. **Do NOT** run the DoR pre-flight gate, **do NOT** invoke `${CLAUDE_SKILL_DIR}/../_partials/epic-linkage.md` Step 3 sub-issue link (no parent epic yet), **do NOT** compute a worth-doing judgment.

### G. Confirm to the user and exit

Print one line:

> ✓ Captured as #<N>: <title> · `<url>` · `needs-grooming`. `backlog-grooming` will pick this up.

Exit. The user may continue with whatever they were doing; quick-capture is a single-shot intake, not a session pivot.

## Outputs

- One new GitHub issue with labels `enhancement, needs-grooming`.
- A `<!-- quick-capture-grooming-checklist -->` block in the body that grooming reads.
- One confirmation line in chat. No file writes locally.

## Success criteria

- The skill never blocks on the user not having a worth-doing judgment / a parent epic / acceptance criteria.
- The User-story block is **always** present and complete — that is the only invariant the skill guarantees.
- The grooming checklist block is present and parseable as a single fenced HTML comment.
- The issue carries exactly two labels at file time: `enhancement` + `needs-grooming`. Anything more is grooming's job.

## Out of scope

- **Validating epic linkage.** Quick capture has no parent epic at file time; that's a deferred field.
- **Worth-doing judgment.** Same — deferred.
- **DoR pre-flight gate.** The issue intentionally lacks DoR completeness; gating would defeat the purpose. `${CLAUDE_SKILL_DIR}/../_partials/dor-preflight.md` honors the `needs-grooming` exemption (User-story check stays enforced; the rest are downgraded to INFO).
- **Codebase analysis.** Heavyweight investigation belongs in `backlog` Step B or in grooming.
- **Closing or merging duplicates.** Triage owns dedup decisions.
- **Picking a Type label other than `enhancement`.** If the user clearly describes a bug or tech-debt item, gently suggest `backlog` (which will pick the right template) and let them decide. Quick capture's default is always `enhancement`.

## Cross-references

- [`${CLAUDE_SKILL_DIR}/../_partials/user-story.md`](${CLAUDE_SKILL_DIR}/../_partials/user-story.md) — only partial composed by this skill.
- [`${CLAUDE_SKILL_DIR}/../_partials/dor-preflight.md`](${CLAUDE_SKILL_DIR}/../_partials/dor-preflight.md) — `needs-grooming` exemption that prevents the DoR gate from spuriously WARN-ing on quick-captured issues.
- `backlog` — the heavyweight sibling; may nudge underspecified intakes here.
- `backlog-grooming` — picks up `needs-grooming` items, ticks the checklist, hands off to `triage` (or closes as `not-planned`).
- `triage` — receives the issue from grooming once `needs-grooming` is cleared.
