---
last_updated: 2026-08-01
---

# Pass 1b scope brief — adversarial review

**Pass namespace:** `adversarial-review-2026-08-01`
**Runs against:** the repo as it stands, *unfixed* — all 14 pass-one findings are still open
**Tracking issue:** #25
**Reads first:** [2026-07-29-full-repo-audit.md](2026-07-29-full-repo-audit.md)

This brief doubles as the first draft of the repeatable audit procedure O1's KR1.4 asks for. If a step here proves wrong or insufficient while running, say so — procedure defects are findings too.

---

## Mission

A first reader has already swept this repo and filed 14 findings. **Your job is to find what they missed**, not to re-find what they caught.

Assume the first pass was competent but non-uniform: it went deep on a few skills and may never have opened others. Coverage evidence says 19 of 58 skills are cited by a finding; the other 39 are unknown — possibly clean, possibly unread. Treat "no finding exists here" as *no information*, not as a clean bill of health.

Read adversarially. The product of this repo is guidance that other repos follow literally, so the failure mode is not a crash — it is a consuming repo silently doing the wrong thing because a skill told it to.

### What this pass is not

- **Not a regression hunt.** Nothing has been fixed yet. You are reading the same artifact pass one read.
- **Not a fix pass.** File findings; change no skill files. A tempting one-line fix is still a finding.
- **Not a style review.** Prose that is merely awkward is out of scope. Prose that is *wrong*, contradictory, or names something nonexistent is in scope.

## Scope — all of it

Everything under `dev-kit/`, with no skill exempt:

- All 58 skills in `dev-kit/skills/` (excluding the `_`-prefixed shared dirs, counted separately)
- `dev-kit/skills/_partials/` — shared content included by multiple skills
- `dev-kit/skills/_docs/` — including the ADRs that define cross-skill protocols
- `dev-kit/assets/github/` — issue templates, PR template, `LABELS.md`, and the rest of the vendored scaffolding
- Repo-level docs where a skill makes a claim about them: `docs/ROADMAP.md`, `docs/OBJECTIVES.md`, `docs/adr/`, `docs/requirements/`, `docs/GLOSSARY.md`, `docs/ARCHITECTURE.md`
- Live GitHub state where a skill depends on it (label set, template presence, branch protection)

**Prioritize the 39 uncited skills** — that is where unknown coverage is concentrated. But do not skip the 19 cited ones: how much you find in already-examined ground is a deliberate measurement of how leaky a single-reader audit is, and it is one of this pass's two products.

## Already known — do not refile

The 14 findings in the ledger's [known-finding registry](2026-07-29-full-repo-audit.md#known-finding-registry), plus open backlog #17, #18, #19.

Pull the authoritative list before you start:

```sh
gh issue list --state all --limit 200 --json number,title,state,body \
  --jq '.[] | select(.body | test("<!-- audit-finding:")) |
        "\(.number)\t\(.state)\t\(.body | capture("<!-- audit-finding: (?<fp>[^ ]+) -->").fp)\t\(.title)"'
```

Encountering a known defect is expected and requires no action. **But** if you find that a known finding is *materially wider than filed* — more affected files, a worse consequence, a second failure mode — comment that on the existing issue rather than filing a new one. Scope corrections to known findings are valuable output.

## Attack angles

Not a checklist to tick — these are the shapes of defect this repo actually produces. Work them adversarially.

1. **Follow every cross-reference to its target.** Skill names, `_partials/` paths, template filenames, ADR numbers, file paths, intra-doc anchor links. Does the target exist, and is it the thing the prose thinks it is? This produced the two highest-blast-radius pass-one findings.
2. **Diff sibling skills against each other.** Within `python-*`, within `r-*`, within `pr-*`, within the backlog/epic/triage family: where two skills speak to the same topic, do they agree? Pass one caught three duplication-drift pairs; there are 58 skills and it checked a handful.
3. **Execute every runnable example in your head.** Would this actually run today, against the version it pins? Pass one found an API that does not exist (`pa.polars.Timestamp`). Assume there are more.
4. **Check every external claim against upstream.** Version pins, deprecated standards, API names, tool flags, action versions. Anything with a date attached is a candidate. Verify against current upstream docs, not against pass one's 2026-07-29 snapshot — which has itself aged.
5. **Check protocol counterparts.** When a skill declares a gate, a contract, or a handoff, open the skill on the *other* end and confirm it implements its side. Orchestrators and their gates; auto-file callers and ADR-0004; retrospective skills and the templates they claim to write.
6. **Check declared state against live state.** Skills that apply labels, expect templates, or assume branch protection — verify against the actual repo via `gh`. This is how #21 was found.
7. **Look for what is absent.** A skill with no failure path. An orchestrator that never says what happens when a gate fails. A `when_to_use` with no "not for" clause. A documented operation with no corresponding step. Absence is harder to see than error, and pass one was reading for errors.
8. **Check frontmatter conformance across all 58 at once.** Field presence, naming, model assignment, description shape. Systematic sweeps catch what per-file reading misses.

## Coverage record — the part pass one failed

**Record every file you examine, including files you read and found clean.** This is not optional bookkeeping; it is the deliverable that makes pass 2's number interpretable. Pass one's single biggest failure was producing findings without producing a reading list, which is why 39 skills are now in an "unknown, possibly unread" limbo that nobody can resolve.

Produce a coverage table: every skill, marked examined-clean / examined-with-findings / not-examined-and-why. Deliver it as a comment on #25 for backfill into the ledger.

If you run out of budget before covering everything, that is fine and expected — **record where you stopped**. A documented partial sweep is worth far more than an undocumented full one.

## Output contract

For each genuine new finding, file via `backlog` auto-file mode:

- **Labels:** `audit-finding` + a priority label (`priority/high` or `priority/medium`; note `priority/low` does not exist in this repo yet — that is known finding #21)
- **Body:** problem statement, expected behavior, reproduction (the exact `grep`/command or file:line), consequence for a consuming repo
- **Classify** into the ledger's [defect taxonomy](2026-07-29-full-repo-audit.md#defect-taxonomy) — and if a finding genuinely does not fit the five classes, **name a sixth rather than forcing it**. A new defect shape is itself a finding about the audit procedure.
- **Fingerprint marker**, last line of the body, non-negotiable:
  ```
  <!-- audit-finding: adversarial-review-2026-08-01:<your-slug> -->
  ```
- **Do not** add findings to Epic B (#16) as sub-issues yourself. File them standalone; epic assignment is a triage decision made after the yield is known.

### Report three numbers, not one

1. **Known / scope-corrections** — already-filed defects encountered
2. **New, in previously-covered ground** (the 19 cited skills) — the inter-rater signal
3. **New, in first-coverage ground** (the 39 uncited skills) — real backlog, but not evidence about defect rate

Plus: the coverage table, and any defects in *this brief* or in the audit procedure it describes.

## Stopping rule

Stop when scope is covered, or when budget runs out — whichever first. Do not stop early because the count feels high. **A large yield is a successful pass, not a failed repo**: this is a pre-fix baseline, and every finding here is one a consuming repo would otherwise have hit silently. Under-reporting to keep Epic B small is the one outcome that makes this pass worthless.

## Related

- Ledger — [2026-07-29-full-repo-audit.md](2026-07-29-full-repo-audit.md)
- Objective [O1 — dev-kit's shipped guidance is trustworthy](../OBJECTIVES.md)
- Epic B — [#16](https://github.com/chris-prener/dev-kit/issues/16)
