#!/usr/bin/env bash
# Tests for the gate-receipt verifier (pr-orchestrator/scripts/verify-gate-receipts.sh) and the
# PreToolUse hook that uses it (.claude/hooks/pr-gate-guard.py). Offline: runs against a
# throwaway git repo.
# Run:  bash tests/gate-receipts/run.sh
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VERIFY="$ROOT/dev-kit/skills/pr-orchestrator/scripts/verify-gate-receipts.sh"
GUARD="$ROOT/.claude/hooks/pr-gate-guard.py"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
pass=0; fail=0

REPO="$TMP/repo"; mkdir -p "$REPO/.github/audit-reports"
git -C "$REPO" init -q && git -C "$REPO" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
SHA="$(git -C "$REPO" rev-parse HEAD)"
D="$REPO/.github/audit-reports"
echo r > "$D/code-review_x.md"; echo r > "$D/repo-qc_x.md"; echo r > "$D/doc-audit_x.md"

# check NAME OUTPUT NEEDLE   (NEEDLE '' means OUTPUT must be empty)
check() {
  local name="$1" out="$2" needle="$3"
  if [ -z "$needle" ]; then
    [ -z "$out" ] && { pass=$((pass+1)); return; }
  elif printf '%s' "$out" | grep -qF -- "$needle"; then pass=$((pass+1)); return; fi
  fail=$((fail+1)); echo "FAIL: $name"; echo "  needle: '$needle'"; echo "  got: $out"
}

# receipt GATE [python-expr-overriding-fields]  -- write a valid receipt, optionally mutated
receipt() {
  python3 - "$D" "$SHA" "$1" "${2:-}" <<'PY'
import json, sys
d, sha, gate, mut = sys.argv[1:5]
base = {
    "code-review": {"invoked": ["code-review"], "artifacts": [".github/audit-reports/code-review_x.md"]},
    "changelog": {"invoked": ["changelog-check"], "artifacts": []},
    "qc": {"invoked": ["run-repo-qc", "documentation-audit-changes", "claude-md-checklist"],
           "artifacts": [".github/audit-reports/repo-qc_x.md", ".github/audit-reports/doc-audit_x.md"]},
    "implementation-plan": {"invoked": ["implementation-plan-locate"], "artifacts": []},
}
r = {"schema": 1, "gate": gate, "head_sha": sha, "signal": 0, "findings": [], "written_at": "2026-01-01T00:00:00Z"}
r.update(base.get(gate, {}))
if mut:
    exec(mut)
json.dump(r, open(f"{d}/receipt-{gate}_{r['head_sha'] if gate!='x' else sha}.json", "w"))
PY
}
reset() { rm -f "$D"/receipt-*.json; }
all() { for g in code-review changelog qc implementation-plan; do receipt "$g"; done; }
verify() { (cd "$REPO" && "$VERIFY" "$@" 2>&1); }
vcode() { (cd "$REPO" && "$VERIFY" "$@" >/dev/null 2>&1; echo $?); }

# --- verifier
reset; all
check "verifier: all good exits 0"          "$(vcode)" '0'
reset
check "verifier: no receipts exits 1"       "$(vcode)" '1'
check "verifier: names each gate"           "$(verify)" 'qc: no receipt'
reset; all; receipt qc 'r["invoked"].remove("documentation-audit-changes")'
check "verifier: skipped sub-skill named"   "$(verify)" 'qc: not invoked: documentation-audit-changes'
reset; all; receipt qc 'r["artifacts"]=r["artifacts"][:1]'
check "verifier: too few artifacts"         "$(verify)" 'needs at least 2 artifact'
reset; all; receipt code-review 'r["artifacts"]=[".github/audit-reports/nope.md"]'
check "verifier: artifact must exist"       "$(verify)" 'artifact missing on disk'
reset; all; receipt code-review 'r["head_sha"]="deadbeef"*5'; rm -f "$D/receipt-code-review_$SHA.json"
check "verifier: stale sha has no receipt"  "$(verify)" 'code-review: no receipt'
reset; all; receipt qc 'r["head_sha"]="deadbeef"*5; r["gate"]="qc"'; mv "$D/receipt-qc_deadbeefdeadbeefdeadbeefdeadbeefdeadbeef.json" "$D/receipt-qc_$SHA.json"
check "verifier: sha inside file checked"   "$(verify)" 'receipt is for deadbeef'
reset; all; receipt qc 'r["signal"]=2'
check "verifier: BLOCKER signal rejected"   "$(verify)" 'signal must be 0 or 1'
reset; all; receipt qc 'r["findings"]=[{"id":"F1","disposition":"later"}]'
check "verifier: finding needs disposition" "$(verify)" 'no valid disposition'
reset; all; receipt qc 'r["findings"]=[{"id":"F1","disposition":"fixed"}]'
check "verifier: dispositioned finding ok"  "$(vcode)" '0'
reset; all; receipt code-review 'r["opted_out"]="no-code-review: lazy"'
check "verifier: code-review not optable"   "$(verify)" 'mandatory'
reset; all; receipt qc 'r["opted_out"]="no-prep-gate: docs only"; r["invoked"]=[]; r["artifacts"]=[]'
check "verifier: qc opt-out accepted"       "$(vcode)" '0'
reset; all; receipt changelog 'r["invoked"]=["changelog-check","changelog"]'
check "verifier: drafted needs approval"    "$(verify)" 'approved_by_operator'
reset; all; receipt changelog 'r["invoked"]=["changelog-check","changelog"]; r["approved_by_operator"]=True'
check "verifier: approved draft ok"         "$(vcode)" '0'
reset; printf 'not json' > "$D/receipt-qc_$SHA.json"; all_but() { :; }
check "verifier: unreadable receipt"        "$(verify)" 'qc: receipt unreadable'
reset; receipt mode 'r["mode"]="update-body-only"'
check "verifier: --edit accepts mode"       "$(vcode --edit)" '0'
check "verifier: mode never satisfies create" "$(vcode)" '1'
reset
check "verifier: --edit with neither fails" "$(vcode --edit)" '1'
check "verifier: bad arg exits 2"           "$(vcode --bogus)" '2'

# --- hook
guard() { printf '{"tool_name":"Bash","cwd":"%s","tool_input":{"command":%s}}' "$REPO" \
  "$(python3 -c 'import json,sys;print(json.dumps(sys.argv[1]))' "$1")" | python3 "$GUARD"; }

reset
check "hook: create without receipts denies" "$(guard 'gh pr create --title x')"        '"permissionDecision": "deny"'
check "hook: names the missing gate"         "$(guard 'gh pr create --title x')"        'code-review: no receipt'
check "hook: edit without receipts denies"   "$(guard 'gh pr edit 7 --body-file b')"    'deny'
check "hook: chained create denies"          "$(guard 'git push && gh pr create')"       'deny'
check "hook: unrelated command passes"       "$(guard 'gh pr view 7')"                   ''
check "hook: echoed text passes"             "$(guard 'echo "gh pr create"')"            ''
check "hook: heredoc body passes"            "$(guard "cat > n.md <<'EOF'
gh pr create
EOF")"                                                                                   ''
check "hook: bypass prefix passes"           "$(guard 'DEVKIT_SKIP_GATE_CHECK=1 gh pr create')" ''
check "hook: bypass env passes"              "$(DEVKIT_SKIP_GATE_CHECK=1 guard 'gh pr create')" ''
check "hook: bypass text elsewhere denies"   "$(guard 'echo DEVKIT_SKIP_GATE_CHECK=1; gh pr create')" 'deny'
check "hook: non-Bash tool ignored"          "$(printf '{"tool_name":"Edit","tool_input":{}}' | python3 "$GUARD")" ''
all
check "hook: create with receipts passes"    "$(guard 'gh pr create --title x')"        ''
check "hook: edit with receipts passes"      "$(guard 'gh pr edit 7 --body-file b')"    ''
reset; receipt mode 'r["mode"]="update-body-only"'
check "hook: body-only edit passes"          "$(guard 'gh pr edit 7 --body-file b')"    ''
check "hook: body-only create still denies"  "$(guard 'gh pr create')"                  'deny'
reset
printf '#!/usr/bin/env bash\necho boom >&2\nexit 2\n' > "$TMP/broken"; chmod +x "$TMP/broken"
check "hook: verifier error fails open"      "$(GATE_VERIFIER="$TMP/broken" guard 'gh pr create')" 'failed open'
check "hook: verifier error no deny"         "$(GATE_VERIFIER="$TMP/broken" guard 'gh pr create' | grep -c deny)" '0'
check "hook: missing verifier fails open"    "$(GATE_VERIFIER="$TMP/none" guard 'gh pr create')"   'failed open'

echo "passed: $pass  failed: $fail"
[ "$fail" -eq 0 ]
