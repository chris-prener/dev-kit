# Epic linkage (shared partial)

Every new issue must declare its parent epic, or it must explicitly opt out as standalone. There is no silent default. This partial documents the prompt, the validation, and the post-creation native sub-issue linkage.

## Step 1 — Prompt for the parent epic

The consumer skill prompts:

> Which epic does this belong to? Either paste the parent epic issue number (e.g., `73`) or type `standalone — <reason>`.

## Step 2 — Validate the response

### Epic-linked path

Verify the chosen issue exists, is `OPEN` (or recently closed if the user is intentionally re-opening scope), and carries the `epic` label:

```bash
gh issue view <PARENT> --json state,labels,title -q '{state, labels: (.labels | map(.name)), title}'
```

If the `epic` label is missing, halt with a clear error and offer to either pick a different parent or use the `epic` skill to file a new epic first. Do **not** invent an epic.

### Standalone path

Require an explicit one-line justification (e.g., `standalone — single-line typo fix; no thematic grouping warranted`). Reject empty / placeholder justifications. The justification is appended to the issue body as the literal line `**Parent epic:** standalone — <reason>` so future readers can see why no epic was chosen.

Record the choice; it becomes part of the body in the consumer skill's draft step.

## Step 3 — Link as a sub-issue (epic-linked path only)

After `gh issue create` returns the new issue number, attach it to its parent epic via the GitHub native sub-issue API. This is what makes the `epic-retrospective` skill's gate work and what populates the `## Sub-issues` section under the parent.

```bash
NEW_ISSUE_NUM=<from gh issue create>
PARENT_EPIC=<from Step 2>
REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner')

# IMPORTANT: sub_issue_id must be the issue's database ID, NOT the issue number.
# Passing the issue number returns 404.
CHILD_ID=$(gh api "repos/$REPO/issues/$NEW_ISSUE_NUM" --jq '.id')

gh api -X POST "repos/$REPO/issues/$PARENT_EPIC/sub_issues" \
  -F sub_issue_id=$CHILD_ID
```

**Two critical details:**

1. **Use uppercase `-F`** to send `sub_issue_id` as an integer; lowercase `-f` sends a string and the API returns 422.
2. **Pass the database `id`, not the issue number.** GitHub's REST sub-issues endpoint expects the issue's global database ID (the value of `.id` in `gh api repos/<owner>/<repo>/issues/<number>`), not the human-facing `.number`. Passing the number returns 404 even when both parent and child exist. Surface this distinction in error handling — the 404 is misleading.

If the sub-issue link call fails (network, permissions, parent edited concurrently), surface the error but do **not** roll back issue creation. The issue exists; the linkage is a recoverable follow-up — re-run Step 3 manually with the captured numbers.

For the standalone path, skip Step 3 entirely.
