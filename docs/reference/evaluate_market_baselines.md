# Evaluate market baselines (Pinnacle + consensus) against actual results

Computes log-loss, Brier, and RPS for Pinnacle and consensus implied
probabilities. These are the benchmarks all models must beat.

## Usage

``` r
evaluate_market_baselines(odds_df, matches_df)
```

## Arguments

- odds_df:

  Parsed odds with `match_id`, `psh/psd/psa`, `avg_h/avg_d/avg_a`.

- matches_df:

  Parsed matches with `match_id`, `ftr`, `league_code`.

## Value

A tibble with per-league calibration metrics for both baselines.

## See also

Other evaluation:
[`bet_returns()`](https://johngavin.github.io/footbet/reference/bet_returns.md),
[`betting_sharpe_ratio()`](https://johngavin.github.io/footbet/reference/betting_sharpe_ratio.md),
[`brier_1x2()`](https://johngavin.github.io/footbet/reference/brier_1x2.md),
[`brier_decomposition()`](https://johngavin.github.io/footbet/reference/brier_decomposition.md),
[`brier_decomposition_1x2()`](https://johngavin.github.io/footbet/reference/brier_decomposition_1x2.md),
[`closing_line_value()`](https://johngavin.github.io/footbet/reference/closing_line_value.md),
[`clv_1x2()`](https://johngavin.github.io/footbet/reference/clv_1x2.md),
[`collect_fold_predictions()`](https://johngavin.github.io/footbet/reference/collect_fold_predictions.md),
[`compute_ensemble_weights()`](https://johngavin.github.io/footbet/reference/compute_ensemble_weights.md),
[`consensus_implied()`](https://johngavin.github.io/footbet/reference/consensus_implied.md),
[`evaluate_glm_baseline()`](https://johngavin.github.io/footbet/reference/evaluate_glm_baseline.md),
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
