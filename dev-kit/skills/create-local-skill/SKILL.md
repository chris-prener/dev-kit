---
name: create-local-skill
description: >
  Scaffolds a new project-local Claude Code skill at
  `.claude/skills/<slug>/SKILL.md` — for skills specific to the project
  you're standing in, not shared workflow skills that belong in the
  dev-kit plugin itself.
when_to_use: >
  Use when a project needs its own skill that has no home in dev-kit
  (a domain-specific check, a project's own scaffolding ritual, a
  local convention-enforcer). Not for editing an existing skill (use
  your editor directly) or for skills that are genuinely
  language-agnostic workflow — those belong in dev-kit itself, ported
  by hand alongside its siblings.
model: opus
# persona: developer   — grouping metadata only; not read by Claude Code.
---

# Create Local Skill

Scaffolds a new skill scoped to the current project, at `.claude/skills/<slug>/SKILL.md` — Claude Code's project-local skill location. This is the right tool for a skill that's genuinely specific to one codebase (a domain check, a local ritual) and has no reason to live in the shared `dev-kit` plugin.

## Activation

Activate this skill when the user asks to:

- Create a new project-specific / local skill
- Scaffold a skill that isn't meant to be shared across projects
- Add a domain-specific skill to the current repo

**When NOT to use:**

- **Editing an existing skill** — use your editor directly.
- **Adding a skill to `dev-kit` itself** — that's a plugin skill, authored directly in `dev-kit/skills/` following the conventions in `dev-kit`'s own exemplars (`backlog`, `epic-dependency`), not scaffolded by this skill.
- **A skill that's really language-agnostic workflow** — if it would be useful in every project, it belongs in `dev-kit`, not `.claude/skills/`.

## Inputs

| Input | Required | Description |
|---|---|---|
| Skill slug | Yes | The directory name under `.claude/skills/`, kebab-case (e.g. `my-custom-check`). |
| Description | Yes | One-line description of what the skill does — this is what Claude Code uses to decide when to trigger it, so make it specific. |
| When to use | Yes | Trigger phrases and explicit "not for X" redirects. |
| Model tier | No | Recommended tier (`opus`, `sonnet`, `haiku`). Default: `sonnet`. |

## Steps

### Step 1: Validate the slug

1. Check that the slug is kebab-case and does not start with `_`.
2. Check that `.claude/skills/<slug>/` does not already exist. If it does → halt with `"Skill directory already exists at .claude/skills/<slug>/. Edit the existing skill or choose a different slug."`
3. Check that the slug doesn't collide with a `dev-kit` skill name (e.g. `backlog`, `epic`). If it does → warn: `"'<slug>' matches a dev-kit skill name. A project-local skill of the same name will shadow it in this repo — confirm that's intended, or choose a different slug."`

### Step 2: Scaffold the skill file

Create `.claude/skills/<slug>/SKILL.md` with this template:

~~~markdown
---
name: <slug>
description: >
  <description>
when_to_use: >
  <trigger phrases, and "not for X" redirects>
model: <model-tier>
---

# <Title>

<< SKILL BODY — fill in the sections below >>

## Activation

Activate this skill when:

- << describe when to use >>

**When NOT to use:**

- << describe when not to use >>

## Inputs

| Input | Required | Description |
|---|---|---|
| << input >> | << yes/no >> | << description >> |

## Steps

<< describe the steps >>

## Outputs

<< describe outputs >>

## Success criteria

<< describe how to know it worked >>

## Out of scope

<< describe what this skill does not do >>

## Cross-references

- << related skills, ADRs, docs >>
~~~

### Step 3: Suggest validation

If `skill-creator` is installed, suggest running it against the new skill to tune the description and measure trigger accuracy before the skill sees real use.

## Outputs

- A new skill file at `.claude/skills/<slug>/SKILL.md` with frontmatter and the standard section scaffold.

## Success criteria

- The skill file exists with valid frontmatter and a filled `description` that Claude Code can use to decide when to trigger it.
- No `dev-kit` skill was overwritten or modified.
- The scaffold matches the standard section layout (Activation, Inputs, Steps, Outputs, Success criteria, Out of scope, Cross-references).

## Out of scope

- **Filling in the skill body** — this skill scaffolds the structure; the user fills in the content.
- **Updating an existing project-local skill** — edit directly; no special tooling needed.
- **Publishing or sharing a project-local skill across repos** — if it turns out to be broadly useful, port it into `dev-kit` by hand instead.

## Cross-references

- `dev-kit/skills/backlog`, `dev-kit/skills/epic-dependency` — exemplars for the section layout this skill scaffolds.
