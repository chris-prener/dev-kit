#!/usr/bin/env python3
"""UserPromptSubmit hook: nudge when a pickup prompt names an issue with no started plan.

Advisory only: it injects context into the turn and never blocks the prompt.
Fails open (with a visible warning) if gh is unavailable.
"""
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import _plan  # noqa: E402

PICKUP = re.compile(r"\b(?:pick(?:ing)?[ -]?up|work(?:ing)? on|start(?:ing)?)\b", re.I)
MAX_REFS = 5


def main():
    ev = _plan.read_event()
    prompt = ev.get("prompt", "")
    if not PICKUP.search(prompt):
        return
    refs = list(dict.fromkeys(re.findall(r"(?<![\w/])#(\d+)\b", prompt)))[:MAX_REFS]
    nudges, warnings = [], []
    budget = _plan.Budget()
    for n in refs:
        if budget.remaining() < 2:
            warnings.append(f"#{n}: plan check skipped (time budget exhausted)")
            continue
        try:
            kind, status, state = _plan.plan_status(n, ev.get("cwd"), timeout=min(20, budget.remaining()))
        except _plan.LocatorError as e:
            warnings.append(f"#{n}: plan check skipped ({e})")
            continue
        if _plan.needs_plan(kind, status, state):
            nudges.append(_plan.remedy(n, status) + " Do this before the first edit.")
    out = {}
    if nudges:
        out["hookSpecificOutput"] = {
            "hookEventName": "UserPromptSubmit",
            "additionalContext": "Plan-step check:\n" + "\n".join(nudges),
        }
    if warnings:
        out["systemMessage"] = "plan-pickup hook failed open: " + "; ".join(warnings)
    if out:
        _plan.emit(**out)


if __name__ == "__main__":
    main()
