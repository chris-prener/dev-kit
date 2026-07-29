---
name: discovery
description: >
  Time-boxed spike on-ramp for unscoped work — new territory, unfamiliar
  data or APIs, ambiguous requirements, or design alternatives. Produces
  artifacts (a requirements doc, scoped issues, an ADR, or a documented
  no-go), not production code.
when_to_use: >
  Reach for this when the answer to "what should we file?" is itself
  unknown — unfamiliar source shape, competing approaches, or "should we
  even build this?" Not for scope that's already clear (file a regular
  issue via `backlog` instead) or multi-week research phases (those are
  full epics).
model: opus
allowed-tools: Bash(gh *)
# persona: developer   — grouping metadata only; not read by Claude Code.
---

# Discovery — time-boxed spikes for unscoped work

> **Purpose.** Provide a structured pattern for time-boxed exploration when scope is unknown. Spikes produce **artifacts**: a requirements doc, scoped issues, an ADR, or a documented decision not to proceed. They do not produce production code.

For trivial ideas, the informal scratchpad path remains acceptable — this skill is for when the exploration itself needs a time-box and a forcing function to land somewhere.

## Activation

Reach for this skill when the answer to **"what should we file?"** is itself unknown. Common triggers:

- "We've been asked to add X; what's the shape, what's feasible?"
- "This API/data source has quirky structure; we need to understand it before designing around it."
- "Three approaches to this problem; which is right?"
- "Should we even build this?"

Do **not** use this skill when scope is already clear — file a regular issue via `backlog` instead.

## Inputs

- A one-sentence question to answer.
- A stated time-box (e.g., "1 session", "4 hours", "2 days").
- A stated artifact target (one of: requirements doc / scoped issues / ADR / decision summary).
- Optional context: known facts, known unknowns, hypotheses.

## Steps

### Op 1 — Open spike

Files a discovery issue with the `spike` Type label and the discovery template body.

1. Confirm the inputs above are populated. Refuse to proceed if the time-box, the question, or the artifact target is missing.
2. Create the issue via `gh issue create` with:
   - Title: `Spike: <topic>`
   - Labels: `spike` (Type — create this label if the repo doesn't have it yet; see [`_partials/label-vocabulary.md`](${CLAUDE_SKILL_DIR}/../_partials/label-vocabulary.md) for the label-migration flow). Optionally add a `priority/*` label. No other Type label is required — `spike` IS the Type for this issue.
   - Body: the discovery template (below).
3. Print the new issue URL and remind the operator of the stated time-box and expiry date.

**Discovery template (frozen for parser stability):**

```markdown
## Spike: <topic>

**Time-box**: <e.g. 1 session, 4 hours, 2 days>
**Opened**: YYYY-MM-DD
**Question to answer**: <one sentence>
**What "done" looks like**: <one of: requirements doc / scoped issues / ADR / decision summary>

## Context

<why we're doing this; what's known; what's unknown>

## Approach

<how exploration will proceed>

## Findings (updated as work progresses)

- YYYY-MM-DD: <finding>
```

### Op 2 — Update findings

Appends a dated finding line under the `## Findings` section of the spike issue body.

1. Read the spike issue body.
2. Locate the `## Findings (updated as work progresses)` heading.
3. Append `- YYYY-MM-DD: <finding>` (UTC date) under the existing entries.
4. PATCH the issue body via `gh api`.

### Op 3 — Close spike

Closes the spike with a structured artifact-selection comment. **REQUIRES the operator to name the artifact produced** — silent close is refused by this skill.

1. Refuse if no artifact selection is supplied.
2. Compose the closure comment:

   ```markdown
   <!-- spike-closure-v1 -->
   ## Spike closure

   **Artifact**: <one of: requirements doc / scoped issues / ADR / not-planned decision summary>
   **Resolved by**:
     - For requirements doc: path to the doc
     - For scoped issues: `#<a>`, `#<b>`, ...
     - For ADR: `docs/adr/ADR-NNNN-<slug>.md`
     - For not-planned: one-paragraph decision summary inline below
   **Time-box**: stated `<…>`; actual `<N>` days/hours
   **Notes**: <optional>
   ```

3. Post the comment via `gh issue comment`.
4. Close the issue:
   - For requirements doc / scoped issues / ADR outputs: `gh issue close <N>` (default reason `completed`).
   - For not-planned outputs: add a `not-planned` close-reason label first, then `gh issue close <N> --reason not-planned`.

**Enforceability note (honest):** This skill enforces artifact selection only during its own `close-spike` op. A user running raw `gh issue close <N>` or closing through the GitHub UI bypasses this — there is no periodic auditor in this suite that catches it after the fact. Treat closure discipline as a habit, not a guarantee.

This skill does **not** invoke `backlog-retrospective`: that skill expects PR/commit evidence, which spikes don't produce. The spike-closure comment above plays the analogous role for discovery work.

### Op 4 — Audit

Surfaces overrun spikes — open `spike` issues whose stated `Time-box:` has expired.

1. Query open issues carrying the `spike` label.
2. For each, parse the `**Time-box**:` line and the `**Opened**:` date from the body. Supported time-box formats (frozen):
   - `1 session` → expires same UTC day as Opened.
   - `<N> hours` → expires Opened + N hours.
   - `<N> days` → expires Opened + N days (UTC).
   - Other / unparseable → annotate `time-box unparseable`.
3. Compare expiry to current UTC time.
4. For overrun spikes, recommend one of: **continue** (with explicit extension reason — append a finding noting the extension), **cut scope** (close with partial artifact), or **close** (`close-spike` op above).

**Severity:** Overrun is a re-evaluation prompt, **not** a hard fail. Spikes can legitimately extend; the discipline is making the extension visible and intentional.

## Outputs

- A new `spike`-labeled issue (Op 1).
- Appended findings on a spike issue (Op 2).
- A spike-closure comment + closed issue (Op 3).
- A list of overrun spikes with re-evaluation prompts (Op 4).

## Success criteria

- Spike issues consistently follow the discovery template.
- Closure produces a structured `<!-- spike-closure-v1 -->` comment naming the artifact.
- Overrun spikes are surfaced by this skill's own audit op — there's no separate detector to rely on.
- The artifact produced by closure (requirements doc / issues / ADR / not-planned summary) survives context loss.

## Out of scope

- Multi-week research phases (those are full epics with their own structure).
- Cross-repo spikes.
- Auto-classification of "spike vs. regular issue" — the operator decides at filing.
- Production code changes — spikes produce artifacts, not implementation.

## Cross-references

- `backlog` — files scoped issues when that's the spike's artifact.
- `requirements` — produces a requirements doc when that's the artifact.
- `adr` — produces an ADR when that's the artifact.
