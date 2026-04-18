# NA

## Key Documents

- [`plans/MODEL_CATALOGUE.md`](https://johngavin.github.io/footbet/plans/MODEL_CATALOGUE.md)
  — All prediction models with results, lessons, and leaderboard. Update
  when adding new models.
- [`plans/PLAN_oagd_model.md`](https://johngavin.github.io/footbet/plans/PLAN_oagd_model.md)
  — OAGD model design (Johnson/Gans-Kominers approach)
- [`plans/IMPL_oagd_model.md`](https://johngavin.github.io/footbet/plans/IMPL_oagd_model.md)
  — OAGD implementation steps and progress
- [`plans/PLAN_brms_crew.md`](https://johngavin.github.io/footbet/plans/PLAN_brms_crew.md)
  — brms + crew parallelisation plan (9-step)
- [`plans/PLAN_xg_kalman_dc.md`](https://johngavin.github.io/footbet/plans/PLAN_xg_kalman_dc.md)
  — xG + Kalman filter + Dixon-Coles correction (5-phase)
- [`plans/PLAN_ah_improvements.md`](https://johngavin.github.io/footbet/plans/PLAN_ah_improvements.md)
  — AH market: Kelly staking, xGK fixes, brms CI betting
- [`CHANGELOG.md`](https://johngavin.github.io/footbet/CHANGELOG.md) —
  Session lab notes, experiment results, failed approaches

## CRITICAL: Package Context (ctx.yaml)

**Central cache:** `~/docs_gh/proj/data/llm/content/inst/ctx/external/`

**To check ctx coverage, ALWAYS run:**

``` r
source("~/docs_gh/llm/R/tar_plans/plan_pkgctx.R")
ctx_audit("DESCRIPTION")
```

**To fix missing ctx:**

``` r
source("~/docs_gh/llm/R/tar_plans/plan_pkgctx.R")
ctx_sync("DESCRIPTION")
```

**NEVER** write your own ctx checking code. NEVER look in
`.claude/context/` or `inst/ctx/`. ALWAYS use `ctx_audit()` from
`plan_pkgctx.R`.
