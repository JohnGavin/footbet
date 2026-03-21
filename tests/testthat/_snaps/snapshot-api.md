# fd_url API is stable

    Code
      args(fd_url)
    Output
      function (league_code, season) 
      NULL

# target_leagues API is stable

    Code
      args(target_leagues)
    Output
      function () 
      NULL

# target_seasons API is stable

    Code
      args(target_seasons)
    Output
      function (start = 2015L, end = 2025L) 
      NULL

# make_match_id API is stable

    Code
      args(make_match_id)
    Output
      function (league_code, match_date, home_team, away_team) 
      NULL

# download_fd_csv API is stable

    Code
      args(download_fd_csv)
    Output
      function (league_code, season, cache_dir = here::here("inst", 
          "extdata", "raw"), overwrite = FALSE) 
      NULL

# parse_fd_csv API is stable

    Code
      args(parse_fd_csv)
    Output
      function (file_path, league_code, season) 
      NULL

# parse_fd_odds API is stable

    Code
      args(parse_fd_odds)
    Output
      function (file_path, league_code, season) 
      NULL

# fetch_understat_xg API is stable

    Code
      args(fetch_understat_xg)
    Output
      function (league, season) 
      NULL

# fetch_fbref_matches API is stable

    Code
      args(fetch_fbref_matches)
    Output
      function (country, season_end, gender = "M", tier = "1st") 
      NULL

# fetch_fbref_all API is stable

    Code
      args(fetch_fbref_all)
    Output
      function (leagues = c("ENG", "ESP", "GER", "ITA", "FRA"), seasons = 2018:2024, 
          delay = 5) 
      NULL

# fetch_league_transfers API is stable

    Code
      args(fetch_league_transfers)
    Output
      function (country, start_year = 2024L, transfer_window = "all", 
          delay = 7) 
      NULL

# fetch_squad_values API is stable

    Code
      args(fetch_squad_values)
    Output
      function (country, start_year = 2024L) 
      NULL

# fetch_league_injuries API is stable

    Code
      args(fetch_league_injuries)
    Output
      function (country, start_year = 2024L) 
      NULL

# fetch_league_suspensions API is stable

    Code
      args(fetch_league_suspensions)
    Output
      function (country, start_year = 2024L) 
      NULL

# connect_db API is stable

    Code
      args(connect_db)
    Output
      function (db_path = ":memory:") 
      NULL

# disconnect_db API is stable

    Code
      args(disconnect_db)
    Output
      function (con) 
      NULL

# create_schema API is stable

    Code
      args(create_schema)
    Output
      function (con) 
      NULL

# insert_matches API is stable

    Code
      args(insert_matches)
    Output
      function (con, matches_df) 
      NULL

# insert_match_odds API is stable

    Code
      args(insert_match_odds)
    Output
      function (con, odds_df) 
      NULL

# write_matches_parquet API is stable

    Code
      args(write_matches_parquet)
    Output
      function (matches_df, parquet_dir = here::here("inst", "extdata", 
          "parquet", "matches")) 
      NULL

# write_odds_parquet API is stable

    Code
      args(write_odds_parquet)
    Output
      function (odds_df, parquet_dir = here::here("inst", "extdata", 
          "parquet", "odds")) 
      NULL

# compute_elo API is stable

    Code
      args(compute_elo)
    Output
      function (matches_df, k = 20, home_advantage = 65, init = 1500, 
          dynamic_k = FALSE, k_start = 40, k_end = 20, team_home_advantage = NULL, 
          margin_k = FALSE, reversion = 0, asymmetric = FALSE) 
      NULL

# rolling_goals API is stable

    Code
      args(rolling_goals)
    Output
      function (matches_df, window = 5L) 
      NULL

# rolling_xg API is stable

    Code
      args(rolling_xg)
    Output
      function (matches_df, window = 5L) 
      NULL

# cumulative_xg_ratio API is stable

    Code
      args(cumulative_xg_ratio)
    Output
      function (matches_df) 
      NULL

# xg_overperformance API is stable

    Code
      args(xg_overperformance)
    Output
      function (matches_df, window = 10L) 
      NULL

# compute_gamestate_xg API is stable

    Code
      args(compute_gamestate_xg)
    Output
      function (matches_df, window = 5L) 
      NULL

# compute_xg_features API is stable

    Code
      args(compute_xg_features)
    Output
      function (matches_df, rolling_window = 5L, overperf_window = 10L) 
      NULL

# compute_xg_xag_composite API is stable

    Code
      args(compute_xg_xag_composite)
    Output
      function (matches_df, window = 5L) 
      NULL

# reliability_threshold API is stable

    Code
      args(reliability_threshold)
    Output
      function (matches_df, metric_col, outcome_col, r2_threshold = 0.5, 
          min_matches = 5L, max_matches = 25L) 
      NULL

# first_reliable_matchday API is stable

    Code
      args(first_reliable_matchday)
    Output
      function (reliability_df) 
      NULL

# team_form_score API is stable

    Code
      args(team_form_score)
    Output
      function (rolling_gf, rolling_xg = NULL, elo, weight_goals = 0.3, 
          weight_xg = 0.5, weight_elo = 0.2) 
      NULL

# add_form_scores API is stable

    Code
      args(add_form_scores)
    Output
      function (matches_df, ...) 
      NULL

# compute_matches_since API is stable

    Code
      args(compute_matches_since)
    Output
      function (matches_df) 
      NULL

# matches_to_long API is stable

    Code
      args(matches_to_long)
    Output
      function (matches_df) 
      NULL

# league_table API is stable

    Code
      args(league_table)
    Output
      function (matches_df, as_of_date, league_code = NULL, season = NULL) 
      NULL

# add_league_positions API is stable

    Code
      args(add_league_positions)
    Output
      function (matches_df) 
      NULL

# h2h_record API is stable

    Code
      args(h2h_record)
    Output
      function (matches_df, home_team, away_team, as_of_date = Sys.Date(), 
          n = 10L) 
      NULL

# add_h2h_features API is stable

    Code
      args(add_h2h_features)
    Output
      function (matches_df, n = 10L) 
      NULL

# add_rest_days API is stable

    Code
      args(add_rest_days)
    Output
      function (matches_df) 
      NULL

# empirical_bayes_shrink API is stable

    Code
      args(empirical_bayes_shrink)
    Output
      function (observed, sample_size, type = c("rate", "count")) 
      NULL

# shrink_team_strength API is stable

    Code
      args(shrink_team_strength)
    Output
      function (team_stats) 
      NULL

# stat_discrimination API is stable

    Code
      args(stat_discrimination)
    Output
      function (df, entity_col = "team", value_col = "value") 
      NULL

# stat_stability API is stable

    Code
      args(stat_stability)
    Output
      function (df, entity_col = "team", value_col = "value", season_col = "season") 
      NULL

# devig_basic API is stable

    Code
      args(devig_basic)
    Output
      function (odds) 
      NULL

# devig_power API is stable

    Code
      args(devig_power)
    Output
      function (odds, tol = 1e-08) 
      NULL

# devig_shin API is stable

    Code
      args(devig_shin)
    Output
      function (odds, tol = 1e-08) 
      NULL

# devig_odds API is stable

    Code
      args(devig_odds)
    Output
      function (odds_df) 
      NULL

# calc_overround API is stable

    Code
      args(calc_overround)
    Output
      function (odds) 
      NULL

# kelly_fraction API is stable

    Code
      args(kelly_fraction)
    Output
      function (prob_win, decimal_odds, fraction = 0.25) 
      NULL

# identify_value_bet API is stable

    Code
      args(identify_value_bet)
    Output
      function (model_prob, market_prob, decimal_odds, min_edge = 0.03, 
          min_odds = 1.5, max_odds = 10) 
      NULL

# find_value_bets API is stable

    Code
      args(find_value_bets)
    Output
      function (preds, devigged, odds, min_edge = 0.03, min_odds = 1.5, 
          max_odds = 10) 
      NULL

# simulate_pnl API is stable

    Code
      args(simulate_pnl)
    Output
      function (bets, initial_bankroll = 1000, drawdown_threshold = 0.2, 
          max_stake = 0.03) 
      NULL

# acca_odds API is stable

    Code
      args(acca_odds)
    Output
      function (odds) 
      NULL

# acca_ev API is stable

    Code
      args(acca_ev)
    Output
      function (probs, odds) 
      NULL

# find_best_accas API is stable

    Code
      args(find_best_accas)
    Output
      function (selections, min_legs = 2L, max_legs = 5L, min_ev = 0) 
      NULL

# multi_kelly_stakes API is stable

    Code
      args(multi_kelly_stakes)
    Output
      function (probs, odds, fraction = 0.25, max_total = 0.2) 
      NULL

# bankroll_growth_target API is stable

    Code
      args(bankroll_growth_target)
    Output
      function (current_bankroll, target_bankroll, avg_odds = 2, avg_edge = 0.05, 
          avg_stake_pct = 0.02) 
      NULL

# line_movement API is stable

    Code
      args(line_movement)
    Output
      function (odds_df) 
      NULL

# analyze_steam_moves API is stable

    Code
      args(analyze_steam_moves)
    Output
      function (movement_df, actual_results) 
      NULL

# detect_flb API is stable

    Code
      args(detect_flb)
    Output
      function (odds_df, actual_results, n_bins = 10L) 
      NULL

# closing_line_value API is stable

    Code
      args(closing_line_value)
    Output
      function (pred_prob, closing_odds) 
      NULL

# estimate_league_strength API is stable

    Code
      args(estimate_league_strength)
    Output
      function (matches_df, reference_league = "E0") 
      NULL

# fit_poisson_glm API is stable

    Code
      args(fit_poisson_glm)
    Output
      function (long_df) 
      NULL

# predict_glm API is stable

    Code
      args(predict_glm)
    Output
      function (model, home_team, away_team, max_goals = 7L) 
      NULL

# predict_matches_glm API is stable

    Code
      args(predict_matches_glm)
    Output
      function (model, matches_df) 
      NULL

# fit_dixon_coles API is stable

    Code
      args(fit_dixon_coles)
    Output
      function (matches_df, xi = 0.003) 
      NULL

# predict_dc API is stable

    Code
      args(predict_dc)
    Output
      function (model, home_team, away_team, max_goals = 7L) 
      NULL

# evaluate_dc API is stable

    Code
      args(evaluate_dc)
    Output
      function (matches_df, train_months = 24L, test_months = 1L, xi = 0.003) 
      NULL

# fit_xgboost API is stable

    Code
      args(fit_xgboost)
    Output
      function (matches, features = NULL, target = "ftr", params = NULL, 
          nrounds = 100L, early_stopping = 10L, verbose = 0L) 
      NULL

# predict_xgboost API is stable

    Code
      args(predict_xgboost)
    Output
      function (fit, new_data) 
      NULL

# score_matrix API is stable

    Code
      args(score_matrix)
    Output
      function (lambda_home, lambda_away, max_goals = 7L) 
      NULL

# score_matrix_to_1x2 API is stable

    Code
      args(score_matrix_to_1x2)
    Output
      function (mat) 
      NULL

# log_loss API is stable

    Code
      args(log_loss)
    Output
      function (prob) 
      NULL

# brier_1x2 API is stable

    Code
      args(brier_1x2)
    Output
      function (prob_h, prob_d, prob_a, actual) 
      NULL

# rps_1x2 API is stable

    Code
      args(rps_1x2)
    Output
      function (prob_h, prob_d, prob_a, actual) 
      NULL

# brier_decomposition API is stable

    Code
      args(brier_decomposition)
    Output
      function (predicted, actual, n_bins = 10L) 
      NULL

# ensemble_predict API is stable

    Code
      args(ensemble_predict)
    Output
      function (predictions, weights = NULL) 
      NULL

# compute_ensemble_weights API is stable

    Code
      args(compute_ensemble_weights)
    Output
      function (cv_results) 
      NULL

# betting_sharpe_ratio API is stable

    Code
      args(betting_sharpe_ratio)
    Output
      function (returns, risk_free_rate = 0.02, periods_per_year = 365L) 
      NULL

# convert_odds API is stable

    Code
      args(convert_odds)
    Output
      function (odds, from, to) 
      NULL

# simulate_match_vr API is stable

    Code
      args(simulate_match_vr)
    Output
      function (lambda_home, lambda_away, n_sims = 10000L, method = c("stacked", 
          "crude", "antithetic", "control", "stratified"), seed = NULL) 
      NULL

# simulate_correlated_matches API is stable

    Code
      args(simulate_correlated_matches)
    Output
      function (matches, correlation = 0.1, n_sims = 5000L, seed = NULL) 
      NULL

# joint_outcome_probability API is stable

    Code
      args(joint_outcome_probability)
    Output
      function (sims, outcomes) 
      NULL

# accumulator_probability API is stable

    Code
      args(accumulator_probability)
    Output
      function (matches, correlation = 0.1, n_sims = 10000L)
      NULL

# blend_with_market API is stable

    Code
      args(blend_with_market)
    Output
      function (model_probs, market_probs, actuals, weights = seq(0,
          1, by = 0.05))
      NULL

# temporal_split API is stable

    Code
      args(temporal_split)
    Output
      function (matches_df, train_end = "1920", validate_end = "2223")
      NULL

