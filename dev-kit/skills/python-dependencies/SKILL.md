---
name: python-dependencies
description: >
  Defines uv lockfile discipline, pyproject.toml dependencies vs
  dependency-groups, version pinning strategy, and dependency management
  workflows for Python projects.
when_to_use: >
  Use to add/remove/update packages, troubleshoot uv issues, configure
  pyproject.toml dependencies, or establish dependency management
  conventions. Trigger phrases: "uv", "python dependencies", "python
  packages", "lockfile", "pip install". Not for setting up a new project
  from scratch (`python-project-scaffold`), CI caching of uv
  (`python-ci`), or build-metadata dependency conventions
  (`python-packaging`).
model: sonnet
# persona: python-developer   — grouping metadata only; not read by Claude Code.
---

# Python Dependencies

You are managing dependencies for a Python project. This skill defines the uv-based dependency management workflow, `pyproject.toml` field conventions, version pinning strategy, and troubleshooting patterns.

## Activation

Activate when the user needs to add/remove/update packages, troubleshoot uv issues, configure `pyproject.toml` dependencies, or establish dependency management conventions.

## Inputs

- **Required**: what dependency operation is needed (add, update, sync, troubleshoot)
- **Optional**: specific package name(s) and version constraints
- **Optional**: whether this is a runtime or dev-only dependency

## Steps

### 1. uv lifecycle

| Operation | Command | When to use |
|---|---|---|
| Initialize | `uv init --package` | New project |
| Add | `uv add <pkg>` | Add a new runtime dependency |
| Add (dev) | `uv add --dev <pkg>` | Add a dev-only dependency |
| Add (group) | `uv add --group docs <pkg>` | Add to a named optional group |
| Lock | `uv lock` | After manually editing `pyproject.toml` |
| Sync | `uv sync` | Fresh clone, CI, or after pulling lockfile changes |
| Update | `uv lock --upgrade-package <pkg>` | Upgrade a specific package |
| Update all | `uv lock --upgrade` | Periodic dependency refresh |
| Remove | `uv remove <pkg>` | Remove unused dependency |
| Status | `uv tree` | Inspect the resolved dependency graph |
| Run | `uv run <cmd>` | Run a command inside the locked environment |

### 2. pyproject.toml field conventions

```toml
[project]
dependencies = [
    "polars>=1.0",
    "httpx>=0.27",
    "pydantic>=2.8",
]

[dependency-groups]
dev = [
    "pytest>=8.0",
    "ruff>=0.6",
    "mypy>=1.11",
]
docs = [
    "mkdocs-material>=9.5",
]
```

**Rules:**

| Field | Contains | Example |
|---|---|---|
| `project.dependencies` | Packages required at runtime | polars, httpx, pydantic |
| `dependency-groups.dev` | Dev-only packages (testing, linting, type-checking) | pytest, ruff, mypy |
| `dependency-groups.<name>` | Optional, purpose-scoped groups | docs, notebook |

- Always specify minimum version for direct dependencies: `polars>=1.0`
- Never pin exact versions (`==`) in `dependencies` — that constrains downstream consumers; let `uv.lock` do exact pinning
- Alphabetize within each list
- Use `requires-python` in `[project]` to declare the supported Python range

### 3. Version pinning strategy

| Context | Strategy |
|---|---|
| Application/project lockfile | Pin exact versions in `uv.lock` (default uv behavior) |
| `pyproject.toml` dependencies | Use `>=` minimum bounds, not exact pins |
| Python version | Pin in `.python-version`; declare range in `requires-python` |
| Publishable library | Wider bounds in `dependencies`; no lockfile shipped (consumers resolve their own) |

**When to update:**
- Security patches: immediately (`uv lock --upgrade-package <pkg>`)
- Minor versions: monthly review cycle
- Major versions: planned migration with testing

### 4. Adding a new dependency

```bash
# 1. Add the package (updates pyproject.toml and uv.lock together)
uv add polars

# 2. Verify
uv tree | grep polars

# 3. Commit both files
# git add pyproject.toml uv.lock
# git commit -m "deps: add polars for dataframe I/O"
```

### 5. Lockfile discipline

**Always commit:**
- `uv.lock` — the reproducibility contract
- `.python-version` — pinned interpreter

**Never commit:**
- `.venv/` — the materialized virtual environment

**Commit message convention for dependency changes:**
```
deps: add <package> for <purpose>
deps: update <package> to <version>
deps: remove unused <package>
deps: bulk update (monthly refresh)
```

### 6. Troubleshooting

| Problem | Solution |
|---|---|
| `uv sync` fails to resolve | Run `uv lock` to see the resolution conflict explicitly; check for incompatible pins |
| Lockfile out of sync | Run `uv lock` then `uv sync` |
| Package not found | Check `[[tool.uv.index]]` for custom indexes; verify package name/spelling |
| Wrong Python picked up | Run `uv python pin <version>`; check `.python-version` |
| Native/compiled package fails | Check platform wheels exist on PyPI; may need system build deps |
| Git dependency | `uv add git+https://github.com/owner/repo.git` — recorded in lockfile with commit hash |

### 7. Alternate/private indexes

```toml
# pyproject.toml
[[tool.uv.index]]
name = "internal"
url = "https://pypi.internal.example.com/simple"
```

```bash
# Install from it explicitly:
uv add --index internal internal-package
```

## Outputs

- Properly configured `uv.lock`
- Clean `pyproject.toml` with correct `dependencies`/`dependency-groups`
- Reproducible dependency state

## Success criteria

- `uv sync` succeeds from a clean checkout (no `.venv` present)
- All runtime dependencies are in `project.dependencies`; dev-only in `dependency-groups.dev`
- Lockfile committed after every dependency change
- `uv tree` shows no unexpected duplicate major versions of the same package

## Out of scope

- CI caching strategies for uv → `python-ci`
- Build/publish dependency metadata → `python-packaging`
- Initial project setup → `python-project-scaffold`

## Cross-references

- `python-project-scaffold` — initial uv setup
- `python-packaging` — `dependencies` in a publishable package context
- `python-ci` — uv caching in CI
- `python-code-style` — commit message conventions
