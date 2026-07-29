# Label Vocabulary

This file is the source of truth for GitHub Issue / PR labels in this repository. The `backlog`, `triage`, `backlog-retrospective`, and related skills under `dev-kit/skills/` read this file when present; they fall back to the embedded baseline in [`_partials/label-vocabulary.md`](../dev-kit/skills/_partials/label-vocabulary.md) only when this file is absent.

This repo *is* the canonical baseline — the vocabulary below mirrors `_partials/label-vocabulary.md` exactly, with no repo-specific customizations. Consuming repos that vendor a copy of this file may add their own "Repo customizations" section following the pattern in the "Vendoring" note at the bottom.

## Baseline (22 labels)

7 Type + 6 Status + 3 Priority + 6 Meta/close-reason = 22 labels.

### Type — what kind of work is this (every issue gets at least one)

| Label | Color | Purpose |
|---|---|---|
| `bug` | `#d73a4a` | Something isn't working |
| `enhancement` | `#a2eeef` | New feature or request |
| `documentation` | `#0075ca` | Improvements or additions to documentation |
| `tech-debt` | `#fbca04` | Refactoring, cleanup, robustness, scaling, or other internal-quality work |
| `epic` | `#5319E7` | Parent issue for a thematic body of work; sub-issues linked |
| `audit-finding` | `#B60205` | Issue identified during an audit |
| `qc` | `#D93F0B` | QC finding from automated or independent audit |

### Status — added/removed during the issue's lifetime

| Label | Color | Purpose |
|---|---|---|
| `qc-fixed` | `#0E8A16` | QC finding auto-fixed by tooling |
| `blocked` | `#E11D48` | Cannot proceed — waiting on data, a decision, or another issue |
| `UAT` | `#FBCA04` | Awaiting user acceptance testing |
| `needs-grooming` | `#cfd3d7` | Quick-captured by the `quick-capture` skill; missing AC or parent epic. Cleared by `backlog-grooming` once the issue is fully baked. |
| `needs-triage` | `#cfd3d7` | Auto-filed (by the `backlog` skill's auto-file mode) or freshly groomed; awaiting routing decision by `triage`. Cleared by triage. |
| `in-progress` | `#0E8A16` | Issue has an active implementation plan in flight. Set by the `implementation-plan` skill on `Status: in-progress` transition; cleared on `ready-for-pr` / `shipped` / `blocked`. Read by session-orientation tooling (e.g. `session-start`) to surface in-flight work. |

### Priority — how urgent (most issues get one)

| Label | Color | Purpose |
|---|---|---|
| `priority/blocker` | `#B60205` | Severe impact, immediate attention required |
| `priority/high` | `#D93F0B` | Significant impact, address soon |
| `priority/medium` | `#FBCA04` | Moderate impact, address as capacity allows |

### Meta + close-reason

| Label | Color | Purpose |
|---|---|---|
| `question` | `#d876e3` | Further information is requested |
| `no-changelog` | `#cfd3d7` | PR is internal/refactor; opts out of `pr-gate-changelog` |
| `duplicate` | `#cfd3d7` | This issue or pull request already exists |
| `wontfix` | `#ffffff` | This will not be worked on |
| `invalid` | `#e4e669` | This doesn't seem right |
| `not-planned` | `#cfd3d7` | Closed without action; out of scope |

The four close-reason labels (`duplicate`, `wontfix`, `invalid`, `not-planned`) gate the `backlog-retrospective` skill's carve-out: an issue closed without a full retro must carry one of these labels at close time. `--reason` alone is not sufficient.

## Removed (do NOT add)

These two GitHub defaults are public-OSS conventions that don't fit a private/internal repo:

- `good first issue`
- `help wanted`

If found, delete them as part of label migration.

## Usage rules

- **Every new issue must carry at least one Type label.** The `backlog` skill enforces this at issue-creation time.
- **Most new issues should also carry a Priority label.** Skip only for low-stakes or speculative items where priority is undecided.
- **Status labels are added/removed during the issue's lifetime**, not at creation. `blocked` and `UAT` are particularly important to keep current.
- **Close-reason labels are required for non-completed closes.** Add the appropriate label *before* `gh issue close --reason ...`. The retro skill checks for the label, not the reason.

## Vendoring

This file is the intended source of truth to copy into other repos that adopt dev-kit's skills. When vendoring:

- Copy this file verbatim as the starting point for `.github/LABELS.md` in the target repo.
- Names and colors are fixed across repos; only label *purpose* text may be specialized per repo (e.g. domain-specific priority thresholds).
- Add a repo-specific "Repo customizations" section at the end for any repo-only labels or specialized purposes — do not edit the baseline tables above in place.
- Do not add scoring axes (e.g. WSJF) or other extensions here unless a dev-kit skill actually reads them; keep this file matched to what the skills in `dev-kit/skills/` implement.
