---
name: backlog-manager
description: >
  Triage, prioritize, file, and plan GitHub issues — interactive authoring plus
  machine-driven auto-file mode.
when_to_use: >
  Use to create a backlog item, bug report, feature request, tech-debt item, or
  similar issue; to suggest implementation order for existing issues; or to file
  a durable finding from QC, doc-audit, or code-review output (auto-file mode).
  Not for bulk grooming, single-item triage, thin ideas, epics, the
  implementation-plan comment, or closing issues — each has its own skill.
model: opus
allowed-tools: Bash(gh *)
# persona: product-owner   — grouping metadata only; not read by Claude Code.
#   Filter all skills by this comment to regenerate each persona's owned-stable list.
---

# Backlog Manager

## Operations

This skill does three things. Identify which one the request calls for before proceeding:

1. **Review & prioritize** an existing backlog → Steps 1–4.
2. **Create a new issue** (bug, feature, tech-debt, QC finding) → Steps A–H.
3. **Auto-file** a durable finding non-interactively → *Auto-file mode* — called by other skills, not run by hand.

If none of these fit, check *Routing* first; another skill may own the request.

## Routing

Before starting, if the request matches a signal below, offer to hand off with:

> This sounds like `<skill>` territory: `<one-line reason>`. Hand off there? [Y/n]

On `n`, continue here. This is the skill's single routing surface — do not re-derive it mid-flow.

| Request shape | Owning skill |
|---|---|
| Thin / half-formed; no problem statement or file refs | `quick-capture` |
| A single fresh `needs-triage` item to route | `triage` |
| Bulk review or re-prioritization of the whole backlog | `backlog-grooming` |
| "A bunch of issues", "everything related to", "epic for …" | `epic` |
| Write or update the `## Implementation plan` comment | `implementation-plan` |
| Close a worked issue / post a retro | `backlog-retrospective` |
| Edit roadmap horizons | `roadmap` |
| Implement, test, or open a PR for the issue | `pull-request`, `code-review` |

## Review & prioritize (Steps 1–4)

### Step 1: Fetch issues

1. Auto-detect the repo from git remote context:

   ```bash
   REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner')
   ```

2. Fetch open issues with labels, body, and metadata:

   ```bash
   gh issue list --repo "$REPO" --state open --json number,title,labels,body,createdAt,assignees --limit 100
   ```

3. If the user requested a subset, filter via `--label` or post-fetch title/body filtering.

### Step 2: Classify and prioritize

For each open issue, determine:

- **Type** from title, labels, or body content:
  - **Bug** — broken behavior or visual defect; highest priority.
  - **Feature** — new capability; medium priority.
  - **Tech debt** — refactor / cleanup / optimization; lower than bugs/features unless blocking.
- **Effort** from scope:
  - **Small** — under 1 day; mechanical, single-file, or tightly scoped.
  - **Medium** — 1–3 days; multiple files and moderate design work.
  - **Large** — 3+ days; cross-cutting or architectural.
- **Dependencies** from explicit references, implicit sequencing, or shared-file conflict.

Apply prioritization rules in this order:

1. Bugs before features before tech debt.
2. Blockers before dependents.
3. Smaller before larger within a tier.
4. Group related issues.
5. Flag file-conflict or sequencing risks.

### Step 3: Present the prioritized backlog

1. Present a summary table with columns `Priority | # | Title | Type | Effort | Dependencies | Notes`.
2. Group issues into recommended phases such as quick wins, feature work, and refactoring.
3. Explain the ordering briefly and transparently.
4. Ask which issues need implementation plans.

### Step 4: Create implementation plans

For each selected issue, produce a concrete, executable plan using the structure in [`TEMPLATES.md`](${CLAUDE_SKILL_DIR}/TEMPLATES.md).

Plan quality rules:

- Reference actual files, functions, and code patterns discovered from the repo.
- Cover the full scope; avoid vague `and similar changes` language.
- Say what still needs investigation.
- Match existing repository patterns unless the issue explicitly changes them.

Workflow: present the plan, accept modifications, and do not implement until the user explicitly approves.

General guidelines: auto-detect the repo (ask if detection fails); use `gh` for GitHub interactions; read full issue bodies, not just titles; cross-reference any `docs/backlog.md`-style planning docs if present; keep prioritization reasoning visible and repository-agnostic.

## Create an issue (Steps A–H)

### Step A: Determine the issue template

1. Read `${CLAUDE_PROJECT_DIR}/.github/ISSUE_TEMPLATE/`.
2. Match the request to the best template:

| Template | Use when the user describes… |
|---|---|
| `bug_report.md` | broken behavior, regression, visual defect |
| `feature_request.md` | new capability, enhancement, UX improvement |
| `tech_debt.md` | refactor, cleanup, scaling crack, internal quality |
| `qc_finding.md` | explicit QC finding |

3. If the request is thin, nudge toward quick capture once:

   > This looks underspecified for the full backlog flow. File it via `quick-capture` with `needs-grooming` and let `backlog-grooming` pick it up later? Proceed here anyway? [y/N]

4. If template choice is ambiguous, ask which template to use.

### Step A.5: Capture the user story *(required)*

1. Prompt for the canonical form from `${CLAUDE_SKILL_DIR}/../_partials/user-story.md`:

   > **As a** <role>, **I want** <capability>, **so that** <outcome>.

2. Use a canonical role from the partial when possible (`data consumer`, `dataset owner`, `repo maintainer`, `AI agent`, `pipeline operator`, `new contributor`), or free text.
3. All three parts are required unless the issue is a minor chore using the partial's `**Mechanical change**` escape hatch.
4. Record this block; it goes at the top of the issue body in Step E.

### Step B: Analyze the codebase for context

Before drafting, investigate the relevant code so the issue is immediately actionable:

1. Identify affected files and functions with explore / grep / glob.
2. Capture concrete references for the issue body: file paths and function names; current behavior and brief code excerpts when useful; related existing issues via `gh issue list --search "<keywords>"`. Never invent file names or line numbers.
3. Check for overlap or blockers among existing issues.

### Step C: Determine epic linkage *(required, no silent default)*

Follow `${CLAUDE_SKILL_DIR}/../_partials/epic-linkage.md` Steps 1–2:

1. Prompt for the parent epic or a standalone justification.
2. Validate that a chosen parent exists and carries the `epic` label.
3. Record the result for the issue body.
4. If epic-linked, use it again in Step H to create the native sub-issue relation.

### Step D: Judge whether it's worth doing *(recommended)*

1. Tiny chores, `qc` findings, and `audit-finding` items may skip this and go straight to Step E.
2. Otherwise ask a single worth-doing question: **now** (do it soon), **later** (worth doing, not urgent), or **no** (not worth doing).
3. On **now**, apply a priority label (`priority/blocker`, `priority/high`, or `priority/medium`) matching urgency.
4. On **later**, file without a priority label — grooming can prioritize it later.
5. On **no**, stop here rather than proceeding to Step E; tell the user why, and offer `quick-capture` instead if they still want a lightweight record.

### Step E: Draft the issue

Fill the chosen template with user input plus codebase context:

- Fill every template section; use `N/A` rather than deleting headings.
- Body line 1 is `**Parent epic:** #<N>` or `**Parent epic:** standalone — <reason>`.
- `## User story` is the first content heading; preserve the template's heading structure exactly.
- Add a final `Codebase Context` section with affected files/functions, clarifying excerpts, and related issues.
- Write clearly enough that the reader does not need the original chat prompt.

### Step F: Review with the user

Present the draft using the review format in [`TEMPLATES.md`](${CLAUDE_SKILL_DIR}/TEMPLATES.md), and require explicit approval before posting.

### Step F.5: DoR pre-flight gate *(soft prompt)*

Run `${CLAUDE_SKILL_DIR}/../_partials/dor-preflight.md` in interactive mode before `gh issue create`. WARNING-level misses surface one summary plus a `[y/N]` proceed prompt; INFO-level misses are listed but never block; the gate never silently fixes structure. A `y` continues to Step G; anything else returns to Step E.

### Step G: Post the issue to GitHub

Once approved, create the issue with `gh issue create` under a concise, descriptive title (usually `[Type]: Brief description`), capture the issue number and URL, and retain the chosen labels.

### Step H: Link as a sub-issue *(epic-linked path only)*

If Step C chose an epic parent, attach the new issue via the native sub-issue API per `${CLAUDE_SKILL_DIR}/../_partials/epic-linkage.md` Step 3. Two critical details from that partial still apply:

- use uppercase `-F sub_issue_id=<INT>`; lowercase `-f` returns 422
- `sub_issue_id` is the issue database **id**, not the issue **number**

Skip this step entirely for standalone issues.

## Auto-file mode

The non-interactive sibling of Steps A–H, invoked by other skills (`run-repo-qc`, `documentation`, `readme`, `walkthrough`) when they surface findings worth durable tracking. It never prompts, never closes issues, never runs the worth-doing judgment, and always labels the issue `needs-triage`.

Do not restate the contract here. Follow the full input contract, dedup rules, and severity → priority mapping in [`../_partials/backlog-autofile-mode.md`](${CLAUDE_SKILL_DIR}/../_partials/backlog-autofile-mode.md) and the auto-file protocol [`../_docs/ADR-0004-auto-filed-issue-protocol.md`](${CLAUDE_SKILL_DIR}/../_docs/ADR-0004-auto-filed-issue-protocol.md).

## Reference

- Input/output contract and success criteria: [`reference.md`](${CLAUDE_SKILL_DIR}/reference.md)
- Label vocabulary: [`../_partials/label-vocabulary.md`](${CLAUDE_SKILL_DIR}/../_partials/label-vocabulary.md); consuming-repo labels, if any, at `${CLAUDE_PROJECT_DIR}/.github/LABELS.md`
- Shared partials (`user-story`, `epic-linkage`, `dor-preflight`) under `${CLAUDE_SKILL_DIR}/../_partials/`
- Related skills: `quick-capture`, `triage`, `backlog-grooming`, `backlog-retrospective`, `epic`, `pull-request`
