# Doc report template (shared partial)

Referenced by `documentation` under its report-generation step. Holds the canonical report template that every audit-run output conforms to.

```markdown
# Documentation Report — [Project Name]

**Date:** YYYY-MM-DD HH:MM:SS
**Repository:** [path or URL]
**Auditor:** documentation skill

---

## Executive Summary

- **Total files audited:** [N]
- **Tier 1 (library/module functions) documented:** [N]
- **Tier 2 (script-embedded functions) documented:** [N]
- **Tier 3 (pipeline/orchestration scripts) commented:** [N]
- **Tier 4 (configuration) commented:** [N]
- **Total functions documented with a docstring block:** [N]
  - Previously documented (enhanced): [N]
  - Newly documented: [N]
- **Total inline comments added:** [N] (approximate)
- **Total section headers added:** [N]
- **Stale documentation corrected:** [N]
- **Parse errors introduced:** 0 (must be zero)

---

## Documentation Inventory

### Tier 1 — Library / Module Functions

| File | Functions | Docstrings Before | Docstrings After | Status |
|------|-----------|-------------------|-------------------|--------|
| `src/normalize.py` | 3 | Partial | Complete | UPDATED |
| `R/calculate_order_total.R` | 1 | Complete | Complete | VERIFIED |
| ... | ... | ... | ... | ... |

### Tier 2 — Script-Embedded Functions

[Same table format]

### Tier 3 — Pipeline / Orchestration Scripts

| File | Sections Added | Inline Comments Added | Header Block | Status |
|------|----------------|------------------------|--------------|--------|
| ... | ... | ... | ... | ... |

### Tier 4 — Configuration

| File | Header Block Added | Status |
|------|---------------------|--------|
| ... | ... | ... |

---

## Changes by File

### [path/to/file]
- **Tier:** [1–4]
- **Functions documented:** [list]
- **Docstring tags/fields added:** [list per function]
- **Section headers added:** [list]
- **Inline comments added:** [count, with notable examples]
- **Stale docs corrected:** [description, if any]

[Repeat for each file modified]

---

## Stale Documentation Found & Corrected

### [File — Function Name]
- **Issue:** parameter doc referenced a name that was renamed
- **Correction:** updated the doc to match the current signature

[Repeat for each stale doc issue]

---

## Observations & Recommendations

[Patterns noticed, documentation debt areas, suggestions for future
documentation standards, or areas where writing the docs revealed a
potential bug (documented but not fixed — see the skill's Critical Rules)]
```
