---
name: adr
description: >
  Files, supersedes, audits, and indexes Architecture Decision Records in
  `docs/adr/`. Optional, never a gate — available whenever a non-trivial
  architectural choice deserves a persistent record.
when_to_use: >
  Use when a non-trivial architectural decision has been made and needs
  persistence ("we decided X over Y because Z"), when an existing ADR
  needs revising (supersede, don't edit), or when the ADR index needs a
  refresh or freshness audit. Not for process/convention changes (those
  belong in project docs, not ADRs), implementation details that don't
  change the architectural posture, or decisions still in flight (file
  when accepted, not when proposed, unless deliberately using
  `status: proposed`).
model: opus
allowed-tools: Bash(gh *)
# persona: developer   — grouping metadata only; not read by Claude Code.
---

# ADR

You are about to file (or audit / supersede / re-index) an Architecture Decision Record under `${CLAUDE_PROJECT_DIR}/docs/adr/`. ADRs are short, dated, immutable documents that capture *why* a non-trivial architectural choice was made. They prevent re-litigating settled decisions across sessions.

This skill produces:

1. A new ADR file (file operation), **or**
2. A status update to an existing ADR (supersede operation), **or**
3. An audit report listing orphan / stale ADRs, **or**
4. A refreshed `docs/adr/README.md` index.

It does NOT modify the body of an accepted ADR — accepted ADRs are immutable. Changes happen via supersession.

## Activation

Activate this skill whenever:

- A non-trivial architectural decision has been made (or is about to be made) and needs persistence.
- An existing ADR is being revised — supersede, don't edit.
- A session needs to verify ADR coverage / freshness.
- A change touches `docs/adr/` and the index needs a refresh.

**When NOT to use**:
- Process / convention changes — those belong in project documentation, not ADRs.
- Implementation details that don't change the architectural posture.
- Decisions still in flight — file when accepted, not when proposed (unless explicitly using `status: proposed`).

## Inputs

- **For file (new ADR)**:
  - Title (concise, decision-shaped, not problem-shaped).
  - Source(s): PR number, issue number, or conversation that motivates the decision.
  - Context paragraph(s): forces at play, prior state, why it's insufficient.
  - Decision statement (phrased "We will X") and alternatives considered.
  - Consequences: easier / harder / constraints / revisit-when.
  - Optional: related epic, related requirements doc, related ADRs.
- **For supersede**: number of the ADR being superseded; all of the above for the new ADR.
- **For audit**: no inputs; reads `docs/adr/`.
- **For index refresh**: no inputs; reads `docs/adr/`.

## Steps

### A. Determine the operation

Ask the user (if not implied by the trigger): file new / supersede / audit / index.

### B. File a new ADR

1. List existing files under `docs/adr/ADR-*.md` and pick the next monotonic number `NNNN`.
2. Copy `docs/adr/_template.md` to `docs/adr/ADR-NNNN-<kebab-case-title>.md` (create the template if this is the first ADR in the repo).
3. Fill in: status `accepted` (or `proposed` if not yet ratified), date (today), source(s), context, decision, consequences, references.
4. Append a row to `docs/adr/README.md`'s index table (append at the bottom — numbering is monotonic).
5. Cross-link from related docs as applicable (the related epic body, peer ADRs' References section).

### C. Supersede an existing ADR

1. Identify the existing ADR (number + filename).
2. File a **new** ADR (steps in B), capturing the new decision.
3. Edit the old ADR's frontmatter: `Status: superseded by ADR-MMMM` (where MMMM is the new number). **Do not modify the old ADR's Context / Decision / Consequences sections** — those are the historic record.
4. In the new ADR's Context section, briefly note what's changing relative to the superseded ADR.
5. Update `docs/adr/README.md`'s index for both files (old → "superseded"; new row appended).

### D. Audit

Walk `docs/adr/`:

- Count ADRs by status (accepted / proposed / deprecated / superseded).
- Flag ADRs in `proposed` status older than 30 days (stale proposals).
- Flag ADRs whose `Related epic(s)` references an issue that no longer exists or is closed without resolution.
- Flag ADRs not referenced from any other ADR, epic, or project doc (orphans — may indicate the decision isn't actually in force).

Output: a markdown report with a section per flagged class.

### E. Index refresh

Walk `docs/adr/ADR-*.md`, parse each file's frontmatter (number, title, status, date), and rewrite `docs/adr/README.md`'s index table in monotonic order. Preserve everything outside the table.

## Outputs

- `docs/adr/ADR-NNNN-<title>.md` (file or supersede)
- Updated `docs/adr/README.md` (file, supersede, or index refresh)
- Updated old ADR frontmatter only (supersede)
- Audit report (markdown text in chat)

## Success criteria

- File: new ADR exists with all required frontmatter fields populated and references back to its source(s); index updated.
- Supersede: new ADR exists; old ADR's status is `superseded by ADR-MMMM`; old ADR's body is unchanged; both rows correct in the index.
- Audit: report enumerates accepted / proposed / deprecated / superseded counts and lists orphans / stale proposals.
- Index refresh: every `ADR-NNNN-*.md` file appears exactly once in the index table.

## Out of scope

- Auto-generating ADRs from PR descriptions or commits.
- Decision-approval workflow tooling (`status: accepted` is convention, not a gated workflow).
- Renaming ADRs — once filed, immutable; supersede instead.
- Capturing process or convention changes — those belong in project documentation.

## Cross-references

- `epic` — when filing an epic involves an architectural decision, the epic skill prompts for a relevant ADR (or an explicit `no-adr-needed` justification).
- `requirements` — requirements docs cross-reference ADRs they depend on.
- `objectives` — objective context can cite ADRs.
- `session-start` — session bootstrap can read `docs/adr/README.md` for context.
- `architecture-overview` — `docs/ARCHITECTURE.md` cites accepted ADRs; this skill's audit flags stale citations from the other direction.
