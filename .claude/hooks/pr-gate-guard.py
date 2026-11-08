#!/usr/bin/env python3
"""PreToolUse(Bash) hook: deny `gh pr create` / `gh pr edit` unless pr-orchestrator's gate
receipts exist for the current HEAD.

The contract and the checking logic live in one place each:
dev-kit/skills/pr-orchestrator/reference/gate-receipts.md (contract) and
dev-kit/skills/pr-orchestrator/scripts/verify-gate-receipts.sh (verifier). This hook only
detects the invocation, runs the verifier, and relays its answer.

Bypass: prefix the command with DEVKIT_SKIP_GATE_CHECK=1 directly before `gh`, or export it.
A verifier error (exit 2, timeout) fails open with a visible warning; missing or incomplete
receipts (exit 1) are a denial.
"""
import os
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import _cmd  # noqa: E402
import _plan  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
VERIFIER = os.environ.get(
    "GATE_VERIFIER", str(ROOT / "dev-kit/skills/pr-orchestrator/scripts/verify-gate-receipts.sh")
)
BYPASS_VAR = "DEVKIT_SKIP_GATE_CHECK"
# gh, optionally path-qualified and with global flags (-R/--repo) before the subcommand.
GH = r"(?:\S*/)?gh(?:\s+(?:-R|--repo)\s+\S+|\s+--\S+)*\s+pr\s+"
CREATE = GH + r"create\b"
EDIT = GH + r"edit\b"


def main():
    ev = _plan.read_event()
    if ev.get("tool_name") != "Bash":
        return
    command = (ev.get("tool_input") or {}).get("command", "")
    is_create = _cmd.invokes(command, CREATE)
    is_edit = _cmd.invokes(command, EDIT)
    if not (is_create or is_edit) or _cmd.bypassed(command, BYPASS_VAR, GH + r"(?:create|edit)\b"):
        return
    args = [VERIFIER] + (["--edit"] if is_edit and not is_create else [])
    try:
        r = subprocess.run(args, capture_output=True, text=True, timeout=20, cwd=ev.get("cwd") or None)
    except (OSError, subprocess.SubprocessError) as e:
        _plan.emit(systemMessage=f"pr-gate-guard failed open: verifier did not run ({e})")
        return
    if r.returncode == 0:
        return
    if r.returncode != 1:
        _plan.emit(systemMessage=f"pr-gate-guard failed open: verifier error ({(r.stderr or r.stdout).strip()})")
        return
    _plan.emit(
        hookSpecificOutput={
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": (
                "PR blocked: pr-orchestrator's gates have not left valid receipts for this HEAD.\n"
                + r.stdout.strip()
                + "\nRun the gates via pr-orchestrator (receipt contract: "
                "dev-kit/skills/pr-orchestrator/reference/gate-receipts.md). "
                f"A deliberate exception: prefix the command with {BYPASS_VAR}=1 and say so in the PR body."
            ),
        }
    )


if __name__ == "__main__":
    main()
