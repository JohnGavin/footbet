# fix_glm_baseline.R — Issue #10: GLM Poisson baseline with walk-forward eval
#
# Changes made:
# 1. Added predict_glm() to R/models_baseline.R — predict match probs from GLM
# 2. Added predict_matches_glm() to R/models_baseline.R — batch predict
# 3. Added evaluate_glm_baseline() to R/models_eval.R — walk-forward CV
# 4. Added pinnacle_implied() to R/models_eval.R — benchmark implied probs
# 5. Added summarise_cv() to R/models_eval.R — aggregate metrics across folds
# 6. Completed plan_models.R with 3 targets:
#    - wf_splits (walk-forward date splits)
#    - glm_baseline_cv (per-fold fit+predict+score)
#    - pinnacle_benchmark (naive implied probs)
# 7. Completed plan_evaluation.R with 3 targets:
#    - glm_eval_summary (mean metrics across folds)
#    - pinnacle_eval (Pinnacle scoring rules)
#    - model_vs_pinnacle (comparison table)
# 8. Tests: unit + adversarial for all new exported functions

if (FALSE) {
  devtools::load_all()

  # Quick test with mock data
  set.seed(42)
  n <- 200
  teams <- c("Arsenal", "Chelsea", "Spurs", "Liverpool")
  dates <- seq.Date(as.Date("2022-01-01"), as.Date("2024-06-30"),
                     length.out = n)

  matches <- tibble::tibble(
    match_id = paste0("m", seq_len(n)),
    match_date = dates,
    home_team = sample(teams, n, replace = TRUE),
    away_team = sample(teams, n, replace = TRUE),
    fthg = as.integer(rpois(n, 1.4)),
    ftag = as.integer(rpois(n, 1.1)),
    season = "2324",
    league_code = "E0"
  )
  same <- matches$home_team == matches$away_team
  matches$away_team[same] <- teams[(match(matches$home_team[same], teams) %% 4) + 1]
  matches$ftr <- dplyr::case_when(
    matches$fthg > matches$ftag ~ "H",
    matches$fthg == matches$ftag ~ "D",
    TRUE ~ "A"
  )

  # Fit GLM
  long <- matches_to_long(matches)
  model <- fit_poisson_glm(long)
  cat("GLM coefficients:\n")
  print(coef(model)[1:5])

  # Predict
  pred <- predict_glm(model, "Arsenal", "Chelsea")
  cat("\nArsenal vs Chelsea 1X2:", round(pred$probs_1x2, 3), "\n")
  cat("O/U 2.5:", round(pred$probs_ou25, 3), "\n")

  # Walk-forward evaluation
  cv <- evaluate_glm_baseline(long, matches,
                               train_months = 18L, test_months = 1L)
  cat("\nWalk-forward CV results:\n")
  print(summarise_cv(cv))
}
