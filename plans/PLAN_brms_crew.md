# PLAN: brms + crew parallelisation on laptop

**Tracks:** [#59](https://github.com/JohnGavin/footbet/issues/59) | Related: #77 (OAGD)
**Status:** Steps 1-4 complete — brms fits (8.4 min, 83K obs, Rhat 1.015), CV done (17 folds, RPS 0.210)
**Created:** 2026-04-03

## Context

brms (470 lines in `R/models_brms.R`) and 8 pipeline targets exist but have
never been executed. The project Nix shell (via `default.sh`) has brms, rstan,
StanHeaders, and crew all available. The blocker was not dependencies — it was
compute time without parallelisation.

## Problem

A single brms fit takes ~30 min (4 chains × 2000 iter). Walk-forward CV with
quarterly refits across 10 leagues needs ~40 fits. Sequential = ~20 hours.
Rolling-window (like OAGD) would need 380 fits = ~190 hours. Not feasible.

## Solution: crew on laptop

Use `crew` to parallelise brms fits across CPU cores. The laptop has N cores;
crew spawns persistent workers that each run one brms fit independently.

### Approach A: Parallelise chains within a single fit (quick win)

brms already supports `cores = 4` in `fit_brms_poisson()`. This runs 4 MCMC
chains in parallel on 4 cores. No crew needed — just set `cores = parallel::detectCores()`.

**Current state:** `fit_brms_poisson()` defaults to `cores = 4L`. This should
already parallelise chains. The bottleneck is *sequential fits across leagues/folds*.

### Approach B: Parallelise fits across leagues with crew (the real win)

Use `crew::crew_controller_local()` as the targets controller. Each league's
brms fit runs on a separate worker.

**Implementation:**

1. Add crew controller to `_targets.R`:
   ```r
   tar_option_set(
     controller = crew::crew_controller_local(workers = 4L, seconds_idle = 120)
   )
   ```

2. Mark brms targets with `deployment = "worker"`:
   ```r
   tar_target(brms_full_model, ..., deployment = "worker")
   ```

3. Use `tarchetypes::tar_map()` to fan out per-league fits:
   ```r
   tar_map(
     values = tibble(league = target_leagues()$code),
     tar_target(brms_league_fit, fit_brms_league(league), deployment = "worker")
   )
   ```

## 9-step workflow

### Step 0: Architecture (this plan)

Confirmed: brms, rstan, crew all in Nix shell. No new deps needed.

### Step 1: Verify brms fits in Nix shell

```bash
env -u R_LIBS_SITE -u R_LIBS -u R_LIBS_USER nix-shell default.nix --run \
  "timeout 600 Rscript -e '
    library(brms)
    # Minimal test: 2 chains × 500 iter on tiny data
    d <- data.frame(y = rpois(50, 1.5), x = rnorm(50), g = rep(1:5, 10))
    fit <- brm(y ~ x + (1|g), data = d, family = poisson(),
               chains = 2, iter = 500, warmup = 250, seed = 42, refresh = 0)
    cat(\"brms fit OK, Rhat:\", max(rhat(fit)), \"\n\")
  '"
```

If this segfaults (Rcpp/Stan issue), fix Nix env first.

### Step 2: Add rstan/StanHeaders to DESCRIPTION

```r
usethis::use_package("rstan", type = "Suggests")
# StanHeaders is a dependency of rstan, pulled in automatically
```

This makes the dependency explicit even though it's already in the Nix shell.

### Step 3: Wire crew controller in _targets.R

Add to `_targets.R` after `tar_option_set()`:

```r
if (requireNamespace("crew", quietly = TRUE)) {
  tar_option_set(
    controller = crew::crew_controller_local(
      workers = min(4L, parallel::detectCores() - 1L),
      seconds_idle = 120
    )
  )
}
```

### Step 4: Run brms targets sequentially first (baseline timing)

```bash
tar_make(names = c("brms_full_model", "brms_cv", "brms_eval_summary"))
```

Record wall-clock time. This gives the sequential baseline.

### Step 5: Fan out per-league fits with tar_map

Replace the single `brms_full_model` target with per-league fits using
`tarchetypes::tar_map()`:

```r
# In plan_models_brms.R
tarchetypes::tar_map(
  values = tibble::tibble(league_code = target_leagues()$code),
  targets::tar_target(
    brms_league_fit,
    {
      lg_data <- matches_long |> dplyr::filter(league_code == league_code)
      fit_brms_poisson(lg_data, chains = 4, iter = 2000, cores = 1)
    },
    deployment = "worker"
  )
)
```

Note `cores = 1` per worker — parallelism is across leagues, not chains.
With 10 leagues and 4 workers, this is ~3x speedup.

### Step 6: Test walk-forward CV with crew

The existing `evaluate_brms()` does walk-forward CV. Parallelise the folds:

```r
tarchetypes::tar_map(
  values = tibble::tibble(fold_id = 1:12),
  tar_target(brms_cv_fold, evaluate_brms_fold(fold_id), deployment = "worker")
)
```

### Step 7: Run and record results

Execute full pipeline with crew. Record:
- Wall-clock time (sequential vs crew)
- Memory per worker
- Any Stan convergence failures

### Step 8: Backtest brms against Pinnacle

Use `predict_matches_brms()` → `find_value_bets()` → `simulate_pnl()`.
Compare ROI against OAGD (-13.5%) and GLM (-7.9%) baselines.

### Step 9: Document in MODEL_CATALOGUE

Add brms results to the leaderboard. Update #59.

## Compute estimates

| Scenario | Fits | Per fit | Workers | Wall time |
|----------|-----:|--------:|--------:|----------:|
| Sequential (current) | 40 | ~3 min* | 1 | ~2 hours |
| crew 4 workers | 40 | ~3 min | 4 | ~30 min |
| crew 4, reduced iter (1000) | 40 | ~1.5 min | 4 | ~15 min |
| Per-league parallel (10 leagues) | 10 | ~3 min | 4 | ~8 min |

*Revised: Step 1 smoke test showed 28.5s for 500 iter on 100 obs. Real data
(~380 matches, 20 teams, 2000 iter) estimated ~2-5 min per fit. Stan compilation
is one-time (~28s), cached for subsequent fits with same model structure.

**Recommended:** Start with default `iter = 2000` — compute is manageable.

## Risks

| Risk | Mitigation |
|------|-----------|
| Stan compilation segfault in Nix | Step 1 tests this explicitly |
| Memory: 4 brms workers × 2GB each = 8GB | Monitor; reduce workers if needed |
| crew worker crashes silently | `crew::crew_controller_local(seconds_timeout = 1800)` |
| brms convergence failures on small league data | `tryCatch()` + log; already in plan_models_brms.R |
| Results no better than OAGD | Expected — document honestly in MODEL_CATALOGUE |
