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

#### Step 0: Resolve the default branch

Never assume `main`:

```bash
default_branch=$(gh api repos/{owner}/{repo} --jq '.default_branch')
```

All subsequent steps use `$default_branch`, not a literal `main`.

#### Step 1: Fetch branch protection

```bash
protection_raw=$(gh api "repos/{owner}/{repo}/branches/${default_branch}/protection" \
  --jq '{
    signed_commits: .required_signatures.enabled,
    force_push_blocked: (.allow_force_pushes.enabled | not),
    deletions_blocked: (.allow_deletions.enabled | not),
    enforce_admins: .enforce_admins.enabled,
    required_checks: [.required_status_checks.checks[]?.context // empty]
  }' 2>&1)
status=$?
```

`gh api` exits non-zero on any non-2xx response and puts the API's error message on stderr (captured above via `2>&1`), so branch on it rather than treating every failure the same way:

- **`status == 0`** → parse `protection_raw` as JSON; proceed to Step 3 with real values.
- **`status != 0` and `protection_raw` contains `HTTP 404`** → no protection configured at all. This is the normal starting state for a fresh personal repo, not a bug — report every protection check as FAIL.
- **`status != 0` and `protection_raw` contains `HTTP 403`** → branch protection is **unavailable on this plan**, not merely unconfigured. This is the live response for a private repo on GitHub's free tier (the API returns *"Upgrade to GitHub Pro or make this repository public to enable this feature."*). Do not conflate this with the 404 case — report it as a distinct **UNAVAILABLE** outcome (Step 3), not FAIL, since there is nothing the user can configure without first changing plan or visibility.
- **`status != 0` and neither substring matches** → an unexpected error (auth, rate limit, network). Surface `protection_raw` verbatim to the user and halt the audit rather than silently reporting FAIL or UNAVAILABLE — a misreported outcome here is worse than an explicit error.

#### Step 2: Check CI workflow exists

```bash
gh api repos/{owner}/{repo}/actions/workflows --jq '.workflows[] | {name, state, path}'
```

PASS if at least one workflow exists and is `active`.

#### Step 3: Print audit report

Normal case (protection reachable, whether configured or not):

```
## Enforcement audit — <owner>/<repo> (default branch: <default_branch>)

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

403/plan-unavailable case — replace the table and verdict with:

```
## Enforcement audit — <owner>/<repo> (default branch: <default_branch>)

⚠️ **UNAVAILABLE** — branch protection is not offered on this repo's current plan (private repo without GitHub Pro/Team/Enterprise). GitHub's own message: "Upgrade to GitHub Pro or make this repository public to enable this feature."

To unblock: make the repo public, or upgrade the account/org plan. Neither is a change this skill makes for you.

| Check | Status | Detail |
|---|---|---|
| CI workflow active | ✅ PASS / ❌ FAIL | <workflow name> |
```

(The CI-workflow check is independent of branch protection and still runs.)

Exit codes: `0` = all PASS (WARN is acceptable), `1` = any FAIL, `2` = UNAVAILABLE (distinguishable from FAIL — nothing to fix by configuring this repo).

None of these settings are assumed to be enforced elsewhere — if `audit` reports FAIL on branch protection basics and the user wants them enabled, that's a manual github.com settings change (or `gh api -X PUT .../protection`) they make deliberately; this skill doesn't write branch-protection rules itself, only reports on them.

### Operation 2: `configure-checks`

Wires a CI workflow job as a required status check on the repo's default branch. This is the only write operation.

#### Step 1: Pre-flight

1. Resolve the default branch — never assume `main` (same as audit Step 0):
   ```bash
   default_branch=$(gh api repos/{owner}/{repo} --jq '.default_branch')
   ```

2. Confirm the target workflow has run at least once on `$default_branch`:
   ```bash
   gh run list --workflow <workflow-file> --branch "$default_branch" --limit 1 --json status
   ```
   If no runs found, halt with: "The workflow has not run on $default_branch yet. Push a commit or open a PR to trigger it, then re-run this operation."

3. Confirm branch protection exists on `$default_branch` and distinguish *why* it doesn't, same as audit Step 1:
   ```bash
   protection_raw=$(gh api "repos/{owner}/{repo}/branches/${default_branch}/protection" 2>&1)
   status=$?
   ```
   - `status == 0` → protection exists, proceed to Step 2.
   - `status != 0` and `protection_raw` contains `HTTP 403` → halt with: "Branch protection is unavailable on this repo's current plan (private repo without GitHub Pro/Team/Enterprise) — make the repo public or upgrade the plan first. This skill doesn't create branch protection from nothing, and can't on this plan regardless."
   - `status != 0` and `protection_raw` contains `HTTP 404` → halt with: "No branch protection exists yet on $default_branch. This skill doesn't create branch protection from nothing — configure the basics first, then re-run this operation."
   - Any other non-zero status → halt and surface `protection_raw` verbatim; don't guess.

#### Step 2: Wire the check

Fetch existing required checks first to avoid destructively replacing them. Use the `checks` field (current API) throughout — not the deprecated `contexts` array — so read and write agree on one convention:

```bash
existing=$(gh api "repos/{owner}/{repo}/branches/${default_branch}/protection/required_status_checks" \
  --jq '[.checks[]? | {context, app_id}]')

new_checks=$(echo "$existing" | jq --arg new "<workflow-name> / <job-name>" \
  '. + [{context: $new, app_id: null}] | unique_by(.context)')

gh api -X PATCH "repos/{owner}/{repo}/branches/${default_branch}/protection/required_status_checks" \
  --input - <<EOF
{
  "strict": false,
  "checks": $new_checks
}
EOF
```

This preserves any previously configured required checks while adding the new one.

#### Step 3: Verify

Re-run the `required_checks` portion of audit Step 1 (against `$default_branch`) to confirm the check appears in the list.

#### Step 4: Report

Print confirmation with the check name and the verification result.

## Outputs

- **`audit`**: a structured enforcement report printed to chat. Exit code 0 (pass), 1 (fail), or 2 (unavailable on this plan).
- **`configure-checks`**: a required status check wired on the repo's default branch.

## Success criteria

- `audit` correctly reports the live enforcement posture without mutations, on any branch-protection-eligible plan.
- `audit` reports a 403 (private repo without GitHub Pro/Team/Enterprise) as a distinct UNAVAILABLE outcome, not as FAIL or a crash.
- `audit` and `configure-checks` both resolve the repo's actual default branch instead of assuming `main`.
- `configure-checks` wires the specified check and verifies it appears in the protection settings.
- `configure-checks` refuses to run if the workflow has never executed on the default branch, or if branch protection doesn't exist yet — and says which of the two (or a 403 plan limit) is the reason.
- The skill works against both the current repo and remote repos via `--repo`.

## Out of scope

- **Creating branch protection from nothing.** This skill audits it and, once it exists, extends its required-checks list — it does not flip branch protection on for a repo that has none.
- **Creating CI workflows.** That's project-specific development work.
- **Any setting outside branch protection and required status checks** (CODEOWNERS, rulesets, org policy) — out of scope for a solo repo.

## Cross-references

- `bootstrap-repo` — provisions dev-kit's canonical files; this skill configures GitHub-side settings, a separate concern.
