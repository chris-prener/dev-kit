#!/usr/bin/env bash
# plan-status.sh — locate an issue's `## Implementation plan` comment and print its Status.
#
# This is the executable form of `implementation-plan`'s Phase 0 (Locate): a plan
# match is a comment whose first non-blank line is exactly
# `<!-- implementation-plan-v1 -->` and whose next non-blank line is exactly
# `## Implementation plan`. Callers that need only a lookup (the enforcement
# hooks under .claude/hooks/) run this instead of re-implementing the match.
#
# Usage:  plan-status.sh <issue-number> [owner/repo]
# Output: one line, "<kind> <status>"
#           kind   = issue | epic | sprint | pr
#           status = none | duplicate | unknown | drafting | in-progress |
#                    blocked | ready-for-pr | shipped
# Exit:   0 on success; 2 if `gh` fails (offline, rate-limited, bad auth) or
#         the arguments are invalid. Callers decide whether to fail open.
set -u

N="${1:-}"
REPO="${2:-}"
if ! [[ "$N" =~ ^[0-9]+$ ]]; then
  echo "usage: plan-status.sh <issue-number> [owner/repo]" >&2
  exit 2
fi

args=(issue view "$N" --json comments,labels,url)
[ -n "$REPO" ] && args+=(--repo "$REPO")

# The jq program runs inside gh (--jq), so no standalone jq dependency.
JQ='
  def trim: gsub("\\s+$"; "");
  ( if (.url | test("/pull/")) then "pr"
    elif ([.labels[].name] | index("epic")) then "epic"
    elif ([.labels[].name] | index("sprint")) then "sprint"
    else "issue" end ) as $kind
  | [ .comments[]
      | select(
          (.body | split("\n") | map(trim) | map(select(length > 0)) | .[0:2])
          == ["<!-- implementation-plan-v1 -->", "## Implementation plan"]) ] as $plans
  | ( if   ($plans | length) == 0 then "none"
      elif ($plans | length) >  1 then "duplicate"
      else ( $plans[0].body
             | capture("(^|\n)_Status: (?<s>[a-z-]+)_")
             | .s ) // "unknown" end ) as $status
  | "\($kind) \($status)"
'

if ! out=$(gh "${args[@]}" --jq "$JQ" 2>&1); then
  echo "gh failed: $out" >&2
  exit 2
fi
echo "$out"
