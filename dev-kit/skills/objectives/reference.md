# Objectives Curator — reference

Contract and QA detail for the `objectives` skill. `SKILL.md` holds the procedure; this file holds outputs, success criteria, scope, and cross-references.

## Outputs

- Edited `${CLAUDE_PROJECT_DIR}/docs/OBJECTIVES.md`.
- Optionally: cross-link edits in epic bodies (when linking).
- Audit report (markdown text).
- Cadence sweep: appended `## KR check-in <date>` block + bumped `Last check-in` fields + auto-filed remediation issues (one per at-risk/off-track KR, deduped on `kr-checkin:O<n>:KR<n.m>`) + console summary.

## Success criteria

- File: new objective in `## Active` with all fields populated and 2–4 KRs.
- Update / check-in: target KR / objective updated; `Last check-in` bumped.
- Link: epic number appears in `Linked epic(s):` and in the linked epic's body.
- Audit: report enumerates stale check-ins and orphan objectives.
- Close: objective moved to `## Archived` with final scoring + "What we learned."
- Cadence sweep: `## KR check-in <date>` block at top of `## Active` listing every active KR with one of the four status values; every active objective's `Last check-in` matches the sweep date; remediation issues filed for every `at-risk` / `off-track` KR (deduped per `kr-checkin:O<n>:KR<n.m>`).

## Out of scope

- `objective/<id>` runtime labels — overhead not justified at this scale.
- Automated KR data collection — KR scoring is manual.
- Cross-repo objectives — single repo for now.
- Sub-issue → objective linkage — only epics link to objectives; sub-issues link via their parent epic.
- Forcing OKR structure when the rhythm feels heavy — degrading to a freeform "Outcomes" section is allowed.

## Cross-references

- `epic` — prompts for supporting objective linkage when filing an epic.
- `epic-retrospective` — prompts for KR-impact when closing an epic.
- `roadmap` — the Now horizon often correlates with the active-objective set.
- `session-start` — surfaces active objectives + stale check-ins at session bootstrap.
- `backlog` — auto-file mode invoked by op H for remediation of `at-risk` / `off-track` KRs.
