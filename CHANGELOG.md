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

### Changed

- `O1` KR1.4 now distinguishes which audit pass counts as its datapoint: only a pass run *after* Epic B's fixes land measures whether the defect rate changed. Pass 1b (#25) reads the unfixed repo and so serves KR1.1 instead. Its "fewer than 12 new findings" threshold is explicitly deferred for restatement once #25 establishes a real baseline and coverage denominator.
- Epic B (#16) records a scope-freeze dependency on #25 — individual sub-issues remain workable, but the epic's scope is a lower bound until the baseline is complete — plus a split threshold at ~20 sub-issues along the protocol/language-pack seam.

### Deprecated

_None._

### Removed

_None._

### Fixed

_None._

### Security

_None._
