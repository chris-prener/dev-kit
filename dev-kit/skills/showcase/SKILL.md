---
name: showcase
description: >
  Periodically generates a stakeholder-facing rollup of "what shipped
  and why it matters" for an upward audience. Scans merged PRs, closed
  epics, CHANGELOG release language, and ROADMAP Now/Next, then composes
  a frozen-schema markdown artifact under docs/showcases/<date>-<audience>.md
  with audience-tailored content rules (internal / leadership / external).
when_to_use: >
  Use when a stakeholder communication is due (recurring leadership
  update, external post, internal demo), or a batch of work just shipped
  and a curated narrative artifact is wanted, separate from the
  technical CHANGELOG. Trigger phrases: "generate showcase", "stakeholder
  rollup", "demo generation", "sprint review", "what shipped and why it
  matters". Not for technical pipeline/dataflow explanation
  (`walkthrough`), executing a release (out of scope for this suite —
  showcases narrate, they don't perform), Keep-a-Changelog entries
  (`changelog`), or single-epic/issue closeout (`epic-retrospective`,
  `backlog-retrospective`).
model: sonnet
allowed-tools: Bash(gh *)
# persona: writer   — grouping metadata only; not read by Claude Code.
---

# Showcase

You are about to generate a stakeholder-facing narrative answering "what shipped in the last window, and why does it matter?". This is **distinct** from `CHANGELOG.md` (per-release, technical), `walkthrough` (technical system tour), and `epic-retrospective` (per-epic closeout). The audience here is upward — leadership, external collaborators, or the broader internal team — not the implementer.

## Activation

Activate whenever:

- The operator says "generate showcase", "stakeholder rollup", "demo generation", "sprint review", or "what shipped and why it matters".
- A stakeholder communication is due (recurring leadership update, external post, internal demo) and a curated rollup artifact is needed.
- A major batch of work just shipped (e.g. one or more epics closed) and the operator wants a narrative artifact to point stakeholders at, separate from the technical CHANGELOG.

**When NOT to use** — strict routing boundaries:

- `walkthrough` — for technical system / dataflow explanations to a *developer* audience. Showcases are about outcomes, not mechanics.
- `changelog` — for Keep-a-Changelog entries. CHANGELOG is per-release and technical; showcase is per-window and outcome-framed.
- `epic-retrospective` — for closing a single epic with rollup retro + KR-impact. A showcase may *cite* a recent epic retro, but it is a periodic stakeholder artifact, not a closeout.

## Inputs

- **Optional `--since`**: ISO date for the start of the window. Default: `window_end` from the frontmatter of the latest **same-audience** showcase (`docs/showcases/*-<audience>.md`), with fallback to 8 weeks ago and a visible warning if no prior same-audience showcase exists. Per-audience derivation is intentional — an `external` showcase narrows scope and must not silently truncate the next `internal` window.
- **Optional `--audience`** ∈ {`internal`, `leadership`, `external`}. Default: `internal`, with a visible warning printed at run time: *"Audience defaulted to internal; do not redistribute as leadership/external without re-running with the correct audience."* The warning is the friction; an `external` showcase has an additional **mandatory scrub gate** (see Step 5).
- **Optional `--amend`** / `--replace`: same-day same-audience collision policy. Default behavior on collision is **refuse** with a one-line explanation. `--amend` updates the existing artifact in place (preserves frontmatter `window_start`); `--replace` overwrites after explicit confirmation. Does NOT support `-N` numeric suffixes — they would weaken the latest-filename → next-window contract.

## Steps

### 1. Determine the window

1. `today=$(date -u +%Y-%m-%d)`.
2. If `--since` not supplied:
   - Find the latest **same-audience** showcase: `ls docs/showcases/*-${AUDIENCE}.md 2>/dev/null | sort | tail -1`.
   - Read its frontmatter `window_end` (NOT the filename — the filename is generation date, which may differ from the actual window end if `--since`/`--until` were customised).
   - `since=$window_end + 1 day` (so windows are non-overlapping and contiguous).
3. If no prior same-audience showcase exists: `since=$(date -u -v-8w +%Y-%m-%d 2>/dev/null || date -u -d '8 weeks ago' +%Y-%m-%d)` and surface a warning: *"No prior `<audience>` showcase; defaulting to 8-week window. Pass `--since` for a specific scope."*
4. Output the window header for the operator: `Showcase window: <since> → <today> (audience: <audience>)`.

### 2. Gather the corpus

**Authority hierarchy** (do NOT collapse — each layer has a distinct role):

1. **Merged PRs in window** — corpus authority for "what shipped". Use `gh api --paginate` (NOT bare `gh pr list`, which truncates):

   ```bash
   REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
   gh api --paginate \
     "search/issues?q=repo:${REPO}+is:pr+is:merged+merged:>=${SINCE}+merged:<=${TODAY}" \
     --jq '.items[] | {number, title, url, closed_at, body, labels: [.labels[].name]}'
   ```

2. **Closed epics in window** — anchors for outcome framing:

   ```bash
   gh api --paginate \
     "search/issues?q=repo:${REPO}+is:issue+is:closed+label:epic+closed:>=${SINCE}+closed:<=${TODAY}" \
     --jq '.items[] | {number, title, url, closed_at, body}'
   ```

3. **CHANGELOG release-language** — supporting evidence for outcome phrasing. Read `## [Unreleased]` (current in-flight) plus any `## [vX.Y.Z] - YYYY-MM-DD` block whose date is inside the window. CHANGELOG provides *language*, not authority — if it disagrees with the merged-PR corpus, the corpus wins.

4. **ROADMAP Now/Next** — source for "What's next" section. Parse `docs/ROADMAP.md`'s `## Epics` block, extract `### Now` and `### Next` entries (per `roadmap`'s contract). Resolve each linked epic with `gh issue view` if more detail is needed for framing.

### 3. Link PRs to epics

Build a PR → epic map for the Shipped detail section. Linkage order (stop at first hit):

1. Parse the PR body for `Closes #N` / `Fixes #N` / `Resolves #N` references.
2. For each closed issue `#N`, check the sub-issue parent: `gh api repos/${REPO}/issues/${N} --jq '.parent.number // empty'`.
3. If the closed issue itself carries the `epic` label, link directly to it.
4. If a parent epic exists, link to parent.
5. Otherwise, mark `Standalone / unknown` — do NOT invent an epic.

### 4. Apply audience tailoring

Section *headings* are frozen (Step 5 schema); *content* per audience:

| Audience | Content rules |
|---|---|
| `internal` (default) | Full PR + epic detail table. Internal repo / issue links permitted. Implementation language allowed. No length cap. |
| `leadership` | Compact evidence table: only major epics + flagship PRs (operator picks; default = epics + PRs labeled `priority/blocker` or that closed an epic sub-issue). KR-impact framing where available (cite `objectives` outcomes). Soft cap ~1 page. Internal links permitted but minimised. Lead with outcomes, not mechanics. |
| `external` | **Mandatory scrub gate** before write — operator must confirm: (a) no private repo references; (b) no internal-only issue/PR URLs in body text (citations may live in an internal-only frontmatter field); (c) no non-public strategic claims; (d) no customer/company-sensitive phrasing; (e) no private roadmap commitments. Refuse the write if any check is unconfirmed. Use public-safe evidence (release tags, public docs URLs) instead of issue numbers. |

### 5. Compose the showcase

Write `docs/showcases/<today>-<audience>.md` using exactly this frozen schema. **Refuse** if the file exists unless `--amend` or `--replace` was passed (per inputs).

```markdown
---
last_updated: <today>
audience: <internal|leadership|external>
window_start: <since>
window_end: <today>
schema_version: 1
---

# Showcase — <today> — <audience>

**Window**: <since> → <today>
**Audience**: <audience>
**Corpus**: <P> merged PRs across <E> epics; <C> closed epics in window.

## Highlights

3–7 bullets, each in the form: **<outcome in operator's language>** — <one-sentence "why it matters" for this audience>. This is the headline — stakeholders who read nothing else should still leave knowing what shipped and why.

## Shipped detail

Per audience-tailoring rules in skill §4. Suggested table:

| Outcome | Epic | Evidence |
|---|---|---|
| <plain-language outcome> | <Epic N or "Standalone"> | <PR #s, or release tag, or doc URL> |

## What's next

Top 3 from ROADMAP Now/Next horizons (per skill §2 corpus item 4). Operator-edited; do NOT auto-fill without operator review.

- <Epic N: Title> — one-line "what stakeholders will see when this lands"
- …

## Notes

Operator narrative on context, caveats, decisions worth surfacing to the audience. Optional.
```

Commit the file. The showcase artifact is the primary deliverable.

### 6. Update the index

Append (or insert in reverse-chronological position) a row to `docs/showcases/README.md`:

```markdown
| Date | Audience | Window | Highlights teaser |
|---|---|---|---|
| <today> | <audience> | <since> → <today> | <one-line teaser, ≤ 80 chars> |
```

If `docs/showcases/README.md` does not exist, create it with a header + table skeleton (one-time bootstrap).

### 7. Output a console summary

For the operator:

- Window covered, audience, corpus stats (PRs, epics).
- Path to the committed showcase.
- Audience warnings (if `internal` was defaulted) or scrub-gate confirmations (if `external`).
- Reminder to commit the index README update alongside the showcase.

## Outputs

- Committed `docs/showcases/<today>-<audience>.md` with the frozen schema above.
- Updated `docs/showcases/README.md` index row (or bootstrap if first run).
- Console summary.

**No auto-filed remediation issues** — showcases are narrative artifacts. Follow-up work, if any, is the operator's call (file via `backlog` directly).

## Success criteria

- Showcase exists at `docs/showcases/<today>-<audience>.md` with all required sections + frontmatter (`audience`, `window_start`, `window_end`).
- Index README lists the showcase in reverse-chronological order.
- Re-running the same-day same-audience without `--amend`/`--replace` fails fast with a clear refusal message.

## Out of scope

- **Slide / video / dashboard generation** — markdown only. Audience tools may consume the markdown downstream.
- **Automated metric collection** — manual narrative; no auto-pulled velocity/throughput metrics.
- **Release execution** — this skill only narrates releases post-hoc, never performs them.
- **Per-release Keep-a-Changelog entries** — `changelog` owns those; this skill consumes CHANGELOG language as evidence, never writes to it.
- **Per-issue or per-epic retrospectives** — `backlog-retrospective` and `epic-retrospective` own those; this skill is window-scoped and audience-scoped.
- **Auto-filed remediation** — showcases never hand off to `backlog` auto-file. Operator-mediated follow-ups only.
- **Showcase frequency enforcement** — operator-triggered, not scheduled. `session-start` may surface "last `<audience>` showcase > 8 weeks ago" as a future watchlist item.

## Anti-patterns — what NOT to do

1. **Do NOT use the latest *any-audience* showcase to derive the default `since`.** Per-audience derivation is required (skill §1) — mixing audiences silently truncates windows.
2. **Do NOT silently overwrite an existing same-day same-audience showcase.** Refuse by default; require explicit `--amend` or `--replace`. Does NOT add `-N` suffixes.
3. **Do NOT write an `external` audience showcase without operator confirmation of all five scrub-gate items.** Leakage of internal references defeats the audience contract.
4. **Do NOT auto-fill the "What's next" section without operator review.** ROADMAP horizons are the source; operator framing is required for stakeholder language.
5. **Do NOT collapse the per-issue or per-epic retros into the showcase.** Retros are inward-facing learning; showcase is outward-facing narrative. Cite, don't replace.
6. **Do NOT trust CHANGELOG over the merged-PR corpus.** CHANGELOG can drift; merged PRs are authoritative for "what shipped".
7. **Do NOT report PRs without an epic linkage attempt.** Mark `Standalone / unknown` if no epic can be found — never invent one.
8. **Do NOT bare-`gh pr list` the corpus query** — it truncates. Use `gh api --paginate` per skill §2.

## Cross-references

- `walkthrough` — technical system tour (developer audience). Routing boundary in Activation "When NOT to use".
- `changelog` — Keep-a-Changelog authoring. Showcase consumes; does not write.
- `epic-retrospective` — single-epic closeout. Showcase may cite recent epic retros.
- `backlog-retrospective` — single-issue closeout / outcome validation. Showcase may cite recent validations as outcome evidence (especially for `leadership`).
- `objectives` — KR cadence sweep. `leadership` audience showcases should cite `## KR check-in` entries for outcome framing.
- `roadmap` — owns the ROADMAP `## Epics` Now/Next contract this skill parses for the "What's next" section.
- `backlog` — operator-mediated follow-up filing (showcase does NOT auto-file).
- `docs/showcases/` — the showcase artifact directory + index README.
