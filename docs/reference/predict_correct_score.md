# Predict correct score probabilities for a match

Computes probabilities for all scorelines and returns top predictions.

## Usage

``` r
predict_correct_score(model, home_team, away_team, max_goals = 7L, top_n = 10L)
```

## Arguments

- model:

  A fitted Poisson model (glm or similar).

- home_team:

  Character. Home team name.

- away_team:

  Character. Away team name.

- max_goals:

  Integer. Maximum goals to consider (default 7).

- top_n:

  Integer. Number of top scorelines to return (default 10).

## Value

A tibble with top scoreline predictions.

## See also

Other models:
[`correct_score_value()`](https://johngavin.github.io/footbet/reference/correct_score_value.md),
[`cv_xgboost()`](https://johngavin.github.io/footbet/reference/cv_xgboost.md),
[`ensemble_predict()`](https://johngavin.github.io/footbet/reference/ensemble_predict.md),
[`evaluate_brms()`](https://johngavin.github.io/footbet/reference/evaluate_brms.md),
[`evaluate_dc()`](https://johngavin.github.io/footbet/reference/evaluate_dc.md),
[`fit_brms_poisson()`](https://johngavin.github.io/footbet/reference/fit_brms_poisson.md),
[`fit_dixon_coles()`](https://johngavin.github.io/footbet/reference/fit_dixon_coles.md),
[`fit_poisson_glm()`](https://johngavin.github.io/footbet/reference/fit_poisson_glm.md),
[`fit_xgboost()`](https://johngavin.github.io/footbet/reference/fit_xgboost.md),
[`plot_xgb_importance()`](https://johngavin.github.io/footbet/reference/plot_xgb_importance.md),
[`predict_brms()`](https://johngavin.github.io/footbet/reference/predict_brms.md),
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
