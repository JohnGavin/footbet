# Decompose Brier score into reliability, resolution, and uncertainty

The Murphy decomposition breaks Brier score into three components:

- **Reliability (calibration)**: How well predicted probabilities match
  observed frequencies. Lower is better.

- **Resolution**: How much predictions vary from the base rate. Higher
  is better (more informative forecasts).

- **Uncertainty**: Inherent difficulty of the prediction task based on
  outcome distribution. Cannot be improved by the model.

## Usage

``` r
brier_decomposition(predicted, actual, n_bins = 10L)
```

## Arguments

- predicted:

  Numeric vector. Predicted probabilities for the positive class.

- actual:

  Logical or 0/1 numeric. Actual outcomes.

- n_bins:

  Integer. Number of bins for calibration (default 10).

## Value

A tibble with `brier_score`, `reliability`, `resolution`, `uncertainty`,
and `brier_skill_score` (1 - BS/Uncertainty).

## Details

Formula: BS = Reliability - Resolution + Uncertainty

## References

Murphy, A.H. (1973). A New Vector Partition of the Probability Score.
Journal of Applied Meteorology, 12(4), 595-600.

## See also

Other evaluation:
[`bet_returns()`](https://johngavin.github.io/footbet/reference/bet_returns.md),
[`betting_sharpe_ratio()`](https://johngavin.github.io/footbet/reference/betting_sharpe_ratio.md),
[`brier_1x2()`](https://johngavin.github.io/footbet/reference/brier_1x2.md),
[`brier_decomposition_1x2()`](https://johngavin.github.io/footbet/reference/brier_decomposition_1x2.md),
[`closing_line_value()`](https://johngavin.github.io/footbet/reference/closing_line_value.md),
[`clv_1x2()`](https://johngavin.github.io/footbet/reference/clv_1x2.md),
[`compute_ensemble_weights()`](https://johngavin.github.io/footbet/reference/compute_ensemble_weights.md),
[`evaluate_glm_baseline()`](https://johngavin.github.io/footbet/reference/evaluate_glm_baseline.md),
[`evaluate_xgboost()`](https://johngavin.github.io/footbet/reference/evaluate_xgboost.md),
[`log_loss()`](https://johngavin.github.io/footbet/reference/log_loss.md),
[`pinnacle_implied()`](https://johngavin.github.io/footbet/reference/pinnacle_implied.md),
[`rps_1x2()`](https://johngavin.github.io/footbet/reference/rps_1x2.md),
[`summarise_betting_performance()`](https://johngavin.github.io/footbet/reference/summarise_betting_performance.md),
[`summarise_clv()`](https://johngavin.github.io/footbet/reference/summarise_clv.md),
[`summarise_cv()`](https://johngavin.github.io/footbet/reference/summarise_cv.md),
[`walk_forward_splits()`](https://johngavin.github.io/footbet/reference/walk_forward_splits.md)
