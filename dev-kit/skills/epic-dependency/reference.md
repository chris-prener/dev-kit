# Epic Dependency — reference

Contract and QA detail for the `epic-dependency` skill. `SKILL.md` holds the procedure; this file holds outputs, success criteria, restartable semantics, scope, and cross-references.

## Outputs

- **Op 1 (Map)**: updated `${CLAUDE_PROJECT_DIR}/docs/ROADMAP.md` with `## Epic dependencies` section (mermaid + table). One commit if content changed.
- **Op 2 (Validate)**: printed validation summary. No file writes, no commits.

## Success criteria

- The rendered dependency section in `docs/ROADMAP.md` accurately reflects the `## Dependencies` blocks in all epic issue bodies.
- Re-running `map` on unchanged epic bodies produces a no-op (no commit).
- Cycles in open edges are detected and block rendering.
- Resolved edges (closed blocker) are shown with `✅` status, not hidden.
- The mermaid diagram renders correctly on GitHub (tested by visual inspection of the PR diff).

## Restartable semantics

Fully idempotent. The marker-fenced section in ROADMAP is replaced wholesale on each run. No partial state to recover from.

## Out of scope

- **Intra-epic sub-issue ordering.** Native GitHub sub-issues handle that.
- **Automated dependency detection.** Manual `## Dependencies` block is the contract; no NLP inference.
- **Cross-repository epic dependencies.** Single-repo only.

## Cross-references

- `epic` — prompts for `## Dependencies` during epic creation.
- `roadmap` — manages the `## Epics` section that this skill's output sits adjacent to.
- `epic-retrospective` — when an epic closes, its inbound edges become `resolved`.
- `${CLAUDE_PROJECT_DIR}/docs/ROADMAP.md` — render target for the `## Epic dependencies` section.
