---
name: epic
description: >
  Files an epic parent issue with the canonical body template, the epic
  label, and a Priority label, and registers it in the roadmap. Restartable;
  runs requirements / ADR / objective lifecycle gates before filing.
when_to_use: >
  Use to scope a new thematic body of work into an epic, or to resume
  filing one that was interrupted (issue exists but roadmap entry is
  missing). Not for small, single-PR work — file that via `backlog`
  instead.
model: opus
allowed-tools: Bash(gh *)
# persona: product-owner   — grouping metadata only; not read by Claude Code.
---

# Epic Creator

You are about to file (or finish filing) a GitHub epic — a parent issue that anchors a thematic body of work and gathers sub-issues. Epics are how the roadmap is curated and how multi-PR work survives session loss.

This skill produces:

1. A GitHub issue with the `epic` label, a Priority label, the canonical title format `[Epic <id>] <theme>`, and the canonical body template.
2. (Optionally) a milestone attachment.
3. A roadmap entry registered via the `roadmap` skill at `Later` (default) or `Next` (if explicitly committed).

It does NOT link sub-issues. Sub-issue linking happens at sub-issue *creation* time via the `backlog` skill's epic-linkage step.

## Inputs

- **Required**: theme / one-paragraph goal of the epic.
- **Required**: at least one Priority label (`priority/blocker` / `priority/high` / `priority/medium`) per `${CLAUDE_SKILL_DIR}/../_partials/label-vocabulary.md`.
- **Required for resume**: existing epic issue number `N`. Skill reads everything else from the issue.
- **Optional**: epic ID (auto-suggest if existing IDs are clean monotonic single letters; otherwise prompt).
- **Optional**: milestone name (`vX.Y.Z`). If supplied and the milestone doesn't exist, the skill prompts whether to create it.
- **Optional**: initial horizon — `Later` (default) or `Next` (if explicitly committed).
- **Optional**: list of related issue numbers / PR numbers / spec sections / requirements doc / objective KR / ADRs to populate the body's "Related work" section.

## When does work warrant an epic?

File an epic when **at least two** of the following hold:

- Work spans **multiple PRs** by design (not just because one got too big).
- Work involves **architectural decisions** that should be ratified across the team.
- Work has a **non-trivial sub-issue tree** (≥ 4 sub-issues) where the relationship matters more than the individual issues.
- Work has a **distinct outcome / KR** that's worth tracking on the roadmap as a unit.

If only one holds, prefer a regular issue (or a small chain) via `backlog`.

## Gate precedence

Three lifecycle gates run in this order, **before** body composition. Each gate is documented below in Phase 1.5; this section is the precedence rule:

1. **Does work warrant an epic at all?** — covered above.
2. **Requirements doc gate (soft).** Is there a requirements doc for this body of work? If not, prompt the user whether to draft one first via `requirements`. **Bypassable** for tiny epics (user explicitly says "no requirements doc needed").
3. **ADR prompt (soft, never blocks).** Does this epic involve an architectural decision (a structural choice that future sessions might re-litigate)? If yes, prompt the user to link an existing ADR or file one via `adr`. If the user declines, record `no-adr-needed` with a one-line reason for the record — same courtesy as the requirements bypass, not a precondition for filing. `adr` itself is optional and never a gate; this skill doesn't hold epics to a stricter bar.
4. **Supporting objective prompt (soft, never blocks).** Is there a relevant active objective? If yes, prompt the user to link it; if no, prompt the user whether to file one via `objectives`. Either way, never block.

Conflicts: the gates do not collide because they operate on independent dimensions (the *what*, the *how*, and the *why*). A "tiny epic" that bypasses the requirements gate may still trigger the ADR gate if it involves an architectural choice; that's expected.

## Steps

### Phase 0: Pre-flight + duplicate check

1. **`gh repo view --json nameWithOwner -q .nameWithOwner`** to resolve the repo.
2. **Resume mode** — if the user supplied an existing epic issue number `N`:
   - `gh issue view <N> --json number,title,state,labels,body,milestone,url`.
   - Verify it has the `epic` label and the title matches `[Epic <id>] <theme>`. Halt with a clear error if not.
   - Skip Phases 1–3 and jump to Phase 4 (roadmap registration).
3. **Duplicate epic detection** — search existing epics for likely duplicates:
   - `gh issue list --label epic --state all --limit 100 --json number,title,state`.
   - Normalize the proposed theme (lowercase, strip punctuation / `[Epic <id>]` prefix) and compare against existing titles using a simple substring / token-overlap heuristic.
   - **If matches found**: surface them to the user with title, state, and number. **Require explicit confirmation** to proceed (do NOT auto-no-op; do NOT auto-create). The user may legitimately want a follow-on epic on the same theme.

### Phase 1: Pick the epic ID

1. List existing epic IDs by parsing titles of all epics returned in Phase 0's duplicate-check call.
2. **If existing IDs are clean monotonic single letters** starting at `A` with no gaps (e.g., `A`, `B`, `C`): suggest the next unused single letter.
3. **Otherwise** (gaps, multi-character slugs, no existing epics, or skip patterns): **prompt the user** for an explicit ID. Do not invent `AA` or guess. The convention beyond Z is undocumented; it should remain so until a real case appears.
4. The user may always override the suggestion.

### Phase 1.5: Lifecycle gates

Run the three gates in order. Each gate produces either a "proceed" signal or a "draft / file the linked artifact first" hand-off. None of the three block filing outright — the requirements and objective gates were always bypassable, and the ADR gate now matches (see 1.5b).

#### 1.5a — Requirements gate (soft)

1. Ask the user: "Is there a requirements doc under `${CLAUDE_PROJECT_DIR}/docs/requirements/` that scopes this epic?"
2. If yes: capture the path; populate the `Requirements doc` field of the body template in Phase 2.
3. If no: prompt: "Should I invoke the `requirements` skill to draft one first, or proceed without one (tiny-epic bypass)?"
   - If draft: hand off to `requirements`; resume this skill afterwards (Phase 0 resume mode is fine).
   - If bypass: record `Requirements doc: _none — tiny-epic bypass_` in the body and continue.

#### 1.5b — ADR prompt (soft, never blocks)

1. Ask the user: "Does this epic involve an architectural decision (a structural choice that future sessions might re-litigate)?"
2. If no: continue.
3. If yes: ask "Is there a relevant ADR under `${CLAUDE_PROJECT_DIR}/docs/adr/`, or are you about to file one?"
   - If existing ADR: capture the ADR number; populate the `ADRs` field in the body template.
   - If about to file: hand off to `adr`; resume this skill afterwards.
   - If neither and the user wants to skip it: record a one-line `no-adr-needed` reason in the body's `Decisions and constraints` section if one is offered, but **don't require it** — continue either way. Filing stalls on architectural rationale often enough that a mandatory justification would just train users to type a throwaway line; the ADR itself stays the actual record when one is warranted.

#### 1.5c — Supporting objective prompt (soft, never blocks)

1. Read `${CLAUDE_PROJECT_DIR}/docs/OBJECTIVES.md`'s `## Active` section.
2. Ask the user: "Does this epic support one of the active objectives [list O1, O2, …]? Or should we file a new one?"
3. If linking to an existing objective: capture `O<n>`; populate the `Supporting objective` field in the body. Hand off to `objectives` (link operation) so the linkage appears in `OBJECTIVES.md` too.
4. If filing a new objective: hand off to `objectives` (file operation), then resume.
5. If user declines (no supporting objective): record `Supporting objective: _none_` in the body and continue. **Never block.**

### Phase 2: Compose the epic body

Use exactly this template. All sections required:

```markdown
# [Epic <id>] <theme>

## Goal

One paragraph. What outcome does this epic produce? Past-tense user-visible
description of the world after the epic closes.

## Why now?

2–4 sentences. What's the cost of not doing this; what's the trigger;
what does this unblock.

## Acceptance criteria (epic-level)

- [ ] Bullet 1 — measurable, falsifiable.
- [ ] Bullet 2 — ...
- [ ] ...

## Decisions and constraints

- Pre-ADR record of architectural choices made for this epic. Linked
  ADRs (per the ADR gate) are the authoritative record; this section
  notes any constraints or rationale that didn't warrant a separate ADR.
- If the ADR gate was bypassed with `no-adr-needed`, record the
  justification verbatim here.

## Sub-issues

_None yet._ Sub-issues are linked here via the GitHub native sub-issue
feature when filed by the `backlog` skill.

## Dependencies

_None._ <!-- or: - Blocked by #NN — one-line reason -->

## Related work

- **Requirements doc:** `docs/requirements/<slug>.md` (or `_none — tiny-epic bypass_`).
- **Supporting objective:** `O<n>` in `docs/OBJECTIVES.md` (or `_none_`).
- **ADRs:** `ADR-NNNN`, `ADR-MMMM`, … (or `_none — no-adr-needed: <justification>_`).
- **Predecessors:** <issue/PR refs, or "none">
- **Successors:** <if known, or "none">

## Out of scope

- Bullet 1 — explicit boundary.
- Bullet 2 — ...
```

The skill prompts the user to fill each section interactively (or accept a pre-supplied draft). Empty AC / Goal / Why-now sections halt filing.

### Phase 3: File the issue

1. Compose the title: `[Epic <id>] <theme>`.
2. Compose the labels: `epic` (required) + the user-supplied Priority label (required) + any other Type/Status labels the user requested.
3. **File via `gh issue create`**:
   ```bash
   gh issue create \
     --title "[Epic <id>] <theme>" \
     --body-file <tempfile> \
     --label "epic,<priority>,<other>"
   ```
   Capture the returned URL and issue number.
4. **Optional milestone attachment**:
   - If user requested a milestone name, check existence: `gh api repos/<owner>/<repo>/milestones --jq '.[] | select(.title=="<name>") | .number'`.
   - If missing: prompt whether to create. If yes: `gh api -X POST repos/<owner>/<repo>/milestones -f title=<name>` (`vX.Y.Z` semver naming convention).
   - Attach: `gh issue edit <N> --milestone <name>`.

### Phase 4: Register in the roadmap

1. **Invoke the `roadmap` skill** with operation `add <N> <horizon>` where horizon defaults to `Later` (or `Next` if user explicitly said committed).
2. The roadmap skill validates the issue, derives `<id>` / `<theme>` / `<milestone>` from the live issue, and inserts the canonical entry. Pass through the user-supplied one-line goal.
3. **If the `roadmap` skill errors** (e.g., epic block missing, format invalid): surface the error and report partial success — the issue exists, the roadmap is not updated. The user can re-run this skill in resume mode after resolving the roadmap problem; Phase 0 will skip filing and jump to Phase 4.

### Phase 5: Confirm + report

- Print: epic URL, epic number, ID, horizon, milestone (or `—`), and roadmap-entry diff.
- Cleanup any tempfiles.

## Reference

- Outputs, success criteria, restartable semantics, scope boundary, and cross-references: [`reference.md`](${CLAUDE_SKILL_DIR}/reference.md)
