#!/usr/bin/env python3
"""PreToolUse(Bash) hook: block `git commit` that references an issue lacking a started plan.

A ref is keyword-qualified (Closes/Fixes/Resolves/Refs/Part of/Implements #N);
bare `#N` mentions are ignored so epic and PR numbers in prose do not block.
Epics, sprints and PRs are skipped. A commit with no qualifying refs passes.

Bypass for a deliberate no-plan `Refs #N` commit: prefix the command with
DEVKIT_SKIP_PLAN_CHECK=1 (or export it where Claude Code runs). Any gh failure
fails open with a visible warning.
"""
import os
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import _plan  # noqa: E402

# A real invocation: `git commit` at a command position (line start or after && || ; | ( ),
# optionally behind VAR=val assignments. Text that merely contains "git commit" (an echo,
# a quoted string, a heredoc being written to a file) is not an invocation.
COMMIT = re.compile(
    r"(?:^|&&|\|\||[;|(])\s*(?:[A-Za-z_]\w*=\S*\s+)*(?:command\s+)?"
    r"git(?:\s+-[Cc]\s+\S+|\s+--\S+)*\s+commit\b"
)
HEREDOC = re.compile(r"(?<!<)<<(?!<)-?\s*(['\"]?)(\w+)\1")


def code_lines(command):
    """Command lines with heredoc bodies removed (bodies are data, not commands)."""
    lines, term = [], None
    for line in command.split("\n"):
        if term is not None:
            if line.strip() == term:
                term = None
            continue
        lines.append(line)
        m = HEREDOC.search(line)
        if m:
            term = m.group(2)
    return lines


def is_commit(command):
    return any(COMMIT.search(line) for line in code_lines(command))


KEYWORD = re.compile(
    r"\b(?:close[sd]?|fix(?:e[sd])?|resolve[sd]?|refs?|references?|part of|implements?|towards?)\b:?\s+"
    r"((?:[\w.-]+/[\w.-]+)?#\d+(?:\s*(?:,|and|&)\s*(?:[\w.-]+/[\w.-]+)?#\d+)*)",
    re.I,
)
FILE_FLAG = re.compile(r"(?:\s-F\s*|\s--file[= ])\s*(['\"]?)([^\s'\"]+)\1")


def message_text(command, cwd):
    text = command
    m = FILE_FLAG.search(command)
    if m:
        p = Path(m.group(2))
        p = p if p.is_absolute() else Path(cwd or ".") / p
        try:
            text += "\n" + p.read_text()
        except OSError:
            pass
    return text


def bypassed(command):
    if os.environ.get(_plan.BYPASS_VAR) == "1":
        return True
    code = "\n".join(code_lines(command))
    return re.search(rf"(?:^|[;&|\s]){_plan.BYPASS_VAR}=1\b", code) is not None


def main():
    ev = _plan.read_event()
    if ev.get("tool_name") != "Bash":
        return
    command = (ev.get("tool_input") or {}).get("command", "")
    if not is_commit(command) or bypassed(command):
        return
    text = message_text(command, ev.get("cwd"))
    refs = []
    for group in KEYWORD.findall(text):
        refs += re.findall(r"#(\d+)", group)
    refs = list(dict.fromkeys(refs))
    problems, warnings = [], []
    for n in refs:
        try:
            kind, status = _plan.plan_status(n, ev.get("cwd"))
        except _plan.LocatorError as e:
            warnings.append(f"#{n} ({e})")
            continue
        if _plan.needs_plan(kind, status):
            problems.append(_plan.remedy(n, status))
    if problems:
        _plan.emit(
            hookSpecificOutput={
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": (
                    "Commit blocked: every referenced issue needs an `## Implementation plan` "
                    "at `in-progress` or later.\n" + "\n".join(problems)
                    + f"\nDeliberate no-plan `Refs #N` commit? Prefix the command with {_plan.BYPASS_VAR}=1."
                ),
            }
        )
    elif warnings:
        _plan.emit(systemMessage="plan-commit-guard failed open: could not check " + "; ".join(warnings))


if __name__ == "__main__":
    main()
