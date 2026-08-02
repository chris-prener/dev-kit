---
status: accepted
date: 2026-08-02
source: "Spike #61 (Sprint 1.5, #63), Epic B (#16), docs/requirements/skill-decomposition.md (R1-R5)"
---

# ADR-0002: Skill decomposition — lifecycle-unit and canonical-source rules, with per-skill merge/demote/keep verdicts

## Context

dev-kit ships 58 skills (37 core + 21 language-pack) as a single plugin. The skill listing (every skill's `description` + `when_to_use`) loads into context every turn, budgeted at `skillListingBudgetFraction`, defaulting to 1% of the model's context window. Direct measurement on 2026-08-02 put the full listing at 33,079 characters across 58 skills; a `/doctor` run the same day estimated that against a ~2,000-token default budget (0.01 × a 200K-token context window, ≈8,000 chars) — roughly **4.1x over**, before any other plugin or built-in skill competes for the same space. On overflow, Claude Code drops descriptions for the least-used skills and keeps only their names; an observed session lost descriptions for 19 skills, six of them core workflow skills (`quick-capture`, `readme`, `run-repo-qc`, `showcase`, `triage`, `walkthrough`).

Beyond the raw budget, 43% of core `when_to_use` text (5,335 of 12,481 chars, across 33 of 37 core skills) is spent on "Not for X, that's Y" disambiguation — a cost that scales with the number of near-neighbor skills, not with the value any one skill delivers. And at least 8 open audit findings (#28, #30, #31, #33, #45, #5/#37, #6/#10/#12, #38) are boundary disputes — two skills disagreeing about who owns what — which cannot be closed correctly until the boundary itself is decided. Closing them first risks picking a seam this decision later moves, which `O1` KR1.4 counts as a regression of a fingerprinted finding.

Full evidence base: `docs/requirements/skill-decomposition.md` (sources S1-S6).

## Decision

We will apply two general rules across the 58-skill suite, rather than negotiate each boundary dispute individually, and record a per-skill merge/demote/keep verdict from them.

### Rule 1 — the lifecycle-unit rule

A lifecycle stage earns its own listed skill only when it has **both** an independent trigger (an event or cadence distinct from its neighbors) **and** a caller class distinct from its neighbors (interactively human-invoked vs. machine-invoked). Two stages that share a trigger source (the same label-state object) and no distinct caller class belong inside one skill as separate operations, not separate listing entries.

### Rule 2 — the canonical-source rule

A policy value cited by more than one skill (a coverage threshold, a lint config block, a comment-style worked example) lives in exactly one canonical skill or a `_partials/` file, and is referenced — never restated — everywhere else. This is a content rule, not a decomposition rule: it doesn't change which skills exist, but it is the general fix underlying the language-pack duplication findings (#6, #10, #12) and the coverage-gating contradiction (#5, #37), and the citation violation in #38.

### Per-skill verdicts

**Merge — backlog lifecycle cluster.** `quick-capture`, `backlog-grooming`, and `triage` merge into `backlog` as additional operations (capture / groom / triage, alongside `backlog`'s existing create / prioritize / auto-file). Rule 1 applies directly: all four share one trigger source — an issue's Status label — and the maintainer reports running them in serial by hand; `triage`'s propose-promote-to-epic and `backlog-grooming`'s propose-epic-promotion are already acknowledged in-corpus as "the same mechanic, different queue." `backlog` keeps its directory identity rather than taking a new umbrella name, specifically because ADR-0004 names `backlog`'s Auto-file mode as the caller registry's owner — merging into the existing identity means the registry needs no amendment (see R3 below), and every caller skill's existing reference to "`backlog`'s auto-file mode" stays correct. Auto-file remains a narrow, separately-documented operation surface within the merged skill, distinguished from the three interactive operations because it answers to a different caller class (machine callers under ADR-0004, not a human at the keyboard). `backlog-retrospective` is explicitly **not** part of this merge: the closing side already answered Rule 1 correctly on its own (bundling close + retro + validate as operations of one skill), and this decision only extends that precedent to the opening side.

**Demote — pr-gate-\* trio.** `pr-gate-changelog`, `pr-gate-code-review`, and `pr-gate-qc` demote from skills to reference files under `pr-orchestrator/` (e.g. `pr-orchestrator/reference/gate-changelog.md`, `gate-code-review.md`, `gate-qc.md`). All three self-declare "invoked only by `pr-orchestrator`, not triggered directly by the user" — Rule 1's caller-class test fails outright: there is no independent trigger a human or the model would use to select them, so their 788 chars of listing cost buys nothing. `disable-model-invocation` is not the right mechanism here (it would also block `pr-orchestrator`'s own dispatch to them); demotion to a plain reference file removes them from the listing entirely, and `pr-orchestrator` inlines their logic as steps that read the reference file directly, with no `Skill`-tool dispatch involved.

**Keep — everything else**, including the three clusters Rule 1 was explicitly tested against and did not merge:

- **Docs trio** (`documentation`, `documentation-suite`, `documentation-audit-changes`): `documentation-suite` is a legitimate thin orchestrator with its own independent trigger ("run full documentation" is a distinct, deliberate ask) — the same shape as `pr-orchestrator`, which stays a skill because orchestration triggered directly by a user or the model is exactly what Rule 1's caller-class test protects. `documentation-audit-changes` differs from `documentation` in write-mode (read-only vs. mutates code) and scope (PR diff vs. full repo) — not an adjacency, a different operation.
- **Retrospective pair** (`backlog-retrospective`, `epic-retrospective`): different objects (issue vs. epic) with materially different close semantics (an epic close moves a roadmap entry and prompts for KR impact; an issue close does not) — Rule 1's trigger/object test keeps them separate. They do share one rule duplicated by copy — `epic-retrospective`'s non-completion-close carve-out is, in its own words, "mirrored from `backlog-retrospective`" — which Rule 2 resolves: extract that carve-out into a `_partials/` file both reference.
- **`showcase`**: Sprint 1.5's issue text flagged it as a "Writer-cluster merge candidate" pending this ADR. Checked against its four named siblings (`walkthrough`, `changelog`, `epic-retrospective`, `backlog-retrospective`), each exclusion is real — technical explanation vs. stakeholder narrative, Keep-a-Changelog entries vs. audience-tailored rollup, single-object close vs. cross-object period rollup. The merge candidacy does not survive contact with the evidence; `showcase` stays a skill.
- **`code-review` / `pr-gate-code-review`** (finding #31): resolved as a side effect of the pr-gate demotion above, not as an independent merge — `code-review` was never the source of the mismatch; the gate wrapper was.
- **`epic-dependency`**: already correctly handled by #62 (`disable-model-invocation: true`); no further action.
- **21 language-pack skills** (`python-*`, `r-*`): out of this decision's scope. The R/Python plugin split (`docs/requirements/plugin-packaging.md`) is a separate, already-scoped decision about *packaging*, not decomposition — these skills are mirrored by design and none of them fail Rule 1. Their three open findings (#5/#37, #6/#10/#12, #38) are Rule 2 violations (duplicated or contradicted policy values), not boundary disputes, and were never held pending this ADR — sprints 4 and 5 remain free to fix them independently, with `python-testing`/`r-testing` as the canonical owner of coverage-gating policy and `python-code-style`/`r-code-style` as the canonical owner of lint config and comment-style examples.

### R3 — auto-file caller class

`backlog`'s Auto-file mode remains the sole surface ADR-0004's callers (`run-repo-qc`, `documentation`, `readme`, `walkthrough`, `code-review`, `documentation-audit-changes`, `docs-organization`, `playbooks`, `objectives`, `backlog-retrospective`) invoke. Because the merge keeps `backlog`'s directory identity, ADR-0004's caller registry needs no amendment.

### R5 — real budget, not an estimate

A `/doctor` run on 2026-08-02 measured the full 58-skill listing at 33,079 characters (~8,270 est. tokens) against an estimated ~2,000-token budget (0.01 × a 200K-token context window) — roughly **4.1x over**. No individual skill hits the 1,536-char per-skill cap, so every character counts against the budget. The backlog merge and pr-gate demotion together remove at least 2,666 characters from the listing outright (`quick-capture` 687 + `backlog-grooming` 484 + `triage` 707 + the pr-gate trio 788 chars), before accounting for the modest growth of `backlog`'s own entry to describe its new operations — a partial but real reduction. Closing the remaining gap needs the `disable-model-invocation` work already done in #62 and/or further reduction outside this ADR's scope (notably the R/Python plugin split).

### Alternatives considered

- **Negotiate each boundary finding independently.** Rejected — this is exactly the failure mode Rule 1 exists to prevent: closing #33's or #31's specific complaint without deciding the underlying unit risks picking a seam this ADR would then move, spending `O1` KR1.4's regression budget on a decision deferred by choice.
- **Merge the entire backlog cluster including `backlog-retrospective` into one skill.** Rejected — the closing side has a genuinely different caller-class and object-lifecycle shape (terminal state, KR/roadmap side effects on the epic variant) from the opening side; forcing one skill to cover both ends of the lifecycle would recreate the mode-vocabulary confusion #31 already documents, for a much larger cluster.
- **Give `backlog`'s merged identity a new umbrella name.** Rejected — every existing cross-reference (ADR-0004's registry, sibling skills' `when_to_use` text, this repo's own routing table) already says `backlog`; renaming would require touching all of them for no behavioral benefit, and directly reproduces finding #29's frontmatter/directory-mismatch problem a tenth time.
- **Use `disable-model-invocation` for the pr-gate trio instead of demoting them.** Rejected — the flag also blocks the invoking skill (`pr-orchestrator`) from dispatching to them via the `Skill` tool; it's the correct mechanism for user-initiated-only skills (already applied to six others in #62) but not for machine-only ones.

## Consequences

- **Easier:** four listing entries (`quick-capture`, `backlog-grooming`, `triage`, and the three pr-gates as one demotion) collapse to inline operations or reference files, cutting four disputed boundary findings (#28, #30, #31, #33) down to single-file fixes instead of cross-skill reconciliations. The suite has one written rule (Rule 1) for the next time a lifecycle-stage-vs-object question comes up, instead of re-litigating from scratch.
- **Harder:** `backlog`'s `SKILL.md` grows to cover four operations instead of one, raising the bar for keeping its own `when_to_use` legible as it grows — the same super-linear disambiguation cost this ADR's evidence (§2 of the requirements doc) warns about, now concentrated in one file instead of spread across four. Every skill that currently says "hand off to `quick-capture`" or "invoked by `pr-gate-qc`" needs its cross-reference updated to the new shape.
- **Constraints:** future lifecycle-stage skill proposals should be tested against Rule 1 before they're filed, not after; future cross-skill policy values (thresholds, config blocks, style examples) should be authored once in a canonical skill or partial per Rule 2, not copied.
- **Revisit when:** the R/Python plugin split (`plugin-packaging.md`) ships — at that point the 21 language-pack skills leave this listing's budget entirely and Rule 1's evidence should be re-measured against core-only; or if `backlog`'s merged `SKILL.md` grows past a size where its own `when_to_use` needs the same disambiguation-cost treatment this ADR was filed to avoid.

## References

- Related epic: #16
- Related requirements doc: `docs/requirements/skill-decomposition.md`
- Related ADRs: ADR-0004 (`dev-kit/skills/_docs/ADR-0004-auto-filed-issue-protocol.md`) — auto-file registry this decision leaves unchanged
- Related issue: #61
