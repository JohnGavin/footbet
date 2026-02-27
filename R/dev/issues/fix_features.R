# fix_features.R — Issue #8: Feature engineering targets
#
# Changes made:
# 1. Added compute_elo() to R/features.R — Elo ratings per league using elo pkg
# 2. Added devig_odds() to R/features.R — batch devig using Shin (1X2) and
#    power (O/U) methods
# 3. Completed plan_features.R with 7 targets:
#    - rolling_5, rolling_10, rolling_38 (rolling goal averages)
#    - matches_long (Poisson format)
#    - elo_ratings (per league)
#    - devigged_odds (Shin + power method)
#    - feature_matrix (combined join of all features)
# 4. Tests: unit + adversarial for compute_elo and devig_odds

if (FALSE) {
  devtools::load_all()

  # Quick test with mock data
  matches <- tibble::tibble(
    match_id = paste0("m", 1:6),
    match_date = as.Date("2024-01-01") + seq(0, 35, 7),
    home_team = rep(c("Arsenal", "Chelsea", "Spurs"), 2),
    away_team = rep(c("Chelsea", "Spurs", "Arsenal"), 2),
    fthg = c(2L, 1L, 0L, 3L, 1L, 2L),
    ftag = c(1L, 1L, 2L, 0L, 0L, 1L),
    ftr = c("H", "D", "A", "H", "H", "H"),
    season = "2324",
    league_code = "E0"
  )

  # Rolling goals
  rolling <- rolling_goals(matches, window = 3L)
  cat("Rolling goals:", nrow(rolling), "rows\n")

  # Elo
  elo <- compute_elo(matches)
  cat("Elo ratings:\n")
  print(elo)

  # Devig
  odds <- tibble::tibble(
    match_id = paste0("m", 1:3),
    psh = c(2.10, 3.40, 1.50),
    psd = c(3.40, 3.40, 4.20),
    psa = c(3.50, 2.10, 6.50),
    p_over25 = c(1.90, 1.85, 1.60),
    p_under25 = c(2.00, 2.05, 2.40)
  )
  devigged <- devig_odds(odds)
  cat("Devigged odds:\n")
  print(devigged)
}
