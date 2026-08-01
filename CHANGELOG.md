# Changelog

All notable changes to this project are documented in this file, in the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.

## [Unreleased]

### Added

- Repo bootstrap scaffolding: `docs/ROADMAP.md`, `docs/OBJECTIVES.md`, `docs/ARCHITECTURE.md`, `docs/GLOSSARY.md`, ADR/requirements templates, and the `.claude-plugin/marketplace.json` marketplace manifest with an initial `0.1.0` plugin version.
- [ADR-0001](docs/adr/ADR-0001-sprint-as-issue-backed-concept-mirroring-epic.md): ratifies Epic A's (#13) deferred sprint-mechanism decision, plus its supporting requirements doc (`docs/requirements/epic-sprint-model.md`).
- Objective `O1` ("dev-kit's shipped guidance is trustworthy") in `docs/OBJECTIVES.md` — the first entry in the objectives layer, with four key results covering defect remediation, cross-reference integrity, upstream-verification freshness, and audit recurrence.
- Roadmap entry for [Epic B](https://github.com/chris-prener/dev-kit/issues/16) (#16, audit remediation) at the `Next` horizon; the twelve 2026-07-30 audit findings (#1–#12) and the follow-on #21 are now linked to it as sub-issues.
- `docs/audits/` — audit ledgers, recording audit *passes* (scope, coverage, fingerprint conventions) rather than the individual findings that live as GitHub issues. Seeded with the pass-one ledger for the 2026-07-29 sweep, which inventories all fourteen findings against a five-class defect taxonomy and documents that only 19 of 58 skills are demonstrably covered.
- Scope brief for pass 1b (#25), an adversarial re-audit of the unfixed repo intended to complete the pre-fix baseline and record coverage explicitly. Doubles as the first draft of the repeatable audit procedure `O1` KR1.4 calls for.
- Pass 1b results: 21 new findings (#26–#46) filed under the `adversarial-review-2026-08-01` namespace, plus four scope corrections on already-known findings (#3, #4, #9, #23). Three-number result — 14 known re-encountered, **7 new inside the 19 skills pass one had already read**, 13 new in first-coverage ground, and 1 in the persona layer added to scope during the run.
- The pass-one ledger now carries pass 1b's finding registry, its full coverage record (58/58 skills plus partials, ADRs, vendored assets, repo docs, live GitHub state, and the six output-style personas), and a sixth defect class — *missing failure path*, for a skill that defines no behavior for an environment state its own audience routinely occupies.
- Six sprint issues ([#49–#54](https://github.com/chris-prener/dev-kit/issues/49)) and a `sprint` label — the first live exercise of the area/timebox model from [ADR-0001](docs/adr/ADR-0001-sprint-as-issue-backed-concept-mirroring-epic.md), filed by hand ahead of the `sprint` skill so the friction of doing it manually becomes that skill's specification. Sprints group the 35 findings by what the work touches (filing substrate → cross-reference integrity → PR/gate flow, plus three independent tracks) rather than by which audit pass found them.
- A field report on [#13](https://github.com/chris-prener/dev-kit/issues/13#issuecomment-5153179276) recording what this restructure validated against the epic/sprint requirements (R1, R2, R4) and what it contradicted: **GitHub native sub-issues permit only one parent** (verified, HTTP 422), so R3's two independent linkage dimensions cannot both use the native mechanism. Area keeps native sub-issues; sprint membership uses a body task list for the pilot.

### Changed

- `O1` KR1.4 now distinguishes which audit pass counts as its datapoint: only a pass run *after* Epic B's fixes land measures whether the defect rate changed. Pass 1b (#25) reads the unfixed repo and so serves KR1.1 instead. Its "fewer than 12 new findings" threshold is explicitly deferred for restatement once #25 establishes a real baseline and coverage denominator.
- Epic B (#16) records a scope-freeze dependency on #25 — individual sub-issues remain workable, but the epic's scope is a lower bound until the baseline is complete — plus a split threshold at ~20 sub-issues along the protocol/language-pack seam.
- Epic B is reshaped from a project into a **durable area** — retitled `[Epic B] Audit remediation`, given an `Owner` field per the epic/sprint requirements doc's R1, and holding all 35 findings from both audit passes. Epic C (#47), filed hours earlier for pass 1b's yield, is closed as superseded: the B/C boundary encoded *which reader found a defect* rather than what the work touches, and eleven files were edited by an issue from each. Provenance is unaffected — it lives in each issue's `audit-finding` fingerprint marker and in the ledger's registry tables, never in the epic layer.
- Epic B moves from the `Next` horizon to `Now`, reflecting that sprint 1 is active. The roadmap's horizon model is deliberately **not** restructured to key on sprints (R6) — that entangles the roadmap contract before the `sprint` skill exists to maintain it.
- `O1` KR1.1's progress moves from 14 to 35 open `audit-finding` issues — baseline completion, not regression. Pass 1b read the same unfixed repo; the count rose because a second reader opened the 39 skills whose coverage was previously unknown. This is the first time the figure has stood over a fully documented denominator.
- `O1` KR1.4's threshold is restated from "fewer than 12 new findings" to "fewer than 10, of which no more than 2 are regressions," now that #25 has established a real baseline (35) and a known coverage denominator (58/58). The calibration input is pass 1b's inter-rater signal — 7 new findings inside ground pass one had already read — rather than the raw baseline. KR1.2 and KR1.3 progress notes pick up the surfaces pass 1b added.

### Deprecated

_None._

### Removed

_None._

### Fixed

_None._

### Security

_None._
