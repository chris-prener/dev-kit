# Repo layout note (shared partial — repo-local)

> Replace the placeholder sections below with this repo's actual file-layout conventions. Layout-sensitive skills (e.g. `walkthrough`, `documentation`, `readme`) link here for the full reference and carry only a short skill-specific note inline.

## How to use this partial

Document every path convention that skills need to know about — source code locations, generated output directories, config file paths, and any naming conventions.

### Source code layout

_Replace with this repo's source code organization. Example:_

- **Library code** lives under `src/` (or `lib/`, `source/`, etc.).
- **Entry points** live at the repo root or under `bin/`.
- **Tests** live under `tests/` (or `test/`, `spec/`, etc.).

### Configuration and metadata

_Replace with this repo's config file locations. Example:_

- **Project config** is `<config-file>` at the repo root.
- **CI/CD workflows** live under `.github/workflows/`.

### Generated outputs

_Replace with this repo's build output conventions. Example:_

- **Build artifacts** under `dist/` or `build/` are gitignored.
- **Release artifacts** under `releases/` ARE tracked.

### Skills and governance

- **Cross-cutting skills** live in `dev-kit/skills/` (installed as the `dev-kit` plugin).
- **Skill partials** live in `dev-kit/skills/_partials/`.
