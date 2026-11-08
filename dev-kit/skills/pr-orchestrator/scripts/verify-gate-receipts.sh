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
import glob, json, os, subprocess, sys

root, d, sha, edit = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4] == "1"
real_d = os.path.realpath(d)

# gate -> required sub-steps, {sub-step: artifact filename prefix}, sub-steps that may be skipped
# with a reason (the gate file says "if missing: skip"), whether the gate may be opted out.
REQUIRED = {
    "preflight": (set(), {}, set(), False),
    "code-review": ({"code-review"}, {"code-review": "code-review_"}, set(), False),
    "changelog": ({"changelog-check"}, {}, set(), True),
    "qc": (
        {"run-repo-qc", "documentation-audit-changes", "claude-md-checklist"},
        {"run-repo-qc": "repo-qc_", "documentation-audit-changes": "doc-audit-changes_"},
        {"run-repo-qc", "documentation-audit-changes", "claude-md-checklist"},
        True,
    ),
    "implementation-plan": ({"implementation-plan-locate"}, {}, set(), True),
}
DISPOSITIONS = {"fixed", "filed", "accepted", "n/a"}
gaps = []


def git(*a):
    return subprocess.run(["git", "-C", root, *a], capture_output=True, text=True)


def still_valid(old):
    """A receipt for an earlier SHA stays valid if every commit since touched only CHANGELOG.md
    (the changelog gate's own commit)."""
    if git("merge-base", "--is-ancestor", old, sha).returncode != 0:
        return False
    r = git("diff", "--name-only", old, sha)
    return r.returncode == 0 and set(r.stdout.split()) <= {"CHANGELOG.md"}


def load(gate):
    """Return (receipt, gap). Prefers an exact-HEAD receipt, else a still-valid earlier one."""
    exact = os.path.join(d, f"receipt-{gate}_{sha}.json")
    cands = [exact] if os.path.exists(exact) else sorted(glob.glob(os.path.join(d, f"receipt-{gate}_*.json")))
    stale = None
    for p in cands:
        try:
            with open(p) as f:
                r = json.load(f)
        except (OSError, ValueError) as e:
            return None, f"{gate}: receipt unreadable ({e})"
        if not isinstance(r, dict):
            return None, f"{gate}: malformed receipt (not a JSON object)"
        h = r.get("head_sha")
        if h == sha or (isinstance(h, str) and still_valid(h)):
            return r, None
        stale = h
    if stale is not None:
        return None, f"{gate}: receipt is for {str(stale)[:8]}, HEAD is {sha[:8]}"
    return None, f"{gate}: no receipt for {sha[:8]} ({os.path.relpath(exact, root)})"


def str_list(v):
    return isinstance(v, list) and all(isinstance(x, str) for x in v)


def check_artifacts(gate, arts, art_for, skipped):
    resolved = []
    for a in arts:
        p = os.path.realpath(os.path.join(root, a))
        if os.path.commonpath([p, real_d]) != real_d:
            gaps.append(f"{gate}: artifact outside the report directory: {a}")
        elif not os.path.isfile(p):
            gaps.append(f"{gate}: artifact missing on disk: {a}")
        else:
            resolved.append(os.path.basename(p))
    for step, prefix in art_for.items():
        if step in skipped:
            continue
        if not any(b.startswith(prefix) for b in resolved):
            gaps.append(f"{gate}: no valid {prefix}* artifact for {step}")


def check_gate(gate, r, need, art_for, skippable, can_opt_out):
    if r.get("schema") != 1 or r.get("gate") != gate:
        gaps.append(f"{gate}: wrong schema or gate field")
    sig = r.get("signal")
    if type(sig) is not int or sig not in (0, 1):
        gaps.append(f"{gate}: signal must be the integer 0 or 1 (a BLOCKER halts the flow), got {sig!r}")
    if not r.get("written_at"):
        gaps.append(f"{gate}: missing written_at")
    findings = r.get("findings", [])
    if not isinstance(findings, list):
        gaps.append(f"{gate}: findings must be a list")
        findings = []
    for f in findings:
        if not isinstance(f, dict) or f.get("disposition") not in DISPOSITIONS:
            gaps.append(f"{gate}: finding {f.get('id') if isinstance(f, dict) else f!r} has no valid disposition")
    if gate == "preflight" and r.get("confirmed_by_operator") is not True:
        gaps.append("preflight: the operator has not confirmed issue_refs and branch shape (confirmed_by_operator)")
    if r.get("opted_out"):
        if not can_opt_out:
            gaps.append(f"{gate}: this gate is mandatory and cannot be opted out")
        return
    invoked, arts = r.get("invoked", []), r.get("artifacts", [])
    if not str_list(invoked) or not str_list(arts):
        gaps.append(f"{gate}: invoked and artifacts must be lists of strings")
        return
    skipped = r.get("skipped", {})
    if not isinstance(skipped, dict) or not all(isinstance(k, str) and isinstance(v, str) and v.strip() for k, v in skipped.items()):
        gaps.append(f"{gate}: skipped must map a sub-step to a non-empty reason")
        skipped = {}
    for k in skipped:
        if k not in skippable:
            gaps.append(f"{gate}: sub-step {k} cannot be skipped")
    missing = sorted(need - set(invoked) - set(skipped))
    if missing:
        gaps.append(f"{gate}: not invoked: {', '.join(missing)}")
    check_artifacts(gate, arts, art_for, set(skipped))
    if gate == "changelog" and (r.get("drafted") is True or "changelog" in invoked) and r.get("approved_by_operator") is not True:
        gaps.append("changelog: a drafted entry needs approved_by_operator=true")


try:
    if edit:
        r, _ = load("mode")
        if r and r.get("schema") == 1 and r.get("gate") == "mode" and r.get("mode") == "update-body-only":
            sys.exit(0)
        # No mode receipt: fall through to the full check (a normal update ran the gates).
    for gate, (need, art_for, skippable, can_opt_out) in REQUIRED.items():
        r, err = load(gate)
        if err:
            gaps.append(err)
        else:
            check_gate(gate, r, need, art_for, skippable, can_opt_out)
except SystemExit:
    raise
except Exception as e:  # a verifier bug must not read as "gaps"
    print(f"verifier error: {e!r}", file=sys.stderr)
    sys.exit(2)

if gaps:
    print("\n".join(gaps))
    sys.exit(1)
PY
