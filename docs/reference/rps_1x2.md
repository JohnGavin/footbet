# Compute Ranked Probability Score for ordered outcomes

Better than Brier for ordered categories (H \> D \> A is ordered by goal
difference).

## Usage

``` r
rps_1x2(prob_h, prob_d, prob_a, actual)
```

## Arguments

- prob_h:

  Numeric vector.

- prob_d:

  Numeric vector.

- prob_a:

  Numeric vector.

- actual:

  Character vector ("H", "D", or "A").

## Value

Numeric. Mean RPS (lower is better).

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
[`evaluate_market_baselines()`](https://johngavin.github.io/footbet/reference/evaluate_market_baselines.md),
[`evaluate_xgboost()`](https://johngavin.github.io/footbet/reference/evaluate_xgboost.md),
[`log_loss()`](https://johngavin.github.io/footbet/reference/log_loss.md),
[`pinnacle_implied()`](https://johngavin.github.io/footbet/reference/pinnacle_implied.md),
[`ranger_walkforward_cv()`](https://johngavin.github.io/footbet/reference/ranger_walkforward_cv.md),
[`reliability_curve_data()`](https://johngavin.github.io/footbet/reference/reliability_curve_data.md),
[`summarise_betting_performance()`](https://johngavin.github.io/footbet/reference/summarise_betting_performance.md),
[`summarise_clv()`](https://johngavin.github.io/footbet/reference/summarise_clv.md),
[`summarise_cv()`](https://johngavin.github.io/footbet/reference/summarise_cv.md),
[`walk_forward_splits()`](https://johngavin.github.io/footbet/reference/walk_forward_splits.md),
[`xgboost_walkforward_cv()`](https://johngavin.github.io/footbet/reference/xgboost_walkforward_cv.md)
