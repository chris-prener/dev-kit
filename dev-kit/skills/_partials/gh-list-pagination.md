# gh list pagination (shared partial)

`gh issue list` and `gh pr list` default to **30 results** and truncate silently — no error, no warning, just a short list that looks complete. Every call site needs one of the two patterns below; never call either command bare with no `--limit` and no `--paginate`.

## Rule

1. **Completeness matters** (a count fed to a human or a report; a coverage/audit claim that something covers *everything* since a cutoff) → use `gh api`, not `gh issue list` / `gh pr list`.

   - **For a count**, prefer the `search/issues` endpoint's `total_count` field over paginating and counting rows yourself: it reports the true total on a single call, regardless of how many pages the matching set would span. `is:issue` excludes pull requests — the plain `repos/{owner}/{repo}/issues` endpoint returns PRs too and will overcount a label count if any PR carries it.

     ```bash
     # Count — e.g. "how many needs-triage issues are open"
     gh api "search/issues?q=repo:{owner}/{repo}+is:issue+is:open+label:needs-triage" \
       --jq '.total_count'
     ```

   - **For a full row-level listing** where nothing but `total_count` will do, use `gh api --paginate`, which follows every page (a bare list command does not, regardless of `--limit`). `--jq` runs once *per page* under `--paginate`, not once over the merged result — never use `--jq 'length'` here, since that reports only the last page's count. Filter and stream fields (`.items[] | {...}`) and let the caller consume the full stream instead.

     ```bash
     # Coverage query — e.g. "every PR merged since <date>, no gaps"
     gh api --paginate \
       "search/issues?q=repo:{owner}/{repo}+is:pr+is:merged+merged:>=${SINCE}" \
       --jq '.items[] | {number, title, url}'
     ```

2. **Completeness doesn't matter** (a top-N surface for a human to skim, a dedup probe expected to return 0–1 rows) → bare `gh issue list` / `gh pr list` is fine, but it must always carry an explicit `--limit` sized to the domain. Never omit `--limit` on the assumption the result set is small — that assumption is exactly what silently breaks when a repo grows.

   ```bash
   gh issue list --repo "$REPO" --state open --label needs-grooming \
     --json number,title,labels --limit 50
   ```

## What NOT to do

Do not reach for `--limit 1000` as a way to dodge the decision — pick the pattern that matches whether completeness is actually load-bearing here, and size `--limit` to the domain (10–100 is typical; go higher only when the domain is known to run large, e.g. a full-repo dedup read).

## Provenance

`showcase` names this rule explicitly (its merged-PR and closed-epic corpus queries are completeness-critical). Every other skill issuing `gh issue list` / `gh pr list` follows this same partial rather than restating the rule locally.
