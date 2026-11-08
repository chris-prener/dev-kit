"""Shared shell-command detection for the PreToolUse guards.

A guard must act on an *invocation*, not on text that merely contains the command
(an echo, a quoted string, a heredoc body being written to a file) — but it must still
see a command that the shell would run from inside a string (`"$(gh pr create)"`). A
small left-to-right scanner does that; regexes cannot track quoting. This module is the
one place that rule lives; plan-commit-guard.py and pr-gate-guard.py both use it.

Scope. These guards catch an *accidental* omission, not an adversary. Covered: separators,
shell keywords, env/VAR=/sudo/time/nohup/exec/xargs prefixes, `bash -c '...'` / `eval '...'`
bodies, `$(...)` and backticks (also inside double quotes), comments, heredoc bodies, quoted
subcommand words. Not covered (documented limits): variable or alias indirection (`$GH pr
create`, `alias gc='git commit'`), `case ... )` patterns or `#` inside a `$(...)` body, and
a command run in another directory than the hook's cwd. Anything the scanner cannot parse
(unbalanced quotes, unexpected errors) falls back to the raw text, which can only
over-detect: a false deny, never a missed invocation.
"""
import os
import re

# Command position: line start, or after a separator / shell keyword, optionally behind
# `env`, VAR=val assignments and `command`.
SEP = r"(?:^|&&|\|\||[;|({!`]|\b(?:then|do|else)\b)"
ASSIGN = r"(?:[A-Za-z_]\w*=\S*\s+)*"
# Prefixes that run the next word as a command: env/sudo/time/..., VAR=val, xargs and its flags.
PRE = (
    r"(?:(?:env|sudo|exec)(?:\s+-[ugCrtphSUaT]\s+[^-\s]\S*|\s+-\S+)*\s+"
    r"|(?:time|nohup|command|builtin)(?:\s+-\S+)*\s+"
    r"|timeout(?:\s+-\S+)*\s+\d\S*\s+"
    r"|nice(?:\s+-n\s+[^-\s]\S*|\s+-\S+)*\s+"
    r"|[A-Za-z_]\w*=\S*\s+"
    r"|xargs(?:\s+-[ILnPdsEaJ]\s+[^-\s]\S*|\s+-\S+)*\s+)*"
)  # value alternatives start with a non-dash so each token matches one way: no backtracking blowup
HEREDOC = re.compile(r"(?<!<)<<(?!<)-?\s*(['\"]?)(\w+)\1")
_ARITH = re.compile(r"\$\(\(.*?\)\)")
_QUOTED = re.compile(r"'[^']*'|\"(?:\\.|[^\"\\])*\"")
# `bash -c '<body>'`, `sh -c "<body>"`, `eval '<body>'`: the quoted body is code.
WRAP = re.compile(
    r"\b(?:(?:ba|z|da)?sh\s+(?:-\w+\s+)*-\w*c\w*|eval)\s+('[^']*'|\"(?:\\.|[^\"\\])*\")"
)
# `gh "pr" create` -> `gh pr create`: unwrap quoted simple words only.
SIMPLE_QUOTED = re.compile(r"""(["'])([A-Za-z0-9_./=-]+)\1""")


def _heredoc_term(line):
    """Terminator word of a heredoc opened on this line, or None. A `<<` inside quotes or
    arithmetic (`$((1<<2))`, `echo "x <<EOF"`) opens nothing."""
    blanked = _ARITH.sub(lambda m: " " * len(m.group(0)), line)
    spans = [(m.start(), m.end()) for m in _QUOTED.finditer(blanked)]
    for m in HEREDOC.finditer(blanked):
        if not any(a < m.start() < b for a, b in spans):
            return m.group(2)
    return None


def code_lines(command):
    """Command lines with heredoc bodies removed (bodies are data, not commands). A heredoc
    whose terminator never appears opens no body: its lines are kept (deny-safe)."""
    raw, lines, i = command.split("\n"), [], 0
    while i < len(raw):
        line = raw[i]
        lines.append(line)
        i += 1
        term = _heredoc_term(line)
        if term is not None:
            for j in range(i, len(raw)):
                if raw[j].strip() == term:
                    i = j + 1
                    break
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
        elif c == "#" and (i == 0 or s[i - 1] in " \t\n;&|("):
            j = s.find("\n", i)  # a comment runs to end of line and cannot hold a command
            i = n if j < 0 else j
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


def cleaned_lines(command, _depth=0):
    """Heredoc-stripped, quote-aware command lines, plus the bodies of `bash -c '...'` and
    `eval '...'`. On unbalanced quotes or any scanner error the text is returned unstripped,
    which can only over-detect (deny-safe), never miss an invocation."""
    text = "\n".join(code_lines(command))
    try:
        code, ok = _scan(SIMPLE_QUOTED.sub(r"\2", text))
        lines = (code if ok else text).split("\n")
        if _depth < 4:
            for m in WRAP.finditer(text):
                body = m.group(1)[1:-1].replace('\\"', '"')
                lines += cleaned_lines(body, _depth + 1)
        return lines
    except Exception:  # RecursionError on adversarial nesting, or an unforeseen parse error
        return text.split("\n")


def unbypassed(command, tail, var):
    """Number of invocations of `tail` at a command position that are not bypassed.

    An invocation is bypassed by `var=1` in the environment, or by `var=1` as an assignment
    prefix on that same invocation (a prefix on an earlier command in a chain does not count)."""
    env_bypass = os.environ.get(var) == "1"
    pat = re.compile(SEP + r"\s*(?P<pre>" + PRE + ")" + "(?:" + tail + ")")
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
