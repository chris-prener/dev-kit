# Create Repo QC — reference

Contract and QA detail for the `create-repo-qc` skill. `SKILL.md` holds the procedure; this file holds outputs, success criteria, and scope.

## Outputs

- A `tests/` directory with `README.md` and a placeholder structural test.
- A `docs/qc-modifications.md` overlay stub.
- A chat summary of what was scaffolded.

## Success criteria

- `tests/` and `docs/qc-modifications.md` exist after this skill runs (or were already present and the skill no-op'd cleanly).
- `run-repo-qc` can be invoked next without erroring on missing infrastructure.
- The skill does NOT execute any tests or file any issues.

## Out of scope

- **Writing test cases** — incremental, dev-driven. Not bulk-scaffolded.
- **Executing tests** — `run-repo-qc`'s job.
- **Filing issues** — `run-repo-qc` does this via auto-file mode.
- **Choosing exotic frameworks** — use the language standard.
- **Installing language dependencies** — surface missing deps to the user.

## Cross-references

- `run-repo-qc` — runs after this skill scaffolds; reads `docs/qc-modifications.md`.
- `backlog` — `run-repo-qc` files findings via auto-file mode.
