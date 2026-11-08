"""Shared shell-command detection for the PreToolUse guards.

A guard must act on an *invocation*, not on text that merely contains the command
(an echo, a quoted string, a heredoc body being written to a file). This module is
the one place that rule lives; plan-commit-guard.py and pr-gate-guard.py both use it.
"""
import os
import re

# Command position: line start or after && || ; | ( , optionally behind VAR=val assignments.
ANCHOR = r"(?:^|&&|\|\||[;|(])\s*(?:[A-Za-z_]\w*=\S*\s+)*(?:command\s+)?"
ASSIGN = r"(?:[A-Za-z_]\w*=\S*\s+)*"
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


def invokes(command, tail):
    """True if `tail` (a regex, e.g. r'git\\s+commit\\b') is invoked at a command position."""
    pat = re.compile(ANCHOR + tail)
    return any(pat.search(line) for line in code_lines(command))


def bypassed(command, var):
    """Bypass via the environment, or as an assignment prefix of the guarded command itself."""
    if os.environ.get(var) == "1":
        return True
    code = "\n".join(code_lines(command))
    return re.search(rf"(?:^|&&|\|\||[;|(])\s*{ASSIGN}{var}=1\s+{ASSIGN}\S", code) is not None
