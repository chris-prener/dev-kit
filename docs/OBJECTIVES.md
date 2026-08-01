# Objectives

## Active

### O1 — dev-kit's shipped guidance is trustworthy

- **Filed:** 2026-08-01
- **Linked epic(s):** [#16 — Epic B: Audit remediation](https://github.com/chris-prener/dev-kit/issues/16)
- **Last check-in:** 2026-08-01

**Why this matters**

dev-kit's entire product surface is guidance: skills that other repos read and follow literally. A defect here is unlike a defect in application code — it does not fail loudly in dev-kit, it propagates silently into every consuming repo and is discovered, if at all, by whoever followed the instructions and got a broken result. The 2026-07-30 full-repo audit found twelve such defects in a single pass, spanning three distinct failure modes: references to skills and templates that do not exist, guidance that contradicts other guidance in the suite, and technical claims that were true once but have since been overtaken by upstream reality. Twelve findings from one unplanned audit is evidence about a rate, not just a batch — the real risk is not the known twelve but the unknown next twelve, accumulating between audits that only happen when someone thinks to run one. This objective exists to drain what is known and to make the discovery of what is unknown a process rather than an accident.

**Key results**

- **KR1.1 — The known-defect backlog reaches zero.**
  - *Rationale:* Every open `audit-finding` issue is a documented defect that a user can hit today. Carrying them is a choice to ship known-broken guidance.
  - *Target:* 0 open issues labeled `audit-finding`.
  - *Progress:* 14 open (2026-08-01). Baseline was 12 when O1 was filed; #21 and #23 were found and triaged into Epic B the same day, which is the count moving for the right reason rather than the target slipping. Delivered by Epic B.

- **KR1.2 — Every cross-reference in skill prose resolves, and a check proves it.**
  - *Rationale:* The largest single failure mode found by the audit was prose naming something that does not exist — a renamed skill (#1, 9 stale references), a template that was never vendored (#2, 6 references). These are mechanically detectable, which means they should never have survived to an audit. A check that runs is worth more than a fix that does not repeat.
  - *Target:* 0 unresolvable references to skill names, template paths, partial paths, or file paths across `dev-kit/skills/`; verified by a repeatable check rather than by reading.
  - *Progress:* ≥15 known-broken references; no automated check exists (baseline, 2026-08-01).

- **KR1.3 — Language-pack technical claims are verified against upstream, with a date attached.**
  - *Rationale:* The hardest defect class is the one that decays without anyone touching the file: a version pin that ages out (#7), a packaging standard that gets superseded (#8, PEP 639), an API that never existed or stopped existing (#9, pandera). These cannot be fixed once — they need a verification date so staleness is visible instead of invisible.
  - *Target:* All 21 `python-*` / `r-*` skills carry an upstream-verification date no older than 6 months, covering runnable examples and version pins.
  - *Progress:* 0 of 21 carry a verification date (baseline, 2026-08-01).

- **KR1.4 — The audit is a recurring process, and the second pass finds less than the first.**
  - *Rationale:* This is the KR that decides whether the objective actually worked. If a repeatable audit runs again and surfaces a comparable pile, the fixes were symptomatic and the defect rate is unchanged. Fewer new findings on pass two is the real evidence that guidance quality improved.
  - *Target:* A documented, repeatable audit procedure exists and has run at least twice; the second pass surfaces fewer than 12 new findings.
  - *Progress:* Audit run once (2026-07-30), ad hoc and undocumented (baseline, 2026-08-01).

## Archived

_None yet._
