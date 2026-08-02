---
status: draft
owner: Chris Prener
date: 2026-08-02
last-updated: 2026-08-02
related-epic: '#16'
related-adr: none
supersedes: none
superseded-by: none
---

# Skill decomposition: is dev-kit's skill surface the right size?

## Background

dev-kit ships 58 skills. Nobody chose that number — it accumulated one reasonable
decision at a time. This doc asks whether 58 is the right decomposition, and scopes a
time-boxed spike to answer it before Epic B closes findings that assume the current one.

Three independent lines of evidence say it is not, and they were found in this order.

### 1. The skill listing is over budget, and descriptions are being dropped

Claude Code loads a **skill listing** — every skill's name plus its combined
`description` and `when_to_use` — into context on every turn. That listing has a budget:
`skillListingBudgetFraction`, defaulting to **1% of the model's context window**. When the
listing overflows, Claude Code **drops descriptions for the least-used skills and lists
them by name only**. Claude can still invoke them; it can no longer see what they do.

dev-kit's listing is **33,079 characters** across 58 skills (no skill hits the per-skill
`skillListingMaxDescChars` cap of 1,536, so every character is counted). This exceeds the
default budget by a wide margin before any built-in skill competes for the same space.

This is not a projection. **In a routine session on 2026-08-02, 19 of 58 dev-kit skills
were listed with no description at all.** Thirteen were language-pack skills. Six were
not:

`quick-capture` · `readme` · `run-repo-qc` · `showcase` · `triage` · `walkthrough`

Six core workflow skills were being routed to on their names alone. The eviction is
usage-ranked, silent, and it hits whatever is least-used — which is not the same as what
is least important.

### 2. 43% of core `when_to_use` text is spent saying what a skill is *not*

| Measure | Value |
|---|---|
| Core (`37` skills) `when_to_use` total | 12,481 chars |
| Of which negative disambiguation ("Not for X, that's `y`") | **5,335 chars (43%)** |
| Core skills carrying a "Not for" clause | 33 of 37 |

`documentation` spends 322 of its 547 `when_to_use` characters saying what it isn't.

This is the important measurement in this doc, because **it is not prose bloat — it is a
tax on skill count.** Every near-neighbor added forces every existing sibling to fence its
boundary against the newcomer. The cost scales super-linearly in the number of overlapping
skills, which is why 58 skills cost far more than 58 × a fixed rate.

It also means the reduction levers compound: removing a skill from the listing removes
both its own characters *and* every sibling's need to disambiguate against it.

### 3. At least 10 of 28 open audit findings are boundary disputes, not content defects

This is the line of evidence that determines *when* the spike must run.

| Issue | Dispute |
|---|---|
| #33 | `backlog` Step 4 collides with `implementation-plan`'s exclusive contract |
| #31 | `code-review` / `pr-gate-code-review` mode vocabulary mismatch |
| #28 | `pr-gate-changelog` commits to the tree, contradicting `pr-orchestrator`'s no-dirty contract |
| #30 | `pr-gate-qc`'s persona check omits two personas |
| #45 | Persona lane rules conflict with skills' inline gate handoffs |
| #5 / #37 | `python-testing` ↔ `python-ci`, `r-testing` ↔ `r-ci` contradict on coverage gating |
| #6 / #10 / #12 | The same config duplicated and drifted across two skills, three times over |
| #38 | Box-drawing separators contradict `_partials/inline-comment-standards.md` |

**A boundary dispute cannot be fixed without deciding the boundary.** Each of these is
"fixed" by picking a side. If a later decision redraws that seam, the side was picked
twice — and the finding recurs.

That last consequence is what makes this urgent rather than merely worthwhile. `O1` KR1.4
counts **regressions of fingerprinted findings, capped at 2**, as its evidence that
remediation was structural rather than symptomatic. Closing a boundary finding before
deciding the boundary spends that regression budget on a decision deferred by choice. The
cost is not rework; it is the integrity of the instrument.

### Supporting signal: usage, with heavy caveats

Across 31 session transcripts (2026-07-25 → 2026-08-01), **16 of 58 skills have ever been
invoked**. The clusters:

| Cluster | Invocations |
|---|---|
| `backlog` · `quick-capture` · `triage` · `backlog-grooming` | **1** (one `backlog` call) |
| Writer persona (10 skills, 6,659 chars) | **1** (one `documentation-audit-changes`) |
| `documentation` · `documentation-suite` | 0 |
| `backlog-retrospective` · `epic-retrospective` | 0 |

**This data cannot authorize deletion and must not be read as doing so.** The corpus is
seven days old. It covers four projects, three of which are dev-kit itself. Language-pack
skills *cannot* fire in a Markdown repo, so their zeros are uninformative. Many skills are
lifecycle-seasonal by design — `epic-retrospective` fires when an epic closes, `changelog`
at release. **Never-fired ≠ dead.**

Its legitimate use is to **rank what to examine first**. The findings evidence (§3) tells
you where the seams are wrong; usage tells you where to look first. Different jobs, and
the spike's conclusions must rest on the former.

### What the maintainer reports

The four backlog-lifecycle skills are run **in serial, one after another**. This is
stronger evidence than the usage data, and it explains it: `backlog` fired once and the
other three never, because the state machine is being run by hand and only the front door
gets a tool call.

## Sources

- **S1** — [Claude Code skills reference](https://code.claude.com/docs/en/skills) — the skill
  listing is loaded every turn; on overflow, least-used skills lose their descriptions and
  keep only their names. `skillOverrides` (the per-skill visibility lever) **does not apply
  to plugin skills**. `disable-model-invocation: true` removes a skill's description from
  the listing entirely while leaving `/dev-kit:<name>` working.
- **S2** — [Claude Code settings reference](https://code.claude.com/docs/en/settings) —
  `skillListingBudgetFraction` defaults to `0.01`; `skillListingMaxDescChars` defaults to
  `1536`.
- **S3** — Direct measurement of `dev-kit/skills/*/SKILL.md`, 2026-08-02 — all listing,
  disambiguation, and cluster figures in this doc.
- **S4** — 31 session transcripts under `~/.claude/projects/`, 2026-07-25 → 2026-08-01 —
  the invocation counts, with the caveats stated above.
- **S5** — Open `audit-finding` issues on this repo as of 2026-08-02 — the boundary-dispute
  categorisation.
- **S6** — Observed skill listing in a live session, 2026-08-02 — the 19 name-only skills.

## Requirements

### R1 — The decomposition decision is made before the seams are remediated

**Rationale:** §3. Sprints 2 and 3 close findings whose fixes select boundaries this
decision may redraw, and `O1` KR1.4 records the resulting recurrences as regressions.

**Source(s):** S5

**Acceptance criteria:**
- [ ] A spike produces an accepted ADR stating, per skill, one of: **merge** (into what),
      **demote** (to a reference file of which skill), or **keep** (with rationale).
- [ ] The ADR lands before sprint 2 begins.
- [ ] Every held finding (#28, #30, #31, #33, #45) carries a comment stating whether the
      decision **dissolves** it, **changes its fix**, or **leaves it unchanged**.

### R2 — The spike answers the lifecycle-unit question, not "merge y/n"

**Rationale:** `quick-capture`, `backlog-grooming`, `backlog`, and `triage` are four stages
over one object — a GitHub issue — with the labels as its state:

`quick-capture` → `needs-grooming` → `backlog-grooming` → `needs-triage` → `triage` → routed

The real question is whether the right unit is the **lifecycle stage** or the **object**.
dev-kit has already answered this once for the closing side: `backlog-retrospective`
bundles close+retro as one transaction and holds `validate` as a second operation over the
same object. The spike must say why the opening side should differ, or align it.

**Source(s):** S3, S4, maintainer report

**Acceptance criteria:**
- [ ] The ADR states a general rule for when a lifecycle stage earns its own skill, and
      applies that rule to both the opening and closing halves of the issue lifecycle.
- [ ] The rule is applied to the documentation trio (`documentation`,
      `documentation-suite`, `documentation-audit-changes`) and the retrospective pair
      (`backlog-retrospective`, `epic-retrospective`) as well as the backlog cluster.

### R3 — The auto-file caller class is resolved explicitly

**Rationale:** This is the concrete risk that decides the backlog merge. `backlog`'s
auto-file mode is **machine**-invoked by QC, doc-audit, and code-review under ADR-0004 — a
different caller class from the three interactive stages. Sprint 1 has just repaired that
registry (#3, #32). A merge either mixes a machine-facing operation with interactive ones
inside one skill, or splits auto-file out as its own surface.

**Source(s):** `dev-kit/skills/_docs/ADR-0004-auto-filed-issue-protocol.md`, S5 (#3, #32)

**Acceptance criteria:**
- [ ] The ADR states which surface owns auto-file after the decision.
- [ ] ADR-0004's caller registry is shown to remain valid, or its required amendment is
      filed as an issue.

### R4 — Skills that only a human initiates leave the listing

**Rationale:** §1 and §2. `disable-model-invocation: true` removes a skill's description
from the listing while preserving `/dev-kit:<name>`. **Zero of 58 skills use it today.**
This is independent of the merge decision for every candidate except `showcase`, so it can
proceed in parallel.

**Source(s):** S1, S3

**Acceptance criteria:**
- [ ] Each of `bootstrap-repo`, `showcase`, `create-local-skill`, `github-enforcement`,
      `create-repo-qc`, `session-start`, `epic-dependency` (**4,436 chars**) is either
      marked `disable-model-invocation: true` or has a recorded reason it must stay
      model-routable.
- [ ] The three `pr-gate-*` skills (**791 chars**) — which declare themselves *"Invoked
      only by `pr-orchestrator`. Not triggered directly by the user"* — are demoted to
      reference files under `pr-orchestrator/`. Note that `disable-model-invocation` is
      **not** the right mechanism here: it would also block `pr-orchestrator` from
      dispatching to them.

### R5 — The result is verified against the real budget, not an estimate

**Rationale:** The documentation describes the budget as a fraction of the context window
while the companion override (`SLASH_COMMAND_TOOL_CHAR_BUDGET`) is a character count; the
two units are not reconciled in the docs. Every budget figure in this doc is therefore a
measurement of dev-kit's *contribution*, not of the headroom remaining.

**Source(s):** S1, S2

**Acceptance criteria:**
- [ ] `/doctor` is run and its reported listing cost and budget are recorded in the ADR,
      replacing the estimates in this doc.
- [ ] After the work lands, a fresh session shows **zero core skills listed name-only**.

## Non-goals

- **Changing what dev-kit does.** This is decomposition and packaging. The moment it starts
  redesigning workflows, it is different work.
- **Splitting core by persona.** Settled and rejected — see
  [plugin-packaging.md](plugin-packaging.md) §"Rejected: persona as a plugin boundary".
- **The R/Python plugin split.** Same root cause, different decision and different timing —
  see [plugin-packaging.md](plugin-packaging.md).
- **Deleting skills on usage evidence.** The corpus is too young; see the caveats in §
  "Supporting signal".

---

## Appendix — Sprint 1.5, proposed issue body

Sprints live as GitHub issues (#49–#54), not as files. This appendix is the body ready to
file. It is a **proposal from a Product Manager window** — membership, sequencing, and
filing are Product Owner calls.

> **Note on form.** A purist reading of [ADR-0001](../adr/ADR-0001-sprint-as-issue-backed-concept-mirroring-epic.md)
> says sprints are time-boxed *execution* inside an area epic, and this sprint's centre of
> gravity is a *decision*. It is filed as a sprint anyway, at the maintainer's direction,
> because it occupies a real timebox between sprints 1 and 2 and because the alternative —
> a bare spike issue blocking two sprints — leaves the parallel reduction work (R4) without
> a home. The impurity is recorded rather than hidden.

### `[Sprint 1.5] Skill decomposition`

**Area:** [Epic B — Audit remediation](https://github.com/chris-prener/dev-kit/issues/16)
**Timebox:** 2026-08-08 → 2026-08-15
**Status:** planned

#### Goal

The suite's decomposition is decided and the skill listing is materially smaller, before
sprints 2 and 3 close findings that select boundaries the decision may redraw.

#### Membership

- [ ] **NEW (`spike`)** — Skill decomposition spike. Delivers the ADR required by R1–R3:
      which skills merge, which demote, which stay; the lifecycle-unit rule; the auto-file
      caller-class resolution.
- [ ] **NEW** — Listing-budget reduction (R4). `disable-model-invocation` on the seven
      user-initiated skills; `pr-gate-*` demoted to reference files. **~5,227 chars**,
      ~24% of the core listing.
- [ ] **NEW** — Run `/doctor`; record the real budget and listing cost (R5).

#### Sequencing

**After sprint 1, before sprint 2.** Sprint 1 is a *prerequisite*, not a conflict: its goal
is that the issue-filing substrate is coherent, and this sprint's primary deliverable is
scoped issues. The spike cannot file its own output until sprint 1 lands.

Internally, the spike and the R4 reduction are independent and may run in parallel —
`showcase` is the only skill appearing in both, and R4 should defer it to the spike's
verdict.

**Held pending this sprint's ADR:** #29 (sprint 2, renames 4 merge candidates), and #28,
#30, #31, #33 (sprint 3, boundary class). #45 (sprint 6) is soft-held.

**Unaffected and runnable in parallel throughout:** sprints 4 and 5 — **16 of the 35
findings**, both explicitly declared independent of sprints 1–3. Epic B does not stall.
Those 16 are also all language-pack work, which is the pre-work for the plugin split, so
draining them during this sprint serves two roadmap items at once.

#### Definition of done

- An accepted ADR states, per skill, merge / demote / keep, with the lifecycle-unit rule it
  applied.
- Each of #28, #29, #30, #31, #33, #45 carries a comment stating whether the ADR dissolves
  it, changes its fix, or leaves it unchanged.
- Sprint 2 and sprint 3 membership is revised to match.
- Every user-initiated-only skill carries `disable-model-invocation: true`; no `pr-gate-*`
  skill remains in the listing.
- `/doctor`'s reported listing cost is recorded, and a fresh session shows **zero core
  skills listed name-only**.

#### Explicitly out of scope

- Executing the merges. Scope is unknown until the ADR lands; the merges are filed as issues
  by this sprint and land in a revised sprint 2/3. **Keeping implementation out is what
  keeps this sprint bounded.**
- The R/Python plugin split — see [plugin-packaging.md](plugin-packaging.md).
