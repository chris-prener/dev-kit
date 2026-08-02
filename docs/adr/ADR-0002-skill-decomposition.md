---
status: accepted
date: 2026-08-02
source: "Spike #61 (Sprint 1.5, #63), Epic B (#16), docs/requirements/skill-decomposition.md (R1-R5)"
---

# ADR-0002: Skill decomposition — lifecycle-unit and canonical-source rules, with per-skill merge/demote/keep verdicts

## Context

dev-kit ships 58 skills (37 core + 21 language-pack) as a single plugin. The skill listing (every skill's `description` + `when_to_use`) loads into context every turn, budgeted at `skillListingBudgetFraction`, defaulting to 1% of the model's context window. Direct measurement on 2026-08-02, before #62 landed, put the full listing at 33,079 characters across 58 skills — see R5 below for the post-#62 current figure. On overflow, Claude Code drops descriptions for the least-used skills and keeps only their names; an observed session lost descriptions for 19 skills, six of them core workflow skills (`quick-capture`, `readme`, `run-repo-qc`, `showcase`, `triage`, `walkthrough`).

Beyond the raw budget, 43% of core `when_to_use` text (5,335 of 12,481 chars, across 33 of 37 core skills) is spent on "Not for X, that's Y" disambiguation — a cost that scales with the number of near-neighbor skills, not with the value any one skill delivers.

Five open audit findings — #28, #30, #31, #33, #45 — are genuine boundary disputes: two skills disagreeing about who owns what, closable only by picking a seam this decision might move. Three further findings — #5/#37 (coverage-gating contradiction), #6/#10/#12 (duplicated lint/comment config), #38 (a partial's convention violated) — are a different failure mode: duplicated or contradicted *policy content* between skills that both keep existing, not a dispute over which skill should exist or own a lifecycle stage. They motivate Rule 2 below but were never held pending this ADR; sprints 4 and 5 remained free to fix them throughout. Closing the five genuine boundary disputes before this decision landed risked picking a seam the decision later moves, which `O1` KR1.4 counts as a regression of a fingerprinted finding — that is what made this urgent rather than merely worthwhile.

Full evidence base: `docs/requirements/skill-decomposition.md` (sources S1-S6).

## Decision

We will apply two general rules across the 58-skill suite, rather than negotiate each boundary dispute individually, and record a per-skill merge/demote/keep verdict from them.

### Rule 1 — the lifecycle-unit rule

Two independent tests, answering two different questions:

- **1a — the merge test.** Stages that share one trigger source (the same label-state object) and answer to the same caller class merge into a single skill as separate operations, rather than separate listing entries. A stage with its own independent trigger — a cadence or event distinct from its neighbors' — stays its own skill even if it shares an object with them.
- **1b — the demote test.** A skill reachable only by dispatch from another skill, with no independent trigger a human or the model would ever use to select it directly, earns no listing entry regardless of what it does. It demotes to a reference file the dispatching skill reads inline.

A skill that has an independent trigger passes both tests: it neither merges (1a) nor demotes (1b).

### Rule 2 — the canonical-source rule

A policy value cited by more than one skill (a coverage threshold, a lint config block, a comment-style worked example, an artifact's contract/schema) lives in exactly one canonical skill or a `_partials/` file, and is referenced — never restated or re-implemented — everywhere else. This is a content rule, not a decomposition rule: it doesn't change which skills exist, but it is the general fix underlying the language-pack duplication findings (#6, #10, #12), the coverage-gating contradiction (#5, #37), the citation violation in #38, and — within this suite's core skills — finding #33 (see below).

### Per-skill verdicts

**Merge — backlog lifecycle cluster.** `quick-capture`, `backlog-grooming`, and `triage` merge into `backlog` as additional operations (capture / groom / triage, alongside `backlog`'s existing create / prioritize / auto-file). Rule 1a applies directly: all four share one trigger source — an issue's Status label — and the maintainer reports running them in serial by hand; `triage`'s propose-promote-to-epic and `backlog-grooming`'s propose-epic-promotion are already acknowledged in-corpus as "the same mechanic, different queue." `backlog` keeps its directory identity rather than taking a new umbrella name, specifically because ADR-0004 keys its dedup and caller registry on the *directory* name (`<skill>` in the `autofile-id` marker), not the frontmatter `name` — merging into the existing identity means the registry needs no amendment (see R3 below), and every caller skill's existing reference to "`backlog`'s auto-file mode" stays correct. Auto-file remains a narrow, separately-documented operation surface within the merged skill, distinguished from the three interactive operations because it answers to a different caller class (machine callers under ADR-0004, not a human at the keyboard). `backlog-retrospective` is explicitly **not** part of this merge: the closing side already answered Rule 1a correctly on its own (bundling close + retro + validate as operations of one skill), and this decision only extends that precedent to the opening side.

**Demote — pr-gate-\* trio.** `pr-gate-changelog`, `pr-gate-code-review`, and `pr-gate-qc` demote from skills to reference files under `pr-orchestrator/` (e.g. `pr-orchestrator/reference/gate-changelog.md`, `gate-code-review.md`, `gate-qc.md`) — six listing entries removed via two actions (the backlog merge above, and this demotion). All three self-declare "invoked only by `pr-orchestrator`, not triggered directly by the user" — Rule 1b's independent-trigger test fails outright: there is no trigger a human or the model would use to select them on their own, so their 788 chars of listing cost buys nothing. (They pass the caller-class distinction cleanly — they are unambiguously machine-invoked — but Rule 1b does not turn on caller class; a distinct caller class alone does not earn a listing entry.) `disable-model-invocation` is not the right mechanism here (it would also block `pr-orchestrator`'s own dispatch to them); demotion to a plain reference file removes them from the listing entirely, and `pr-orchestrator` inlines their logic as steps that read the reference file directly, with no `Skill`-tool dispatch involved.

**Keep — everything else**, including the three clusters Rule 1 was explicitly tested against and did not merge or demote:

- **Docs trio** (`documentation`, `documentation-suite`, `documentation-audit-changes`): each has its own independent trigger distinct from its siblings — "audit this file for docstrings," "run full documentation," "audit this PR's diff for staleness" are three different deliberate asks, not one object's stages — so Rule 1a doesn't merge them, and each is reachable directly by a human or the model, so Rule 1b doesn't demote any of them. `documentation-suite` is a legitimate thin orchestrator, the same shape as `pr-orchestrator` itself: orchestration triggered directly by a user or the model is exactly what Rule 1b protects, unlike the pr-gates' dispatch-only shape.
- **Retrospective pair** (`backlog-retrospective`, `epic-retrospective`): different objects (issue vs. epic) with materially different close semantics (an epic close moves a roadmap entry and prompts for KR impact; an issue close does not) and each has its own independent trigger ("close #N" vs. "close epic #N") — Rule 1a keeps them separate. They do share one rule duplicated by copy — `epic-retrospective`'s non-completion-close carve-out is, in its own words, "mirrored from `backlog-retrospective`" — which Rule 2 resolves: extract that carve-out into a `_partials/` file both reference.
- **`showcase`**: Sprint 1.5's issue text flagged it as a "Writer-cluster merge candidate" pending this ADR. Checked against its four named siblings (`walkthrough`, `changelog`, `epic-retrospective`, `backlog-retrospective`), each exclusion is real — technical explanation vs. stakeholder narrative, Keep-a-Changelog entries vs. audience-tailored rollup, single-object close vs. cross-object period rollup — so Rule 1a doesn't merge it into any of them. It also passes Rule 1b: unlike the six skills #62 flagged `disable-model-invocation: true` on, `showcase`'s own trigger phrases ("generate showcase," "stakeholder rollup due") anticipate a human or the model deciding independently that a stakeholder communication is due — a real independent trigger, not dispatch-only. It stays a skill, unflagged.
- **`code-review` / `pr-gate-code-review`** (finding #31): resolved as a side effect of the pr-gate demotion above, not as an independent merge — `code-review` was never the source of the mismatch; the gate wrapper was. Fixing #31 becomes a single edit to the demoted `gate-code-review.md` reference file, aligning its gate-invocation step to `code-review`'s actual vocabulary (`--mode=review` / `--mode=self-review`, not `--mode=gate`).
- **`epic-dependency`**: already correctly handled by #62 (`disable-model-invocation: true`); no further action.
- **21 language-pack skills** (`python-*`, `r-*`): out of this decision's scope. The R/Python plugin split (`docs/requirements/plugin-packaging.md`) is a separate, already-scoped decision about *packaging*, not decomposition — these skills are mirrored by design and none of them fail Rule 1. Their three open findings (#5/#37, #6/#10/#12, #38) are Rule 2 violations, addressed above in Context; sprints 4 and 5 remain free to fix them, with `python-testing`/`r-testing` as the canonical owner of coverage-gating policy and `python-code-style`/`r-code-style` as the canonical owner of lint config and comment-style examples.

**#33 — resolved by Rule 2, not Rule 1.** "`backlog` Step 4 implementation plans collide with `implementation-plan`'s exclusive contract" is not a question of which skill should exist — `implementation-plan` is unambiguously the canonical owner of the `## Implementation plan` issue-comment contract, and `backlog` re-implementing a competing template is exactly the duplicated-policy-content failure Rule 2 names. The verdict is: `implementation-plan` is canonical; `backlog`'s Step 4 must defer to it, not restate it. This fix is unrelated to the backlog-cluster merge decided above, but it lands in the same pull request, because that PR already rewrites `backlog/SKILL.md` for the merge — folding it in avoids touching the file twice.

**#29 — eight skills unchanged, one changes its fix.** Eight of the nine frontmatter/directory mismatches (`changelog`, `docs-organization`, `documentation`, `epic`, `objectives`, `readme`, `requirements`, `roadmap`) are untouched by any verdict above — still a plain frontmatter `name:` rename to match the directory, unaffected by this decision. `backlog`'s rename (`backlog-manager` → `backlog`) changes its fix only in *where* it lands: folded into the backlog-merge PR (which touches `backlog/SKILL.md` regardless) rather than shipped standalone.

**#45 — unchanged.** "Persona lane rules conflict with skills' inline gate handoffs (epic → requirements/adr/objectives)" is a persona-policy question about `epic`'s handoffs to `requirements`, `adr`, and `objectives` — none of which this ADR merges, demotes, or otherwise restructures. The pr-gate demotion does change *how* `pr-orchestrator` dispatches to its own gates (inline reference-file reads instead of `Skill`-tool calls), but that is a different handoff pattern from the one #45 disputes, and does not touch it. #45 was only soft-held out of caution; it can proceed independently of this ADR.

### R3 — auto-file caller class

`backlog`'s Auto-file mode remains the sole surface ADR-0004's callers (`run-repo-qc`, `documentation`, `readme`, `walkthrough`, `code-review`, `documentation-audit-changes`, `docs-organization`, `playbooks`, `objectives`, `backlog-retrospective`) invoke. ADR-0004 keys its `autofile-id` dedup marker and caller registry on the skill's *directory* name, not its frontmatter `name` — so `backlog`'s own frontmatter/directory mismatch (`backlog-manager` vs. `backlog`, part of #29 above) does not affect the registry either way. Because the merge keeps `backlog`'s directory identity, ADR-0004's caller registry needs no amendment.

### R5 — real budget, not an estimate

The 33,079-character figure in Context is the pre-#62 baseline (measured 2026-08-02, the same day #62 was filed, before it merged). #62 has since landed on this branch's base and set `disable-model-invocation: true` on six skills (`bootstrap-repo`, `create-local-skill`, `create-repo-qc`, `epic-dependency`, `github-enforcement`, `session-start`), which removes their combined 3,448 characters from the listing entirely. **The current listing is 33,079 − 3,448 = 29,631 characters (~7,408 est. tokens).**

A `/doctor` run on 2026-08-02 (post-#62) reported that current figure against an estimated ~2,000-token budget (0.01 × a 200K-token context window, ≈8,000 est. chars) — roughly **3.7x over**, before any other plugin or built-in skill competes for the same space. `/doctor` reports the character measurement directly from the skill files; the token/budget conversion is an estimate (tokens ≈ chars/4), consistent with the units-reconciliation gap the requirements doc already flagged (`SLASH_COMMAND_TOOL_CHAR_BUDGET` is a raw character count while `skillListingBudgetFraction` is a fraction of the token-denominated context window, and the two are not reconciled in the upstream docs). No individual skill hits the 1,536-char per-skill cap, so every remaining character counts against the budget.

The backlog merge and pr-gate demotion together remove at least 2,666 characters from the *current* 29,631 outright (`quick-capture` 687 + `backlog-grooming` 484 + `triage` 707 + the pr-gate trio 788 chars), before accounting for the modest growth of `backlog`'s own entry to describe its new operations — a partial but real reduction, leaving the residual gap to the R/Python plugin split and any further reduction outside this ADR's scope.

### Alternatives considered

- **Negotiate each boundary finding independently.** Rejected — this is exactly the failure mode Rule 1 exists to prevent: closing #33's or #31's specific complaint without deciding the underlying unit risks picking a seam this ADR would then move, spending `O1` KR1.4's regression budget on a decision deferred by choice.
- **Merge the entire backlog cluster including `backlog-retrospective` into one skill.** Rejected — the closing side has a genuinely different caller-class and object-lifecycle shape (terminal state, KR/roadmap side effects on the epic variant) from the opening side; forcing one skill to cover both ends of the lifecycle would recreate the mode-vocabulary confusion #31 already documents, for a much larger cluster.
- **Give `backlog`'s merged identity a new umbrella name.** Rejected — every existing cross-reference (ADR-0004's registry, sibling skills' `when_to_use` text, this repo's own routing table) already says `backlog`, and renaming would require touching all of them for no behavioral benefit.
- **Use `disable-model-invocation` for the pr-gate trio instead of demoting them.** Rejected — the flag also blocks the invoking skill (`pr-orchestrator`) from dispatching to them via the `Skill` tool; it's the correct mechanism for user-initiated-only skills (already applied to six others in #62) but not for machine-only ones.

## Consequences

- **Easier:** six listing entries (`quick-capture`, `backlog-grooming`, `triage`, and the three pr-gates) collapse to inline operations or reference files via two actions, cutting three disputed boundary findings (#28, #30, #31) down to single-file fixes instead of cross-skill reconciliations. #33 collapses similarly via Rule 2, landing in the same PR as the backlog merge. The suite has two written rules for the next time a decomposition question comes up, instead of re-litigating from scratch.
- **Harder:** `backlog`'s `SKILL.md` grows to cover four operations instead of one, raising the bar for keeping its own `when_to_use` legible as it grows — the same super-linear disambiguation cost this ADR's evidence (§2 of the requirements doc) warns about, now concentrated in one file instead of spread across four. Every skill that currently says "hand off to `quick-capture`" or "invoked by `pr-gate-qc`" needs its cross-reference updated to the new shape.
- **Constraints:** future lifecycle-stage skill proposals should be tested against Rule 1a/1b before they're filed, not after; future cross-skill policy values (thresholds, config blocks, style examples, artifact contracts) should be authored once in a canonical skill or partial per Rule 2, not copied or re-implemented.
- **Revisit when:** the R/Python plugin split (`plugin-packaging.md`) ships — at that point the 21 language-pack skills leave this listing's budget entirely and this decision's evidence should be re-measured against core-only; or if `backlog`'s merged `SKILL.md` grows past a size where its own `when_to_use` needs the same disambiguation-cost treatment this ADR was filed to avoid.

## References

- Related epic: #16
- Related requirements doc: `docs/requirements/skill-decomposition.md`
- Related ADRs: ADR-0004 (`dev-kit/skills/_docs/ADR-0004-auto-filed-issue-protocol.md`) — auto-file registry this decision leaves unchanged
- Related issue: #61
