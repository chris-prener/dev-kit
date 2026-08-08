<!--
This is a content fragment composed into the `backlog` skill's Auto-file mode
section. Edit only here; the parent file keeps a stub heading so cross-skill
references to "Auto-file mode" keep resolving.
-->

The protocol (template choice rules, autofile-id format, parent-epic requirement, severity → priority mapping, dedup semantics) is captured in [ADR-0004](../_docs/ADR-0004-auto-filed-issue-protocol.md) and is the durable contract that every caller skill depends on.

### When to use auto-file mode

- The caller is a finding-producing skill (QC or documentation audit) that discovers issues mechanically and needs to create tracker entries without prompting a user.
- The findings are **non-trivial** (i.e. they would not be flagged INFO/LOW) — see "Severity → Priority mapping" below.
- The caller can supply a stable `<check-id>` for dedup.

### When NOT to use auto-file mode

- The user is asking to file an issue interactively → use Steps A–H instead.
- The finding is INFO/LOW severity → surface in the caller's report only; do not file.
- The finding is a one-off bug or feature request that needs human framing → human files via Steps A–H.

### Required inputs (caller-supplied)

| Input | Type | Notes |
|---|---|---|
| `template` | string | One of `qc_finding`, `tech_debt`, `feature_request`, `bug_report`. QC skills use `qc_finding`; doc skills use `tech_debt`. Must match an existing template in `.github/ISSUE_TEMPLATE/`. |
| `title` | string | Human-readable, concise. Convention: `[QC] <slug> · <check-id>: <one-line>` for QC findings; `[Docs] <area> · <check-id>: <one-line>` for documentation findings. The title is for human skim-ability, **not** the dedup key. |
| `body` | string | Full template-conformant body. **Must contain** the autofile-id marker (see below). The body's top-level headings must match the chosen template's required-heading set. |
| `labels` | list | Must include exactly one Type label and one Priority label from [`label-vocabulary.md`](label-vocabulary.md). For QC: `qc` + `priority/*` (and optionally `qc-fixed` if the caller fixed in-place). For docs: `documentation` + `priority/*`. |
| `dedup_id` | string | The autofile-id value (without the surrounding HTML comment). Format: `<skill>:<scope>:<check-id>`. Used both in the body marker and in the dedup search. |
| Exactly one of `parent_epic` (int) or `standalone_reason` (string) | — | `parent_epic` is a validated open epic-issue number (must carry the `epic` label). `standalone_reason` is a non-empty justification. **There is no default.** Callers should pass the currently active parent epic for the session context (e.g., the epic the calling skill is working under). If no parent epic applies, pass `standalone_reason` instead. |

### Autofile-id body marker

Every auto-filed body MUST contain a hidden HTML comment marker:

```html
<!-- autofile-id: <skill>:<scope>:<check-id> -->
```

Components:

- `<skill>` — the caller's skill name, kebab-case (e.g. `code-review`, `documentation`, `readme`).
- `<scope>` — the targeted unit. For QC findings: a module or component name (e.g. `auth-service`). For documentation findings: a file path (`src/utils.js`) or `root` for repo-level docs.
- `<check-id>` — a stable identifier from the caller's check-ID inventory (e.g. `missing-test-coverage`, `unmatched-param`, `stale-readme-table`).

The marker is the dedup key and is exact-match-searched. Title wording may drift across re-files; the marker MUST NOT.

Examples:

```html
<!-- autofile-id: code-review:auth-service:missing-test-coverage -->
<!-- autofile-id: documentation:src/utils.js:unmatched-param -->
<!-- autofile-id: readme:root:stale-readme-table -->
```

### Algorithm

1. **Validate inputs.** All required inputs present; `parent_epic` XOR `standalone_reason` exactly. Body contains an `<!-- autofile-id: <dedup_id> -->` marker matching the supplied `dedup_id`. Labels list contains ≥1 Type + ≥1 Priority. Template matches a real `.github/ISSUE_TEMPLATE/*.md` filename. Any failure → return caller error; do NOT post.

2. **Dedup search (open issues).** Exact-match on a unique marker realistically returns 0–1 rows, but carries an explicit `--limit` anyway per [`gh-list-pagination.md`](gh-list-pagination.md) rather than relying on that assumption.
   ```bash
   REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner')
   gh issue list --repo "$REPO" --state open --search "in:body \"autofile-id: <dedup_id>\"" --json number,title,state,labels --limit 10
   ```
   - **Hit (1+ open issues)**: post a single comment on the most-recently-updated match — `"Still reproduces in <run_id> on <date>; see <report-path>."` — and **conditionally patch the dedup target's labels**: add `needs-triage` only if **all three** are true: (a) the label is absent today, (b) the issue carries no priority label (a triaged issue will have one), and (c) no comment authored on the issue contains the heading `## Triage` (the audit trail left by `backlog`'s Triage operation). This guard prevents already-routed or in-progress issues from being yanked back into the triage queue by a re-firing finding. If patched, do so via `gh issue edit <existing-num> --add-label needs-triage`. Then return `{action: "deduped", issue: <existing-num>, label_patched: <bool>}` to the caller. Do NOT file a duplicate.
   - **Miss**: continue.

3. **Dedup search (closed issues, advisory only).**
   ```bash
   gh issue list --repo "$REPO" --state closed --search "in:body \"autofile-id: <dedup_id>\"" --json number,title --limit 5
   ```
   If a closed match exists, capture the issue number(s) and return `{action: "filing-after-closed-precedent", previously_closed: [<num>, ...]}` alongside the new-issue result so the caller can note it in its report. Do NOT auto-reopen — that's explicitly out of scope (see ADR-0004).

4. **Run the DoR pre-flight checks non-interactively.** Invoke [`dor-preflight.md`](dor-preflight.md) in **non-interactive mode** against the supplied `body` + `labels`. Per that partial's auto-file contract, the User-story header / template-appropriate top-level headings / Type label / Priority label / epic linkage are all WARNING-level — any miss returns a caller error with the list of failures. **Do NOT prompt the user, and do NOT silently fix.** The caller is responsible for assembling a conformant body.

5. **Compose the final body.** Auto-file mode prepends (or verifies the presence of) the `**Parent epic:** #<N>` or `**Parent epic:** standalone — <reason>` line per Step E. The autofile-id marker stays where the caller placed it (typically near the top of the body, after the parent-epic line).

6. **Post the issue.** Inject the `needs-triage` Status label into the labels list if not already present (auto-filed issues are routed through `backlog`'s Triage operation — the label is the queue marker). Then:
   ```bash
   gh issue create --repo "$REPO" --title "<title>" --body "<body>" --label "<label1>,<label2>,...,needs-triage"
   ```

7. **Sub-issue link** (epic-linked path only). Per [`epic-linkage.md`](epic-linkage.md) Step 3 — uppercase `-F sub_issue_id=<INT>` and the value is the issue's database `id` (not its number). Failure here is a soft error — return the new issue # to the caller with a note that the link failed; do not roll back the file.

8. **Return** `{action: "filed", issue: <new-num>, previously_closed: [...], labels: [<final list including needs-triage>]}` to the caller.

### What auto-file mode does NOT do

- **Does not invoke the `backlog-retrospective` skill or close issues.** Auto-filed issues close via the normal PR `Closes #N` flow, where the `pr-orchestrator` skill triggers the retro on a real resolving commit. Auto-file is **file-only**; see ADR-0004 §5 for the rationale and the deferred-close follow-up.
- **Does not prompt the user.** Steps F (review draft) and F.5 (`[y/N]` proceed) from interactive mode are skipped — the structural checks run, but their result is "succeed or caller error", not "ask the user".
- **Does not run a worth-doing judgment.** QC and audit-finding items are exempt per the embedded baseline note in Step D.
- **Does not auto-reopen closed issues** that match the dedup_id. Surfaces them advisory-only.

### Severity → Priority mapping (cross-skill standard)

Aligned with the `qc_finding.md` template's severity vocabulary. Caller skills MUST use this mapping; they do not get to redefine it.

| Caller-skill severity | Priority label | File issue? |
|---|---|---|
| critical / blocker | `priority/blocker` | yes |
| high / failing test / missing required doc | `priority/high` | yes |
| medium / warning / stale doc / broken link | `priority/medium` | yes |
| low / info / nit | — | no — surfaced in caller's report only |

### Caller responsibilities

Each finding-producing caller skill is responsible for:

1. Maintaining a stable **Check-ID inventory** subsection in its own spec. Listed IDs are a contract — they may be added but never silently renamed.
2. Mapping its native severity vocabulary to the table above.
3. Constructing a body that conforms to the chosen template's heading set.
4. Embedding the `<!-- autofile-id: ... -->` marker in the body.
5. Supplying the currently active `parent_epic` for the session context (the epic the calling skill is working under). If no parent epic applies, pass `standalone_reason` instead with a non-empty justification.
6. Surfacing dedup hits and `previously_closed` indicators in its run report so re-runs are auditable.

### Cross-references

- `backlog-retrospective` — closes auto-filed issues via the normal PR `Closes #N` flow; never invoked directly by auto-file mode.
- `run-repo-qc`, `documentation`, `readme`, `walkthrough`, `code-review`, `documentation-audit-changes`, `docs-organization`, `playbooks`, `objectives`, `backlog-retrospective` — the finding-producing callers.
- [`../_docs/ADR-0004-auto-filed-issue-protocol.md`](../_docs/ADR-0004-auto-filed-issue-protocol.md) — durable record of the protocol contract.
