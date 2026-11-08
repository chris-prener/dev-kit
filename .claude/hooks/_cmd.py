"""Shared shell-command detection for the PreToolUse guards.

A guard must act on an *invocation*, not on text that merely contains the command
(an echo, a quoted string, a heredoc body being written to a file) — but it must still
see a command that the shell would run from inside a string (`"$(gh pr create)"`). A
small left-to-right scanner does that; regexes cannot track quoting. This module is the
one place that rule lives; plan-commit-guard.py and pr-gate-guard.py both use it.
"""
import os
import re

# Command position: line start, or after a separator / shell keyword, optionally behind
# `env`, VAR=val assignments and `command`.
SEP = r"(?:^|&&|\|\||[;|({!]|\b(?:then|do|else)\b)"
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


def _find_close(s, start):
    """Index of the `)` closing a `$(` whose body starts at `start`, or -1."""
    depth, i, n = 1, start, len(s)
    while i < n:
        c = s[i]
        if c == "\\":
            i += 2
            continue
        if c in "'\"":
            j = s.find(c, i + 1)
            if j < 0:
                return -1
            i = j + 1
            continue
        if c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return -1


def _scan(s):
    """Return (code, balanced). Quoted text becomes `""`; `$(...)` and backtick bodies inside
    double quotes are kept as code, set off by `;` so they sit at a command position."""
    out, i, n = [], 0, len(s)
    while i < n:
        c = s[i]
        if c == "\\":
            nxt = s[i + 1 : i + 2]
            out.append(" " if nxt == "\n" else nxt)
            i += 2
        elif c == "'":
            j = s.find("'", i + 1)
            if j < 0:
                return s, False
            out.append('""')
            i = j + 1
        elif c == "$" and s[i + 1 : i + 2] == "'":  # ANSI-C string: backslash escapes allowed
            j = i + 2
            while j < n and s[j] != "'":
                j += 2 if s[j] == "\\" else 1
            if j >= n:
                return s, False
            out.append('""')
            i = j + 1
        elif c == '"':
            j, parts = i + 1, []
            while j < n and s[j] != '"':
                d = s[j]
                if d == "\\":
                    j += 2
                elif d == "$" and s[j + 1 : j + 2] == "(":
                    k = _find_close(s, j + 2)
                    if k < 0:
                        return s, False
                    body, ok = _scan(s[j + 2 : k])
                    if not ok:
                        return s, False
                    parts.append(";" + body + ";")
                    j = k + 1
                elif d == "`":
                    k = s.find("`", j + 1)
                    if k < 0:
                        return s, False
                    body, ok = _scan(s[j + 1 : k])
                    if not ok:
                        return s, False
                    parts.append(";" + body + ";")
                    j = k + 1
                else:
                    j += 1
            if j >= n:
                return s, False
            out.append('""' + "".join(parts))
            i = j + 1
        else:
            out.append(c)
            i += 1
    return "".join(out), True


def cleaned_lines(command):
    """Heredoc-stripped, quote-aware command lines. On unbalanced quotes the text is returned
    unstripped, which can only over-detect (deny-safe), never miss an invocation."""
    text = "\n".join(code_lines(command))
    code, ok = _scan(text)
    return (code if ok else text).split("\n")


def unbypassed(command, tail, var):
    """Number of invocations of `tail` at a command position that are not bypassed.

    An invocation is bypassed by `var=1` in the environment, or by `var=1` as an assignment
    prefix on that same invocation (a prefix on an earlier command in a chain does not count)."""
    env_bypass = os.environ.get(var) == "1"
    pat = re.compile(SEP + r"\s*(?P<pre>(?:env\s+)?" + ASSIGN + r"(?:command\s+)?)" + "(?:" + tail + ")")
    flag = re.compile(rf"(?:^|\s){re.escape(var)}=1(?:\s|$)")
    count = 0
    for line in cleaned_lines(command):
        for m in pat.finditer(line):
            if not (env_bypass or flag.search(m.group("pre"))):
                count += 1
    return count


def invokes(command, tail):
    """True if `tail` is invoked at a command position (bypass ignored)."""
    return unbypassed(command, tail, "__NO_SUCH_BYPASS_VAR__") > 0
