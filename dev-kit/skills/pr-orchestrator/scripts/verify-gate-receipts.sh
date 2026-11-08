#!/usr/bin/env bash
# verify-gate-receipts.sh — check pr-orchestrator preflight + gate receipts against the contract in
# reference/gate-receipts.md (that file is the single definition; keep the two in step).
#
# Usage: verify-gate-receipts.sh [--edit] [--sha SHA] [--dir DIR]
#   --edit      also accept an update-body-only mode receipt in place of the four gate receipts
#   --sha SHA   HEAD to check against (default: git rev-parse HEAD)
#   --dir DIR   receipt directory (default: <repo root>/.github/audit-reports)
# Exit: 0 all satisfied; 1 gaps (one per line on stdout); 2 verifier error.
set -u
EDIT=0; SHA=""; DIR=""
while [ $# -gt 0 ]; do
  case "$1" in
    --edit) EDIT=1 ;;
    --sha)  shift; SHA="${1:-}" ;;
    --dir)  shift; DIR="${1:-}" ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done
command -v python3 >/dev/null 2>&1 || { echo "python3 not found" >&2; exit 2; }
ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "not in a git repo" >&2; exit 2; }
[ -n "$SHA" ] || SHA=$(git rev-parse HEAD 2>/dev/null) || { echo "cannot resolve HEAD" >&2; exit 2; }
[ -n "$DIR" ] || DIR="$ROOT/.github/audit-reports"

exec python3 -I - "$ROOT" "$DIR" "$SHA" "$EDIT" <<'PY'
import json, os, sys

root, d, sha, edit = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4] == "1"

REQUIRED = {  # gate -> (invoked, min artifacts, opt-out allowed)
    "preflight": (set(), 0, False),
    "code-review": ({"code-review"}, 1, False),
    "changelog": ({"changelog-check"}, 0, True),
    "qc": ({"run-repo-qc", "documentation-audit-changes", "claude-md-checklist"}, 2, True),
    "implementation-plan": ({"implementation-plan-locate"}, 0, True),
}
DISPOSITIONS = {"fixed", "filed", "accepted", "n/a"}
gaps = []


def load(gate):
    p = os.path.join(d, f"receipt-{gate}_{sha}.json")
    if not os.path.exists(p):
        return None, f"{gate}: no receipt for {sha[:8]} ({os.path.relpath(p, root)})"
    try:
        with open(p) as f:
            return json.load(f), None
    except (OSError, ValueError) as e:
        return None, f"{gate}: receipt unreadable ({e})"


if edit:
    r, err = load("mode")
    if r and r.get("mode") == "update-body-only" and r.get("head_sha") == sha:
        sys.exit(0)
    # No mode receipt: fall through to the full four-gate check (a normal update ran the gates).

for gate, (need, min_art, can_opt_out) in REQUIRED.items():
    r, err = load(gate)
    if err:
        gaps.append(err)
        continue
    if r.get("schema") != 1 or r.get("gate") != gate:
        gaps.append(f"{gate}: wrong schema or gate field")
    if r.get("head_sha") != sha:
        gaps.append(f"{gate}: receipt is for {str(r.get('head_sha'))[:8]}, HEAD is {sha[:8]}")
    if r.get("signal") not in (0, 1):
        gaps.append(f"{gate}: signal must be 0 or 1 (a BLOCKER halts the flow), got {r.get('signal')!r}")
    if not r.get("written_at"):
        gaps.append(f"{gate}: missing written_at")
    for f in r.get("findings", []):
        if f.get("disposition") not in DISPOSITIONS:
            gaps.append(f"{gate}: finding {f.get('id')!r} has no valid disposition")
    if gate == "preflight" and r.get("confirmed_by_operator") is not True:
        gaps.append("preflight: the operator has not confirmed issue_refs and branch shape (confirmed_by_operator)")
    opted = r.get("opted_out")
    if opted:
        if not can_opt_out:
            gaps.append(f"{gate}: this gate is mandatory and cannot be opted out")
        continue
    missing = sorted(need - set(r.get("invoked", [])))
    if missing:
        gaps.append(f"{gate}: not invoked: {', '.join(missing)}")
    arts = r.get("artifacts", [])
    if len(arts) < min_art:
        gaps.append(f"{gate}: needs at least {min_art} artifact(s), has {len(arts)}")
    for a in arts:
        if not os.path.exists(os.path.join(root, a)):
            gaps.append(f"{gate}: artifact missing on disk: {a}")
    if gate == "changelog" and "changelog" in r.get("invoked", []) and r.get("approved_by_operator") is not True:
        gaps.append("changelog: a drafted entry needs approved_by_operator=true")

if gaps:
    print("\n".join(gaps))
    sys.exit(1)
PY
