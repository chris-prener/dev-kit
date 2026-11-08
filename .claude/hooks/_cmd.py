"""Shared shell-command detection for the PreToolUse guards.

A guard must act on an *invocation*, not on text that merely contains the command
(an echo, a quoted string, a heredoc body being written to a file). This module is
the one place that rule lives; plan-commit-guard.py and pr-gate-guard.py both use it.
"""
import os
import re

# Command position: line start, or after a separator / shell keyword, optionally behind
# `env`, VAR=val assignments and `command`.
SEP = r"(?:^|&&|\|\||[;|({!]|\b(?:then|do|else)\b)"
ASSIGN = r"(?:[A-Za-z_]\w*=\S*\s+)*"
PREFIX = r"(?:env\s+)?" + ASSIGN + r"(?:command\s+)?"
ANCHOR = SEP + r"\s*" + PREFIX
HEREDOC = re.compile(r"(?<!<)<<(?!<)-?\s*(['\"]?)(\w+)\1")
QUOTED = re.compile(r"'[^']*'|\"(?:\\.|[^\"\\])*\"")


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


def _unquoted(line):
    """Blank out quoted spans so a `|` or `;` inside a string is not a separator."""
    return QUOTED.sub('""', line)


def invokes(command, tail):
    """True if `tail` (a regex, e.g. r'git\\s+commit\\b') is invoked at a command position."""
    pat = re.compile(ANCHOR + tail)
    return any(pat.search(_unquoted(line)) for line in code_lines(command))


def bypassed(command, var, tail):
    """Bypass via the environment, or as an assignment prefix of the guarded invocation itself
    (same command segment; a prefix on an earlier command in a chain does not count)."""
    if os.environ.get(var) == "1":
        return True
    pat = re.compile(SEP + r"\s*(?:env\s+)?" + ASSIGN + rf"{var}=1\s+" + ASSIGN + r"(?:command\s+)?" + tail)
    return any(pat.search(_unquoted(line)) for line in code_lines(command))
