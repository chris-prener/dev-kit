---
name: glossary
description: >
  Owns docs/GLOSSARY.md. Four operations: add a term with an
  authoritative-source link, update an existing term's definition, audit
  for undefined terms appearing in skills / docs but missing from the
  glossary, and produce a cross-link report (terms → docs that reference
  them).
when_to_use: >
  Use to file a new term, fix a stale definition, audit for terminology
  drift, produce a cross-reference report, or look up what a term means.
  Trigger phrases: "add glossary term", "update glossary term", "audit
  glossary", "what is <term>", "define <term>". Not for term definitions
  that belong in a requirements doc's scope-specific glossary, if one
  exists — this skill owns the repo-wide glossary.
model: sonnet
# persona: writer   — grouping metadata only; not read by Claude Code.
---

# Glossary

Operational counterpart to `${CLAUDE_PROJECT_DIR}/docs/GLOSSARY.md`. The glossary is a living doc; this skill is the only sanctioned writer of net-new entries and the canonical place to ask "is term X defined? where?"

## Activation

Invoke when:

- A new term needs filing ("add slug to glossary", "define vintage").
- An existing term's definition is stale or wrong ("update QC report definition").
- Auditing for terminology drift ("audit glossary", "find undefined terms").
- Producing a cross-reference report ("which docs use the term family?").
- Looking up a term ("what is a sub-issue?").

## Inputs

- **Add term**: `term` (required, kebab-case-or-spaces), `section` (required — pick sections that fit the project, e.g. `domain` / `workflow` / `tooling`), `definition` (required, 1–3 sentences), `authoritative_source` (required, relative path to the doc / skill / ADR that owns the underlying concept), optional `aliases` (list).
- **Update term**: `term` (required), `definition` (required), optional `authoritative_source` (replaces existing).
- **Audit**: no inputs; walks the corpus.
- **Cross-link report**: no inputs (full report) OR `term` (required, single-term report).
- **Lookup**: `term` (required).

## Steps

### 1. Add term

1. Resolve the alphabetic insertion point in the named section.
2. Compose the entry: `### <term>\n\n<definition>. See [<authoritative-source>](<path>).\n`. If `aliases` provided, file each alias with body `See [<canonical>](#<canonical-anchor>).`
3. Insert into `docs/GLOSSARY.md`.
4. Bump frontmatter `last_updated` to today's date.
5. Surface a one-line confirmation with the new anchor URL.

**Preflight**: refuse if the term already exists (case-insensitive, ignoring punctuation). Surface the existing entry and offer the `Update term` operation instead.

### 2. Update term

1. Locate the term (case-insensitive). Refuse if not found; surface candidates and offer `Add term`.
2. Replace the definition body. If `authoritative_source` provided, replace the link.
3. Bump `last_updated`.
4. Confirm with a diff summary.

### 3. Audit

Walks the corpus for terminology drift:

| Check | Severity |
|---|---|
| Term used as bold-emphasis or `code-formatted` in a `dev-kit`/`.claude` skill body that does not appear in `docs/GLOSSARY.md` (case-insensitive) | INFO |
| Term used in `CLAUDE.md` not in glossary | WARNING |
| Glossary entry whose `authoritative_source` link is broken (file does not exist) | BLOCKER |
| Glossary entry whose `authoritative_source` link points to an archived doc under `docs/archive/` | WARNING |
| Glossary entries with duplicate canonical names (case-insensitive) | BLOCKER |
| Aliases pointing at non-existent canonical entries | BLOCKER |

Audit is **read-only**. Surfaces a markdown report.

**Out of scope** for this op: any inference of "this term should be defined" from prose; only structural/explicit usage triggers a finding.

### 4. Cross-link report

For each glossary term, lists which files in the corpus reference it (case-insensitive substring match in markdown bodies, excluding `docs/archive/`). Output is a markdown table written to chat — **NOT** materialized back into `docs/GLOSSARY.md` (avoids a cross-link-saturation maintenance trap).

For single-term mode (`term` input provided), restricts the report to one row.

### 5. Lookup

Reads the term entry and returns it inline. Convenience op for "what is X?" questions during a session. Read-only.

## Outputs

- `add term` / `update term`: modified `docs/GLOSSARY.md`; `last_updated` frontmatter bumped.
- `audit`: markdown report surfaced to chat. No file writes.
- `cross-link report`: markdown report surfaced to chat. No file writes.
- `lookup`: inline term entry surfaced to chat.

## Success criteria

- After `add term`, the new entry appears in alphabetic position in the named section, with a working authoritative-source link, and `last_updated` reflects today.
- After `update term`, the diff is limited to the term's body and the frontmatter `last_updated` line.
- `audit` produces zero BLOCKER findings against a clean corpus; INFO/WARNING findings are actionable (each names a file + suggested term + section).
- `cross-link report` lists only existing files; broken or archived references are excluded (or surfaced as audit findings, not silently included).

## Out of scope

- Auto-generating definitions from code (e.g. parsing docstrings) — manual authoring; the skill assists, the agent proposes, the human confirms.
- Translation / multi-language glossary.
- Replacing API reference documentation — that's `documentation-suite`'s job.
- Materializing exhaustive backlinks into `docs/GLOSSARY.md` — cross-link op produces a report only.

## Cross-references

- **Owned doc**: `docs/GLOSSARY.md`.
- `architecture-overview` — its audit op cross-validates that every bullet under `docs/ARCHITECTURE.md`'s key-abstractions section links to a `GLOSSARY.md` anchor that exists. That semantic check lives in the architecture skill, not here — each skill owns its own doc's outbound contract.
- `docs-organization` — catalogs `docs/GLOSSARY.md` as a never-archived living doc; this skill owns its content.
