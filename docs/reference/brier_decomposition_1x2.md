# Decompose Brier score for 1X2 predictions

Applies
[`brier_decomposition()`](https://johngavin.github.io/footbet/reference/brier_decomposition.md)
separately for each outcome class (Home, Draw, Away) and combines
results.

## Usage

``` r
brier_decomposition_1x2(prob_h, prob_d, prob_a, actual, n_bins = 10L)
```

## Arguments

- prob_h:

  Numeric vector. Predicted P(Home win).

- prob_d:

  Numeric vector. Predicted P(Draw).

- prob_a:

  Numeric vector. Predicted P(Away win).

- actual:

  Character vector. Actual result ("H", "D", or "A").

- n_bins:

  Integer. Number of bins (default 10).

## Value

A tibble with decomposition for each outcome and overall.

## See also

Other evaluation:
[`bet_returns()`](https://johngavin.github.io/footbet/reference/bet_returns.md),
[`betting_sharpe_ratio()`](https://johngavin.github.io/footbet/reference/betting_sharpe_ratio.md),
[`brier_1x2()`](https://johngavin.github.io/footbet/reference/brier_1x2.md),
[`brier_decomposition()`](https://johngavin.github.io/footbet/reference/brier_decomposition.md),
[`closing_line_value()`](https://johngavin.github.io/footbet/reference/closing_line_value.md),
[`clv_1x2()`](https://johngavin.github.io/footbet/reference/clv_1x2.md),
[`collect_fold_predictions()`](https://johngavin.github.io/footbet/reference/collect_fold_predictions.md),
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
