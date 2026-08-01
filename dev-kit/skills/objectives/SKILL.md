---
name: objectives-curator
description: >
  Files, updates, links, audits, checks in on, and closes Objectives and
  Key Results in docs/OBJECTIVES.md, and drives the recurring
  cross-objective KR cadence sweep (Op H). The objective layer sits
  above epics; epics link to a supporting objective when one exists.
when_to_use: >
  Use when a new strategic intent should be made explicit, a KR's
  progress changes, an epic needs a supporting objective, an objective
  hasn't had a check-in in 90+ days, or the recurring cadence sweep is
  due ("KR check-in", "review KRs", "cadence sweep"). Not for tactical
  work scoped within a single epic (that's an epic) or implementation
  milestones (those go on the roadmap). Lightweight ritual — degrades to
  a freeform "Outcomes" list if OKR rhythm feels heavy; don't force the
  structure.
model: opus
allowed-tools: Bash(gh *)
# persona: product-manager   — grouping metadata only; not read by Claude Code.
---

# Objectives Curator

You are about to file (or update / link / audit / check-in / close) an entry in `${CLAUDE_PROJECT_DIR}/docs/OBJECTIVES.md`. Objectives are the strategic layer above epics — they answer "why is this body of work strategically important?". Each Objective has 2–4 Key Results that quantify progress.

This skill produces:

1. A new Active section entry in `docs/OBJECTIVES.md` (file operation), or
2. A KR-progress edit (update operation), or
3. A `Linked epic(s)` field update on an objective (link operation), or
4. An audit report listing stale / unlinked objectives, or
5. A check-in note on an active objective (check-in operation), or
6. A move from Active → Archived with a "What we learned" line (close operation), or
7. A cross-objective **cadence sweep** (op H) — walks every active objective + KR in one transaction, composes a `## KR check-in <date>` summary block at the top of `## Active`, bumps each objective's `Last check-in`, and hands off `at-risk` / `off-track` KRs to the `backlog` skill's auto-file mode for remediation issues.

## Inputs

- **For file**: title (qualitative intent); 2–4 KRs (quantitative when possible); rationale paragraph; optional initial linked epic(s).
- **For update**: target objective ID (`O1`); target KR ID (`KR1.2`); new progress value or note.
- **For link**: target objective ID; epic issue number(s).
- **For audit**: no inputs.
- **For check-in**: target objective ID; check-in note (1–3 sentences).
- **For close**: target objective ID; final scoring note; "What we learned" line.
- **For cadence sweep**: no required inputs (operator is prompted per KR for status). Optional: time-window note, theme.

## Steps

### A. Determine the operation

file / update / link / audit / check-in / close / cadence-sweep.

### B. File a new objective

1. Read `${CLAUDE_PROJECT_DIR}/docs/OBJECTIVES.md`; pick the next monotonic objective ID (`O<n+1>`).
2. Append under `## Active`:
   - Title.
   - Filed (today's date), Linked epic(s), Last check-in (today's date).
   - "Why this matters" rationale paragraph.
   - 2–4 KRs with rationale, target, current progress.
3. If the objective was prompted by an epic-creation flow, return control to `epic` so it can record the linkage in the epic body.

### C. Update a KR

1. Find the target KR in the objective.
2. Update its `Progress:` line (or numeric scoring).
3. Bump the parent objective's `Last check-in` date.

### D. Link an epic to an objective

1. Find the target objective.
2. Add the epic number to the `Linked epic(s):` line.
3. Cross-link from the epic's body (Supporting objective field).

### E. Audit

Walk `${CLAUDE_PROJECT_DIR}/docs/OBJECTIVES.md`:

- List active objectives with their last-check-in age.
- Flag objectives with `Last check-in` > 90 days ago.
- Flag objectives with no `Linked epic(s)` (likely orphan strategic intent).
- Flag KRs whose progress hasn't moved in > 60 days.

Output: a markdown report.

### F. Check-in

1. Append a one-line check-in note to the objective (date + 1–3 sentence summary).
2. Bump `Last check-in`.
3. Optionally update KR progress at the same time.

### G. Close

1. Move the objective from `## Active` to `## Archived`.
2. Add a final "What we learned" one-liner.
3. Mark each KR with its final scoring (met / partial / missed) and a one-line note.

### H. Cadence sweep

The cross-objective sweep that drives the recurring KR rhythm. Use this — not op F — when the trigger is "KR check-in" / "review KRs" / "cadence sweep" / "objective drift". Op F remains the right choice for a single-objective targeted check-in.

1. **Enumerate active objectives.** Read `docs/OBJECTIVES.md`; collect every objective under `## Active` with its KR list.
2. **Per KR, prompt the operator** for current status from the four-value vocabulary: `on-track | at-risk | off-track | done`. Bundle the prompts (e.g., one block per objective) so the operator can answer in one pass. Optionally accept a one-line rationale per KR.
3. **Compose the summary block.** Insert at the **top** of the `## Active` section (immediately after the section heading, before the first objective), in this exact schema:

   ```markdown
   ## KR check-in YYYY-MM-DD

   Summary: <N> active objectives; <M>/<T> KRs on-track, <X> at-risk, <Y> off-track, <Z> done.

   - O1 (<short title>): <on-track | at-risk | off-track | mixed>
     - KR1.1 — <status> — <optional one-line rationale>
     - KR1.2 — <status>
   - O2 (<short title>): ...
   ```

   Append, never overwrite, prior `## KR check-in <date>` blocks. The most recent sweep stays at the top of `## Active`; older sweeps remain in chronological-reverse order. Trim sweeps older than 6 months at the operator's discretion (NOT automatically).
4. **Bump per-objective `Last check-in`** for every objective touched, even those with no KR-status change (the sweep itself is the touch). This keeps op E (audit) honest — a swept objective is no longer "stale".
5. **Hand off remediation** for every KR marked `at-risk` or `off-track`:

   **Check-ID inventory:** `kr-checkin` — the single stable check-ID this op emits; the at-risk/off-track KR identity lives in `dedup_id`'s `<scope>` component (`O<n>-KR<n.m>`), not in a per-check-type ID, since every remediation issue from this op is the same kind of finding.

   **Auto-file invocation contract:**
   - Invoke the `backlog` skill's auto-file mode with:
     - `template = tech_debt`
     - `parent_epic = <objective's first linked open epic, if any; else standalone with reason "objective-level remediation, not yet scoped to an epic">`
     - `labels = ["tech-debt", "<priority/medium for at-risk | priority/high for off-track>"]` per [ADR-0004](${CLAUDE_SKILL_DIR}/../_docs/ADR-0004-auto-filed-issue-protocol.md) severity mapping
     - `dedup_id = objectives:O<n>-KR<n.m>:kr-checkin` (status is **NOT** part of the dedup key — this prevents spam when a KR cycles between at-risk and recovered, and correctly re-files if a closed remediation issue's KR drifts back into trouble)
     - Body with the literal marker `<!-- autofile-id: objectives:O<n>-KR<n.m>:kr-checkin -->` and `tech_debt.md` template headings; reference the sweep date and the prior status if applicable.
   - `done` and `on-track` KRs are not filed.
6. **Output a console summary** for the operator: total KRs swept, count by status, list of issues filed (or skipped via dedup).

## Reference

- Outputs, success criteria, scope boundary, and cross-references: [`reference.md`](${CLAUDE_SKILL_DIR}/reference.md)
