---
name: requirements-author
description: >
  Drafts, amends, supersedes, and audits requirements documents under
  docs/requirements/. Requirements docs sit before epic creation in the
  lifecycle and capture the *what* (background, sources, R1..Rn)
  separately from the *how* (ADRs).
when_to_use: >
  Use when a new body of work is being scoped and the *what* needs to be
  written down before an epic is filed, an existing requirements doc
  needs a new or amended requirement, a doc is being replaced by a newer
  one, or the user wants a coverage check across docs/requirements/. Not
  for capturing how/why something will be implemented (that's an ADR,
  `adr`) or filing the parent issue once requirements are settled
  (that's `epic`).
model: opus
# persona: product-manager   — grouping metadata only; not read by Claude Code.
---

# Requirements Author

You are about to draft (or amend / supersede / audit) a requirements document under `${CLAUDE_PROJECT_DIR}/docs/requirements/`. Requirements docs capture the *what* of a body of work — background, sources, and a numbered list of testable requirements. They are the document an epic links to when scoping work, sitting **before** the epic in the lifecycle.

This skill produces:

1. A new file `docs/requirements/<slug>.md` from `_template.md` (draft operation), **or**
2. An edit to an existing requirements doc that adds / amends a requirement (amend operation), **or**
3. A status flip to `superseded` with cross-link to a newer doc (supersede operation), **or**
4. An audit report listing draft / stalled requirements docs.

It does NOT produce ADRs (that's `adr`) or epics (that's `epic`).

## Inputs

- **For draft (new doc)**:
  - Slug for the file (`<slug>.md` under `docs/requirements/`).
  - Background paragraph(s).
  - At least one source (S1) with link / summary.
  - At least one requirement (R1) with rationale, source citations, and acceptance criteria.
  - Optional: related epic, related ADR(s).
- **For amend**: target doc filename; the new R-number content (or the existing R-number being amended).
- **For supersede**: target doc filename; new doc filename (must already exist).
- **For audit**: no inputs; reads the directory.

## Steps

### A. Determine the operation

draft / amend / supersede / audit.

### B. Draft a new requirements doc

1. Confirm the slug doesn't already exist.
2. Copy `${CLAUDE_PROJECT_DIR}/docs/requirements/_template.md` to `${CLAUDE_PROJECT_DIR}/docs/requirements/<slug>.md`.
3. Fill frontmatter: `status: draft`, owner, today's date, related epic / ADR (if known).
4. Replace the template's Background / Sources / Requirements placeholders with real content. R-numbers start at R1 and are monotonic.
5. If the requirements doc is intended to anchor an epic, prompt the user: "Should I now invoke `epic` to file the parent epic?"
6. Status remains `draft` until the user (or a downstream review process) flips it to `approved`.

### C. Amend an existing doc

1. Read the target doc; identify the next R-number (or the existing R-number to amend).
2. Insert the new R or edit the existing one.
3. Bump `last-updated` in frontmatter.
4. **Preserve R-number stability.** Never renumber existing requirements; if a requirement is removed, mark it `(removed)` rather than renumbering.

### D. Supersede

1. In the new doc's frontmatter, set `supersedes: docs/requirements/<old-slug>.md`.
2. In the old doc's frontmatter, set `status: superseded` and add `superseded-by: docs/requirements/<new-slug>.md`.
3. Cross-link in both docs' Background sections (one-sentence note).

### E. Audit

Walk `${CLAUDE_PROJECT_DIR}/docs/requirements/`:

- List docs by status (draft / in-review / approved / superseded).
- Flag `draft` docs older than 30 days with no linked epic (stalled).
- Flag `approved` docs whose linked epic is closed (decide: archive? keep for history?).
- Flag docs with zero requirements (R-section empty).

Output: a markdown report with sections for each flagged class.

## Outputs

- `docs/requirements/<slug>.md` (draft)
- Edited existing requirements doc (amend / supersede)
- Audit report (markdown text)

## Success criteria

- Draft: new doc exists with all frontmatter fields populated, at least one source (S1), and at least one requirement (R1) with acceptance criteria.
- Amend: R-numbers preserved; `last-updated` bumped; existing content untouched (except the targeted R).
- Supersede: both docs cross-linked; old doc's status is `superseded`.
- Audit: report enumerates status counts and flags stalled / orphan docs.

## Out of scope

- Auto-generating requirements from issues / discussions — manual draft.
- Approval workflow / signoff tooling — `status: approved` is convention, not enforced by GitHub.
- Cross-repo requirements — single repo for now.
- Capturing implementation decisions — those are ADRs.

## Cross-references

- `epic` — soft-gates on requirements-doc linkage when filing an epic; bypassable for tiny epics.
- `adr` — peer "captures decisions" tool; requirements capture *what we want to build*, ADRs capture *how we decided to build it*.
- `objectives` — KRs may reference requirements docs they depend on.
