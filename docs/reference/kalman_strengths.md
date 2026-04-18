# Run Kalman filter over a season for one league

Processes matches chronologically, updating team strengths after each
match. Each team has two state variables: attack and defence.

## Usage

``` r
kalman_strengths(
  matches,
  sigma_process = 0.05,
  sigma_obs = 0.7,
  use_xg = TRUE,
  record_innovations = FALSE
)
```

## Arguments

- matches:

  Tibble with `match_date`, `home_team`, `away_team`, `home_xg` (or
  `fthg`), `away_xg` (or `ftag`). Must be sorted by date.

- sigma_process:

  Numeric. Process noise SD (default 0.05). Controls how fast team
  strength can change between matches.

- sigma_obs:

  Numeric. Observation noise SD (default 0.7). Single-match xG/goals
  noise.

- use_xg:

  Logical. If TRUE, use `home_xg`/`away_xg` columns. If FALSE, use
  `fthg`/`ftag` (default TRUE).

- record_innovations:

  Logical. If TRUE, return a list with both `strengths` and
  `innovations` (a tibble with `match_date`, `home_team`, `away_team`,
  `side` ("home"/"away"), `observation`, `y_hat`, `S`, `innovation`,
  `std_innovation`). Use post-hoc to diagnose regime breaks:
  `abs(std_innovation) > 3` sustained over several matches for a given
  team suggests a structural change not captured by the steady-state
  process noise. Default FALSE for backwards compatibility.

## Value

A tibble with `team`, `match_date`, `matchday`, `attack`, `defence`
(pre-match strength estimates). If `record_innovations = TRUE`, a list
with `strengths` and `innovations`.

## See also

Other models:
[`blend_with_market()`](https://johngavin.github.io/footbet/reference/blend_with_market.md),
[`brms_ah_ci()`](https://johngavin.github.io/footbet/reference/brms_ah_ci.md),
[`brms_converged()`](https://johngavin.github.io/footbet/reference/brms_converged.md),
[`brms_diagnostics()`](https://johngavin.github.io/footbet/reference/brms_diagnostics.md),
[`brms_loo()`](https://johngavin.github.io/footbet/reference/brms_loo.md),
[`brms_r2()`](https://johngavin.github.io/footbet/reference/brms_r2.md),
[`brms_waic()`](https://johngavin.github.io/footbet/reference/brms_waic.md),
[`correct_score_value()`](https://johngavin.github.io/footbet/reference/correct_score_value.md),
[`cv_xgboost()`](https://johngavin.github.io/footbet/reference/cv_xgboost.md),
[`dc_score_matrix()`](https://johngavin.github.io/footbet/reference/dc_score_matrix.md),
[`dc_tau()`](https://johngavin.github.io/footbet/reference/dc_tau.md),
[`dskellam()`](https://johngavin.github.io/footbet/reference/dskellam.md),
[`edge_credible_interval()`](https://johngavin.github.io/footbet/reference/edge_credible_interval.md),
[`ensemble_predict()`](https://johngavin.github.io/footbet/reference/ensemble_predict.md),
[`evaluate_brms()`](https://johngavin.github.io/footbet/reference/evaluate_brms.md),
[`evaluate_dc()`](https://johngavin.github.io/footbet/reference/evaluate_dc.md),
[`fit_brms_poisson()`](https://johngavin.github.io/footbet/reference/fit_brms_poisson.md),
[`fit_dixon_coles()`](https://johngavin.github.io/footbet/reference/fit_dixon_coles.md),
[`fit_poisson_glm()`](https://johngavin.github.io/footbet/reference/fit_poisson_glm.md),
[`fit_xgboost()`](https://johngavin.github.io/footbet/reference/fit_xgboost.md),
[`kalman`](https://johngavin.github.io/footbet/reference/kalman.md),
[`kalman_tune()`](https://johngavin.github.io/footbet/reference/kalman_tune.md),
[`kalman_update()`](https://johngavin.github.io/footbet/reference/kalman_update.md),
[`lambdas_from_hda()`](https://johngavin.github.io/footbet/reference/lambdas_from_hda.md),
[`oagd`](https://johngavin.github.io/footbet/reference/oagd.md),
[`oagd_add_odds()`](https://johngavin.github.io/footbet/reference/oagd_add_odds.md),
[`oagd_fit_window()`](https://johngavin.github.io/footbet/reference/oagd_fit_window.md),
[`oagd_form()`](https://johngavin.github.io/footbet/reference/oagd_form.md),
[`oagd_match_data()`](https://johngavin.github.io/footbet/reference/oagd_match_data.md),
[`oagd_predict`](https://johngavin.github.io/footbet/reference/oagd_predict.md),
[`oagd_predict_all()`](https://johngavin.github.io/footbet/reference/oagd_predict_all.md),
[`oagd_predict_match()`](https://johngavin.github.io/footbet/reference/oagd_predict_match.md),
[`oagd_residuals()`](https://johngavin.github.io/footbet/reference/oagd_residuals.md),
[`oagd_roll_fits()`](https://johngavin.github.io/footbet/reference/oagd_roll_fits.md),
[`plot_xgb_importance()`](https://johngavin.github.io/footbet/reference/plot_xgb_importance.md),
[`predict_ah()`](https://johngavin.github.io/footbet/reference/predict_ah.md),
[`predict_brms()`](https://johngavin.github.io/footbet/reference/predict_brms.md),
[`predict_correct_score()`](https://johngavin.github.io/footbet/reference/predict_correct_score.md),
[`predict_dc()`](https://johngavin.github.io/footbet/reference/predict_dc.md),
[`predict_glm()`](https://johngavin.github.io/footbet/reference/predict_glm.md),
[`predict_matches_brms()`](https://johngavin.github.io/footbet/reference/predict_matches_brms.md),
[`predict_matches_dc()`](https://johngavin.github.io/footbet/reference/predict_matches_dc.md),
[`predict_matches_glm()`](https://johngavin.github.io/footbet/reference/predict_matches_glm.md),
[`predict_matches_xgb()`](https://johngavin.github.io/footbet/reference/predict_matches_xgb.md),
[`predict_ou()`](https://johngavin.github.io/footbet/reference/predict_ou.md),
[`predict_xgboost()`](https://johngavin.github.io/footbet/reference/predict_xgboost.md),
[`prepare_xgb_features()`](https://johngavin.github.io/footbet/reference/prepare_xgb_features.md),
[`score_matrix()`](https://johngavin.github.io/footbet/reference/score_matrix.md),
[`score_matrix_probs()`](https://johngavin.github.io/footbet/reference/score_matrix_probs.md),
[`score_matrix_to_1x2()`](https://johngavin.github.io/footbet/reference/score_matrix_to_1x2.md),
[`score_matrix_to_ah()`](https://johngavin.github.io/footbet/reference/score_matrix_to_ah.md),
[`score_matrix_to_ou()`](https://johngavin.github.io/footbet/reference/score_matrix_to_ou.md),
[`score_probability()`](https://johngavin.github.io/footbet/reference/score_probability.md),
[`temporal_split()`](https://johngavin.github.io/footbet/reference/temporal_split.md),
[`top_scorelines()`](https://johngavin.github.io/footbet/reference/top_scorelines.md),
[`tune_xgboost()`](https://johngavin.github.io/footbet/reference/tune_xgboost.md)
