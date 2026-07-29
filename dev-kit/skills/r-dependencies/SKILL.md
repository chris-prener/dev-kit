---
name: r-dependencies
description: >
  Defines renv lockfile discipline, DESCRIPTION Imports vs Suggests,
  version pinning strategy, and dependency management workflows for R projects.
when_to_use: >
  Use to add/remove/update packages, troubleshoot renv issues, configure
  DESCRIPTION dependencies, or establish dependency management conventions.
  Trigger phrases: "renv", "r dependencies", "r packages", "lockfile". Not
  for setting up a new project from scratch (`r-project-scaffold`), CI
  caching of renv (`r-ci`), or package-specific DESCRIPTION conventions
  (`r-package-structure`).
model: sonnet
# persona: r-developer   — grouping metadata only; not read by Claude Code.
---

# R Dependencies

You are managing dependencies for an R project. This skill defines the renv-based dependency management workflow, DESCRIPTION field conventions, version pinning strategy, and troubleshooting patterns.

## Activation

Activate when the user needs to add/remove/update packages, troubleshoot renv issues, configure DESCRIPTION dependencies, or establish dependency management conventions.

## Inputs

- **Required**: what dependency operation is needed (add, update, restore, troubleshoot)
- **Optional**: specific package name(s) and version constraints
- **Optional**: whether this is Imports or Suggests

## Steps

### 1. renv lifecycle

| Operation | Command | When to use |
|---|---|---|
| Initialize | `renv::init(bare = TRUE)` | New project (prefer bare to avoid scanning) |
| Install | `renv::install("pkg")` | Add a new dependency |
| Snapshot | `renv::snapshot()` | After installing/updating packages |
| Restore | `renv::restore()` | Fresh clone, CI, or after pulling lockfile changes |
| Update | `renv::update("pkg")` | Upgrade a specific package |
| Update all | `renv::update()` | Periodic dependency refresh |
| Remove | `renv::remove("pkg")` | Remove unused dependency |
| Status | `renv::status()` | Check lockfile vs library drift |
| Clean | `renv::clean()` | Remove packages not in lockfile |

### 2. DESCRIPTION field conventions

```
Imports:
    dplyr (>= 1.1.0),
    arrow,
    DBI,
    pool,
    cli,
    rlang
Suggests:
    testthat (>= 3.0.0),
    lintr,
    styler,
    covr,
    withr,
    mockery
```

**Rules:**

| Field | Contains | Example |
|---|---|---|
| `Imports` | Packages required at runtime | dplyr, arrow, DBI |
| `Suggests` | Dev-only packages (testing, linting, docs) | testthat, lintr, covr |
| `Depends` | **Avoid** — use only for R version constraint | `R (>= 4.1.0)` |

- Always specify minimum version for critical packages: `dplyr (>= 1.1.0)`
- Alphabetize within each field
- One package per line, trailing comma on all but the last

### 3. Version pinning strategy

| Context | Strategy |
|---|---|
| Production pipelines | Pin exact versions in `renv.lock` (default renv behavior) |
| DESCRIPTION Imports | Use `>=` minimum bounds, not exact pins |
| R version | Pin in DESCRIPTION: `Depends: R (>= 4.1.0)` |
| Bioconductor | Pin to a release version via `renv::init(bioconductor = "3.18")` |

**When to update:**
- Security patches: immediately
- Minor versions: monthly review cycle
- Major versions: planned migration with testing

### 4. Adding a new dependency

```r
# 1. Install the package
renv::install("arrow")

# 2. Add to DESCRIPTION (if using package structure)
usethis::use_package("arrow", type = "Imports", min_version = "14.0.0")

# 3. Snapshot the lockfile
renv::snapshot()

# 4. Verify
renv::status()  # Should report "No issues found."

# 5. Commit both files
# git add DESCRIPTION renv.lock
# git commit -m "deps: add arrow for parquet I/O"
```

### 5. Lockfile discipline

**Always commit:**
- `renv.lock` — the reproducibility contract
- `renv/activate.R` — bootstraps renv for new users
- `renv/.gitignore` — renv's own gitignore for its library
- `renv/settings.json` — renv project settings

**Never commit:**
- `renv/library/` — platform-specific compiled packages
- `renv/staging/` — temporary install staging
- `renv/sandbox/` — isolation sandbox

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
| `renv::restore()` fails | Check R version matches lockfile; run `renv::rebuild()` for compiled packages |
| Lockfile out of sync | Run `renv::status()` then `renv::snapshot()` |
| Package not found | Check repos in `renv/settings.json`; add custom repos via `options(repos = ...)` |
| Binary vs source conflicts | Set `options(renv.config.ppm.enabled = TRUE)` for Posit Package Manager binaries |
| Bioconductor packages | Use `renv::install("bioc::PackageName")` |
| GitHub packages | Use `renv::install("owner/repo")` — recorded in lockfile |

### 7. Multi-source repositories

```r
# renv/settings.json or .Rprofile
options(repos = c(
  CRAN = "https://packagemanager.posit.co/cran/latest",
  BioCsoft = "https://bioconductor.org/packages/release/bioc"
))
```

For internal packages:
```r
renv::install("git::https://github.internal.com/org/package.git")
```

## Outputs

- Properly configured `renv.lock`
- Clean `DESCRIPTION` with correct Imports/Suggests
- Reproducible dependency state

## Success criteria

- `renv::status()` reports "No issues found."
- `renv::restore()` succeeds from a clean state (no library present)
- All runtime dependencies are in `Imports`; dev-only in `Suggests`
- Lockfile committed after every dependency change

## Out of scope

- CI caching strategies for renv → `r-ci`
- Package NAMESPACE management → `r-package-structure`
- Initial project setup → `r-project-scaffold`

## Cross-references

- `r-project-scaffold` — initial renv setup
- `r-package-structure` — DESCRIPTION in package context
- `r-ci` — renv caching in CI
- `r-code-style` — commit message conventions
