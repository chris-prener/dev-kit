---
name: github-enforcement
description: >
  Audits and configures the github.com-side enforcement layer for a
  repo: branch protection posture and required status checks. Two
  operations — audit (read the live posture) and configure-checks (wire
  a CI job as a required status check).
when_to_use: >
  Use to check what branch protection is actually configured ("audit
  enforcement", "check enforcement posture") or to wire a CI workflow as
  a required check ("configure checks", "wire required checks"). Not for
  creating CI workflows themselves, or for any setting outside branch
  protection and required checks.
model: opus
allowed-tools: Bash(gh *)
disable-model-invocation: true
# persona: developer   — grouping metadata only; not read by Claude Code.
---

# GitHub Enforcement

Audits or configures the github.com-side enforcement layer for a repo. Unlike an organization-managed repo where branch protection might be enforced automatically, a personal/solo repo has nothing configured unless you configure it yourself — this skill makes that posture visible and, for the one narrow write operation it supports, reproducible.

## Activation

Activate this skill whenever:

- The user wants to verify a repo's actual enforcement posture ("audit enforcement", "check enforcement posture").
- The user wants to wire a CI workflow as a required check ("configure checks", "wire required checks").
- A repo has just been bootstrapped and its enforcement layer hasn't been looked at yet.

## Inputs

- **Required**: the target repository (defaults to the current repo; override with `--repo <owner/repo>`).
- **Required for `configure-checks`**: the CI workflow name and job name to wire.
- **Optional**: `--json` flag for machine-readable output (default: human-readable summary).

## Steps

### Operation 1: `audit`

Checks the repo's live GitHub enforcement posture. Read-only — no mutations.

#### Step 1: Fetch branch protection

```bash
gh api repos/{owner}/{repo}/branches/main/protection \
  --jq '{
    signed_commits: .required_signatures.enabled,
    force_push_blocked: (.allow_force_pushes.enabled | not),
    deletions_blocked: (.allow_deletions.enabled | not),
    enforce_admins: .enforce_admins.enabled,
    required_checks: [.required_status_checks.checks[]?.context // empty]
  }'
```

If the API returns 404 (no protection configured at all), report every check as FAIL — this is the normal starting state for a fresh personal repo, not a bug.

#### Step 2: Check CI workflow exists

```bash
gh api repos/{owner}/{repo}/actions/workflows --jq '.workflows[] | {name, state, path}'
```

PASS if at least one workflow exists and is `active`.

#### Step 3: Print audit report

```
## Enforcement audit — <owner>/<repo>

| Check | Status | Detail |
|---|---|---|
| Signed commits required | ✅ PASS / ❌ FAIL | |
| Force-push blocked | ✅ PASS / ❌ FAIL | |
| Deletions blocked | ✅ PASS / ❌ FAIL | |
| Admin bypass policy | ℹ️ INFO | enforce_admins: true/false |
| CI workflow active | ✅ PASS / ❌ FAIL | <workflow name> |
| Required status checks | ✅ PASS / ⚠️ WARN | <list of contexts> |

**Verdict:** PASS / WARN / FAIL
```

Exit codes: `0` = all PASS (WARN is acceptable), `1` = any FAIL.

None of these settings are assumed to be enforced elsewhere — if `audit` reports FAIL on branch protection basics and the user wants them enabled, that's a manual github.com settings change (or `gh api -X PUT .../protection`) they make deliberately; this skill doesn't write branch-protection rules itself, only reports on them.

### Operation 2: `configure-checks`

Wires a CI workflow job as a required status check on `main`. This is the only write operation.

#### Step 1: Pre-flight

1. Confirm the target workflow has run at least once on `main`:
   ```bash
   gh run list --workflow <workflow-file> --branch main --limit 1 --json status
   ```
   If no runs found, halt with: "The workflow has not run on main yet. Push a commit or open a PR to trigger it, then re-run this operation."

2. Confirm branch protection exists on `main` (the API endpoint must return 200). If not, tell the user required-status-checks can't be configured until basic branch protection exists, and stop — this skill doesn't create branch protection from nothing.

#### Step 2: Wire the check

Fetch existing required checks first to avoid destructively replacing them:

```bash
existing=$(gh api repos/{owner}/{repo}/branches/main/protection/required_status_checks \
  --jq '.contexts')

new_contexts=$(echo "$existing" | jq --arg new "<workflow-name> / <job-name>" \
  '. + [$new] | unique')

gh api -X PATCH repos/{owner}/{repo}/branches/main/protection/required_status_checks \
  --input - <<EOF
{
  "strict": false,
  "contexts": $new_contexts
}
EOF
```

This preserves any previously configured required checks while adding the new one.

#### Step 3: Verify

Re-run the `required_checks` portion of audit Step 1 to confirm the check appears in the list.

#### Step 4: Report

Print confirmation with the check name and the verification result.

## Outputs

- **`audit`**: a structured enforcement report printed to chat. Exit code 0 (pass) or 1 (fail).
- **`configure-checks`**: a required status check wired on `main`.

## Success criteria

- `audit` correctly reports the live enforcement posture without mutations.
- `configure-checks` wires the specified check and verifies it appears in the protection settings.
- `configure-checks` refuses to run if the workflow has never executed on `main`, or if branch protection doesn't exist yet.
- The skill works against both the current repo and remote repos via `--repo`.

## Out of scope

- **Creating branch protection from nothing.** This skill audits it and, once it exists, extends its required-checks list — it does not flip branch protection on for a repo that has none.
- **Creating CI workflows.** That's project-specific development work.
- **Any setting outside branch protection and required status checks** (CODEOWNERS, rulesets, org policy) — out of scope for a solo repo.

## Cross-references

- `bootstrap-repo` — provisions dev-kit's canonical files; this skill configures GitHub-side settings, a separate concern.
