# roxygen2 standards (shared partial)

Referenced by `r-code-style`, `r-documentation`, `r-testing`, and `r-pipeline-patterns`.

### Required roxygen2 tags for every function

At minimum, every function must have these three tags:

```r
#' @description A clear, concise description of what the function does and when
#'     to use it. Should be 1–3 sentences. Describe behavior, not implementation.
#'
#' @param param1 Description of the parameter, including expected type (e.g.,
#'     "A character vector of ISO 3166-1 alpha-3 country codes") and any
#'     constraints (e.g., "Must be length 1", "Cannot be NULL").
#' @param param2 Description of the second parameter.
#' @param param3 Description with note about the default value and when you
#'     would change it.
#'
#' @return A clear description of what the function returns, including the
#'     type/class (e.g., "A tibble with columns: region, year, orders, revenue")
#'     and any important characteristics (e.g., "Rows with NA region codes
#'     are excluded from the output").
```

`@usage` is **not** required — roxygen2 auto-generates the Usage section from
the function signature. Add `@usage` manually only to override an
auto-generated signature that's wrong (e.g., hiding an internal parameter).

### Optional but encouraged tags

Add these when they provide genuine value — do not add them as boilerplate:

| Tag | When to Use |
|-----|-------------|
| `@details` | When the function has complex behavior, design decisions, or edge cases that `@description` alone cannot cover. Especially useful for explaining *why* a function works the way it does (e.g., why a specific join strategy was chosen). |
| `@examples` | When a function can be demonstrated with a self-contained example that does not require external data or file I/O. Use `\dontrun{}` for examples that require external resources. |
| `@seealso` | When a function is closely related to another function in the codebase (e.g., a main function and its subfunction). |
| `@note` | For important caveats, limitations, or known issues. |
| `@importFrom` | Only if the project is structured as an R package. Do not add for script-based projects. |

### Writing high-quality `@description` tags

**Good descriptions** answer: "What does this function do, and why would I call it?"

```r
# BAD — restates the function name
#' @description Normalizes a region.

# BAD — describes implementation instead of purpose
#' @description Uses dplyr mutate and case_when to change column values.

# GOOD — explains purpose and context
#' @description Normalizes raw region-level sales data into a standard
#'     schema with consistent column names, region codes, and store
#'     hierarchy fields. Called once per region during the initial pipeline
#'     step (01_sales_initial.R).
```

### Writing high-quality `@param` tags

Every `@param` must specify:
1. **What** the parameter represents (not just its name restated)
2. **Type** expected (tibble, character vector, numeric, sf object, etc.)
3. **Constraints** (can it be NULL? what values are valid?)
4. **Default** behavior if the parameter has a default value

```r
# BAD — no type, no constraints
#' @param .data The data.

# GOOD — complete specification
#' @param .data A tibble or data.frame containing raw sales data with
#'     at minimum the columns: \code{region}, \code{code}, and \code{code_level}.
#'     Cannot be NULL or empty.
```

### Writing high-quality `@return` tags

Every `@return` must specify:
1. **Type/class** of the return value (tibble, sf object, character vector, etc.)
2. **Structure** — key columns, dimensions, or properties
3. **Side effects** — if the function writes files, modifies global state, or
   produces messages/warnings, document that here

```r
# BAD — vague
#' @return The processed data.

# GOOD — specific and useful
#' @return A tibble with the same rows as the input but with added columns:
#'     \code{region} (composite geographic key), \code{region_level} (one of
#'     "country", "state", "county", "store"),
#'     \code{region_type}, and \code{region_source}. Rows with unmappable
#'     geographic codes are retained but receive \code{NA} in the region fields.
```

### Handling multi-function files

When a file contains multiple functions (e.g., a main function and its helpers):
- **Every function** gets its own roxygen2 block — including internal helpers.
- Use `@seealso` to cross-reference related functions.
- If a helper is only meant to be called by its parent, note that in the
  `@description`: "Internal helper called by \code{get_totals()}. Not intended
  for direct use."

### Handling existing partial roxygen2

When a function already has some roxygen2 tags but is missing others:
1. **Do not delete or rewrite** existing tags unless they are factually wrong.
2. **Add missing tags** in the standard order: `@description`,
   `@param` (one per parameter), `@return`, then optional tags.
3. **Fill in empty tags** — if `@param x` exists with no description, add one.
4. **Verify accuracy** — if the function signature has changed since the docs
   were written (e.g., a parameter was added or renamed), update the docs to
   match the current code.
