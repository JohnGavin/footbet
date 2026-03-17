# fd_url: error on non-string league_code

    Code
      fd_url(123, "2324")
    Condition
      Error in `fd_url()`:
      ! `league_code` must be a single string.

# fd_url: error on non-string season

    Code
      fd_url("E0", 2324)
    Condition
      Error in `fd_url()`:
      ! `season` must be a single string.

# fd_url: error on invalid season format

    Code
      fd_url("E0", "24")
    Condition
      Error in `fd_url()`:
      x `season` must be a 4-digit code like "2324".
      i Got "24".

# devig_basic: error on empty odds

    Code
      devig_basic(numeric(0))
    Condition
      Error in `validate_odds()`:
      ! Odds vector must not be empty.

# devig_basic: error on non-numeric odds

    Code
      devig_basic("abc")
    Condition
      Error in `validate_odds()`:
      ! Odds must be numeric. Got <character>.

# devig_basic: error on Inf odds

    Code
      devig_basic(c(2, Inf))
    Condition
      Error in `validate_odds()`:
      ! Odds must be finite. Got Inf values.

# devig_basic: error on odds <= 1

    Code
      devig_basic(c(0.5, 2))
    Condition
      Error in `validate_odds()`:
      ! All odds must be > 1. Got minimum 0.5.

# devig_shin: error on non-3 odds

    Code
      devig_shin(c(2, 3))
    Condition
      Error in `devig_shin()`:
      ! Shin method requires exactly 3 odds (1X2). Got 2.

# kelly_fraction: error on prob_win out of range

    Code
      kelly_fraction(0, 2)
    Condition
      Error in `kelly_fraction()`:
      ! `prob_win` must be between 0 and 1 (exclusive).

# kelly_fraction: error on decimal_odds <= 1

    Code
      kelly_fraction(0.5, 1)
    Condition
      Error in `kelly_fraction()`:
      ! `decimal_odds` must be > 1.

# find_value_bets: error on non-data-frame inputs

    Code
      find_value_bets("x", "y", "z")
    Condition
      Error in `find_value_bets()`:
      ! All inputs must be data frames.

# simulate_pnl: error on non-data-frame bets

    Code
      simulate_pnl("not_a_df")
    Condition
      Error in `simulate_pnl()`:
      ! `bets` must be a data frame, not <character>.

# log_loss: error on non-numeric prob

    Code
      log_loss("abc")
    Condition
      Error in `log_loss()`:
      ! `prob` must be numeric.

# log_loss: error on empty prob

    Code
      log_loss(numeric(0))
    Condition
      Error in `log_loss()`:
      ! `prob` must not be empty.

# evaluate_glm_baseline: error on non-df long_df

    Code
      evaluate_glm_baseline("x", tibble::tibble())
    Condition
      Error in `evaluate_glm_baseline()`:
      ! `long_df` must be a data frame, not <character>.

# evaluate_glm_baseline: error on non-df matches_df

    Code
      evaluate_glm_baseline(tibble::tibble(), "x")
    Condition
      Error in `evaluate_glm_baseline()`:
      ! `matches_df` must be a data frame, not <character>.

# closing_line_value: error on length mismatch

    Code
      closing_line_value(c(0.5, 0.6), c(2))
    Condition
      Error in `closing_line_value()`:
      ! `pred_prob` and `closing_odds` must have same length.

# ensemble_predict: error on non-list predictions

    Code
      ensemble_predict("not_a_list")
    Condition
      Error in `ensemble_predict()`:
      ! `predictions` must be a list with at least 2 model predictions.

# ensemble_predict: error on unnamed list

    Code
      ensemble_predict(list(tibble::tibble(), tibble::tibble()))
    Condition
      Error in `ensemble_predict()`:
      ! `predictions` must be a named list.

# compute_ensemble_weights: error on single model

    Code
      compute_ensemble_weights(list(a = tibble::tibble(log_loss = 1)))
    Condition
      Error in `compute_ensemble_weights()`:
      ! `cv_results` must be a list with at least 2 model results.

# compute_ensemble_weights: error on unnamed cv_results

    Code
      compute_ensemble_weights(list(tibble::tibble(log_loss = 1), tibble::tibble(
        log_loss = 2)))
    Condition
      Error in `compute_ensemble_weights()`:
      ! `cv_results` must be a named list.

# betting_sharpe_ratio: error on non-numeric returns

    Code
      betting_sharpe_ratio("abc")
    Condition
      Error in `betting_sharpe_ratio()`:
      ! `returns` must be numeric.

# decimal_to_fractional: error on non-numeric

    Code
      decimal_to_fractional("abc")
    Condition
      Error in `decimal_to_fractional()`:
      ! `decimal_odds` must be numeric.

# decimal_to_american: error on non-numeric

    Code
      decimal_to_american("abc")
    Condition
      Error in `decimal_to_american()`:
      ! `decimal_odds` must be numeric.

# american_to_decimal: error on non-numeric

    Code
      american_to_decimal("abc")
    Condition
      Error in `american_to_decimal()`:
      ! `american_odds` must be numeric.

# fractional_to_decimal: error on non-character

    Code
      fractional_to_decimal(2.5)
    Condition
      Error in `fractional_to_decimal()`:
      ! `fractional_odds` must be character.

# brier_decomposition: error on length mismatch

    Code
      brier_decomposition(c(0.5, 0.6), c(1))
    Condition
      Error in `brier_decomposition()`:
      ! `predicted` and `actual` must have same length.

# empirical_bayes_shrink: error on length mismatch

    Code
      empirical_bayes_shrink(c(1, 2, 3), c(10, 20))
    Condition
      Error in `empirical_bayes_shrink()`:
      ! `observed` and `sample_size` must have same length.

# convert_odds: error on invalid from format

    Code
      convert_odds(2, "bogus", "decimal")
    Condition
      Error in `convert_odds()`:
      ! `from` must be one of: "decimal", "fractional", and "american"

# convert_odds: error on invalid to format

    Code
      convert_odds(2, "decimal", "bogus")
    Condition
      Error in `convert_odds()`:
      ! `to` must be one of: "decimal", "fractional", and "american"

# shrink_team_strength: error on missing columns

    Code
      shrink_team_strength(tibble::tibble(x = 1))
    Condition
      Error in `shrink_team_strength()`:
      ! Missing required columns: "team", "n_matches", "attack", and "defense"

# stat_discrimination: error on missing entity_col

    Code
      stat_discrimination(tibble::tibble(x = 1), entity_col = "team")
    Condition
      Error in `stat_discrimination()`:
      ! Column "team" not found.

# stat_stability: error on missing columns

    Code
      stat_stability(tibble::tibble(x = 1))
    Condition
      Error in `stat_stability()`:
      ! Missing columns: "team", "value", and "season"

# acca_odds: error on non-numeric odds

    Code
      acca_odds("abc")
    Condition
      Error in `acca_odds()`:
      ! `odds` must be numeric.

# acca_odds: error on odds < 1

    Code
      acca_odds(c(0.5, 2))
    Condition
      Error in `acca_odds()`:
      ! All odds must be >= 1.

# acca_ev: error on length mismatch

    Code
      acca_ev(c(0.5), c(2, 3))
    Condition
      Error in `acca_ev()`:
      ! `probs` and `odds` must have same length.

# acca_ev: error on non-numeric arguments

    Code
      acca_ev("a", "b")
    Condition
      Error in `acca_ev()`:
      ! Arguments must be numeric.

# find_best_accas: error on missing columns

    Code
      find_best_accas(tibble::tibble(x = 1))
    Condition
      Error in `find_best_accas()`:
      ! `selections` must have "prob" and "odds" columns.

# multi_kelly_stakes: error on length mismatch

    Code
      multi_kelly_stakes(c(0.5, 0.6), c(2))
    Condition
      Error in `multi_kelly_stakes()`:
      ! `probs` and `odds` must have same length.

# bankroll_growth_target: error on non-positive bankroll

    Code
      bankroll_growth_target(0, 1000)
    Condition
      Error in `bankroll_growth_target()`:
      ! `current_bankroll` must be positive.

# bankroll_growth_target: error on target <= current

    Code
      bankroll_growth_target(1000, 500)
    Condition
      Error in `bankroll_growth_target()`:
      ! `target_bankroll` must exceed `current_bankroll`.

# line_movement: error on missing Bet365 odds

    Code
      line_movement(tibble::tibble(psh = 1, psd = 1, psa = 1))
    Condition
      Error in `line_movement()`:
      ! Missing Bet365 opening odds (b365h, b365d, b365a).

# line_movement: error on missing Pinnacle odds

    Code
      line_movement(tibble::tibble(b365h = 1, b365d = 1, b365a = 1))
    Condition
      Error in `line_movement()`:
      ! Missing Pinnacle closing odds (psh, psd, psa).

# analyze_steam_moves: error on length mismatch

    Code
      analyze_steam_moves(df, c("H", "D"))
    Condition
      Error in `analyze_steam_moves()`:
      ! `movement_df` and `actual_results` must have same length.

# detect_flb: error on missing Pinnacle columns

    Code
      detect_flb(tibble::tibble(x = 1), "H")
    Condition
      Error in `detect_flb()`:
      ! Need Pinnacle odds columns (psh, psd, psa).

# estimate_league_strength: error on missing columns

    Code
      estimate_league_strength(tibble::tibble(x = 1))
    Condition
      Error in `estimate_league_strength()`:
      ! Missing required columns: "league_code", "season", "home_team", "away_team", "fthg", and "ftag"

# fit_poisson_glm: error on missing columns

    Code
      fit_poisson_glm(tibble::tibble(x = 1))
    Condition
      Error in `fit_poisson_glm()`:
      ! Missing columns: "goals", "home", "team", and "opponent"

# predict_matches_glm: error on non-glm model

    Code
      predict_matches_glm("not_glm", tibble::tibble())
    Condition
      Error in `predict_matches_glm()`:
      ! `model` must be a <glm> object, not <character>.

# fit_dixon_coles: error on non-data-frame

    Code
      fit_dixon_coles("not_a_df")
    Condition
      Error in `fit_dixon_coles()`:
      ! `matches_df` must be a data frame, not <character>.

# fit_dixon_coles: error on missing columns

    Code
      fit_dixon_coles(tibble::tibble(x = 1))
    Condition
      Error in `fit_dixon_coles()`:
      ! Missing columns: "home_team", "away_team", "fthg", "ftag", and "match_date"

# fit_dixon_coles: error on empty data

    Code
      fit_dixon_coles(empty)
    Condition
      Error in `fit_dixon_coles()`:
      ! `matches_df` must not be empty.

# simulate_match_vr: error on non-positive lambda

    Code
      simulate_match_vr(0, 1.5)
    Condition
      Error in `simulate_match_vr()`:
      ! Lambda values must be positive.

# simulate_correlated_matches: error on missing columns

    Code
      simulate_correlated_matches(tibble::tibble(x = 1))
    Condition
      Error in `simulate_correlated_matches()`:
      ! Missing columns: match_id, lambda_home, and lambda_away

# accumulator_probability: error on missing bet column

    Code
      accumulator_probability(df)
    Condition
      Error in `accumulator_probability()`:
      ! matches must have a bet column with 'H', 'D', or 'A'.

# parse_fd_csv: error on file not found

    Code
      parse_fd_csv("/nonexistent/file.csv", "E0", "2324")
    Condition
      Error in `parse_fd_csv()`:
      ! File not found: '/nonexistent/file.csv'

# parse_fd_odds: error on file not found

    Code
      parse_fd_odds("/nonexistent/file.csv", "E0", "2324")
    Condition
      Error in `parse_fd_odds()`:
      ! File not found: '/nonexistent/file.csv'

# rolling_xg: error on missing columns

    Code
      rolling_xg(tibble::tibble(x = 1))
    Condition
      Error in `rolling_xg()`:
      x Missing required columns: "match_date", "home_team", "away_team", "home_xg", and "away_xg"
      i Use `join_xg_to_matches()` to add xG data first.

# cumulative_xg_ratio: error on missing columns

    Code
      cumulative_xg_ratio(tibble::tibble(x = 1))
    Condition
      Error in `cumulative_xg_ratio()`:
      x Missing required columns: "match_date", "home_team", "away_team", "home_xg", and "away_xg"
      i Use `join_xg_to_matches()` to add xG data first.

# xg_overperformance: error on missing columns

    Code
      xg_overperformance(tibble::tibble(x = 1))
    Condition
      Error in `xg_overperformance()`:
      x Missing required columns: "match_date", "home_team", "away_team", "home_xg", "away_xg", "fthg", and "ftag"
      i Need both goals (fthg/ftag) and xG (home_xg/away_xg).

# compute_gamestate_xg: error on missing columns

    Code
      compute_gamestate_xg(tibble::tibble(x = 1))
    Condition
      Error in `compute_gamestate_xg()`:
      x Missing required columns: "match_date", "home_team", "away_team", "home_xg", "away_xg", "fthg", and "ftag"
      i Need both goals and xG to compute gamestate-aware features.

# reliability_threshold: error on missing metric_col

    Code
      reliability_threshold(df, "missing_col", "other")
    Condition
      Error in `reliability_threshold()`:
      ! Column "missing_col" not found in data.

# compute_xg_xag_composite: error on missing xg columns

    Code
      compute_xg_xag_composite(tibble::tibble(x = 1))
    Condition
      Error in `compute_xg_xag_composite()`:
      ! Requires "home_xg" and "away_xg" columns.

# team_form_score: error on weights not summing to 1

    Code
      team_form_score(1.5, 1.3, 1500, weight_goals = 0.5, weight_xg = 0.5,
        weight_elo = 0.5)
    Condition
      Error in `team_form_score()`:
      ! Weights must sum to 1. Got 1.5.

# add_form_scores: error on missing columns

    Code
      add_form_scores(tibble::tibble(x = 1))
    Condition
      Error in `add_form_scores()`:
      x Missing required columns: "home_rolling_gf", "away_rolling_gf", "home_elo", and "away_elo"
      i Compute rolling features and Elo first.

# compute_matches_since: error on missing columns

    Code
      compute_matches_since(tibble::tibble(x = 1))
    Condition
      Error in `compute_matches_since()`:
      ! Missing required columns: "match_date", "home_team", "away_team", "ftr", "fthg", and "ftag"

# connect_db: error on empty db_path

    Code
      connect_db("")
    Condition
      Error in `connect_db()`:
      ! `db_path` must not be empty. Use ":memory:" for in-memory.

# fetch_league_transfers: error on non-string country

    Code
      fetch_league_transfers(123)
    Condition
      Error in `fetch_league_transfers()`:
      ! `country` must be a single string, not <numeric>.

# fetch_squad_values: error on non-string country

    Code
      fetch_squad_values(123)
    Condition
      Error in `fetch_squad_values()`:
      ! `country` must be a single string, not <numeric>.

# fetch_league_injuries: error on non-string country

    Code
      fetch_league_injuries(123)
    Condition
      Error in `fetch_league_injuries()`:
      ! `country` must be a single string, not <numeric>.

# fetch_league_suspensions: error on non-string country

    Code
      fetch_league_suspensions(123)
    Condition
      Error in `fetch_league_suspensions()`:
      ! `country` must be a single string, not <numeric>.

# key_players_unavailable: error on non-string team

    Code
      key_players_unavailable(123, tibble::tibble(), tibble::tibble(), tibble::tibble())
    Condition
      Error in `key_players_unavailable()`:
      ! `team` must be a single string.

# add_player_availability: error on missing columns

    Code
      add_player_availability(tibble::tibble(x = 1), tibble::tibble(), tibble::tibble(),
      tibble::tibble())
    Condition
      Error in `add_player_availability()`:
      ! `matches` must have `home_team` and `away_team` columns.

# plot_xgb_importance: error on no importance data

    Code
      plot_xgb_importance(list(importance = NULL))
    Condition
      Error in `plot_xgb_importance()`:
      ! No feature importance data in `fit`.

# fetch_fbref_matches: error on unknown country code

    Code
      fetch_fbref_matches("ZZ", 2024)
    Condition
      Error in `fetch_fbref_matches()`:
      x Unknown country code: "ZZ"
      i Supported: "ENG", "E0", "E1", "ESP", "SP1", "SP2", "GER", "D1", "D2", "ITA", "I1", "I2", "FRA", "F1", and "F2"

# compute_xg_features: warning on missing xG data

    Code
      compute_xg_features(df)
    Condition
      Warning:
      ! No xG data found in matches.
      i Use `join_xg_to_matches()` to add xG data from FBref.
    Output
      # A tibble: 0 x 3
      # i 3 variables: team <chr>, match_date <date>, match_id <chr>

# compute_xg_xag_composite: warning on missing xAG columns

    Code
      compute_xg_xag_composite(df, window = 1L)
    Condition
      Warning:
      ! No xAG columns found ("home_xag", "away_xag").
      i Returning xG-only features. Add xAG data from FBref for full composite.
    Output
      # A tibble: 2 x 7
        team  match_date match_id is_home rolling_xg_for rolling_xg_against
        <chr> <date>     <chr>    <lgl>            <dbl>              <dbl>
      1 A     2024-01-01 <NA>     TRUE                NA                 NA
      2 B     2024-01-01 <NA>     FALSE               NA                 NA
      # i 1 more variable: rolling_xg_diff <dbl>

# betting_sharpe_ratio: warning on < 2 returns

    Code
      betting_sharpe_ratio(0.5)
    Condition
      Warning:
      Need at least 2 returns to compute Sharpe ratio.
    Output
      [1] NA

# stat_discrimination: warning on too few observations

    Code
      stat_discrimination(df)
    Condition
      Warning:
      Too few observations for reliable discrimination estimate.
    Output
      [1] NA

# stat_stability: warning on < 2 seasons

    Code
      stat_stability(df)
    Condition
      Warning:
      Need at least 2 seasons to compute stability.
    Output
      [1] NA

