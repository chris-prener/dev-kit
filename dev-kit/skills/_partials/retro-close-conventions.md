# Retrospective close conventions (shared partial)

Rules shared by [`backlog-retrospective`](../backlog-retrospective/SKILL.md) and [`epic-retrospective`](../epic-retrospective/SKILL.md). Stated once here so the two skills cannot drift (ADR-0002, Rule 2: a policy value cited by more than one skill lives in exactly one canonical place).

## Non-completion closes carry no retrospective

A close as **duplicate / wontfix / not-planned / invalid** is not a completed close, so it gets a label and a short rationale instead of a full retro.

1. Add the matching close-reason **label** to the issue *before* closing: `duplicate`, `wontfix`, `not-planned`, or `invalid`.
2. Leave a 1–3 sentence rationale comment.
3. Close with `gh issue close <N> --reason <reason>`.

The `--reason` flag alone is **not** sufficient. The label is the durable, auditable signal that gates this carve-out for the retro skills, the `backlog` skill, and any future tooling. If a user asks to close as duplicate/wontfix/etc. and the issue lacks the matching label, prompt them to add it first (`gh issue edit <N> --add-label <label>`).

The close-reason vocabulary lives in `${CLAUDE_PROJECT_DIR}/.github/LABELS.md` (or [`label-vocabulary.md`](label-vocabulary.md) if absent).

**Carve-out label set:** `duplicate`, `wontfix`, `not-planned`, `invalid`. An issue carrying any of them is *descoped*, not *completed*.
