---
status: draft
owner: Chris Prener
date: 2026-08-02
last-updated: 2026-08-02
related-epic: none
related-adr: none
supersedes: none
superseded-by: none
---

# Plugin packaging: should the R and Python tracks be separate plugins?

## Background

dev-kit ships as one plugin containing 58 skills, of which **21 (36%) are the `r-*` and
`python-*` language packs**. Every session in every repo carries all of them.

This doc shares its evidence base with
[skill-decomposition.md](skill-decomposition.md), which states the skill-listing budget
mechanism and the measurements once. **That evidence is not restated here** — duplicating it
would create exactly the drift this repo has filed five findings about (#6, #10, #12, #38,
and part of #11). Read §"Background" there first; this doc covers only what is specific to
the packaging decision.

The one figure that matters here:

| | chars | share |
|---|---|---|
| Full listing (58 skills) | 33,079 | 100% |
| `r-*` + `python-*` (21 skills) | **10,835** | **33%** |
| Core (37 skills) | 22,244 | 67% |

An R developer in an R repo carries the entire Python pack, and vice versa. A Go or
TypeScript developer — the plausible community adopter, given the `.github` scaffolding
already in place for publication — carries all 10,835 characters for nothing.

And it is not merely waste. Because listing overflow evicts by *usage rank*, the language
packs are what pushed `quick-capture`, `readme`, `run-repo-qc`, `showcase`, `triage`, and
`walkthrough` out of the listing in an observed session. **The language packs are evicting
the core product from its own routing table.**

## Sources

- **S1** — [Claude Code plugins reference](https://code.claude.com/docs/en/plugins-reference) —
  the plugin `name` is the skill namespace (`dev-kit:backlog`); `defaultEnabled: false`
  ships a plugin installed-but-disabled; a plugin's bundled `settings.json` supports only
  the `agent` and `subagentStatusLine` keys.
- **S2** — [Claude Code plugin dependencies](https://code.claude.com/docs/en/plugin-dependencies) —
  `plugin.json` takes a `dependencies` array with semver constraints; installing a plugin
  resolves and installs its dependencies automatically; **enabling a plugin also enables its
  dependencies**; disabling one that another enabled plugin needs is refused. Releases are
  tagged `{plugin-name}--v{version}`, so one marketplace repo can host independent version
  lines.
- **S3** — [Claude Code settings reference](https://code.claude.com/docs/en/settings) —
  `skillOverrides` (the per-skill visibility lever) **does not apply to plugin skills**;
  `enabledPlugins` honours project and local settings.
- **S4** — Direct measurement of `dev-kit/skills/*/SKILL.md`, 2026-08-02 — listing figures
  and the cross-reference graph.

## The mechanism forces the shape of the answer

The lever that would fix the waste without splitting — `skillOverrides`, which collapses a
skill to name-only — **explicitly does not apply to plugin skills**, which are "managed
through `/plugin`" (S3).

**Per-plugin enable/disable is therefore the only granularity Claude Code offers anyone for
controlling a plugin's listing footprint.** If a user is to avoid paying for R while working
in Python, splitting is not a preference among options; it is the only supported mechanism.

## The seam is clean

Measured over `dev-kit/skills/`, the dependency is close to one-directional:

| Direction | Volume |
|---|---|
| Core → language packs | **1 reference** (`documentation` → `r-documentation`) |
| Language packs → core | 17 references across 5 core skills (`changelog`, `documentation`, `code-review`, `run-repo-qc`, `readme`) |

Core stands alone; the language packs are add-ons that assume core. That is exactly the
shape `dependencies` models (S2).

## Requirements

### R1 — Three plugins, one marketplace, dependency-linked

**Rationale:** The only supported granularity, applied along the only clean seam.

**Source(s):** S1, S2, S3, S4

**Acceptance criteria:**
- [ ] `dev-kit` (37 core skills), `dev-kit-r` (10), `dev-kit-py` (11), all listed in the
      existing `.claude-plugin/marketplace.json`.
- [ ] Each language pack declares `dependencies: ["dev-kit"]` with a version constraint, so
      `claude plugin install dev-kit-r` remains a **single command** and enabling it enables
      core.
- [ ] Language packs ship `defaultEnabled: false`.
- [ ] Releases are tagged `{plugin-name}--v{version}` per S2, giving each pack an
      independent version line.

### R2 — Cross-plugin references are namespaced

**Rationale:** Once a skill lives in a different plugin, a bare name no longer resolves —
references need the `plugin:skill` form.

**Source(s):** S1, S4

**Acceptance criteria:**
- [ ] The 17 language→core references and the 1 core→language reference use the namespaced
      form.
- [ ] `pr-gate-qc`'s cross-reference sweep is taught to resolve namespaced names, or a
      follow-up issue is filed. (Note the trap recorded in #29: that sweep validates prose
      names against *directories*, so it is structurally blind to namespace divergence.)

### R3 — The payoff is banked by project-scoped enablement

**Rationale:** **This is the requirement most likely to be skipped, and without it the split
delivers nothing.** If all three plugins are enabled at user scope, the listing cost is
exactly what it is today. The saving exists only when a repo enables the pack it needs.
`enabledPlugins` honours project scope (S3), so this is available — but it is a workflow
change, not a packaging change.

**Source(s):** S3

**Acceptance criteria:**
- [ ] The README documents per-repo enablement (`--scope project`) as the intended install
      pattern, not an optional refinement.
- [ ] `bootstrap-repo` offers to write the appropriate `enabledPlugins` entry when it
      detects an R or Python project.
- [ ] Verified: an R repo's session listing contains **zero** `python-*` characters.

## Sequencing

**This work is fourth in a five-step order** established during discovery on 2026-08-02:

1. Skill decomposition spike — [skill-decomposition.md](skill-decomposition.md), Sprint 1.5
2. Listing-budget reduction (levers A/B) — parallel, Sprint 1.5
3. #29 — skill-name/directory reconciliation (sprint 2)
4. **This split**
5. Language-pack audit findings — sprints 4 and 5, runnable in parallel throughout

**Behind #29**, because a split rewrites cross-reference prose and #29 rewrites the names
that prose points at. Doing the split first means touching 100+ references twice.

**Behind the decomposition spike**, because #29 is itself held behind it — four of the nine
skills #29 renames are merge candidates.

**Sprints 4 and 5 are the natural pre-work.** All 16 of their findings are language-pack
content that this split relocates. Fixing them before the move costs nothing extra — the
content travels with the skills — and it means the packs ship clean.

## Rejected: persona as a plugin boundary

Considered and rejected on 2026-08-02: splitting core further along the persona tags (a
`dev-kit-pm` plugin, and so on). **Recorded here so it is not re-litigated.**

**Reason 1 — scope mismatch, and it is disqualifying on its own.** Personas are
**session-level**: hats are switched with `/output-style`, several times within one repo.
Plugin enablement is **project- or user-scoped** configuration written to `settings.json`.
There is no session-level plugin toggle, so flipping would mean `/plugin` plus
`/reload-plugins` at every hat change. Language works as a boundary precisely because it is
a stable property of the *repo*, matching project scope. Persona is a property of *what you
are doing right now*, and no plugin mechanism tracks that.

**A plugin boundary only pays off when the thing it divides is stable at project scope.**

**Reason 2 — the persona tags are a view, not a partition.** Measured on the
cross-reference graph:

| `product-manager` cluster (`objectives`, `requirements`, `roadmap`) | |
|---|---|
| Listing cost | 1,878 chars — 8% of core |
| References **into** the cluster from non-PM core | **45** |
| References **among** the three | **1** |

`roadmap` alone is referenced by `epic` (9×), `docs-organization`, `bootstrap-repo`,
`epic-retrospective`, `backlog-grooming`, `showcase`, and `session-start`. It is **shared
substrate that the PM persona happens to author**, not a module. Splitting it would
namespace 45 references to recover 5% of the listing.

The pattern holds across every persona — cross-persona edges dominate: writer→product-owner
30, developer→product-owner 23, writer→developer 21, product-owner→product-manager 21.

The frontmatter comment in every skill already says as much: *"grouping metadata only; not
read by Claude Code."* The tags were never a partition and the graph confirms they cannot
become one.

## Non-goals

- **Splitting core along any axis.** See above. Core's size is a *decomposition* problem,
  addressed by [skill-decomposition.md](skill-decomposition.md), not a packaging one.
- **Migrating the output-style personas.** They are session-level and unaffected. A plugin
  *can* ship an output style (S1), but that is a distribution convenience, not a reason to
  move them.
- **Parity-enforcement tooling between the packs.** Splitting does make R/Python drift
  easier, and the repo already carries mirror-image findings (#5/#37, #6/#12). Worth
  flagging; not worth solving before the split exists to be drifted against.
