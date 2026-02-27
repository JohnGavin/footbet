# fix_dixon_coles.R — Issue #12: Dixon-Coles model with goalmodel
#
# Changes made:
# 1. Enhanced fit_dixon_coles() — added input validation, required columns check
# 2. Enhanced predict_dc() — now returns O/U, AH probs + expected goals
# 3. Added predict_matches_dc() — batch prediction for all matches
# 4. Added evaluate_dc() — walk-forward cross-validation
# 5. Updated plan_models.R — added dc_cv target
# 6. Updated plan_evaluation.R — added dc_eval_summary, multi-model comparison
# 7. Tests: unit + adversarial for all DC functions

if (FALSE) {
  devtools::load_all()

  set.seed(42)
  n <- 200
  teams <- c("Arsenal", "Chelsea", "Spurs", "Liverpool", "ManCity", "ManUtd")
  matches <- tibble::tibble(
    match_id = paste0("m", seq_len(n)),
    match_date = seq.Date(as.Date("2022-01-01"), as.Date("2024-06-30"),
                           length.out = n),
    home_team = sample(teams, n, replace = TRUE),
    away_team = sample(teams, n, replace = TRUE),
    fthg = as.integer(rpois(n, 1.4)),
    ftag = as.integer(rpois(n, 1.1)),
    season = "2324",
    league_code = "E0"
  )
  same <- matches$home_team == matches$away_team
  matches$away_team[same] <- teams[(match(matches$home_team[same], teams) %% 6) + 1]
  matches$ftr <- dplyr::case_when(
    matches$fthg > matches$ftag ~ "H",
    matches$fthg == matches$ftag ~ "D",
    TRUE ~ "A"
  )

  # Fit DC model
  model <- fit_dixon_coles(matches)
  cat("DC model attack params:\n")
  print(head(model$parameters$attack))

  # Predict
  pred <- predict_dc(model, "Arsenal", "Chelsea")
  cat("\nArsenal vs Chelsea 1X2:", round(pred$probs_1x2, 3), "\n")
  cat("O/U 2.5:", round(pred$probs_ou25, 3), "\n")

  # Walk-forward
  cv <- evaluate_dc(matches, train_months = 18L, test_months = 1L)
  cat("\nDC walk-forward CV:\n")
  print(summarise_cv(cv))
}
