---
last_updated: 2026-10-03
---

# Glossary

Terms used across this project's docs and skills, with authoritative-source links.

## tooling

### partial

A shared file under `dev-kit/skills/_partials/` holding content that more than one skill needs, so each skill links to it instead of carrying its own copy. See [ADR-0002](adr/ADR-0002-skill-decomposition.md).

### persona

The role a skill or output style belongs to (`product-owner`, `product-manager`, `developer`, `writer`, `python-developer`, `r-developer`), recorded in a skill's `# persona:` frontmatter comment. Grouping metadata only; Claude Code does not read it. See [`gate-qc.md`](../dev-kit/skills/pr-orchestrator/reference/gate-qc.md).
