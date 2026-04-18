# Walk-forward CV for Ranger random forest (1X2 classification)

Fits a probability forest per fold using
[`ranger::ranger()`](http://imbs-hl.github.io/ranger/reference/ranger.md)
with `probability = TRUE`. Evaluates 1X2 predictions with log-loss,
Brier, and RPS — same metrics as
[`evaluate_glm_baseline()`](https://johngavin.github.io/footbet/reference/evaluate_glm_baseline.md).

## Usage

``` r
ranger_walkforward_cv(
  fm,
  feature_cols,
  train_months = 24L,
  test_months = 1L,
  league_code = NA_character_,
  num_trees = 500L
)
```

## Arguments

- fm:

  Feature matrix (wide format, one row per match) with `match_date`,
  `ftr`, and numeric feature columns.

- feature_cols:

  Character vector of feature column names.

- train_months:

  Integer. Training window (default 24).

- test_months:

  Integer. Test period (default 1).

- league_code:

  Character. League label for output.

- num_trees:

  Integer. Number of trees (default 500).

## Value

A tibble with one row per fold and scoring metrics.

## Details

Ranger handles correlated features and nonlinear interactions naturally,
so shot quality features that hurt the Poisson GLM can be included
safely.

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
[`reliability_curve_data()`](https://johngavin.github.io/footbet/reference/reliability_curve_data.md),
[`rps_1x2()`](https://johngavin.github.io/footbet/reference/rps_1x2.md),
[`summarise_betting_performance()`](https://johngavin.github.io/footbet/reference/summarise_betting_performance.md),
[`summarise_clv()`](https://johngavin.github.io/footbet/reference/summarise_clv.md),
[`summarise_cv()`](https://johngavin.github.io/footbet/reference/summarise_cv.md),
[`walk_forward_splits()`](https://johngavin.github.io/footbet/reference/walk_forward_splits.md),
[`xgboost_walkforward_cv()`](https://johngavin.github.io/footbet/reference/xgboost_walkforward_cv.md)
