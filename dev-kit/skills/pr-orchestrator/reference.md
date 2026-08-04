# PR Orchestrator — reference

Contract and QA detail for `pr-orchestrator` and its three gate skills (`pr-gate-code-review`, `pr-gate-changelog`, `pr-gate-qc`). `SKILL.md` holds the orchestrator's own procedure; this file holds the shared gate protocol, the PR-body marker grammar, the managed-fence contract, outputs, and success criteria.

## Push-state check

Invoked at two points — SKILL.md Step 1 (pre-flight) and again at the top of Step 6, immediately before `gh pr create` / `gh pr edit` — because gates 3–5 can produce local fix-up commits between the two, and a clean working tree does not imply the remote is current.

1. Resolve the upstream ref for the current branch (`git rev-parse --abbrev-ref --symbolic-full-name @{u}`).
2. **No upstream** (first push): `git push -u origin <branch>`, then proceed. This is the ordinary create-mode case, not an error.
3. **Upstream exists**: compare `git rev-parse HEAD` to `git rev-parse @{u}`.
   - Equal → proceed, nothing to do.
   - Local ahead only → `git push`, then proceed.
   - Diverged or local behind → halt: `"Local HEAD and origin/<branch> have diverged — resolve before continuing (do not force-push without operator confirmation)."` Do not auto-force-push.

This check never substitutes for `post-merge`'s `git branch -d` "not fully merged" refusal — that backstop stays as-is; this check exists so the PR itself is never opened against stale remote content in the first place.

## Gate protocol

Every gate skill is invoked with the same input object and must return the same shape of result.

**Input** (built once in orchestrator Step 1, passed to every gate):

| Field | Meaning |
|---|---|
| `issue_refs` | Issues this PR closes |
| `diff_context` | `{ base, head, files_changed, additions, deletions }` |
| `opt_out_markers` | Pre-scanned `_no-*:_` markers from the PR body |
| `mode` | `create` / `update` / `update-body-only` |
| `pr_number` | Existing PR number (update modes only) |
| `pr_body_managed` | Current managed-fence content (update modes only) |

**Output:**

| Field | Meaning |
|---|---|
| `signal` | `0` CLEAN (proceed) / `1` FINDINGS (proceed, surface) / `2` BLOCKER (halt) |
| `findings` | Optional list of structured findings |
| `body_amendments` | Optional lines to fold into the PR body's `## Notes` |
| `chat_output` | One-paragraph human-readable summary |

A gate skill that doesn't exist yet (not all writer/QC skills are ported) is treated as effective signal 0 with a `"⚠ Gate <slug> not found; skipping."` log line — never a hard failure.

## Closing-keyword grammar (canonical)

Issue references use two distinct grammars, never conflated:

| Grammar | Regex | Meaning |
|---|---|---|
| Closing keyword | `(Closes\|Fixes\|Resolves) #\d+` | Closes the referenced issue on merge; feeds `issue_refs`, `## Closes`, and the retro/close-out step |
| Additive reference | `Refs #\d+` | Cross-references an issue without closing it; operator-added only, never produced by pre-flight, preserved verbatim wherever it sits |

Both pre-flight (SKILL.md Step 1) and the `## Closes` carry-forward diff (below) use the closing-keyword regex exclusively. `Refs #N` lines are additive content the operator writes directly into the PR body — they are never detected from `git log`, never diffed, and never promoted to a closing keyword.

## PR-body markers (canonical grammar)

Every marker lives in the PR body's `## Notes` section.

| Marker | Regex | Scope |
|---|---|---|
| `_no-changelog: <justification>_` | `^_no-changelog:\s+(?P<j>.+?)_$` | opts out of the changelog gate |
| `_no-prep-gate: <justification>_` | `^_no-prep-gate:\s+(?P<j>.+?)_$` | opts out of the QC gate |
| `_created: <ISO-8601 UTC>_` | `^_created:\s+(?P<ts>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z)_$` | machine-only; written once at create, never overwritten |
| `_updated: <ISO-8601 UTC>_` | `^_updated:\s+(?P<ts>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z)_$` | machine-only; rewritten on every update |

Justifications must be non-empty and not in `{none, n/a, tbd, ''}`. Use the em-dash (`—`, U+2014) where the grammar calls for one.

The code-review gate has no opt-out marker — it's mandatory.

## Marker fence (PR body machine-ownership boundary)

The PR body has a single managed region:

```
<!-- pr-skill-managed-start -->
…the five-section body template (Summary / Implementation / Testing / Closes / Notes)…
<!-- pr-skill-managed-end -->
```

Inside the fence, this skill is the owner. Outside it, the operator is the owner — the skill never reads, writes, or moves unfenced content (the `_no-*:_` markers are the one exception: they're scanned across the whole body).

**Create mode**: writes the entire body inside the fence. Anything the operator adds afterward (screenshots, reviewer notes) goes outside the fence and survives future updates.

**Update mode**: parses the body into `[pre-fence, managed, post-fence]` and re-emits `pre-fence + regenerated-managed + post-fence`. By default only `## Closes` and the `_updated:` marker regenerate; `## Summary` / `## Implementation` / `## Testing` and `## Notes` prose carry forward verbatim. Force full regeneration with `--update --regen-body` (per-section diff prompt).

**Carry-forward rules:**
- `## Closes`: diff the parsed closing-keyword lines (`(Closes|Fixes|Resolves) #\d+` — see "Closing-keyword grammar" above) against the live set from `git log <base>..HEAD`; surface adds/removes before regenerating. Operator-added `Refs #N` lines are additive references, not closing keywords — they're preserved verbatim and never enter this diff.
- `_no-*:_` markers: preserved verbatim wherever they sit in the body.
- `_created:`: written once, never overwritten.
- `_updated:`: rewritten every update run.

**Fence integrity**: if exactly one of the two markers is present, refuse to proceed in update mode and re-prompt for a body-shape fix. If both are missing, treat the body as unmanaged and offer to wrap it (append a fresh managed block below the existing content, or wrap the whole thing) — operator's explicit choice, no default.

## Outputs

- One open PR (create) or one updated PR (update), body matching the five-section template inside the managed fence.
- Every issue listed under `## Closes` is already closed with a `## Retrospective` comment (from `backlog-retrospective`, via the inline retro step).
- Zero or more auto-filed code-review / QC / doc-audit issues if the gates surfaced findings.
- Update mode also: refreshed `_updated:` marker; preserved `_created:` marker, `_no-*:_` markers, and unfenced content.

## Success criteria

- The PR body has all five sections, non-empty (or `None.` for `## Notes`).
- The code-review gate returned a non-BLOCKER signal — no marker overrides this one.
- Every `Closes #N` references an issue that is `CLOSED` and carries a `## Retrospective` comment.
- `CHANGELOG.md`'s `[Unreleased]` block has an entry referencing this PR or its closed issues, or the PR carries `no-changelog`.
- The QC gate returned non-BLOCKER, or `## Notes` carries `_no-prep-gate: <justification>_`.
- The working tree is clean immediately before `gh pr create` — no gate may dirty it (they write to gitignored `.github/audit-reports/`).
- Local `HEAD` matches `origin/<branch>` immediately before `gh pr create` / `gh pr edit` — the push-state check re-runs at that point, not just at pre-flight.
- Re-running this skill on the same branch detects the open PR and dispatches to update mode rather than opening a duplicate.

## Out of scope

- Reviewing or merging PRs — merges happen on github.com.
- Squashing or rewriting commits.
- Triaging or opening issues — `backlog`.
- Gate-specific logic — each gate owns its own validation.

## Cross-references

- `pr-gate-code-review` — gate 1.
- `pr-gate-changelog` — gate 2.
- `pr-gate-qc` — gate 3.
- `backlog-retrospective` — invoked inline per closing issue.
- `implementation-plan` — `Transition` invoked inline when a plan comment exists.
- `changelog` — drafts entries for the changelog gate.
- [ADR-0004](${CLAUDE_SKILL_DIR}/../_docs/ADR-0004-auto-filed-issue-protocol.md) — auto-file protocol used by the gates.
