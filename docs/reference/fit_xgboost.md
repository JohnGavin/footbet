# Fit XGBoost model for match outcome prediction

Trains an XGBoost classifier for predicting match outcomes (H/D/A) or
goals. Supports multi-class classification and regression.

## Usage

``` r
fit_xgboost(
  matches,
  features = NULL,
  target = "ftr",
  params = NULL,
  nrounds = 100L,
  early_stopping = 10L,
  verbose = 0L
)
```

## Arguments

- matches:

  A tibble with match data including features and outcome.

- features:

  Character vector of feature column names. If NULL, uses default
  feature set.

- target:

  Character. Target column: "ftr" for outcome (H/D/A), "fthg" for home
  goals, "ftag" for away goals.

- params:

  List of XGBoost parameters. Defaults provided for classification or
  regression based on target.

- nrounds:

  Integer. Number of boosting rounds (default 100).

- early_stopping:

  Integer. Rounds without improvement to stop (default 10). Set to NULL
  to disable.

- verbose:

  Integer. Verbosity level (0 = silent, default).

## Value

A list with `model` (xgb.Booster), `feature_names`, `target`, `params`,
and `importance`.

## See also

Other models:
[`brms_converged()`](https://johngavin.github.io/footbet/reference/brms_converged.md),
[`brms_diagnostics()`](https://johngavin.github.io/footbet/reference/brms_diagnostics.md),
[`brms_loo()`](https://johngavin.github.io/footbet/reference/brms_loo.md),
[`brms_r2()`](https://johngavin.github.io/footbet/reference/brms_r2.md),
[`brms_waic()`](https://johngavin.github.io/footbet/reference/brms_waic.md),
[`correct_score_value()`](https://johngavin.github.io/footbet/reference/correct_score_value.md),
[`cv_xgboost()`](https://johngavin.github.io/footbet/reference/cv_xgboost.md),
[`edge_credible_interval()`](https://johngavin.github.io/footbet/reference/edge_credible_interval.md),
[`ensemble_predict()`](https://johngavin.github.io/footbet/reference/ensemble_predict.md),
[`evaluate_brms()`](https://johngavin.github.io/footbet/reference/evaluate_brms.md),
[`evaluate_dc()`](https://johngavin.github.io/footbet/reference/evaluate_dc.md),
[`fit_brms_poisson()`](https://johngavin.github.io/footbet/reference/fit_brms_poisson.md),
[`fit_dixon_coles()`](https://johngavin.github.io/footbet/reference/fit_dixon_coles.md),
[`fit_poisson_glm()`](https://johngavin.github.io/footbet/reference/fit_poisson_glm.md),
[`plot_xgb_importance()`](https://johngavin.github.io/footbet/reference/plot_xgb_importance.md),
[`predict_brms()`](https://johngavin.github.io/footbet/reference/predict_brms.md),
[`predict_correct_score()`](https://johngavin.github.io/footbet/reference/predict_correct_score.md),
[`predict_dc()`](https://johngavin.github.io/footbet/reference/predict_dc.md),
[`predict_glm()`](https://johngavin.github.io/footbet/reference/predict_glm.md),
[`predict_matches_brms()`](https://johngavin.github.io/footbet/reference/predict_matches_brms.md),
[`predict_matches_dc()`](https://johngavin.github.io/footbet/reference/predict_matches_dc.md),
[`predict_matches_glm()`](https://johngavin.github.io/footbet/reference/predict_matches_glm.md),
[`predict_matches_xgb()`](https://johngavin.github.io/footbet/reference/predict_matches_xgb.md),
[`predict_xgboost()`](https://johngavin.github.io/footbet/reference/predict_xgboost.md),
[`prepare_xgb_features()`](https://johngavin.github.io/footbet/reference/prepare_xgb_features.md),
[`score_matrix()`](https://johngavin.github.io/footbet/reference/score_matrix.md),
[`score_matrix_to_1x2()`](https://johngavin.github.io/footbet/reference/score_matrix_to_1x2.md),
[`score_matrix_to_ah()`](https://johngavin.github.io/footbet/reference/score_matrix_to_ah.md),
[`score_matrix_to_ou()`](https://johngavin.github.io/footbet/reference/score_matrix_to_ou.md),
[`score_probability()`](https://johngavin.github.io/footbet/reference/score_probability.md),
[`top_scorelines()`](https://johngavin.github.io/footbet/reference/top_scorelines.md),
[`tune_xgboost()`](https://johngavin.github.io/footbet/reference/tune_xgboost.md)
