# Label vocabulary (shared partial)

> **Source of truth at runtime:** `.github/LABELS.md` when present. This partial documents a cross-repo canonical baseline so consumer skills work in repos that haven't yet adopted a `LABELS.md`.

## Resolution order

1. **If `.github/LABELS.md` exists in the repo**, treat it as the source of truth. Read it once at the start of the session and use the canonical baseline + repo customizations it defines. Differences between the baseline below and the repo's `LABELS.md` are decided by `LABELS.md`.
2. **Otherwise**, fall back to the canonical baseline below.
3. **Always sanity-check against runtime state** with `gh label list --repo "$REPO" --limit 50 --json name`. If a baseline label is missing in the repo, surface that to the user (it likely needs to be created — see "Label migration" below).

## Canonical baseline

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
| `needs-grooming` | `#cfd3d7` | Quick-captured by the `quick-capture` skill; missing AC or parent epic. Cleared by `backlog-grooming` once the issue is fully baked. |
| `needs-triage` | `#cfd3d7` | Auto-filed (by the `backlog` skill's auto-file mode) or freshly groomed; awaiting routing decision by `triage`. Cleared by triage. |
| `in-progress` | `#0E8A16` | Issue has an active implementation plan in flight. Set by the `implementation-plan` skill on `Status: in-progress` transition; cleared on `ready-for-pr` / `shipped` / `blocked`. Read by session-orientation tooling (e.g. `session-start`) to surface in-flight work. |

### Priority — how urgent (most issues get one; descriptions may be specialized per repo)

| Label | Color | Purpose (default) |
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

## Removed (do NOT propose, and delete if found)

These two GitHub defaults are public-OSS conventions that don't fit private/internal repos:

- `good first issue`
- `help wanted`

If you encounter them in a repo without `.github/LABELS.md`, flag them to the user as label-migration work and proceed without using them.

## Label migration

If the repo is missing baseline labels, has deprecated overlap labels (`cleanup`, `refactor`, `robustness`, `scaling`, `future`), or still has `good first issue` / `help wanted`, do **not** silently fix this from inside a consumer skill. Instead:

1. Surface the gap to the user.
2. Offer to file a tracking issue for the label migration (one issue per repo).
3. Proceed with the closest available label and note the workaround in the issue body.
