---
name: code-review
description: >
  Runs a rubber-duck-style AI code review pass against a diff (PR-bound
  or local) via an independent subagent, and produces a structured
  findings report. Invoked as the mandatory pre-PR gate by
  `pr-orchestrator`'s code-review gate; can also be invoked ad hoc as
  `self-review` before pushing.
when_to_use: >
  Use for "review the diff", "rubber-duck this", "AI review my changes",
  "self-review before push" — or let `pr-orchestrator`'s code-review
  gate invoke it automatically. Not for merging PRs (that's github.com's
  job) or style / formatting findings (lint's job).
model: opus
allowed-tools: Bash(gh *), Bash(git *)
# persona: developer   — grouping metadata only; not read by Claude Code.
---

# Code Review

You are about to run an AI code review pass on a diff. In a solo+AI workflow there is no human PR reviewer in the default loop — this skill standardizes the rubber-duck invocation that closes that gap.

The skill is **stateless and read-only**: it reads the diff + repo context, posts findings to its report file (and optionally as auto-filed issues for non-trivial findings), and returns an exit signal. It does not commit, push, merge, label, or otherwise mutate GitHub state on its own — those are the caller's responsibility.

## Activation

Activate when:
- Invoked by `pr-orchestrator`'s code-review gate as the pre-PR gate. Mode: `review`.
- The user says "review the diff", "rubber-duck this", "AI review my changes", "self-review before push". Mode: `self-review`.
- Re-running on a branch with prior findings — same `review` mode; dedup is automatic via auto-file markers.

**Prior in-flight critique does NOT exempt gate mode.** The proactive rubber-duck-style critique an agent naturally does while implementing reviews intermediate states through its own lens; this gate reviews the *final shipped diff* against acceptance criteria and repo invariants under adversarial framing, from a subagent with no stake in the implementation. Even on the same SHA, the gate catches things self-critique tends to miss. The only path to CLEAN without a gate call is the `--minimal` whitelist short-circuit — there is no "I already reviewed this" override.

Merging is out of scope — that happens on github.com, where branch-protection / required-checks are the right enforcement layer. This skill secures the pre-PR-creation moment, where the local agent has the most leverage.

## Inputs

- **Required**: a diff to review. Resolved by mode:
  - `review` (default, called by `pr-orchestrator`'s code-review gate): `<base>..HEAD` for the current branch — caller passes base + head; the skill computes the unified diff via `git diff <base>...HEAD`.
  - `self-review`: same, OR includes uncommitted changes if the user explicitly opts in (`git diff` plus `git diff --cached`).
- **Required**: at least one issue reference for context. The skill reads the issue body via `gh issue view <n>` to extract acceptance criteria. PRs that don't close an issue are still reviewable, but review depth is reduced (no AC traceability).
- **Optional context (graceful when absent)**:
  - An `implementation-plan` comment on the issue, if one exists.
  - Recent ADRs: files under `docs/adr/` modified in the last ~30 commits, or ADRs cross-referenced from the issue body.
  - A glossary, if `docs/GLOSSARY.md` exists.
- **Required for gate mode (`--mode=gate`)**: a writable `.github/audit-reports/` directory (gitignored).

## Steps

### Operation 1 — `review` (default; pre-PR gate)

1. **Pre-flight.**
   - Confirm the diff is non-empty. If empty, return CLEAN immediately.
   - Compute the touched-file list. Apply the **`--minimal` whitelist** (see "Minimal mode" below) to decide whether to short-circuit to a quick pass; require explicit operator confirmation before bypassing full review. `--minimal` is the only sanctioned path to a CLEAN gate result without a review call; a prior `self-review` on the same SHA is informational only and does NOT short-circuit gate mode.
2. **Gather context.**
   - Diff: `git diff <base>...HEAD` (full unified diff).
   - Issue AC: `gh issue view <n> --json body` for each `Closes #N` reference, extract the `## Acceptance criteria` checklist.
   - Plan comment (best-effort): `gh issue view <n> --comments`, search for the `implementation-plan` locator marker. When present, include `### Approach`, `### Verification`, and `### Decisions made` in the review context (`Where I left off` is for human handoff, not review). Silently absent on issues with no plan.
   - Recent ADRs: `git log --since="30 days ago" --name-only -- 'docs/adr/*.md'`.
   - Repo invariants: read whatever this repo documents as non-negotiable (e.g. an acceptance-criteria section in a requirements doc, or a "must not do" list in `CLAUDE.md`), once.
3. **Invoke an independent subagent.** Use the Agent tool to spawn a fresh, general-purpose subagent with no context from this session, passing the templated prompt below verbatim (substituting the bracketed values). The subagent's independence — no shared context, no stake in the implementation — is the whole point; do not paraphrase the prompt or skip this step.
4. **Parse findings.** Categorize each finding by severity:
   - **BLOCKER** — bug, logic error, missed edge case that would corrupt data or break a stated invariant.
   - **HIGH** — design flaw, missing test for a non-trivial change, ADR-worthy decision made silently, security smell.
   - **MEDIUM** — missing test for a trivial change, doc-staleness in a touched file, naming inconsistency that masks correctness.
   - **NIT/QUESTION** — informational only, filed nowhere. Style and formatting findings are **forbidden** at this severity — use lint, not review.
5. **Write the report.** At `.github/audit-reports/code-review_<timestamp>.md` (gitignored). Structure: [`reference.md`](${CLAUDE_SKILL_DIR}/reference.md).
6. **Auto-file non-trivial findings.** For each BLOCKER/HIGH/MEDIUM finding, invoke `backlog` auto-file mode with the contract in [`reference.md`](${CLAUDE_SKILL_DIR}/reference.md).
7. **Set the exit signal.**
   - `0` — CLEAN, no BLOCKER/HIGH findings (MEDIUM may still be auto-filed but doesn't block).
   - `1` — FINDINGS (HIGH/MEDIUM only; advisory, caller continues).
   - `2` — BLOCKER (any BLOCKER finding; PR-prep callers refuse to proceed).

### Operation 2 — `self-review` (ad hoc, pre-push)

Same as `review` but:
- May include uncommitted changes if the user opts in.
- Mode is `self-review`, not `gate`. Findings still auto-file, but the exit signal is informational only.
- Report goes to the same `.github/audit-reports/` location.

## Minimal mode (whitelist)

Switch to `--minimal` mode if **all** hold:

- `git diff --shortstat <base>...HEAD` reports ≤ 20 lines changed.
- Touched files are **only** in this whitelist: `CHANGELOG.md`, `README.md`, top-level `docs/*.md` excluding `docs/adr/` and requirements docs.
- Operator explicitly confirms (the skill prompts; default is full review).

Anything touching source code, config, CI, or skill/workflow files always gets full review — the whitelist is intentionally narrow, since governance and code paths are exactly where review matters most.

In `--minimal` mode, skip steps 3–4 of `review` (no subagent call), write a one-paragraph "minimal pass" entry to the report, and return `0` (CLEAN).

## Rubber-duck prompt template

Invoke the subagent with this fixed prompt structure:

```
You are reviewing a diff for a PR in <repo>. Branch: <branch>. Head SHA: <sha>.

# Diff (<files-changed> files, <lines-added> additions, <lines-removed> deletions)
<unified diff>

# Issue acceptance criteria
<for each Closes #N: title + AC list extracted from issue body>

# Implementation plan (if present)
<plan comment body, or "None on file.">

# Relevant ADRs (recent or cross-referenced)
<list of file paths + 1-line summaries>

# Repo invariants (must not violate)
<whatever this repo documents as non-negotiable, or "None documented.">

# Prior findings on this PR (re-review only)
<from previous report file, if exists; otherwise "First review on this branch.">

# What I want from you

1. Identify bugs, logic errors, missing edge cases, race conditions, error-handling gaps.
2. Identify design flaws — code that works but will create maintenance pain or violate the repo's stated invariants.
3. Identify security concerns — credential leaks, injection vectors, unsafe shell quoting, untrusted-input handling.
4. Identify missing tests for non-trivial changes (branching logic, error paths). Do NOT flag missing tests for pure refactors or doc-only changes.
5. Identify ADR-worthy decisions made silently — architectural shifts that should have an entry in docs/adr/.
6. Categorize each finding as BLOCKER / HIGH / MEDIUM / NIT or QUESTION.
7. Cite file:line for every finding. Findings without code anchors are NIT-only.
8. Forbidden: style, formatting, naming-aesthetics, comment-density. Lint covers those. Only flag naming if it actively masks correctness.

Return findings in this exact format (one block per finding):

## <SEVERITY>: <one-line finding title>
**File:** `path/to/file:LN`  (or "(no anchor)" for design-level findings)
**Why:** <2-3 sentences>
**Suggested fix:** <1-3 sentences, or "Defer for design discussion.">

End with a single-line verdict: `VERDICT: CLEAN` | `VERDICT: ADVISORY` | `VERDICT: BLOCKED`.
```

## Reference

Review comment structure, the auto-file contract, outputs, success criteria, the check-ID inventory, and cross-references: [`reference.md`](${CLAUDE_SKILL_DIR}/reference.md)
