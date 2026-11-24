# CLAUDE.md

## Project

R package that extracts FishBase data on native freshwater and brackish-water fish, plus Quarto analyses that use it. The research question: which indigenous low-trophic fish could contribute to Africa's Blue Transformation.

- `R/`: reusable functions, documented with roxygen.
- `analysis/`: one Quarto document per analysis. Each loads the package with `devtools::load_all("..")`.
- `docs/`: draft manuscripts, git-ignored. Use them for aims and scope; keep them out of committed files and links.

## Commands

```r
devtools::load_all()
devtools::document()   # after editing roxygen comments; man/ is committed
devtools::check()
```

```sh
quarto render analysis/<name>.qmd   # first run downloads FishBase tables
```

## Rules

- Analysis code is the source of truth. Manuscripts are context, not a spec: change code only when asked.
- Package code refers to columns as `.data$col` in data-masking verbs (`mutate()`, `filter()`) and as `"col"` strings in tidy-select verbs (`select()`), with `@importFrom rlang .data`, as in dplyr's "Using dplyr in packages".
- Quarto documents render two formats: `gfm` (committed with its `<name>_files/` figures, so results show on GitHub) and `html` with `embed-resources: true` (git-ignored, for sharing). List `gfm` first: the embedded HTML render deletes `<name>_files/`.
- Set knitr chunk defaults under `knitr: opts_chunk:` in the YAML; `message` is a knitr option, not a Quarto `execute` option.
- FishBase country codes (`C_Code`) are ISO 3166 numeric strings: 566 Nigeria, 404 Kenya, 834 Tanzania.
- Code style: native pipe `|>`, namespaced calls (`dplyr::mutate()`), [tidyverse style guide](https://style.tidyverse.org), roxygen with markdown.
- Releases: bump `Version:` in `DESCRIPTION` and add a block at the top of `NEWS.md` (`# fishtrophic X.Y.Z`, a `##` headline, then `* **NEW**`, `* **CHANGED**` or `* **FIXED**` lines). Write each line for a non-technical reader, in plain words, with no function, file or column names.
- `README.md` is written by hand, for non-technical readers; keep it in step with the code.

## Behavioral guidelines

From [andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills/blob/main/CLAUDE.md).

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

### 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.
