# Snapshot tests for ALL cli_abort/cli_warn messages across the package.
# Ensures user-facing error/warning messages don't change unexpectedly.
# Review changes with: testthat::snapshot_review()

# ============================================================================
# SECTION 1: cli_abort error message snapshots
# ============================================================================

# ---- utils.R ----

test_that("fd_url: error on non-string league_code", {

  expect_snapshot(error = TRUE, fd_url(123, "2324"))
})

test_that("fd_url: error on non-string season", {
  expect_snapshot(error = TRUE, fd_url("E0", 2324))
})

test_that("fd_url: error on invalid season format", {
  expect_snapshot(error = TRUE, fd_url("E0", "24"))
})

# ---- devig.R ----

test_that("devig_basic: error on empty odds", {
  expect_snapshot(error = TRUE, devig_basic(numeric(0)))
})

test_that("devig_basic: error on non-numeric odds", {
  expect_snapshot(error = TRUE, devig_basic("abc"))
})

test_that("devig_basic: error on Inf odds", {
  expect_snapshot(error = TRUE, devig_basic(c(2.0, Inf)))
})

test_that("devig_basic: error on odds <= 1", {
  expect_snapshot(error = TRUE, devig_basic(c(0.5, 2.0)))
})

test_that("devig_shin: error on non-3 odds", {
  expect_snapshot(error = TRUE, devig_shin(c(2.0, 3.0)))
})

# ---- kelly.R ----

test_that("kelly_fraction: error on prob_win out of range", {
  expect_snapshot(error = TRUE, kelly_fraction(0, 2.0))
})

test_that("kelly_fraction: error on decimal_odds <= 1", {
  expect_snapshot(error = TRUE, kelly_fraction(0.5, 1.0))
})

test_that("find_value_bets: error on non-data-frame inputs", {
  expect_snapshot(error = TRUE, find_value_bets("x", "y", "z"))
})

test_that("simulate_pnl: error on non-data-frame bets", {
  expect_snapshot(error = TRUE, simulate_pnl("not_a_df"))
})

# ---- models_eval.R ----

test_that("log_loss: error on non-numeric prob", {
  expect_snapshot(error = TRUE, log_loss("abc"))
})

test_that("log_loss: error on empty prob", {
  expect_snapshot(error = TRUE, log_loss(numeric(0)))
})

test_that("evaluate_glm_baseline: error on non-df long_df", {
  expect_snapshot(error = TRUE, evaluate_glm_baseline("x", tibble::tibble()))
})

test_that("evaluate_glm_baseline: error on non-df matches_df", {
  expect_snapshot(error = TRUE, evaluate_glm_baseline(tibble::tibble(), "x"))
})

test_that("closing_line_value: error on length mismatch", {
  expect_snapshot(error = TRUE, closing_line_value(c(0.5, 0.6), c(2.0)))
})

test_that("ensemble_predict: error on non-list predictions", {
  expect_snapshot(error = TRUE, ensemble_predict("not_a_list"))
})

test_that("ensemble_predict: error on unnamed list", {
  expect_snapshot(error = TRUE, ensemble_predict(list(tibble::tibble(), tibble::tibble())))
})

test_that("compute_ensemble_weights: error on single model", {
  expect_snapshot(error = TRUE, compute_ensemble_weights(list(a = tibble::tibble(log_loss = 1))))
})

test_that("compute_ensemble_weights: error on unnamed cv_results", {
  expect_snapshot(
    error = TRUE,
    compute_ensemble_weights(list(tibble::tibble(log_loss = 1), tibble::tibble(log_loss = 2)))
  )
})

test_that("betting_sharpe_ratio: error on non-numeric returns", {
  expect_snapshot(error = TRUE, betting_sharpe_ratio("abc"))
})

test_that("decimal_to_fractional: error on non-numeric", {
  expect_snapshot(error = TRUE, decimal_to_fractional("abc"))
})

test_that("decimal_to_american: error on non-numeric", {
  expect_snapshot(error = TRUE, decimal_to_american("abc"))
})

test_that("american_to_decimal: error on non-numeric", {
  expect_snapshot(error = TRUE, american_to_decimal("abc"))
})

test_that("fractional_to_decimal: error on non-character", {
  expect_snapshot(error = TRUE, fractional_to_decimal(2.5))
})

test_that("brier_decomposition: error on length mismatch", {
  expect_snapshot(error = TRUE, brier_decomposition(c(0.5, 0.6), c(1)))
})

test_that("empirical_bayes_shrink: error on length mismatch", {
  expect_snapshot(error = TRUE, empirical_bayes_shrink(c(1, 2, 3), c(10, 20)))
})

test_that("convert_odds: error on invalid from format", {
  expect_snapshot(error = TRUE, convert_odds(2.0, "bogus", "decimal"))
})

test_that("convert_odds: error on invalid to format", {
  expect_snapshot(error = TRUE, convert_odds(2.0, "decimal", "bogus"))
})

test_that("shrink_team_strength: error on missing columns", {
  expect_snapshot(error = TRUE, shrink_team_strength(tibble::tibble(x = 1)))
})

test_that("stat_discrimination: error on missing entity_col", {
  expect_snapshot(error = TRUE, stat_discrimination(tibble::tibble(x = 1), entity_col = "team"))
})

test_that("stat_stability: error on missing columns", {
  expect_snapshot(error = TRUE, stat_stability(tibble::tibble(x = 1)))
})

# ---- betting.R ----

test_that("acca_odds: error on non-numeric odds", {
  expect_snapshot(error = TRUE, acca_odds("abc"))
})

test_that("acca_odds: error on odds < 1", {
  expect_snapshot(error = TRUE, acca_odds(c(0.5, 2.0)))
})

test_that("acca_ev: error on length mismatch", {
  expect_snapshot(error = TRUE, acca_ev(c(0.5), c(2.0, 3.0)))
})

test_that("acca_ev: error on non-numeric arguments", {
  expect_snapshot(error = TRUE, acca_ev("a", "b"))
})

test_that("find_best_accas: error on missing columns", {
  expect_snapshot(error = TRUE, find_best_accas(tibble::tibble(x = 1)))
})

test_that("multi_kelly_stakes: error on length mismatch", {
  expect_snapshot(error = TRUE, multi_kelly_stakes(c(0.5, 0.6), c(2.0)))
})

test_that("bankroll_growth_target: error on non-positive bankroll", {
  expect_snapshot(error = TRUE, bankroll_growth_target(0, 1000))
})

test_that("bankroll_growth_target: error on target <= current", {
  expect_snapshot(error = TRUE, bankroll_growth_target(1000, 500))
})

test_that("line_movement: error on missing Bet365 odds", {
  expect_snapshot(error = TRUE, line_movement(tibble::tibble(psh = 1, psd = 1, psa = 1)))
})

test_that("line_movement: error on missing Pinnacle odds", {
  expect_snapshot(error = TRUE, line_movement(tibble::tibble(b365h = 1, b365d = 1, b365a = 1)))
})

test_that("analyze_steam_moves: error on length mismatch", {
  df <- tibble::tibble(x = 1:3)
  expect_snapshot(error = TRUE, analyze_steam_moves(df, c("H", "D")))
})

test_that("detect_flb: error on missing Pinnacle columns", {
  expect_snapshot(error = TRUE, detect_flb(tibble::tibble(x = 1), "H"))
})

test_that("estimate_league_strength: error on missing columns", {
  expect_snapshot(error = TRUE, estimate_league_strength(tibble::tibble(x = 1)))
})

# ---- models_baseline.R ----

test_that("fit_poisson_glm: error on missing columns", {
  expect_snapshot(error = TRUE, fit_poisson_glm(tibble::tibble(x = 1)))
})

test_that("predict_matches_glm: error on non-glm model", {
  expect_snapshot(error = TRUE, predict_matches_glm("not_glm", tibble::tibble()))
})

# ---- models_dc.R ----

test_that("fit_dixon_coles: error on non-data-frame", {
  skip_if_not_installed("goalmodel")
  expect_snapshot(error = TRUE, fit_dixon_coles("not_a_df"))
})

test_that("fit_dixon_coles: error on missing columns", {
  skip_if_not_installed("goalmodel")
  expect_snapshot(error = TRUE, fit_dixon_coles(tibble::tibble(x = 1)))
})

test_that("fit_dixon_coles: error on empty data", {
  skip_if_not_installed("goalmodel")
  empty <- tibble::tibble(
    home_team = character(), away_team = character(),
    fthg = integer(), ftag = integer(),
    match_date = as.Date(character())
  )
  expect_snapshot(error = TRUE, fit_dixon_coles(empty))
})

# ---- simulation.R ----

test_that("simulate_match_vr: error on non-positive lambda", {
  expect_snapshot(error = TRUE, simulate_match_vr(0, 1.5))
})

test_that("simulate_correlated_matches: error on missing columns", {
  expect_snapshot(error = TRUE, simulate_correlated_matches(tibble::tibble(x = 1)))
})

test_that("accumulator_probability: error on missing bet column", {
  df <- tibble::tibble(match_id = "m1", lambda_home = 1.5, lambda_away = 1.2)
  expect_snapshot(error = TRUE, accumulator_probability(df))
})

# ---- data_parse.R ----

test_that("parse_fd_csv: error on file not found", {
  expect_snapshot(error = TRUE, parse_fd_csv("/nonexistent/file.csv", "E0", "2324"))
})

test_that("parse_fd_odds: error on file not found", {
  expect_snapshot(error = TRUE, parse_fd_odds("/nonexistent/file.csv", "E0", "2324"))
})

# ---- features.R ----

test_that("rolling_xg: error on missing columns", {
  expect_snapshot(error = TRUE, rolling_xg(tibble::tibble(x = 1)))
})

test_that("cumulative_xg_ratio: error on missing columns", {
  expect_snapshot(error = TRUE, cumulative_xg_ratio(tibble::tibble(x = 1)))
})

test_that("xg_overperformance: error on missing columns", {
  expect_snapshot(error = TRUE, xg_overperformance(tibble::tibble(x = 1)))
})

test_that("compute_gamestate_xg: error on missing columns", {
  expect_snapshot(error = TRUE, compute_gamestate_xg(tibble::tibble(x = 1)))
})

test_that("reliability_threshold: error on missing metric_col", {
  df <- tibble::tibble(match_num = 1, other = 2)
  expect_snapshot(error = TRUE, reliability_threshold(df, "missing_col", "other"))
})

test_that("compute_xg_xag_composite: error on missing xg columns", {
  expect_snapshot(error = TRUE, compute_xg_xag_composite(tibble::tibble(x = 1)))
})

test_that("team_form_score: error on weights not summing to 1", {
  expect_snapshot(
    error = TRUE,
    team_form_score(1.5, 1.3, 1500, weight_goals = 0.5, weight_xg = 0.5, weight_elo = 0.5)
  )
})

test_that("add_form_scores: error on missing columns", {
  expect_snapshot(error = TRUE, add_form_scores(tibble::tibble(x = 1)))
})

test_that("compute_matches_since: error on missing columns", {
  expect_snapshot(error = TRUE, compute_matches_since(tibble::tibble(x = 1)))
})

# ---- database.R ----

test_that("connect_db: error on empty db_path", {
  expect_snapshot(error = TRUE, connect_db(""))
})

# ---- data_transfers.R ----

test_that("fetch_league_transfers: error on non-string country", {
  skip_if_not_installed("worldfootballR")
  expect_snapshot(error = TRUE, fetch_league_transfers(123))
})

test_that("fetch_squad_values: error on non-string country", {
  skip_if_not_installed("worldfootballR")
  expect_snapshot(error = TRUE, fetch_squad_values(123))
})

test_that("fetch_league_injuries: error on non-string country", {
  skip_if_not_installed("worldfootballR")
  expect_snapshot(error = TRUE, fetch_league_injuries(123))
})

test_that("fetch_league_suspensions: error on non-string country", {
  skip_if_not_installed("worldfootballR")
  expect_snapshot(error = TRUE, fetch_league_suspensions(123))
})

test_that("key_players_unavailable: error on non-string team", {
  expect_snapshot(
    error = TRUE,
    key_players_unavailable(123, tibble::tibble(), tibble::tibble(), tibble::tibble())
  )
})

test_that("add_player_availability: error on missing columns", {
  expect_snapshot(
    error = TRUE,
    add_player_availability(tibble::tibble(x = 1), tibble::tibble(), tibble::tibble(), tibble::tibble())
  )
})

# ---- models_xgboost.R ----

test_that("fit_xgboost: error on missing target column", {
  skip_if_not_installed("xgboost")
  df <- tibble::tibble(x = 1:10)
  expect_snapshot(error = TRUE, fit_xgboost(df, target = "missing_col"))
})

test_that("plot_xgb_importance: error on no importance data", {
  skip_if_not_installed("ggplot2")
  expect_snapshot(error = TRUE, plot_xgb_importance(list(importance = NULL)))
})

# ---- data_understat.R ----

test_that("fetch_understat_xg: error on invalid league", {
  skip_if_not_installed("understatr")
  expect_snapshot(error = TRUE, fetch_understat_xg("InvalidLeague", 2023))
})

# ---- data_fbref.R ----

test_that("fetch_fbref_matches: error on unknown country code", {
  skip_if_not_installed("worldfootballR")
  expect_snapshot(error = TRUE, fetch_fbref_matches("ZZ", 2024))
})

# ============================================================================
# SECTION 2: cli_warn warning message snapshots
# ============================================================================

test_that("compute_xg_features: warning on missing xG data", {
  df <- tibble::tibble(home_team = "A", away_team = "B")
  expect_snapshot(compute_xg_features(df))
})

test_that("compute_xg_xag_composite: warning on missing xAG columns", {
  df <- tibble::tibble(
    match_date = as.Date("2024-01-01"),
    home_team = "A", away_team = "B",
    home_xg = 1.5, away_xg = 1.0
  )
  expect_snapshot(compute_xg_xag_composite(df, window = 1L))
})

test_that("betting_sharpe_ratio: warning on < 2 returns", {
  expect_snapshot(betting_sharpe_ratio(0.5))
})

test_that("stat_discrimination: warning on too few observations", {
  df <- tibble::tibble(team = "A", value = 1)
  expect_snapshot(stat_discrimination(df))
})

test_that("stat_stability: warning on < 2 seasons", {
  df <- tibble::tibble(team = "A", value = 1, season = "2324")
  expect_snapshot(stat_stability(df))
})
