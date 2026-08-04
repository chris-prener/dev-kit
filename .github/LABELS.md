# Label Vocabulary

This file is the source of truth for GitHub Issue / PR labels in this repository. `backlog` (and its Triage operation), `backlog-retrospective`, and related skills under `dev-kit/skills/` read this file when present; they fall back to the embedded baseline in [`_partials/label-vocabulary.md`](../dev-kit/skills/_partials/label-vocabulary.md) only when this file is absent.

This repo *is* the canonical baseline — the vocabulary below mirrors `_partials/label-vocabulary.md` exactly. One label exists live in this repo but is deliberately *not* admitted to the baseline below — see "Known deviations". Consuming repos that vendor a copy of this file may add their own "Repo customizations" section following the pattern in the "Vendoring" note at the bottom.

## Baseline (23 labels)

8 Type + 6 Status + 3 Priority + 6 Meta/close-reason = 23 labels.

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
| `spike` | `#C5DEF5` | Time-boxed discovery spike; produces artifacts, not production code |

### Status — added/removed during the issue's lifetime

| Label | Color | Purpose |
|---|---|---|
| `qc-fixed` | `#0E8A16` | QC finding auto-fixed by tooling |
| `blocked` | `#E11D48` | Cannot proceed — waiting on data, a decision, or another issue |
| `UAT` | `#FBCA04` | Awaiting user acceptance testing |
| `needs-grooming` | `#cfd3d7` | Captured by `backlog`'s Capture operation; missing AC or parent epic. Cleared by `backlog`'s Groom operation once the issue is fully baked. |
| `needs-triage` | `#cfd3d7` | Auto-filed (by `backlog`'s Auto-file mode) or freshly groomed; awaiting routing decision by `backlog`'s Triage operation. Cleared by triage. |
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
| `no-changelog` | `#cfd3d7` | PR is internal/refactor; opts out of `pr-orchestrator`'s changelog gate |
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

## Known deviations

- **`sprint`** (`#1D76DB`) — created live for the Epic B / Epic A area-timebox pilot (issues #49–#54). Deliberately excluded from the baseline: whether sprints are issue-backed at all is Epic A's (#13) decision, and admitting the label now would bake in an answer #13 hasn't reached. Revisit when #13 resolves. See [#4](https://github.com/chris-prener/dev-kit/issues/4).

## Vendoring

This file is the intended source of truth to copy into other repos that adopt dev-kit's skills. When vendoring:

- Copy this file verbatim as the starting point for `.github/LABELS.md` in the target repo.
- Names and colors are fixed across repos; only label *purpose* text may be specialized per repo (e.g. domain-specific priority thresholds).
- Add a repo-specific "Repo customizations" section at the end for any repo-only labels or specialized purposes — do not edit the baseline tables above in place.
- Do not add scoring axes (e.g. WSJF) or other extensions here unless a dev-kit skill actually reads them; keep this file matched to what the skills in `dev-kit/skills/` implement.
