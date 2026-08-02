# Objectives

## Active

### O1 — dev-kit's shipped guidance is trustworthy

- **Filed:** 2026-08-01
- **Linked epic(s):** [#16 — Epic B: Audit remediation](https://github.com/chris-prener/dev-kit/issues/16) (area; execution sequenced by sprints [#49–#54](https://github.com/chris-prener/dev-kit/issues/49), plus [#63](https://github.com/chris-prener/dev-kit/issues/63) and [#67](https://github.com/chris-prener/dev-kit/issues/67))
- **Last check-in:** 2026-08-02

**Why this matters**

dev-kit's entire product surface is guidance: skills that other repos read and follow literally. A defect here is unlike a defect in application code — it does not fail loudly in dev-kit, it propagates silently into every consuming repo and is discovered, if at all, by whoever followed the instructions and got a broken result. The 2026-07-30 full-repo audit found twelve such defects in a single pass, spanning three distinct failure modes: references to skills and templates that do not exist, guidance that contradicts other guidance in the suite, and technical claims that were true once but have since been overtaken by upstream reality. Twelve findings from one unplanned audit is evidence about a rate, not just a batch — the real risk is not the known twelve but the unknown next twelve, accumulating between audits that only happen when someone thinks to run one. This objective exists to drain what is known and to make the discovery of what is unknown a process rather than an accident.

**Key results**

- **KR1.1 — The known-defect backlog reaches zero.**
  - *Rationale:* Every open `audit-finding` issue is a documented defect that a user can hit today. Carrying them is a choice to ship known-broken guidance.
  - *Target:* 0 open issues labeled `audit-finding`.
  - *Progress:* 28 open, 36 total (2026-08-02, after [Sprint 1](https://github.com/chris-prener/dev-kit/issues/49)). The count has moved three times: 12 → 14 when #21 and #23 were found while filing O1; 14 → 35 when [pass 1b](https://github.com/chris-prener/dev-kit/issues/25) — an adversarial second read of the *same unfixed* repo — surfaced 21 more (#26–#46); 35 → 36 when #55 was filed after the baseline was set. First real drawdown: Sprint 1 closed 8 findings (#4, #21, #2, #23, #3, #32, #34, #35) — the filing-substrate area of Epic B (#16) — shipped via [#57](https://github.com/chris-prener/dev-kit/pull/57)/[#58](https://github.com/chris-prener/dev-kit/pull/58). Remaining work is sequenced by sprints #63 (Sprint 1.5, decomposition), #50–#54, and #67 (Sprint 7, filing/lifecycle substrate follow-ups). All 34 open sub-issues have a sprint home as of the 2026-08-02 grooming pass.

- **KR1.2 — Every cross-reference in skill prose resolves, and a check proves it.**
  - *Rationale:* The largest single failure mode found by the audit was prose naming something that does not exist — a renamed skill (#1, 9 stale references), a template that was never vendored (#2, 6 references). These are mechanically detectable, which means they should never have survived to an audit. A check that runs is worth more than a fix that does not repeat.
  - *Target:* 0 unresolvable references to skill names, template paths, partial paths, or file paths across `dev-kit/skills/`; verified by a repeatable check rather than by reading.
  - *Progress:* ≥15 known-broken references, plus the surfaces pass 1b added — a phantom `plan.md` (#36) and nine skills whose registered name diverges from the name 100+ cross-references use (#29). No automated check exists (baseline, 2026-08-01). Note that #29 is the class this KR is about but would *not* be caught by a naive check: `pr-gate-qc`'s existing cross-reference sweep validates prose names against directories, so it is structurally blind to it. The check this KR calls for must resolve names the way Claude Code does.

- **KR1.3 — Language-pack technical claims are verified against upstream, with a date attached.**
  - *Rationale:* The hardest defect class is the one that decays without anyone touching the file: a version pin that ages out (#7), a packaging standard that gets superseded (#8, PEP 639), an API that never existed or stopped existing (#9, pandera). These cannot be fixed once — they need a verification date so staleness is visible instead of invisible.
  - *Target:* All 21 `python-*` / `r-*` skills carry an upstream-verification date no older than 6 months, covering runnable examples and version pins.
  - *Progress:* 0 of 21 carry a verification date (baseline, 2026-08-01). Pass 1b added six more findings of exactly this decay class in packs pass one had partially or never read (#39–#43, #46) — including two that a consumer would copy and run. That the second reader found six more in the same aging corpus is the argument for dating claims rather than re-auditing them.

- **KR1.4 — The audit is a recurring process, and the second pass finds less than the first.**
  - *Rationale:* This is the KR that decides whether the objective actually worked. If a repeatable audit runs again and surfaces a comparable pile, the fixes were symptomatic and the defect rate is unchanged. Fewer new findings on pass two is the real evidence that guidance quality improved.
  - *Target (restated 2026-08-01, see below):* A documented, repeatable audit procedure exists and has run at least twice; **the post-fix pass surfaces fewer than 10 new findings** over the full 58-skill denominator, of which **no more than 2 are regressions** of a fingerprinted finding that a prior pass closed.
  - *Progress:* Procedure drafted and exercised once. Pass one (2026-07-30) was ad hoc and undocumented; [pass 1b](https://github.com/chris-prener/dev-kit/issues/25) (2026-08-01) ran against a written scope brief, recorded its coverage in full, and logged three defects in the procedure itself — the next draft has to fix the brief's unsatisfiable auto-file output contract, its understated denominator, and its five-class taxonomy (a sixth, *missing failure path*, was named in the process). All 35 baseline findings are fingerprinted in [the ledger](audits/2026-07-29-full-repo-audit.md), so a later pass's known-vs-new diff is mechanical.
  - *Scope note — what counts as "the post-fix pass" (2026-08-01).* Only a pass run **after both Epic B's and Epic C's fixes land** is a KR1.4 datapoint, because only then has the repo actually changed. Pass 1b read the *unfixed* repo and therefore measured what pass one missed, not whether quality improved — its findings serve KR1.1. See the ledger's three-instrument model.
  - *Threshold restatement (2026-08-01), replacing "fewer than 12".* The original number was set against a 12-finding baseline whose coverage was undocumented; both inputs have since changed. The baseline is now **35 findings over a known 58/58 denominator**. The calibration input that matters is not that raw number but pass 1b's inter-rater signal: a fresh reader found **7** new findings inside the 19 skills pass one had demonstrably already read. That is the honest estimate of what any competent second reader turns up in already-audited ground, and it is what a post-fix pass has to beat to prove the remediation was structural rather than symptomatic. The other 13 of pass 1b's findings came from first-coverage ground, which cannot recur — coverage is complete and recorded. **Fewer than 10** therefore allows roughly the inter-rater rate plus a small allowance for drift accumulated between passes, while still failing if remediation only treated symptoms. The regression sub-clause exists because a *recurrence* after a fix is far stronger evidence of a bad fix than a first-time finding is of a bad repo, and averaging the two would hide it.

## Archived

_None yet._
