"""Shared helpers for the implementation-plan enforcement hooks.

The plan locator and Status parsing are NOT implemented here. They live in
dev-kit/skills/implementation-plan/scripts/plan-status.sh (the executable form
of that skill's Phase 0), and this module only shells out to it.
"""
import json
import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LOCATOR = os.environ.get(
    "PLAN_STATUS_SCRIPT",
    str(ROOT / "dev-kit/skills/implementation-plan/scripts/plan-status.sh"),
)
STARTED = {"in-progress", "blocked", "ready-for-pr", "shipped"}  # matches gate 4
BYPASS_VAR = "DEVKIT_SKIP_PLAN_CHECK"


class LocatorError(Exception):
    """gh/locator failed; callers fail open and warn."""


def read_event():
    try:
        return json.load(sys.stdin)
    except (ValueError, OSError):
        return {}


def plan_status(n, cwd=None, timeout=20):
    """Return (kind, status, state) for issue n, or raise LocatorError."""
    try:
        r = subprocess.run(
            [LOCATOR, str(n)], capture_output=True, text=True, timeout=timeout, cwd=cwd or None
        )
    except (OSError, subprocess.SubprocessError) as e:
        raise LocatorError(str(e))
    if r.returncode != 0:
        raise LocatorError((r.stderr or r.stdout).strip() or f"exit {r.returncode}")
    parts = r.stdout.split()
    if len(parts) != 3:
        raise LocatorError(f"unparseable locator output: {r.stdout!r}")
    return parts[0], parts[1], parts[2]


def needs_plan(kind, status, state="open"):
    """True when this issue should have a started plan but does not."""
    if kind != "issue":  # epics, sprints and PRs carry no plan
        return False
    if state == "closed":  # historical refs: work is over, a plan can no longer come first
        return False
    return status not in STARTED


def remedy(n, status):
    if status == "drafting":
        return f"#{n}: plan is still `drafting`. Run `implementation-plan` Transition to `in-progress`."
    if status == "unknown":
        return f"#{n}: a plan comment exists but its `_Status:` line is unparseable. Fix it with `implementation-plan` Update/Transition; do not Create a second plan."
    if status == "duplicate":
        return f"#{n}: duplicate plan comments. Delete one, then retry."
    return f"#{n}: no `## Implementation plan`. Run `implementation-plan` Create, then Transition to `in-progress`."


def emit(**payload):
    print(json.dumps(payload))


class Budget:
    """Shared wall-clock budget so several serial gh calls stay inside the hook timeout."""

    def __init__(self, seconds=24):
        import time
        self._time = time
        self.deadline = time.monotonic() + seconds

    def remaining(self):
        return self.deadline - self._time.monotonic()
