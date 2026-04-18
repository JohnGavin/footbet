# Collect match-level predictions from walk-forward CV

Runs the same walk-forward split as
[`evaluate_glm_baseline()`](https://johngavin.github.io/footbet/reference/evaluate_glm_baseline.md)
but returns per-match predictions instead of per-fold summary metrics.
Used for calibration plots (reliability curves).

## Usage

``` r
collect_fold_predictions(
  long_df,
  matches_df,
  train_months = 24L,
  test_months = 1L,
  model_label = "model"
)
```

## Arguments

- long_df:

  Long-format match data for GLM fitting.

- matches_df:

  Wide-format matches with `match_id`, `ftr`, `match_date`,
  `league_code`.

- train_months:

  Integer. Training window (default 24).

- test_months:

  Integer. Test period (default 1).

- model_label:

  Character. Label for the model (e.g., "goals_only").

## Value

A tibble with `match_id`, `league_code`, `pred_h`, `pred_d`, `pred_a`,
`actual`, `model`.

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
[`consensus_implied()`](https://johngavin.github.io/footbet/reference/consensus_implied.md),
[`evaluate_glm_baseline()`](https://johngavin.github.io/footbet/reference/evaluate_glm_baseline.md),
[`evaluate_market_baselines()`](https://johngavin.github.io/footbet/reference/evaluate_market_baselines.md),
[`evaluate_xgboost()`](https://johngavin.github.io/footbet/reference/evaluate_xgboost.md),
[`log_loss()`](https://johngavin.github.io/footbet/reference/log_loss.md),
[`pinnacle_implied()`](https://johngavin.github.io/footbet/reference/pinnacle_implied.md),
[`ranger_walkforward_cv()`](https://johngavin.github.io/footbet/reference/ranger_walkforward_cv.md),
[`reliability_curve_data()`](https://johngavin.github.io/footbet/reference/reliability_curve_data.md),
[`rps_1x2()`](https://johngavin.github.io/footbet/reference/rps_1x2.md),
[`summarise_betting_performance()`](https://johngavin.github.io/footbet/reference/summarise_betting_performance.md),
[`summarise_clv()`](https://johngavin.github.io/footbet/reference/summarise_clv.md),
[`summarise_cv()`](https://johngavin.github.io/footbet/reference/summarise_cv.md),
[`walk_forward_splits()`](https://johngavin.github.io/footbet/reference/walk_forward_splits.md),
[`xgboost_walkforward_cv()`](https://johngavin.github.io/footbet/reference/xgboost_walkforward_cv.md)
