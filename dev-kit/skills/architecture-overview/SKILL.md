---
name: architecture-overview
description: >
  Owns docs/ARCHITECTURE.md. Four operations: refresh the doc from
  current repo state, audit its internal contracts (every key
  abstraction links to a real glossary anchor, named components and
  files exist, ADR cross-references resolve), update a single section
  without touching the rest, and drift detection (what's changed
  materially since the doc's last update).
when_to_use: >
  Use after material structural change lands (new component, new
  subsystem, an accepted ADR with structural implications) and the doc
  needs a refresh; to verify the doc's internal contracts still hold; to
  update one section in isolation; or to check whether drift has
  accumulated since the doc was last touched. Not for per-component deep
  docs (those live near the code) or historical decision rationale
  (that's `adr`) — this doc reflects current state only.
model: opus
# persona: developer   — grouping metadata only; not read by Claude Code.
---

# Architecture Overview

Operational counterpart to `docs/ARCHITECTURE.md`. The architecture doc is a living state snapshot; this skill is the only sanctioned writer and the canonical place to ask "is the architecture doc still accurate?"

## Activation

Invoke when:

- Material structural change has landed (new component, new subsystem, an accepted ADR with structural implications) and the doc needs a refresh.
- The doc's internal contracts need verification — key abstractions link to real glossary anchors, named components exist.
- A targeted section refresh is needed (e.g. an updated dataflow diagram) without touching the rest of the doc.
- Periodic drift detection is wanted (e.g. at the start of a session, or before a release).

## Inputs

- **For refresh**: optional `force` (default `false`; if `true`, regenerates even when drift detection reports clean).
- **For audit**: no inputs.
- **For section update**: `section` (required, one of the doc's H2 headings), `content` (required, replacement markdown for that section).
- **For drift detection**: optional `since` (ISO date; defaults to the doc's `last_updated` frontmatter value).

## Steps

### 1. Refresh

Regenerates `docs/ARCHITECTURE.md` from current repo state:

1. Re-read the codebase's major components; confirm the **Major components** table has the right paths and responsibilities.
2. Re-read accepted ADRs under `docs/adr/`; confirm cited ADRs still exist with `status: accepted`.
3. Re-read `docs/GLOSSARY.md` (if present); confirm every term cited under **Key abstractions** still has an entry and the anchor resolves.
4. Re-render the architecture diagram (Mermaid) if its node set has changed — additions to material paths surface as a manual prompt; do NOT auto-rewrite the diagram's shape.
5. Bump `last_updated` and `last_updated_by`.
6. Surface a diff summary.

**Hard constraint**: refresh is **structure-preserving**. The H2 section list does not change without a deliberate decision to amend the doc's own contract.

### 2. Audit

Verifies the doc's internal contracts:

| Check | Severity |
|---|---|
| Bullet under `## Key abstractions` does not link to `docs/GLOSSARY.md#<anchor>` | BLOCKER |
| Linked GLOSSARY anchor does not exist | BLOCKER |
| Component path named in `## Major components` does not exist on disk | BLOCKER |
| ADR file cited in body does not exist under `docs/adr/` | BLOCKER |
| ADR cited in body has `status: superseded` (should reference the superseding ADR instead) | WARNING |
| Mermaid block fails GitHub-syntax validation | WARNING |
| Glossary term used definitionally in body but absent from `## Key abstractions` | INFO |
| Skill cited in body does not exist in the skill suite | BLOCKER |

Audit is read-only. Surfaces a markdown report.

### 3. Section update

1. Validate `section` against the canonical H2 set.
2. Replace the named section's body (between its `## <heading>` line and the next `## ` or `---`).
3. Bump `last_updated` and `last_updated_by`.
4. Re-run the audit op against the modified doc; surface findings before declaring success.

### 4. Drift detection

Surfaces structural changes since `last_updated` that **likely** warrant a refresh:

1. Resolve `since` from input or from the doc's frontmatter.
2. Run `git log --since="$since" --name-only --pretty=format: -- <material paths>` and dedupe paths. Material paths are whatever this repo's `## Major components` table names as source directories.
3. Cross-check each changed path against `## Major components`:
   - Changed paths under a listed component → INFO review-trigger ("review whether this component's description changed materially").
   - New ADRs whose body mentions "architecture" or "structural" → INFO review-trigger.
   - Removed or renamed paths previously named in `## Major components` → WARNING ("named component no longer exists").
4. Surface a markdown report, one row per finding.

**Severity philosophy**: drift detection is a **review trigger**, not a deterministic truth test. Raw file-count delta is too noisy for WARNING. WARNING is reserved for broken structural invariants; everything else is INFO.

## Outputs

- `refresh`: modified `docs/ARCHITECTURE.md`; `last_updated` bumped; diff summary surfaced.
- `audit`: markdown report. No file writes.
- `section update`: modified `docs/ARCHITECTURE.md` (one section); `last_updated` bumped; audit report attached.
- `drift detection`: markdown report. No file writes.

## Success criteria

- After `refresh`, the audit op reports zero BLOCKERs against the modified doc.
- After `section update`, the modified region is bounded to the named section; no other H2 sections are touched.
- `audit` produces zero false-positive BLOCKERs against a clean doc — every BLOCKER names a real broken contract.
- `drift detection` produces zero findings on a clean post-refresh doc.

## Out of scope

- Auto-rewriting the Mermaid diagram's shape — surfaces additions but defers authorship for shape changes.
- Per-component deep documentation — that lives near the code.
- Historical architecture rationale — that's `adr`; this doc reflects current state only.
- Auto-generating the **Major components** table from a directory walk — manual authoring with refresh assistance.

## Cross-references

- **Owned doc**: `docs/ARCHITECTURE.md`.
- `glossary` — owns `docs/GLOSSARY.md`; this skill's audit enforces the ARCHITECTURE→GLOSSARY anchor contract in one direction, `glossary`'s own audit enforces the reverse.
- `adr` — architectural decisions this doc cites.
