#!/usr/bin/env bash
# Tests for the implementation-plan enforcement hooks (.claude/hooks/) and the
# shared locator (dev-kit/skills/implementation-plan/scripts/plan-status.sh).
# No network: hook tests swap the locator for a fixture via PLAN_STATUS_SCRIPT;
# locator tests put a stub `gh` on PATH (they need `jq`, and skip without it).
# Run:  bash tests/plan-hooks/run.sh
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
PICKUP="$ROOT/.claude/hooks/plan-pickup.py"
GUARD="$ROOT/.claude/hooks/plan-commit-guard.py"
LOCATOR="$ROOT/dev-kit/skills/implementation-plan/scripts/plan-status.sh"
pass=0; fail=0

# Fixture locator: #1 no plan, #2 drafting, #3 in-progress, #4 epic, #5 duplicate,
# #6 PR, anything else (e.g. #9) simulates a gh failure.
cat > "$TMP/locator" <<'LOC'
#!/usr/bin/env bash
case "$1" in
  1) echo "issue none";; 2) echo "issue drafting";; 3) echo "issue in-progress";;
  4) echo "epic none";; 5) echo "issue duplicate";; 6) echo "pr none";;
  *) echo "gh failed: offline" >&2; exit 2;;
esac
LOC
chmod +x "$TMP/locator"
export PLAN_STATUS_SCRIPT="$TMP/locator"

# check NAME OUTPUT NEEDLE   (NEEDLE '' means OUTPUT must be empty)
check() {
  local name="$1" out="$2" needle="$3"
  if [ -z "$needle" ]; then
    [ -z "$out" ] && { pass=$((pass+1)); return; }
  elif printf '%s' "$out" | grep -qF -- "$needle"; then pass=$((pass+1)); return; fi
  fail=$((fail+1)); echo "FAIL: $name"; echo "  needle: '$needle'"; echo "  got: $out"
}
jstr() { python3 -c 'import json,sys;print(json.dumps(sys.argv[1]))' "$1"; }
prompt() { printf '{"prompt":%s,"cwd":"%s"}' "$(jstr "$1")" "$ROOT" | python3 "$PICKUP"; }
commit() { printf '{"tool_name":"Bash","cwd":"%s","tool_input":{"command":%s}}' "$ROOT" "$(jstr "$1")" | python3 "$GUARD"; }

# --- pickup nudge
check "pickup: no plan nudges"          "$(prompt 'pick up #1')"          'no `## Implementation plan`'
check "pickup: drafting nudges"         "$(prompt 'work on #2 please')"   'still `drafting`'
check "pickup: in-progress is silent"   "$(prompt 'start #3')"            ''
check "pickup: no verb is silent"       "$(prompt 'what is #1 about?')"   ''
check "pickup: epic is silent"          "$(prompt 'pick up #4')"          ''
check "pickup: PR is silent"            "$(prompt 'work on #6')"          ''
check "pickup: gh failure warns open"   "$(prompt 'pick up #9')"          'failed open'
check "pickup: gh failure no context"   "$(prompt 'pick up #9' | grep -c additionalContext)" '0'

# --- commit guard: blocking
check "commit: Closes no plan blocks"   "$(commit 'git commit -m "feat: x

Closes #1"')"                                                              '"permissionDecision": "deny"'
check "commit: names issue and fix"     "$(commit 'git commit -m "Refs #1"')" 'Run `implementation-plan` Create'
check "commit: drafting blocks"         "$(commit 'git commit -m "Fixes #2"')" 'still `drafting`'
check "commit: duplicate blocks"        "$(commit 'git commit -m "Resolves #5"')" 'duplicate plan comments'
check "commit: list blocks on any"      "$(commit 'git commit -m "Closes #3, #1"')" 'deny'
check "commit: chained add+commit"      "$(commit 'git add -A && git commit -m "Closes #1"')" 'deny'
check "commit: -C flag form"            "$(commit 'git -C /x commit -m "Closes #1"')" 'deny'
check "commit: -F - heredoc message"    "$(commit "git commit -F - <<'EOF'
feat: x

Closes #1
EOF")"                                                                     'deny'
check "commit: \$(cat <<EOF) message"   "$(commit "git commit -m \"\$(cat <<'EOF'
feat: x

Closes #1
EOF
)\"")"                                                                     'deny'
echo 'Closes #1' > "$TMP/msg.txt"
check "commit: -F file refs read"       "$(commit "git commit -F $TMP/msg.txt")" 'deny'

# --- commit guard: passing
check "commit: in-progress passes"      "$(commit 'git commit -m "Closes #3"')" ''
check "commit: no refs passes"          "$(commit 'git commit -m "chore: tidy"')" ''
check "commit: bare mention passes"     "$(commit 'git commit -m "see parent #1 for context"')" ''
check "commit: epic ref passes"         "$(commit 'git commit -m "Refs #4"')" ''
check "commit: PR ref passes"           "$(commit 'git commit -m "Refs #6"')" ''
check "commit: non-commit passes"       "$(commit 'git log --grep="Closes #1"')" ''
check "commit: echoed text passes"      "$(commit 'echo "git commit -m Closes #1"')" ''
check "commit: heredoc being written passes" "$(commit "cat > notes.md <<'EOF'
run: git commit -m 'Closes #1'
EOF")"                                                                     ''
check "commit: non-Bash tool ignored"   "$(printf '{"tool_name":"Edit","tool_input":{}}' | python3 "$GUARD")" ''

# --- commit guard: bypass and fail-open
check "commit: bypass in command"       "$(commit 'DEVKIT_SKIP_PLAN_CHECK=1 git commit -m "Refs #1"')" ''
check "commit: bypass in env"           "$(DEVKIT_SKIP_PLAN_CHECK=1 commit 'git commit -m "Refs #1"')" ''
check "commit: bypass named in message" "$(commit 'git commit -m "Refs #1"')" 'DEVKIT_SKIP_PLAN_CHECK=1'
check "commit: gh failure fails open"   "$(commit 'git commit -m "Closes #9"')" 'failed open'
check "commit: gh failure no deny"      "$(commit 'git commit -m "Closes #9"' | grep -c deny)" '0'

# --- locator (stub gh runs the real jq program through system jq)
if command -v jq >/dev/null 2>&1; then
  mkdir -p "$TMP/bin"
  cat > "$TMP/bin/gh" <<'GH'
#!/usr/bin/env bash
# stub: `gh issue view N --json ... [--repo R] --jq PROGRAM` over $FIXTURE
[ "${FIXTURE:-}" = "fail" ] && { echo "HTTP 403: rate limit" >&2; exit 1; }
while [ $# -gt 0 ]; do [ "$1" = "--jq" ] && { shift; prog="$1"; }; shift; done
jq -r "$prog" < "$FIXTURE"
GH
  chmod +x "$TMP/bin/gh"
  unset PLAN_STATUS_SCRIPT
  PLAN=$'<!-- implementation-plan-v1 -->\n\n## Implementation plan\n\n_Last updated: 2026-01-01T00:00:00Z_\n_Status: in-progress_\n\n### Approach\n\nx'
  loc() { FIXTURE="$1" PATH="$TMP/bin:$PATH" "$LOCATOR" 7 2>&1; }
  U='"url":"https://github.com/o/r/issues/7"'
  echo "{$U,\"labels\":[],\"comments\":[{\"body\":$(jstr "$PLAN")}]}" > "$TMP/one.json"
  echo "{$U,\"labels\":[],\"comments\":[{\"body\":\"hi\"}]}" > "$TMP/none.json"
  echo "{$U,\"labels\":[],\"comments\":[{\"body\":$(jstr "$PLAN")},{\"body\":$(jstr "$PLAN")}]}" > "$TMP/dup.json"
  echo "{$U,\"labels\":[{\"name\":\"epic\"}],\"comments\":[]}" > "$TMP/epic.json"
  echo "{$U,\"labels\":[{\"name\":\"sprint\"}],\"comments\":[]}" > "$TMP/sprint.json"
  echo '{"url":"https://github.com/o/r/pull/7","labels":[],"comments":[]}' > "$TMP/pr.json"
  # A comment that merely quotes the marker later in its body is not a plan.
  echo "{$U,\"labels\":[],\"comments\":[{\"body\":\"see\\n<!-- implementation-plan-v1 -->\\n## Implementation plan\"}]}" > "$TMP/quote.json"
  check "locator: one plan -> status"    "$(loc "$TMP/one.json")"    'issue in-progress'
  check "locator: no plan"               "$(loc "$TMP/none.json")"   'issue none'
  check "locator: duplicate"             "$(loc "$TMP/dup.json")"    'issue duplicate'
  check "locator: epic kind"             "$(loc "$TMP/epic.json")"   'epic none'
  check "locator: sprint kind"           "$(loc "$TMP/sprint.json")" 'sprint none'
  check "locator: pr kind"               "$(loc "$TMP/pr.json")"     'pr none'
  check "locator: quoted marker ignored" "$(loc "$TMP/quote.json")"  'issue none'
  FIXTURE=fail PATH="$TMP/bin:$PATH" "$LOCATOR" 7 >/dev/null 2>&1; check "locator: gh failure exits 2" "$?" '2'
  "$LOCATOR" abc >/dev/null 2>&1; check "locator: bad arg exits 2" "$?" '2'
else
  echo "SKIP: jq not found; locator tests not run"
fi

echo "passed: $pass  failed: $fail"
[ "$fail" -eq 0 ]
