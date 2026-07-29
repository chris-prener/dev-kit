# dev-kit

A personal issue- and doc-driven development workflow for [Claude Code](https://claude.com/claude-code), packaged as a plugin. It gives Claude a consistent set of skills for backlog management, triage, epics, roadmaps, pull requests, retrospectives, and documentation — plus a set of persona "hats" (output styles) that shape how Claude behaves in a given session.

## Purpose

Software projects accumulate the same kinds of process work regardless of language: grooming a backlog, triaging bugs, writing ADRs, keeping READMEs and changelogs current, running PR gates, and doing retrospectives. `dev-kit` encodes that process as a library of Claude Code **skills** (in [dev-kit/skills](dev-kit/skills)) so it can be reused across projects instead of being rebuilt or re-explained each time.

The workflow is intentionally **language-agnostic**. Skills that need language-specific behavior (code style, testing, packaging, dependency management, etc.) are duplicated per language — currently R and Python — under `r-*` and `python-*` prefixes.

Personas live separately as user-level **output styles** (in [output-styles](output-styles)), not as plugin skills, since output styles are a Claude Code concept that applies at the session level rather than the repo level. Current hats: Developer, Product Manager, Product Owner, Python Developer, R Developer, and Writer.

## Installation and use

This repo is a single Claude Code plugin named `dev-kit`, defined by [dev-kit/.claude-plugin/plugin.json](dev-kit/.claude-plugin/plugin.json).

**To use the skills in a project:**

1. Add this repo as a plugin source for Claude Code (see the [Claude Code plugin docs](https://docs.claude.com/en/docs/claude-code) for the current mechanism — plugin installation UX evolves).
2. Once installed, Claude Code will surface the skills in [dev-kit/skills](dev-kit/skills) automatically based on each skill's `description`/`when_to_use` frontmatter — you generally invoke them by describing the task ("groom the backlog", "update the README") rather than by memorizing skill names.

**To use a persona (output style):**

1. Copy the desired file from [output-styles](output-styles) into your Claude Code output styles location (see the output styles docs), or point Claude Code at this directory.
2. Activate it for a session (e.g. `/output-style developer`). Each persona file documents its own mindset, preferred skills, and handoff boundaries to the other personas.

There is no build step, package manager, or test suite for this repo itself — it is a collection of Markdown-based skill and prompt definitions, not executable code.

## Repository layout

```
dev-kit/
├── dev-kit/                    # the actual Claude Code plugin
│   ├── .claude-plugin/
│   │   └── plugin.json         # plugin manifest (name + description)
│   └── skills/                 # one directory per skill, each with a SKILL.md
│       ├── _docs/              # shared reference docs used by multiple skills
│       ├── _partials/          # shared prompt fragments included by multiple skills
│       └── <skill-name>/SKILL.md
├── output-styles/              # persona hats (user-level output styles, not plugin skills)
├── .github/                    # issue templates, PR template, CODE_OF_CONDUCT, CONTRIBUTING
├── .gitignore
└── README.md
```

Note the nested `dev-kit/dev-kit/` path: the outer directory is this repo, the inner `dev-kit/` is the plugin root that Claude Code's plugin system expects to point at.

## Current state

- ~60 skills exist under `dev-kit/skills`, covering: backlog/roadmap/triage/epics, PR orchestration and gates (code review, QC, changelog), documentation (README maintenance, architecture overview, walkthroughs, glossary), repo bootstrap/QC scaffolding, and language-specific tracks for R and Python (code style, testing, dependencies, packaging, data I/O/validation, pipeline patterns, documentation).
- 6 output-style personas exist: Developer, Product Manager, Product Owner, Python Developer, R Developer, Writer.
- This is a personal toolkit maintained by one person (see `.github/CONTRIBUTING.md` for contribution norms) — it is not (yet) published as a general-purpose community plugin, though the `.github` scaffolding is in place for that.
- No CI/CD workflows are configured in this repo (the `.github/workflows` directory used by other repos of this author's is deliberately omitted here).

## Constraints and conventions for agents working in this repo

- **This repo is skills, not application code.** There is no source to compile, no tests to run, and no runtime to start. "Correctness" here means: does the skill's Markdown accurately describe a workflow Claude Code can follow, and does its frontmatter (`name`, `description`, `when_to_use`) trigger appropriately.
- **Language parity matters.** If you add or change behavior in an `r-*` skill that has a clear Python analog (or vice versa), check whether the counterpart needs the same update. They are meant to stay conceptually parallel, not identical in wording.
- **Don't add project-specific content.** Skills should stay generic enough to work across arbitrary downstream repos. Avoid hardcoding assumptions about any single project's structure, tooling, or team.
- **`_partials` and `_docs` are shared.** Changes there can affect multiple skills — grep for references before editing.
- **Output styles are separate from skills** on purpose (session-level persona vs. repo-level capability). Don't move persona content into `dev-kit/skills` or skill content into `output-styles` without a clear reason.
- **No workflows directory.** `.github/workflows` was intentionally dropped when this repo's GitHub scaffolding was set up; don't assume CI exists.
- When editing a skill, read its `SKILL.md` frontmatter (`name`, `description`, `when_to_use`, `allowed-tools`) first — the description/when_to_use fields are what Claude Code actually uses to decide when to trigger the skill, so imprecise wording has real behavioral consequences.
