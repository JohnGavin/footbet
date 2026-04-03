

## Key Documents

- [`plans/MODEL_CATALOGUE.md`](plans/MODEL_CATALOGUE.md) — All prediction models with results, lessons, and leaderboard. Update when adding new models.
- [`plans/PLAN_oagd_model.md`](plans/PLAN_oagd_model.md) — OAGD model design (Johnson/Gans-Kominers approach)
- [`plans/IMPL_oagd_model.md`](plans/IMPL_oagd_model.md) — OAGD implementation steps and progress
- [`CHANGELOG.md`](CHANGELOG.md) — Session lab notes, experiment results, failed approaches

## CRITICAL: Package Context (ctx.yaml)

**Central cache:** `~/docs_gh/proj/data/llm/content/inst/ctx/external/`

**To check ctx coverage, ALWAYS run:**
```r
source("~/docs_gh/llm/R/tar_plans/plan_pkgctx.R")
ctx_audit("DESCRIPTION")
```

**To fix missing ctx:**
```r
source("~/docs_gh/llm/R/tar_plans/plan_pkgctx.R")
ctx_sync("DESCRIPTION")
```

**NEVER** write your own ctx checking code. NEVER look in `.claude/context/` or `inst/ctx/`. ALWAYS use `ctx_audit()` from `plan_pkgctx.R`.

