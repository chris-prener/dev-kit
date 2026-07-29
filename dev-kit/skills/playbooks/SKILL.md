---
name: playbooks
description: >
  Owns docs/playbooks/. Four operations: run a playbook step-by-step
  (pausing at decision points), author a new playbook from a
  recently-completed operation, audit for drift (broken skill / file /
  command references in playbook prose; frontmatter conformance), and
  list available playbooks.
when_to_use: >
  Use to walk through a worked example of a common operation, capture a
  just-completed operation as a repeatable playbook, check playbooks for
  drift against renamed/removed skills or files, or discover what
  worked examples exist. Trigger phrases: "run playbook", "author
  playbook", "audit playbooks", "list playbooks", "playbook for <x>".
model: sonnet
# persona: writer   — grouping metadata only; not read by Claude Code.
---

# Playbooks

Operational counterpart to `${CLAUDE_PROJECT_DIR}/docs/playbooks/`. Playbooks are **living traces** of common end-to-end operations — the tutorial / worked-example axis of the docs. This skill is the only sanctioned writer of net-new playbook files and the canonical place to ask "is there a worked example for X?"

## Activation

Invoke when:

- A contributor (human or AI) needs a worked example of a common operation ("run the new-skill playbook", "show me how a release goes end-to-end").
- A recently-completed operation is repeatable and should be captured ("author a playbook for the workflow we just did").
- Periodic drift check ("audit playbooks") — surfaces playbooks whose referenced skills / file paths / commands no longer exist.
- Discovery of available worked examples ("list playbooks").

## Inputs

- For `run`: the playbook slug or a topic keyword.
- For `author`: the operation just completed (free-form description) and a proposed slug.
- For `audit`: nothing (scans `docs/playbooks/*.md`).
- For `list`: optional filter (topic / recency).

## Steps

### 1. Run a playbook

1. Resolve playbook slug → `docs/playbooks/<slug>.md`. If no exact match, surface the closest matches via `list` and ask the operator to pick.
2. Print the **Goal / starting state** section verbatim. Confirm the operator's current state matches.
3. For each numbered step in the playbook body:
   - Print the step (skill invocation + commentary).
   - At any **Decision point** (text marked `**If <X>**: ... **Otherwise**: ...`), pause and ask the operator which branch applies before proceeding.
   - For skill invocations, do NOT auto-invoke the named skill — surface the trigger phrase and let the operator confirm or adjust. Playbooks are guidance, not automation.
4. After the final step, print the **Verification** section and confirm with the operator.
5. Optionally append a one-line outcome note to the playbook's `## Recent runs` section if present (light footprint; skip if absent).

### 2. Author a playbook

1. Operator names the operation + proposes a slug. Validate the slug is kebab-case and not already taken.
2. Create `docs/playbooks/<slug>.md` with the standard skeleton:
   - Frontmatter: `last_updated:` (today).
   - `# <Title>` (sentence-case from the slug).
   - `## Goal / starting state`.
   - `## Steps` (numbered; second-person voice; each step starts with the skill being invoked).
   - `## Decision points` (or inline within steps).
   - `## Verification`.
   - `## Pointers` (cross-links to skills and reference docs).
3. Walk the operator through populating each section based on the recently-completed operation. Steps should reference REAL skill names and REAL commands.
4. Update `docs/playbooks/README.md`'s catalog to include the new playbook.
5. Run the audit op against the new file before declaring success.

### 3. Audit (drift detection)

| Finding | Class |
|---|---|
| Playbook-referenced skill does NOT exist in the skill suite | BLOCKER |
| Playbook-referenced relative file path does NOT resolve | BLOCKER |
| Playbook missing its `last_updated` frontmatter field | WARNING |
| Playbook `last_updated` older than 180 days | WARNING |
| Playbook references a command that no longer matches `--help` output of the named tool | INFO (manual-review only; the audit cannot reliably diff CLI surface) |
| Playbook missing from `docs/playbooks/README.md` catalog | WARNING |

### 4. List

1. Read `docs/playbooks/README.md`'s catalog as the source of truth.
2. Optionally filter by topic keyword (substring match on title or first paragraph) or by recency (`last_updated` within the last N days).
3. Surface as a table: slug | title | last_updated | one-line description.

## Authoring conventions

- **Voice**: second person ("You file an issue using the `backlog` skill...").
- **Steps**: numbered; each starts with the skill being invoked (or the command, for non-skill operations).
- **Decision points**: explicit (`**If <X>**: ... **Otherwise**: ...`).
- **Real artifacts**: actual commands, file paths, skill names — not pseudocode. The audit op enforces resolution.
- **Length**: 2-5 pages. Larger than a skill, smaller than a tutorial book. If a playbook is exceeding 5 pages, consider splitting.
- **Naming**: kebab-case slug; verb-noun pattern preferred.
- **Updates**: when a referenced skill renames, restructures, or changes its trigger surface, run `audit` to surface impact and update affected playbooks.

## Outputs

- For `run`: an interactive walkthrough; no file mutations except the optional `## Recent runs` note.
- For `author`: a new `docs/playbooks/<slug>.md` + a one-row catalog update in `docs/playbooks/README.md`.
- For `audit`: a report enumerating findings by class. BLOCKER/WARNING findings are offered for auto-filing via `backlog`.
- For `list`: a table on stdout.

## Success criteria

- For `run`: the operator completes the operation end-to-end without consulting reference docs beyond what the playbook cites.
- For `author`: the new playbook passes audit immediately on save.
- For `audit`: BLOCKER findings have actionable fixes (named skill / file / path); INFO findings are non-actionable but informative.
- For `list`: every playbook in `docs/playbooks/` appears (no orphans) AND every cataloged entry resolves to a file (no dangling).

## Out of scope

- **Auto-rewrite of playbook content** when a referenced skill changes — this skill detects drift and prompts; a human authors the fix.
- **Auto-generation of playbooks from session transcripts.**
- **Video / interactive playbooks** — markdown only.
- **Playbooks for rare or one-off operations** — those stay as ad hoc session notes, not playbooks.
- **Replacing reference docs** — playbooks complement (`docs/ARCHITECTURE.md`, the skill catalog); never replace.

## Cross-references

- **Owned doc**: `docs/playbooks/` (directory of playbook markdown files + subfolder `README.md` hub).
- `docs-organization` — places new playbooks under `docs/playbooks/`.
- `backlog` — auto-file mode for BLOCKER/WARNING audit findings.
