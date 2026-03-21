# Snapshot tests for exported function signatures (API stability).
# Any change to argument names, defaults, or order will be caught.
# Review changes with: testthat::snapshot_review()

# ---- utilities ----

test_that("fd_url API is stable", {
  expect_snapshot(args(fd_url), transform = function(x) trimws(x, "right"))
})

test_that("target_leagues API is stable", {
  expect_snapshot(args(target_leagues), transform = function(x) trimws(x, "right"))
})

test_that("target_seasons API is stable", {
  expect_snapshot(args(target_seasons), transform = function(x) trimws(x, "right"))
})

test_that("make_match_id API is stable", {
  expect_snapshot(args(make_match_id), transform = function(x) trimws(x, "right"))
})

# ---- data acquisition ----

test_that("download_fd_csv API is stable", {
  expect_snapshot(args(download_fd_csv), transform = function(x) trimws(x, "right"))
})

test_that("parse_fd_csv API is stable", {
  expect_snapshot(args(parse_fd_csv), transform = function(x) trimws(x, "right"))
})

test_that("parse_fd_odds API is stable", {
  expect_snapshot(args(parse_fd_odds), transform = function(x) trimws(x, "right"))
})

test_that("fetch_understat_xg API is stable", {
  expect_snapshot(args(fetch_understat_xg), transform = function(x) trimws(x, "right"))
})

test_that("fetch_fbref_matches API is stable", {
  expect_snapshot(args(fetch_fbref_matches), transform = function(x) trimws(x, "right"))
})

test_that("fetch_fbref_all API is stable", {
  expect_snapshot(args(fetch_fbref_all), transform = function(x) trimws(x, "right"))
})

test_that("fetch_league_transfers API is stable", {
  expect_snapshot(args(fetch_league_transfers), transform = function(x) trimws(x, "right"))
})

test_that("fetch_squad_values API is stable", {
  expect_snapshot(args(fetch_squad_values), transform = function(x) trimws(x, "right"))
})

test_that("fetch_league_injuries API is stable", {
  expect_snapshot(args(fetch_league_injuries), transform = function(x) trimws(x, "right"))
})

test_that("fetch_league_suspensions API is stable", {
  expect_snapshot(args(fetch_league_suspensions), transform = function(x) trimws(x, "right"))
})

# ---- database ----

test_that("connect_db API is stable", {
  expect_snapshot(args(connect_db), transform = function(x) trimws(x, "right"))
})

test_that("disconnect_db API is stable", {
  expect_snapshot(args(disconnect_db), transform = function(x) trimws(x, "right"))
})

test_that("create_schema API is stable", {
  expect_snapshot(args(create_schema), transform = function(x) trimws(x, "right"))
})

test_that("insert_matches API is stable", {
  expect_snapshot(args(insert_matches), transform = function(x) trimws(x, "right"))
})

test_that("insert_match_odds API is stable", {
  expect_snapshot(args(insert_match_odds), transform = function(x) trimws(x, "right"))
})

test_that("write_matches_parquet API is stable", {
  expect_snapshot(args(write_matches_parquet), transform = function(x) trimws(x, "right"))
})

test_that("write_odds_parquet API is stable", {
  expect_snapshot(args(write_odds_parquet), transform = function(x) trimws(x, "right"))
})

# ---- features ----

test_that("compute_elo API is stable", {
  expect_snapshot(args(compute_elo), transform = function(x) trimws(x, "right"))
})

test_that("rolling_goals API is stable", {
  expect_snapshot(args(rolling_goals), transform = function(x) trimws(x, "right"))
})

test_that("rolling_xg API is stable", {
  expect_snapshot(args(rolling_xg), transform = function(x) trimws(x, "right"))
})

test_that("cumulative_xg_ratio API is stable", {
  expect_snapshot(args(cumulative_xg_ratio), transform = function(x) trimws(x, "right"))
})

test_that("xg_overperformance API is stable", {
  expect_snapshot(args(xg_overperformance), transform = function(x) trimws(x, "right"))
})

test_that("compute_gamestate_xg API is stable", {
  expect_snapshot(args(compute_gamestate_xg), transform = function(x) trimws(x, "right"))
})

test_that("compute_xg_features API is stable", {
  expect_snapshot(args(compute_xg_features), transform = function(x) trimws(x, "right"))
})

test_that("compute_xg_xag_composite API is stable", {
  expect_snapshot(args(compute_xg_xag_composite), transform = function(x) trimws(x, "right"))
})

test_that("reliability_threshold API is stable", {
  expect_snapshot(args(reliability_threshold), transform = function(x) trimws(x, "right"))
})

test_that("first_reliable_matchday API is stable", {
  expect_snapshot(args(first_reliable_matchday), transform = function(x) trimws(x, "right"))
})

test_that("team_form_score API is stable", {
  expect_snapshot(args(team_form_score), transform = function(x) trimws(x, "right"))
})

test_that("add_form_scores API is stable", {
  expect_snapshot(args(add_form_scores), transform = function(x) trimws(x, "right"))
})

test_that("compute_matches_since API is stable", {
  expect_snapshot(args(compute_matches_since), transform = function(x) trimws(x, "right"))
})

test_that("matches_to_long API is stable", {
  expect_snapshot(args(matches_to_long), transform = function(x) trimws(x, "right"))
})

test_that("league_table API is stable", {
  expect_snapshot(args(league_table), transform = function(x) trimws(x, "right"))
})

test_that("add_league_positions API is stable", {
  expect_snapshot(args(add_league_positions), transform = function(x) trimws(x, "right"))
})

test_that("h2h_record API is stable", {
  expect_snapshot(args(h2h_record), transform = function(x) trimws(x, "right"))
})

test_that("add_h2h_features API is stable", {
  expect_snapshot(args(add_h2h_features), transform = function(x) trimws(x, "right"))
})

test_that("add_rest_days API is stable", {
  expect_snapshot(args(add_rest_days), transform = function(x) trimws(x, "right"))
})

test_that("empirical_bayes_shrink API is stable", {
  expect_snapshot(args(empirical_bayes_shrink), transform = function(x) trimws(x, "right"))
})

test_that("shrink_team_strength API is stable", {
  expect_snapshot(args(shrink_team_strength), transform = function(x) trimws(x, "right"))
})

test_that("stat_discrimination API is stable", {
  expect_snapshot(args(stat_discrimination), transform = function(x) trimws(x, "right"))
})

test_that("stat_stability API is stable", {
  expect_snapshot(args(stat_stability), transform = function(x) trimws(x, "right"))
})

# ---- devig ----

test_that("devig_basic API is stable", {
  expect_snapshot(args(devig_basic), transform = function(x) trimws(x, "right"))
})

test_that("devig_power API is stable", {
  expect_snapshot(args(devig_power), transform = function(x) trimws(x, "right"))
})

test_that("devig_shin API is stable", {
  expect_snapshot(args(devig_shin), transform = function(x) trimws(x, "right"))
})

test_that("devig_odds API is stable", {
  expect_snapshot(args(devig_odds), transform = function(x) trimws(x, "right"))
})

test_that("calc_overround API is stable", {
  expect_snapshot(args(calc_overround), transform = function(x) trimws(x, "right"))
})

# ---- kelly / decisions ----

test_that("kelly_fraction API is stable", {
  expect_snapshot(args(kelly_fraction), transform = function(x) trimws(x, "right"))
})

test_that("identify_value_bet API is stable", {
  expect_snapshot(args(identify_value_bet), transform = function(x) trimws(x, "right"))
})

test_that("find_value_bets API is stable", {
  expect_snapshot(args(find_value_bets), transform = function(x) trimws(x, "right"))
})

test_that("simulate_pnl API is stable", {
  expect_snapshot(args(simulate_pnl), transform = function(x) trimws(x, "right"))
})

# ---- betting ----

test_that("acca_odds API is stable", {
  expect_snapshot(args(acca_odds), transform = function(x) trimws(x, "right"))
})

test_that("acca_ev API is stable", {
  expect_snapshot(args(acca_ev), transform = function(x) trimws(x, "right"))
})

test_that("find_best_accas API is stable", {
  expect_snapshot(args(find_best_accas), transform = function(x) trimws(x, "right"))
})

test_that("multi_kelly_stakes API is stable", {
  expect_snapshot(args(multi_kelly_stakes), transform = function(x) trimws(x, "right"))
})

test_that("bankroll_growth_target API is stable", {
  expect_snapshot(args(bankroll_growth_target), transform = function(x) trimws(x, "right"))
})

test_that("line_movement API is stable", {
  expect_snapshot(args(line_movement), transform = function(x) trimws(x, "right"))
})

test_that("analyze_steam_moves API is stable", {
  expect_snapshot(args(analyze_steam_moves), transform = function(x) trimws(x, "right"))
})

test_that("detect_flb API is stable", {
  expect_snapshot(args(detect_flb), transform = function(x) trimws(x, "right"))
})

test_that("closing_line_value API is stable", {
  expect_snapshot(args(closing_line_value), transform = function(x) trimws(x, "right"))
})

test_that("estimate_league_strength API is stable", {
  expect_snapshot(args(estimate_league_strength), transform = function(x) trimws(x, "right"))
})

# ---- models ----

test_that("fit_poisson_glm API is stable", {
  expect_snapshot(args(fit_poisson_glm), transform = function(x) trimws(x, "right"))
})

test_that("predict_glm API is stable", {
  expect_snapshot(args(predict_glm), transform = function(x) trimws(x, "right"))
})

test_that("predict_matches_glm API is stable", {
  expect_snapshot(args(predict_matches_glm), transform = function(x) trimws(x, "right"))
})

test_that("fit_dixon_coles API is stable", {
  expect_snapshot(args(fit_dixon_coles), transform = function(x) trimws(x, "right"))
})

test_that("predict_dc API is stable", {
  expect_snapshot(args(predict_dc), transform = function(x) trimws(x, "right"))
})

test_that("evaluate_dc API is stable", {
  expect_snapshot(args(evaluate_dc), transform = function(x) trimws(x, "right"))
})

test_that("fit_xgboost API is stable", {
  expect_snapshot(args(fit_xgboost), transform = function(x) trimws(x, "right"))
})

test_that("predict_xgboost API is stable", {
  expect_snapshot(args(predict_xgboost), transform = function(x) trimws(x, "right"))
})

test_that("score_matrix API is stable", {
  expect_snapshot(args(score_matrix), transform = function(x) trimws(x, "right"))
})

test_that("score_matrix_to_1x2 API is stable", {
  expect_snapshot(args(score_matrix_to_1x2), transform = function(x) trimws(x, "right"))
})

# ---- evaluation ----

test_that("log_loss API is stable", {
  expect_snapshot(args(log_loss), transform = function(x) trimws(x, "right"))
})

test_that("brier_1x2 API is stable", {
  expect_snapshot(args(brier_1x2), transform = function(x) trimws(x, "right"))
})

test_that("rps_1x2 API is stable", {
  expect_snapshot(args(rps_1x2), transform = function(x) trimws(x, "right"))
})

test_that("brier_decomposition API is stable", {
  expect_snapshot(args(brier_decomposition), transform = function(x) trimws(x, "right"))
})

test_that("ensemble_predict API is stable", {
  expect_snapshot(args(ensemble_predict), transform = function(x) trimws(x, "right"))
})

test_that("compute_ensemble_weights API is stable", {
  expect_snapshot(args(compute_ensemble_weights), transform = function(x) trimws(x, "right"))
})

test_that("betting_sharpe_ratio API is stable", {
  expect_snapshot(args(betting_sharpe_ratio), transform = function(x) trimws(x, "right"))
})

test_that("convert_odds API is stable", {
  expect_snapshot(args(convert_odds), transform = function(x) trimws(x, "right"))
})

# ---- simulation ----

test_that("simulate_match_vr API is stable", {
  expect_snapshot(args(simulate_match_vr), transform = function(x) trimws(x, "right"))
})

test_that("simulate_correlated_matches API is stable", {
  expect_snapshot(args(simulate_correlated_matches), transform = function(x) trimws(x, "right"))
})

test_that("joint_outcome_probability API is stable", {
  expect_snapshot(args(joint_outcome_probability), transform = function(x) trimws(x, "right"))
})

test_that("accumulator_probability API is stable", {
  expect_snapshot(args(accumulator_probability), transform = function(x) trimws(x, "right"))
})

test_that("blend_with_market API is stable", {
  expect_snapshot(args(blend_with_market), transform = function(x) trimws(x, "right"))
})

test_that("temporal_split API is stable", {
  expect_snapshot(args(temporal_split), transform = function(x) trimws(x, "right"))
})
