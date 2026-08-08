---
name: session-start
description: >
  Best-effort orientation skill for the start of a work session. Reads
  durable sources (ROADMAP, OBJECTIVES, ADR index, GitHub issues/PRs)
  and prints a one-screen summary so the agent picks up where the last
  session left off.
when_to_use: >
  Use when a new session begins and the user wants orientation ("where
  are we?", "session start", "orient me"), or the agent is uncertain
  about current state and needs a context refresh. Not for
  single-question sessions (the overhead isn't justified) or
  mid-session refreshes.
model: haiku
allowed-tools: Bash(gh *)
disable-model-invocation: true
# No persona tag — session orientation is useful from any persona
# window, not owned by one role.
---

# Session Start

You are about to bootstrap a work session. The dominant failure mode of agent-driven development is cross-session context loss: settled decisions get re-litigated, in-flight work gets duplicated, and the user has to re-orient the agent verbally each time. This skill is the deterministic remedy — a fast, durable read of "where things stand" before any new work begins.

**Important framing**: this is **best-effort orientation**, not a technical enforcement gate. It activates when the user (or the agent recognizing a trigger phrase) asks for orientation — the discipline is the convention that work sessions begin here, not an automatic hook.

## Inputs

None. The skill reads durable sources only. Optional input: a focus filter (e.g., "just the in-flight epic" — skips broader watchlist queries).

## Steps

### A. Read the persistent-memory layer

1. **ADR index** — `${CLAUDE_PROJECT_DIR}/docs/adr/README.md`, if present. Note any ADRs filed since the previous session (use file mtimes if a previous-session timestamp is available; otherwise just count and list the latest 3).
2. **OBJECTIVES.md active section** — `${CLAUDE_PROJECT_DIR}/docs/OBJECTIVES.md` `## Active`. Surface each active objective and any KR whose progress has stalled (last-check-in age, if recorded).
3. **ROADMAP Now horizon** — `${CLAUDE_PROJECT_DIR}/docs/ROADMAP.md` `## Epics` → `### Now` block. Surface the in-flight epic(s).

### B. Read live GitHub state

Run a small batch of `gh` queries (in parallel where possible). Counts follow `${CLAUDE_SKILL_DIR}/../_partials/gh-list-pagination.md` — a bare `gh issue list ... --jq 'length'` silently caps at 30, so both watchlist counts use `gh api --paginate` instead:

- **Open PRs by current user**: `gh pr list --author @me --state open --json number,title,url,updatedAt --limit 50`.
- **Open issues with `priority/blocker`**: `gh issue list --state open --label priority/blocker --json number,title,url --limit 50`.
- **Open `needs-triage` count**: `gh api --paginate "repos/{owner}/{repo}/issues?state=open&labels=needs-triage" --jq '.[].number' | wc -l`.
- **Open `needs-grooming` count**: `gh api --paginate "repos/{owner}/{repo}/issues?state=open&labels=needs-grooming" --jq '.[].number' | wc -l`.
- **Open `in-progress` issues (in-flight workstreams)**: `gh issue list --state open --label in-progress --json number,title,url,updatedAt --limit 50`.
- **Issues with no labels at all** (a quick DoR smell): `gh issue list --state open --search "no:label" --limit 5 --json number,title`.

Performance budget: under ~30 seconds for the whole sweep. If a query is slow, surface partial results rather than blocking.

### C. Print the orientation summary

Print to chat in this exact structure:

```
## Session orientation — <YYYY-MM-DD HH:MM>

**In flight:**
- Epic #NN: <title> (Now) — N open / M closed sub-issues
- PR #PP: <title> — awaiting <review|merge|action>

**In-flight workstreams** *(only printed when at least one open `in-progress` issue exists)*:
- #NN: <title> — last touched <D> days ago

**Active objectives:**
- O1: <name> — last check-in <D> days ago

**Watchlist:**
- <X> open issues with no labels at all (top 5 listed)
- <T> open `needs-triage` issues (route via `backlog`'s Triage operation)
- <G> open `needs-grooming` issues (curate via `backlog`'s Groom operation)
- <Z> open priority/blocker issues

**Recent ADRs:**
- ADR-NNNN: <title> (filed <D> days ago)

**Next likely action(s):**
(synthesized from the above — 1–3 bullets, never more)
```

### D. (Optional) Surface a hand-off

If the swept state suggests a clear next step, end with:

> Suggested next action: <one-line>. Confirm to proceed, or override.

The agent **does not block**. It surfaces, asks, and waits for the user's lead. If the user types "skip orientation" the skill records the bypass and exits.

## Outputs

- A markdown orientation summary printed to chat (one screen, structured).
- No file writes. No state mutations.

## Success criteria

- The summary covers: in-flight epic, open PRs, active objectives, watchlist (unlabeled issues, `priority/blocker` issues, `needs-triage` count, `needs-grooming` count), recent ADRs, next likely action.
- The sweep completes in under ~30 seconds; partial results are surfaced if any query stalls.
- Quality of the summary is judged by: can the user resume work without verbally re-orienting the agent?

## Out of scope

- Auto-running on session start without explicit invocation — nothing in Claude Code hooks this automatically.
- Heavy drift-detection / coverage audits across the whole backlog — out of scope for this suite; this skill's watchlist is a light touch, not a full sweep.
- Persisting orientation summaries between sessions.
- Auto-claiming the next available todo — agent + user choose collaboratively; the skill surfaces, doesn't decide.
- Blocking the agent until the user acknowledges.

## Cross-references

- `adr` — produces the ADR index this skill reads.
- `requirements` — surfaces draft requirements docs (via the watchlist), when relevant.
- `objectives` — surfaces active objectives + stale check-ins.
- `roadmap` — surfaces the Now horizon.
- `backlog` — DoR violations (no labels, no epic linkage) are surfaced from issue body scans aligned with the skill's contract. Its Triage operation is the destination for `needs-triage` items surfaced in Step B; its Groom operation is the destination for `needs-grooming` items surfaced in Step B.
- `backlog-retrospective` — issues closed without a retro can be spotted by scanning recently-closed issues for a missing `## Retrospective` comment.
- `post-merge` — invoked after a PR merge as a mid-session pivot; its exit path suggests invoking this skill at the start of the next session.
