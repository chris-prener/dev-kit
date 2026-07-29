---
name: docs-organization-curator
description: >
  Owns the shape of docs/. Places a new doc in the right spot, archives a
  superseded doc explicitly, audits the tree for orphans and staleness,
  and refreshes per-directory README.md catalogs.
when_to_use: >
  Use to decide where a new doc belongs, retire a doc that's been
  superseded or absorbed, run a freshness/orphan sweep across docs/, or
  regenerate a directory README catalog from the actual file inventory.
  Not for ADRs (`adr` owns filing/supersede/audit for those — they're
  exempt from this skill's archival rule), routine content edits to a
  doc an owner skill already maintains, or PR-scoped doc-staleness
  checks (`documentation-audit-changes`).
model: sonnet
# persona: writer   — grouping metadata only; not read by Claude Code.
---

# Docs Organization Curator

Operational counterpart to `${CLAUDE_PROJECT_DIR}/docs/`: it enforces and applies placement, archival, and freshness conventions rather than just describing them.

## Operations

1. **Add doc** — place a new doc, write minimal frontmatter, update the parent catalog → Step B.
2. **Archive doc** — retire a doc to `docs/archive/`, update catalogs → Step C.
3. **Audit** — orphan / staleness / naming / broken-link report → Step D.
4. **Refresh README** — regenerate a directory's catalog from its actual file inventory → Step E.

## The doc set

dev-kit skills already own a handful of named docs — this skill catalogs and archives around them, it does not duplicate their content contracts:

| Location | Owner skill | Archived? |
|---|---|---|
| `docs/ARCHITECTURE.md` | `architecture-overview` | Never — updated in place |
| `docs/ROADMAP.md` | `roadmap` | Never — updated in place |
| `docs/OBJECTIVES.md` | `objectives` | Never — updated in place |
| `docs/GLOSSARY.md` | `glossary` | Never — updated in place |
| `CHANGELOG.md` | `changelog` | Never — release-driven, old entries stay in-file |
| `docs/adr/` | `adr` | Never — append-only, superseded not archived |
| `docs/requirements/<slug>.md` | `requirements` | Yes — superseded requirements move to archive |
| `docs/playbooks/<slug>.md` | `playbooks` | Yes |
| `docs/showcases/<date>-<audience>.md` | `showcase` | No — dated artifacts, left in place |

Anything else under `docs/` is freeform explanatory or how-to writing this skill places and archives directly.

## Inputs

- **Add doc**: title; one-line purpose; proposed filename or topic; optional draft content.
- **Archive doc**: source path; reason (superseded by what, or retired why); optional redirect-stub flag (default: no redirect).
- **Audit**: no inputs.
- **Refresh README**: target directory (e.g. `docs/`, `docs/requirements/`, `docs/adr/`).

## Steps

### A. Determine the operation

add doc / archive doc / audit / refresh README.

### B. Add a new doc

1. Match the doc against the table above. If it's one of the named docs, hand off: "This is `<owner-skill>`'s doc — invoke that skill instead." Do not create it here.
2. Otherwise place it under `docs/` (or an existing series subfolder like `docs/requirements/`, `docs/playbooks/`) using a kebab-case filename; top-level state-of-the-project docs use ALL-CAPS naming to match the table above.
3. Validate the path doesn't collide with an existing file. If it does, halt with the conflict.
4. Compose the file: minimal frontmatter (`last_updated: <today>`) if it's a living reference doc that will need freshness tracking; otherwise skip frontmatter entirely — don't force ceremony on a one-off explainer.
5. Write the file, then update the relevant `README.md` catalog (the immediate parent directory's hub, if one exists) with a one-line description.
6. Print: `Added <path>. Updated catalog in <readme>.` (or note that no catalog exists yet).

### C. Archive a doc

1. Validate the source path exists and isn't already under `docs/archive/`.
2. Reject for ADRs: print `"ADRs are append-only history; supersede via the adr skill instead."` and halt.
3. Reject for the never-archived docs in the table above (`ARCHITECTURE.md`, `ROADMAP.md`, `OBJECTIVES.md`, `GLOSSARY.md`, `CHANGELOG.md`): print `"<doc> is updated in place, not archived."` and halt.
4. Compute the destination: `docs/archive/<YYYY>/<slug>.md`, where `<YYYY>` is the current year and `<slug>` mirrors the original filename (or is renamed for clarity at the operator's option). Create the directory if missing.
5. Move the file (`git mv`).
6. Prepend a header:
   ```markdown
   > **Archived YYYY-MM-DD**: superseded by `<new-path>` / retired because <reason>.
   ```
7. Update the relevant active `README.md` to drop the archived doc from its catalog (or note it as superseded with a cross-link, if still referenced elsewhere).
8. (Optional, operator opt-in) Leave a one-line redirect stub at the original path:
   ```markdown
   > Moved to [`<new-path>`](<new-path>) on YYYY-MM-DD.
   ```
9. Print: `Archived <source> → <dest>. Updated <active-readme>.`

### D. Audit

Walk the `docs/` tree and produce a structured report:

1. **Orphan docs** — files not linked from any `README.md` in their directory.
2. **Missing frontmatter** — the named docs from the table above that carry `last_updated` in their contract but currently lack it.
3. **Stale frontmatter** — `last_updated` older than 180 days on a doc that carries the field. This is a nudge, not a mandate — an owner skill with its own cadence (e.g. `objectives`'s KR check-ins) may already cover freshness for its doc.
4. **Broken links** — relative links inside `docs/` that don't resolve to a file in the tree.
5. **Naming drift** — top-level `docs/` files that should be ALL-CAPS per the table above but aren't, or subfolder files that aren't kebab-case.

Classify each finding BLOCKER / WARNING / INFO. Print the report; for BLOCKER/WARNING findings, offer to auto-file via `backlog`'s auto-file mode with `template = tech_debt`, `dedup_id = docs-organization:<path>:<check-id>`, labels `["documentation", "<priority/*>"]` (blocker → `priority/blocker`, warning → `priority/medium`), and either `parent_epic` or `standalone_reason` supplied by the operator.

### E. Refresh README

1. Read the current `README.md` for the target directory (if absent, offer to create a minimal one).
2. Enumerate the directory's actual file inventory (excluding `README.md` itself, templates, and dot-files).
3. Diff: files present but missing from the catalog → add; files cataloged but missing from disk → remove (likely archived or renamed).
4. Apply the diff; preserve any operator-authored prose verbatim — only the catalog table/list is regenerated.
5. Print: `Refreshed <readme>. Added: [<paths>], Removed: [<paths>].`

## Outputs

- **Add doc**: a new file under `docs/`, catalog updated if a parent README exists.
- **Archive doc**: a moved file under `docs/archive/<YYYY>/`, header prepended, active README updated, optional redirect stub.
- **Audit**: a markdown report by finding type and severity; BLOCKER/WARNING findings offered for auto-filing.
- **Refresh README**: an updated per-directory catalog.

## Success criteria

- `add doc`: the file exists at the right path; a parent catalog, if one exists, lists it.
- `archive doc`: the file lives under `docs/archive/<YYYY>/`, carries the "Archived YYYY-MM-DD" header, and is removed from the active README.
- `audit`: findings enumerated; re-running on a clean tree returns zero BLOCKER/WARNING findings.
- `refresh README`: the catalog matches the directory inventory; non-catalog prose is preserved.

## Out of scope

- ADR filing / supersede / audit — that's `adr`.
- CHANGELOG entries — that's `changelog`.
- Content edits to a doc an owner skill already maintains — this skill handles placement and archival, not content drift.
- Auto-rewriting doc content or auto-renaming files — surfaced as findings, not fixed silently (renames would need every cross-reference updated by hand).

## Cross-references

- `adr`, `changelog`, `architecture-overview`, `roadmap`, `objectives`, `glossary`, `requirements`, `playbooks`, `showcase` — the named docs' owner skills; this skill catalogs and archives around them.
- `documentation-audit-changes` — PR-scoped staleness check; this skill's audit is whole-tree and structural, not PR-scoped.
- `backlog` — auto-file mode for BLOCKER/WARNING audit findings.
