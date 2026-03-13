# Run walk-forward evaluation for the Poisson GLM baseline

For each time split, fits
[`fit_poisson_glm()`](https://johngavin.github.io/footbet/reference/fit_poisson_glm.md)
on the training set, predicts on the test set, and computes scoring
metrics.

## Usage

``` r
evaluate_glm_baseline(
  long_df,
  matches_df,
  train_months = 24L,
  test_months = 1L
)
```

## Arguments

- long_df:

  Long-format match data from
  [`matches_to_long()`](https://johngavin.github.io/footbet/reference/matches_to_long.md).

- matches_df:

  Original match data (wide format) with `match_id`, `ftr`.

- train_months:

  Integer. Training window (default 24).

- test_months:

  Integer. Test period (default 1).

## Value

A tibble with one row per fold and columns for log_loss, brier, rps,
fold number, n_train, n_test.

## See also

Other evaluation:
[`bet_returns()`](https://johngavin.github.io/footbet/reference/bet_returns.md),
[`betting_sharpe_ratio()`](https://johngavin.github.io/footbet/reference/betting_sharpe_ratio.md),
[`brier_1x2()`](https://johngavin.github.io/footbet/reference/brier_1x2.md),
[`brier_decomposition()`](https://johngavin.github.io/footbet/reference/brier_decomposition.md),
[`brier_decomposition_1x2()`](https://johngavin.github.io/footbet/reference/brier_decomposition_1x2.md),
[`closing_line_value()`](https://johngavin.github.io/footbet/reference/closing_line_value.md),
[`clv_1x2()`](https://johngavin.github.io/footbet/reference/clv_1x2.md),
[`compute_ensemble_weights()`](https://johngavin.github.io/footbet/reference/compute_ensemble_weights.md),
[`evaluate_xgboost()`](https://johngavin.github.io/footbet/reference/evaluate_xgboost.md),
[`log_loss()`](https://johngavin.github.io/footbet/reference/log_loss.md),
[`pinnacle_implied()`](https://johngavin.github.io/footbet/reference/pinnacle_implied.md),
[`rps_1x2()`](https://johngavin.github.io/footbet/reference/rps_1x2.md),
[`summarise_betting_performance()`](https://johngavin.github.io/footbet/reference/summarise_betting_performance.md),
[`summarise_clv()`](https://johngavin.github.io/footbet/reference/summarise_clv.md),
[`summarise_cv()`](https://johngavin.github.io/footbet/reference/summarise_cv.md),
[`walk_forward_splits()`](https://johngavin.github.io/footbet/reference/walk_forward_splits.md)
