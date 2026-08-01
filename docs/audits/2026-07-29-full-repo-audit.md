---
last_updated: 2026-08-01
---

# Audit ledger — pass one (2026-07-29 / 2026-08-01)

## Why this doc exists

Audit findings survive as GitHub issues. Audit *passes* do not — pass one was run ad hoc, and its scope was never recorded. This ledger is the durable record of the pass: what it found, how each finding is fingerprinted, and what it is demonstrably known to have examined.

Any later pass reads this first, so that "already known" is decidable mechanically rather than by memory.

**This is not a coverage guarantee.** See [Coverage](#coverage--what-pass-one-actually-examined). Pass one's true reading list is unrecoverable; this doc reconstructs a lower bound from evidence and says so plainly.

## The three-instrument model

Three distinct audit instruments, easily confused because all three "audit the repo." They answer different questions and their findings are not interchangeable:

| | When | Runs against | Question it answers | Findings feed |
|---|---|---|---|---|
| **Pass 1** — manual sweep | 2026-07-29/30 | pre-fix repo | What's broken? | Epic B (#1–#12) |
| **Pass 1b** — adversarial review | 2026-08-01 | **same** pre-fix repo | What did pass 1 *miss*? | Epic B (extends scope) |
| **Pass 2** — KR1.4 comparison | after Epic B closes | **post-fix** repo | Did the defect rate actually drop? | successor epic under O1 |

**Pass 1b is baseline completion, not comparison.** It reads an unfixed repo — nothing has changed since pass one. Anything it surfaces is a pass-one miss (same artifact, different reader), not a regression and not evidence about defect rate. Its findings belong to **KR1.1** (drain the known backlog), never to KR1.4.

**Only pass 2 is a KR1.4 datapoint**, because only pass 2 reads a repo where the fixes have landed. Counting 1b toward KR1.4 would compare two reads of identical input and call the delta a quality signal.

Pass 1b nonetheless *serves* KR1.4 in three ways, which is the argument for running it before Epic B is worked:

1. **It repairs the coverage hole below.** Pass 1 ∪ Pass 1b, with 1b's scope recorded, produces a baseline whose coverage is documented — the precondition KR1.4 currently lacks.
2. **It yields an inter-rater signal.** How much 1b finds *inside* the 19 skills pass one already cited measures how leaky single-reader auditing is. A high yield there is itself a finding about the procedure.
3. **It drafts the procedure.** KR1.4 wants a documented, repeatable audit procedure. 1b's scope brief is that procedure's first draft — written in advance this time, rather than reconstructed afterward.

## Fingerprint convention

Every audit-derived issue carries an HTML comment at the end of its body:

```
<!-- audit-finding: <pass-namespace>:<finding-slug> -->
```

- `<pass-namespace>` identifies the audit run (`manual-repo-review-2026-07-29`, `session-review-2026-08-01`, `adversarial-review-2026-08-01`).
- `<finding-slug>` is a stable kebab-case identifier for the defect itself, chosen to survive rewording of the issue title.

The marker is invisible in rendered issue bodies and greppable via the API. Every pass **must** emit one on every issue it files, under its own namespace. A finding filed without a marker is invisible to every future diff. Markers are never stripped on close — closed issues are how a later pass detects *recurrence*.

Recovering the full known set:

```sh
gh issue list --state all --limit 200 --json number,title,state,body \
  --jq '.[] | select(.body | test("<!-- audit-finding:")) |
        "\(.number)\t\(.state)\t\(.body | capture("<!-- audit-finding: (?<fp>[^ ]+) -->").fp)\t\(.title)"'
```

## Known-finding registry

### `manual-repo-review-2026-07-29` (12 findings)

| # | Fingerprint slug | Class | Primary surface | Priority |
|---|---|---|---|---|
| 1 | `stale-pull-request-refs` | Dangling reference | 9 refs across `backlog`, `backlog-retrospective`, `epic`, `epic-retrospective`, `_docs`, `_partials` | high |
| 2 | `missing-qc-finding-template` | Dangling reference | `assets/github/ISSUE_TEMPLATE/qc_finding.md` (never vendored; 6 referrers) | high |
| 3 | `adr0004-caller-drift` | Dangling reference | `_docs/ADR-0004-auto-filed-issue-protocol.md` caller registry | medium |
| 4 | `label-vocabulary-drift` | Vocabulary drift | `_partials/label-vocabulary.md` vs. prose in `objectives`, `discovery`, `playbooks`, `docs-organization` | medium |
| 5 | `python-testing-contradictions` | Internal contradiction | `python-testing` vs. `python-ci`; `python-testing` vs. itself | high |
| 6 | `ruff-config-drift` | Duplication drift | `python-code-style` ↔ `python-project-scaffold` | medium |
| 7 | `stale-ci-version-pins` | Upstream drift | `python-ci`, `python-code-style` (setup-uv, codecov-action, ruff-pre-commit) | medium |
| 8 | `pep639-license-metadata` | Upstream drift | `python-packaging` | high |
| 9 | `pandera-invalid-api` | Upstream drift | `python-data-validation` (`pa.polars.Timestamp` does not exist) | high |
| 10 | `duplicated-comment-standards` | Duplication drift | `python-code-style` ↔ `python-documentation` | medium |
| 11 | `roxygen2-standards-inconsistencies` | Internal contradiction | `_partials/roxygen2-standards.md`, `r-code-style`, `r-pipeline-patterns` | medium |
| 12 | `lintr-config-drift` | Duplication drift | `r-code-style` ↔ `r-project-scaffold` | medium |

### `session-review-2026-08-01` (2 findings)

Found opportunistically while filing O1 and Epic B, not by a systematic sweep. Triaged into Epic B deliberately.

| # | Fingerprint slug | Class | Primary surface | Priority |
|---|---|---|---|---|
| 21 | `missing-baseline-labels` | Environment drift | live repo label set vs. `_partials/label-vocabulary.md` (10 missing) | high |
| 23 | `template-dor-schema-mismatch` | Internal contradiction | `assets/github/ISSUE_TEMPLATE/*` vs. `_partials/dor-preflight.md` heading matrix | high |

### `adversarial-review-2026-08-01` (pass 1b — complete, 21 findings)

Run 2026-08-01 by a second reader (different model) against the pre-fix repo, per the [scope brief](2026-08-01-pass-1b-scope-brief.md). Full results, coverage table, and triage recommendation: [#25's coverage comment](https://github.com/chris-prener/dev-kit/issues/25). Three numbers: **14 known re-encountered (4 scope corrections posted on #23/#3/#9/#4) · 7 new in previously-covered ground · 13 new in first-coverage ground** (+1 in operator-added scope: personas).

| # | Fingerprint slug | Class | Primary surface | Priority | Ground |
|---|---|---|---|---|---|
| 26 | `pr-orchestrator-close-before-gates` | Internal contradiction | `pr-orchestrator` step order | high | first-coverage |
| 27 | `pr-orchestrator-closes-regex-drift` | Internal contradiction | `pr-orchestrator` SKILL vs reference | medium | first-coverage |
| 28 | `pr-gate-changelog-dirty-tree-contract` | Internal contradiction | `pr-gate-changelog` ↔ `pr-orchestrator` | medium | first-coverage |
| 29 | `skill-name-directory-mismatch` | Internal contradiction | 9 skills' frontmatter `name` vs directory | medium | covered |
| 30 | `pr-gate-qc-persona-enum-incomplete` | Internal contradiction | `pr-gate-qc` sub-step d | medium | first-coverage |
| 31 | `code-review-mode-vocabulary` | Internal contradiction | `code-review` ↔ `pr-gate-code-review` | medium | first-coverage |
| 32 | `autofile-callers-missing-type-label` | Internal contradiction | `backlog-retrospective` V4, `objectives` op H vs ADR-0004 | high | covered |
| 33 | `backlog-step4-plan-contract-collision` | Internal contradiction | `backlog` Step 4 ↔ `implementation-plan` | medium | covered |
| 34 | `triage-duplicate-close-reason` | Internal contradiction | `triage` Route 3 vs close-reason model | medium | first-coverage |
| 35 | `discovery-invalid-close-reason-flag` | Internal contradiction | `discovery` Op 3 (`--reason not-planned`) | medium | covered |
| 36 | `post-merge-phantom-plan-md` | Dangling reference | `post-merge` (`plan.md`) | medium | first-coverage |
| 37 | `r-testing-r-ci-coverage-contradiction` | Internal contradiction | `r-testing` ↔ `r-ci` (mirror of #5) | high | first-coverage |
| 38 | `section-header-format-contradiction` | Internal contradiction | `r-code-style`/`r-documentation`/`r-pipeline-patterns` vs `_partials/inline-comment-standards.md` | medium | covered |
| 39 | `r-data-validation-wrong-api-table` | Upstream drift | `r-data-validation` §5 (`col_count_match`, `matches`) | high | first-coverage |
| 40 | `prefect-map-missing-unmapped` | Upstream drift | `python-pipeline-patterns` §4 | high | first-coverage |
| 41 | `polars-read-excel-engine-stale` | Upstream drift | `python-data-io` §1 (fastexcel/xlsxwriter) | medium | first-coverage |
| 42 | `usethis-use-github-actions-defunct` | Upstream drift | `r-package-structure` §5 | medium | first-coverage |
| 43 | `lintr-no-tab-linter-defunct` | Upstream drift | `r-code-style` §2 | medium | covered |
| 44 | `github-enforcement-403-main-hardcode` | Missing failure path | `github-enforcement` (403 / hardcoded `main`) | medium | first-coverage |
| 45 | `persona-gate-flow-conflict` | Internal contradiction | `output-styles/*` ↔ `epic` gates | medium | added scope |
| 46 | `python-ci-twine-not-installed` | Internal contradiction | `python-ci` publish workflow, `python-packaging` | medium | covered |

### Pre-existing backlog an auditor would plausibly re-find

Not audit findings, but already known and already filed. A rediscovery of any of these is **known**, not new.

| # | Title | Why an auditor would trip over it |
|---|---|---|
| 17 | Spike: commit prompts in file-writing skills | Inconsistent commit-prompt behavior across file-writing skills reads as a cross-skill inconsistency finding |
| 18 | Add a skill that generates CLAUDE.md from maintainer preferences | Gap in the skill suite |
| 19 | Add a CLAUDE.md to this repo | This repo has no CLAUDE.md — an obvious flag on any repo-hygiene sweep |

## Defect taxonomy

Pass one's findings fall into five classes. Later passes classify their own findings into this taxonomy, and **name a sixth class rather than forcing a bad fit** — a genuinely new defect shape is itself a finding about the audit procedure.

1. **Dangling reference** — prose names a skill, template, partial, or path that does not exist. *Mechanically detectable; KR1.2's target class.* (#1, #2, #3)
2. **Internal contradiction** — two skills disagree, or one skill contradicts itself. (#5, #11, #23)
3. **Upstream drift** — a technical claim that was true when written and has since been overtaken. Decays without anyone touching the file. *KR1.3's target class.* (#7, #8, #9)
4. **Duplication drift** — the same config or prose lives in two places and the copies have diverged. (#6, #10, #12)
5. **Environment drift** — declared state (a vocabulary, a baseline) does not match the actual repo. (#4, #21)
6. **Missing failure path** — a skill defines no behavior for an environment state its own stated audience routinely occupies; the guidance isn't wrong, it is silent. *Named by pass 1b per this section's instruction.* (#44)

## Coverage — what pass one actually examined

Pass one left no record of its reading list. What can be reconstructed is which skills are *cited by a finding* — a lower bound, not the real figure. A skill absent from the cited list was either read and found clean, or never opened; the evidence cannot distinguish the two.

**19 of 58 skills are cited by at least one pass-one finding:**

`backlog`, `backlog-retrospective`, `discovery`, `docs-organization`, `epic`, `epic-retrospective`, `objectives`, `playbooks`, `python-ci`, `python-code-style`, `python-data-validation`, `python-documentation`, `python-packaging`, `python-project-scaffold`, `python-testing`, `r-code-style`, `r-pipeline-patterns`, `r-project-scaffold`, `run-repo-qc`

Plus these shared surfaces: `_partials/label-vocabulary.md`, `_partials/roxygen2-standards.md`, `_partials/inline-comment-standards.md`, `_partials/dor-preflight.md`, `_partials/backlog-autofile-mode.md`, `_docs/ADR-0004-auto-filed-issue-protocol.md`, `assets/github/LABELS.md`, `assets/github/ISSUE_TEMPLATE/`.

**39 of 58 skills have unknown coverage:**

`adr`, `architecture-overview`, `backlog-grooming`, `bootstrap-repo`, `changelog`, `code-review`, `create-local-skill`, `create-repo-qc`, `documentation`, `documentation-audit-changes`, `documentation-suite`, `epic-dependency`, `github-enforcement`, `glossary`, `implementation-plan`, `post-merge`, `pr-gate-changelog`, `pr-gate-code-review`, `pr-gate-qc`, `pr-orchestrator`, `python-data-io`, `python-dependencies`, `python-pipeline-patterns`, `python-typing`, `quick-capture`, `r-ci`, `r-data-io`, `r-data-validation`, `r-dependencies`, `r-documentation`, `r-package-structure`, `r-testing`, `readme`, `requirements`, `roadmap`, `session-start`, `showcase`, `triage`, `walkthrough`

Note the shape of that list: the packs are only *partially* covered (7 of 11 `python-*`, 3 of 10 `r-*`), and the entire `pr-*` family is uncited despite #1 being a finding about the PR skill rename. That asymmetry is a strong hint pass one was not uniform — and it is the reason pass 1b records coverage explicitly, including files read and found clean.

### Pass 1b coverage (2026-08-01) — baseline complete

Pass 1b examined **all 58 skills** (every `SKILL.md` plus every `reference.md` / `TEMPLATE(S).md` companion), all 11 `_partials/`, `_docs/ADR-0004`, all of `assets/github/` (diffed against the repo's `.github/` copies), the repo docs (`ROADMAP`, `OBJECTIVES`, `GLOSSARY`, `ARCHITECTURE`, `adr/`, `requirements/`, `audits/`), live GitHub state (labels, branch protection, templates), and — operator-added scope beyond the brief — the 6 `output-styles/` personas, both plugin manifests, README, and CHANGELOG. Nothing in scope was skipped; the per-skill examined-clean / examined-with-findings table is on [#25](https://github.com/chris-prener/dev-kit/issues/25).

The Pass 1 ∪ Pass 1b union therefore has a **fully documented denominator**: 58/58 skills plus all shared and repo surfaces. This is the coverage baseline KR1.4's pass 2 compares against. The pre-fix finding baseline is **35** (14 pass-one + 21 pass-1b).

Procedure defects pass 1b logged against the brief (for the KR1.4 procedure's next draft): the auto-file output contract is unsatisfiable pre-fix (#2/#21/#23 — direct `gh issue create` per #25's AC is the documented fallback); the "58 skills" denominator understates the real guidance surface (partials, personas, assets, manifests); the taxonomy needed the sixth class above.

## Diff protocol for later passes

For each candidate finding, in order:

1. **Fingerprint match.** Does an existing issue (any state) carry a slug describing this same defect? → **Known.** Do not file. If that issue is *closed*, the defect has recurred: file fresh with a `recurrence-of: <slug>` note and flag it — a recurrence after a fix is a far stronger signal than a first-time finding.
2. **Registry match.** Not fingerprinted, but in [Pre-existing backlog](#pre-existing-backlog-an-auditor-would-plausibly-re-find)? → **Known.** Comment on the existing issue rather than filing.
3. **Coverage check.** Genuinely unfiled. Is its primary surface in the 19-skill cited list, or the 39-skill unknown list?
   - **Cited list** → prior coverage existed and missed it. For pass 1b this is the inter-rater signal; for pass 2 it counts against KR1.4.
   - **Unknown list** → **first-coverage finding.** Real, and it belongs in the backlog — but report it separately, because it is not evidence about defect rate.
4. **Classify** into the [taxonomy](#defect-taxonomy).
5. **File** via `backlog` auto-file mode: `audit-finding` label, a priority label, and the pass's fingerprint marker.

Report every pass as three numbers, never one: **known/recurrences**, **new in previously-covered ground**, **new in first-coverage ground**.

## Deferred decision — KR1.4's threshold

KR1.4's target ("fewer than 12 new findings") was set against a 12-finding baseline with undocumented coverage. Both inputs change once pass 1b lands: the baseline becomes 14 + 1b's yield, over a *known* denominator.

**Restate the target after pass 1b closes**, when the real baseline and coverage denominator exist — not now, and not after pass 2 has already produced a number. Amend KR1.4 in [`docs/OBJECTIVES.md`](../OBJECTIVES.md) to state the coverage assumption explicitly, so the number is interpretable to someone reading it six months later.

## Related

- Objective [O1 — dev-kit's shipped guidance is trustworthy](../OBJECTIVES.md)
- Epic B — [#16, Audit remediation](https://github.com/chris-prener/dev-kit/issues/16)
- Pass 1b scope brief — [2026-08-01-pass-1b-scope-brief.md](2026-08-01-pass-1b-scope-brief.md)
