---
name: post-merge
description: >
  Mid-session pivot ceremony invoked after the user manually merges a PR
  on github.com. Detects the merged feature branch and its base, refuses
  to switch with a dirty worktree, resets to the base with a fresh pull,
  optionally cleans up the now-orphaned local feature branch, and prompts
  for one of three exits: continue with new work, invoke `backlog`, or
  close the session. Trust model: the user asserts the PR is merged; this
  skill does NOT call `gh pr view` to verify.
when_to_use: >
  Use right after the user says a PR they had open just got merged on
  github.com ("PR merged", "PR is done", "merge complete", "reset
  branches", "PR landed"). Not for a PR that isn't merged yet
  (`pr-orchestrator`), for closing a session with no recent merge (just
  close), or for mid-implementation context refresh (`implementation-plan`'s
  Read operation, or the issue's `## Implementation plan` comment
  directly).
model: haiku
allowed-tools: Bash(git *), Bash(gh *)
# persona: developer   — grouping metadata only; not read by Claude Code.
---

# Post-Merge

You are running the mid-session pivot ceremony after the user has manually merged a PR on github.com. This skill is a thin orchestrator: it puts the local checkout back on the base branch in a clean state, then surfaces a structured choice for what comes next. It deliberately does not duplicate logic from `backlog` or `session-start` — those skills own their own ceremonies and this one delegates to them at the exit prompt.

## Activation

Activate when the user signals that a PR they had open has just been merged on github.com. Trigger phrases include "PR merged", "PR is done", "merge complete", "reset branches", "PR landed".

**Trust model.** The user asserts merge. This skill does **not** call `gh pr view` to verify merge state. If the user invokes the skill, it proceeds.

**When NOT to use:**
- The PR is not yet merged — invoke `pr-orchestrator` instead.
- Closing the session without a recent merge — there's no branch to reset; just close.
- Mid-implementation context refresh — use `implementation-plan`'s Read operation, or read the issue's `## Implementation plan` comment directly.

## Inputs

None from the user. Two values are auto-detected:

- `current_branch` — `git rev-parse --abbrev-ref HEAD`.
- `base_branch` — derived from the most recent merged PR whose head is the current branch:

  ```bash
  base_branch=$(gh pr list --state merged --head "$current_branch" \
    --json baseRefName --limit 1 \
    --jq 'if length == 0 then empty else .[0].baseRefName end' 2>/tmp/post_merge_gh.err)
  rc=$?
  ```

  Three outcomes:

  - **`rc == 0` and non-empty value** → use it.
  - **`rc == 0` and empty value** → no merged PR found for this head. Prompt: `"No merged PR found with head '<current_branch>'. What branch should we reset to? [main]"` — default `main`.
  - **`rc != 0`** → `gh` itself failed (auth, network, missing CLI). Surface the contents of `/tmp/post_merge_gh.err` verbatim, then prompt: `"gh lookup failed (see error above). What branch should we reset to? [main]"` — default `main`. Do **not** silently collapse this into the no-result path.

## Steps

### A. Detect

Print:

```
post-merge:
  current branch: <current_branch>
  merging into:   <base_branch>
```

If `current_branch == base_branch`, note: `"Already on base branch; will skip the checkout in step C but still run the pull."` Continue to step B (the worktree must still be clean for the upcoming `git pull --ff-only`).

### B. Dirty-worktree guard

```bash
git status --porcelain
```

If output is non-empty, **refuse to switch**. Print the dirty paths and prompt:

```
Working tree has uncommitted changes:
  <paths>

Choose:
  s) stash (git stash push -u -m "post_merge auto-stash <timestamp>")
  a) abort the post-merge ceremony
```

- `s` → run the stash, surface the stash ref (`git stash list --max-count 1`), then continue.
- `a` (or any non-`s` answer) → abort. Do not proceed to step C.

**Never silently stash.** Never proceed with a dirty tree.

### C. Confirm reset, then sync to base

Prompt: `"Reset to <base_branch> (fast-forward only)? [Y/n]"` — default Yes.

On confirm:

```bash
if [ "$current_branch" != "$base_branch" ]; then
  git checkout "$base_branch"
fi

git fetch origin "$base_branch"
git pull --ff-only origin "$base_branch"
```

`--ff-only` is deliberate: this skill resets the local checkout to match `origin/<base_branch>`. If the local branch has diverged from origin, `--ff-only` will refuse and surface the divergence. Stop and surface the error verbatim; do not continue to step D, and do not attempt a merge or rebase on the user's behalf.

If `git fetch` or the checkout fails, surface the error verbatim and stop.

### D. Local feature branch cleanup

Skip this step if step A determined `current_branch == base_branch` (there is no orphaned feature branch to clean).

Otherwise check whether the local feature branch still exists:

```bash
git rev-parse --verify --quiet <feature_branch> >/dev/null 2>&1
```

If yes, prompt: `"Delete local branch \`<feature_branch>\`? [Y/n]"` — default Yes.

On confirm, attempt the **safe** delete first:

```bash
git branch -d <feature_branch>
```

If `-d` refuses (unmerged), surface the refusal and prompt explicitly:

```
git refused to delete `<feature_branch>` because it has commits not merged into <base_branch>.
This usually means the PR was squash-merged or rebased on github.com.
Force-delete with `git branch -D`? [y/N]
```

Default No. Force-delete **only** on explicit `y`. Never auto-`-D`.

### E. Three-way exit prompt

Print:

```
Reset complete. What's next?

  1) Pick up the next block of work (describe it inline)
  2) Invoke backlog to identify the next task
  3) Close the session
     (next session: invoke session-start to re-orient)
```

Wait for the user's choice. Do **not** default silently — surface the prompt and let the user lead.

- **1** → Continue the conversation; the user describes the work. The skill exits.
- **2** → Invoke `backlog`.
- **3** → Acknowledge session close. Do not perform any further steps. Suggest invoking `session-start` at the start of the next session.

If the user gives no signal at all, re-print the three options once. Do not pick on their behalf.

## Outputs

- Local checkout sitting on `<base_branch>` at the latest pulled commit.
- Optionally, the local feature branch deleted.
- A captured user choice for the next step (continue / backlog / close).
- No file writes. No GitHub-side mutations.

## Success criteria

- Local checkout is on `<base_branch>` with `git status` clean and `git rev-parse HEAD` matching `origin/<base_branch>`.
- No silent stashes, no force-deletes without explicit opt-in.
- The user has explicitly chosen one of the three exits (or the skill aborted at step B).
- The skill never called `gh pr view` to verify merge state — trust model preserved.

## Out of scope

- **Verifying the PR is actually merged on GitHub.** The user asserts this; the skill takes them at their word.
- **Backlog logic.** Option 2 of the exit prompt delegates entirely to `backlog`; this skill does not duplicate any prioritization or filing logic.
- **Force-deleting unmerged local branches without explicit opt-in.** Default-safe always.

## Cross-references

- `pr-orchestrator` — the skill whose merge this skill follows.
- `backlog` — delegated to in option 2 of the exit prompt.
- `session-start` — suggested invocation at the start of the next session (option 3).
