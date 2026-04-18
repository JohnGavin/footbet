# Package index

## Data Acquisition

Download and parse match data from various sources

- [`download_all_fd()`](https://johngavin.github.io/footbet/reference/download_all_fd.md)
  : Download all target league/season combinations
- [`download_fd_csv()`](https://johngavin.github.io/footbet/reference/download_fd_csv.md)
  : Download a CSV from football-data.co.uk
- [`fetch_fbref_advanced_all()`](https://johngavin.github.io/footbet/reference/fetch_fbref_advanced_all.md)
  : Fetch FBref passing + shooting match logs for multiple
  league-seasons
- [`fetch_fbref_all()`](https://johngavin.github.io/footbet/reference/fetch_fbref_all.md)
  : Fetch FBref data for multiple leagues and seasons
- [`fetch_fbref_matches()`](https://johngavin.github.io/footbet/reference/fetch_fbref_matches.md)
  : Fetch match-level xG data from FBref
- [`fetch_fbref_season_stats()`](https://johngavin.github.io/footbet/reference/fetch_fbref_season_stats.md)
  : Fetch FBref team season stats (passing, shooting, possession)
- [`fetch_fbref_team_match_logs()`](https://johngavin.github.io/footbet/reference/fetch_fbref_team_match_logs.md)
  : Fetch FBref team match log stats for all teams in a league-season
- [`fetch_league_injuries()`](https://johngavin.github.io/footbet/reference/fetch_league_injuries.md)
  : Fetch current league injuries from Transfermarkt
- [`fetch_league_suspensions()`](https://johngavin.github.io/footbet/reference/fetch_league_suspensions.md)
  : Fetch league suspensions from Transfermarkt
- [`fetch_league_transfers()`](https://johngavin.github.io/footbet/reference/fetch_league_transfers.md)
  : Fetch league transfers from Transfermarkt via worldfootballR
- [`fetch_squad_values()`](https://johngavin.github.io/footbet/reference/fetch_squad_values.md)
  : Fetch squad market values from Transfermarkt
- [`join_xg_to_matches()`](https://johngavin.github.io/footbet/reference/join_xg_to_matches.md)
  : Join FBref xG data to football-data.co.uk matches
- [`parse_fd_csv()`](https://johngavin.github.io/footbet/reference/parse_fd_csv.md)
  : Parse a football-data.co.uk CSV into standardised format
- [`parse_fd_odds()`](https://johngavin.github.io/footbet/reference/parse_fd_odds.md)
  : Parse Pinnacle odds columns from a football-data.co.uk CSV
- [`standardise_fbref_advanced()`](https://johngavin.github.io/footbet/reference/standardise_fbref_advanced.md)
  : Standardise FBref team match log columns for progressive stats

## Data Integration

Join and transform data from multiple sources

- [`add_understat_xg()`](https://johngavin.github.io/footbet/reference/add_understat_xg.md)
  : Fetch and join Understat xG for multiple seasons
- [`fetch_understat_xg()`](https://johngavin.github.io/footbet/reference/fetch_understat_xg.md)
  : Fetch match xG data from Understat
- [`join_understat_xg()`](https://johngavin.github.io/footbet/reference/join_understat_xg.md)
  : Join Understat xG to match data
- [`understat_team_mapping()`](https://johngavin.github.io/footbet/reference/understat_team_mapping.md)
  : Map Understat team names to football-data.co.uk names

## Feature Engineering

Create predictive features from raw match data

- [`add_form_scores()`](https://johngavin.github.io/footbet/reference/add_form_scores.md)
  : Add form scores to match data
- [`add_form_streaks()`](https://johngavin.github.io/footbet/reference/add_form_streaks.md)
  : Add form streak features to match data
- [`add_h2h_features()`](https://johngavin.github.io/footbet/reference/add_h2h_features.md)
  : Add H2H features to match data
- [`add_league_positions()`](https://johngavin.github.io/footbet/reference/add_league_positions.md)
  : Add league position features to match data
- [`add_matches_since()`](https://johngavin.github.io/footbet/reference/add_matches_since.md)
  : Add matches-since features to match data
- [`add_player_availability()`](https://johngavin.github.io/footbet/reference/add_player_availability.md)
  : Add player availability features to match data
- [`add_ratio_features()`](https://johngavin.github.io/footbet/reference/add_ratio_features.md)
  : Add ratio-normalized features to match data
- [`add_rest_days()`](https://johngavin.github.io/footbet/reference/add_rest_days.md)
  : Add rest days features to match data
- [`apply_asof_cutoff()`](https://johngavin.github.io/footbet/reference/apply_asof_cutoff.md)
  : Apply an as-of cutoff to a per-team, per-date feature series
- [`compute_elo()`](https://johngavin.github.io/footbet/reference/compute_elo.md)
  : Compute Elo ratings for a league
- [`compute_gamestate_xg()`](https://johngavin.github.io/footbet/reference/compute_gamestate_xg.md)
  : Compute gamestate-aware xG features
- [`compute_matches_since()`](https://johngavin.github.io/footbet/reference/compute_matches_since.md)
  : Add matches-since-event features to team data
- [`compute_rest_days()`](https://johngavin.github.io/footbet/reference/compute_rest_days.md)
  : Compute rest days for all matches
- [`compute_shot_quality()`](https://johngavin.github.io/footbet/reference/compute_shot_quality.md)
  : Compute per-match shot quality features from Understat shot data
- [`compute_xg_features()`](https://johngavin.github.io/footbet/reference/compute_xg_features.md)
  : Compute all xG-based features
- [`compute_xg_xag_composite()`](https://johngavin.github.io/footbet/reference/compute_xg_xag_composite.md)
  : Compute xG + xAG composite metric
- [`cumulative_xg_ratio()`](https://johngavin.github.io/footbet/reference/cumulative_xg_ratio.md)
  : Compute cumulative xG ratio within season
- [`devig_odds()`](https://johngavin.github.io/footbet/reference/devig_odds.md)
  : Devig Pinnacle odds for all matches
- [`empirical_bayes_shrink()`](https://johngavin.github.io/footbet/reference/empirical_bayes_shrink.md)
  : Apply empirical Bayes shrinkage to rate estimates
- [`first_reliable_matchday()`](https://johngavin.github.io/footbet/reference/first_reliable_matchday.md)
  : Find first reliable matchday for a metric
- [`form_streak()`](https://johngavin.github.io/footbet/reference/form_streak.md)
  : Compute form streaks for a team
- [`h2h_record()`](https://johngavin.github.io/footbet/reference/h2h_record.md)
  : Compute head-to-head record between two teams
- [`key_players_unavailable()`](https://johngavin.github.io/footbet/reference/key_players_unavailable.md)
  : Check key player availability for a team
- [`league_table()`](https://johngavin.github.io/footbet/reference/league_table.md)
  : Compute league table at a specific date
- [`leakage_fix`](https://johngavin.github.io/footbet/reference/leakage_fix.md)
  : Bet-time cutoff: as-of feature joins
- [`margin_k_factor()`](https://johngavin.github.io/footbet/reference/margin_k_factor.md)
  : Margin-based K-factor weight
- [`matches_since_event()`](https://johngavin.github.io/footbet/reference/matches_since_event.md)
  : Compute matches since a specific event
- [`matches_to_long()`](https://johngavin.github.io/footbet/reference/matches_to_long.md)
  : Convert match results to long format for Poisson modelling
- [`pinnacle_implied_elo()`](https://johngavin.github.io/footbet/reference/pinnacle_implied_elo.md)
  : Convert Pinnacle probability to implied Elo rating
- [`ratio_normalize()`](https://johngavin.github.io/footbet/reference/ratio_normalize.md)
  : Normalize features to ratio form
- [`reliability_threshold()`](https://johngavin.github.io/footbet/reference/reliability_threshold.md)
  : Compute reliability threshold for a metric
- [`rest_days()`](https://johngavin.github.io/footbet/reference/rest_days.md)
  : Compute days since last match for a team
- [`rolling_goals()`](https://johngavin.github.io/footbet/reference/rolling_goals.md)
  : Compute rolling goal averages for each team
- [`rolling_progressive()`](https://johngavin.github.io/footbet/reference/rolling_progressive.md)
  : Compute rolling progressive actions from FBref team match logs
- [`rolling_psxg()`](https://johngavin.github.io/footbet/reference/rolling_psxg.md)
  : Compute rolling PSxG overperformance
- [`rolling_shot_quality()`](https://johngavin.github.io/footbet/reference/rolling_shot_quality.md)
  : Compute rolling shot quality features
- [`rolling_sot()`](https://johngavin.github.io/footbet/reference/rolling_sot.md)
  : Compute rolling shots-on-target ratio
- [`rolling_xg()`](https://johngavin.github.io/footbet/reference/rolling_xg.md)
  : Compute rolling xG averages for each team
- [`seasonal_k()`](https://johngavin.github.io/footbet/reference/seasonal_k.md)
  : Compute seasonal K-factor
- [`shrink_team_strength()`](https://johngavin.github.io/footbet/reference/shrink_team_strength.md)
  : Shrink team strength estimates
- [`team_form_score()`](https://johngavin.github.io/footbet/reference/team_form_score.md)
  : Compute composite team form score
- [`team_position()`](https://johngavin.github.io/footbet/reference/team_position.md)
  : Get team position at a specific date
- [`xg_overperformance()`](https://johngavin.github.io/footbet/reference/xg_overperformance.md)
  : Compute xG overperformance (goals minus xG)

## Odds Conversion

Convert between decimal, fractional, and American odds formats

- [`american_to_decimal()`](https://johngavin.github.io/footbet/reference/american_to_decimal.md)
  : Convert American odds to decimal
- [`convert_odds()`](https://johngavin.github.io/footbet/reference/convert_odds.md)
  : Convert odds between any formats
- [`decimal_to_american()`](https://johngavin.github.io/footbet/reference/decimal_to_american.md)
  : Convert decimal odds to American
- [`decimal_to_fractional()`](https://johngavin.github.io/footbet/reference/decimal_to_fractional.md)
  : Convert decimal odds to fractional
- [`fractional_to_decimal()`](https://johngavin.github.io/footbet/reference/fractional_to_decimal.md)
  : Convert fractional odds to decimal

## Devigging Odds

Remove bookmaker margin from odds

- [`calc_overround()`](https://johngavin.github.io/footbet/reference/calc_overround.md)
  : Calculate overround (vig) from decimal odds
- [`devig_basic()`](https://johngavin.github.io/footbet/reference/devig_basic.md)
  : Remove bookmaker margin from odds (basic proportional method)
- [`devig_power()`](https://johngavin.github.io/footbet/reference/devig_power.md)
  : Remove margin using power method
- [`devig_shin()`](https://johngavin.github.io/footbet/reference/devig_shin.md)
  : Remove margin using Shin's model (1993)

## Prediction Models

Fit and predict with Poisson, Dixon-Coles, and Bayesian models

- [`blend_with_market()`](https://johngavin.github.io/footbet/reference/blend_with_market.md)
  : Blend model predictions with market probabilities
- [`brms_ah_ci()`](https://johngavin.github.io/footbet/reference/brms_ah_ci.md)
  : Predict AH cover probability with credible intervals from brms
- [`brms_converged()`](https://johngavin.github.io/footbet/reference/brms_converged.md)
  : Check if a brms model has converged
- [`brms_diagnostics()`](https://johngavin.github.io/footbet/reference/brms_diagnostics.md)
  : Extract MCMC diagnostics from a brms model
- [`brms_loo()`](https://johngavin.github.io/footbet/reference/brms_loo.md)
  : Compute LOO-CV for a brms model
- [`brms_r2()`](https://johngavin.github.io/footbet/reference/brms_r2.md)
  : Compute Bayesian R-squared for a brms model
- [`brms_waic()`](https://johngavin.github.io/footbet/reference/brms_waic.md)
  : Compute WAIC for a brms model
- [`correct_score_value()`](https://johngavin.github.io/footbet/reference/correct_score_value.md)
  : Correct score odds value check
- [`cv_xgboost()`](https://johngavin.github.io/footbet/reference/cv_xgboost.md)
  : Cross-validate XGBoost model
- [`dc_score_matrix()`](https://johngavin.github.io/footbet/reference/dc_score_matrix.md)
  : Build Dixon-Coles corrected score matrix
- [`dc_tau()`](https://johngavin.github.io/footbet/reference/dc_tau.md)
  : Dixon-Coles correction factor for low-scoring games
- [`dskellam()`](https://johngavin.github.io/footbet/reference/dskellam.md)
  : Skellam probability mass function
- [`edge_credible_interval()`](https://johngavin.github.io/footbet/reference/edge_credible_interval.md)
  : Compute credible interval on betting edge
- [`ensemble_predict()`](https://johngavin.github.io/footbet/reference/ensemble_predict.md)
  : Ensemble model predictions
- [`evaluate_brms()`](https://johngavin.github.io/footbet/reference/evaluate_brms.md)
  : Evaluate brms model via walk-forward cross-validation
- [`evaluate_dc()`](https://johngavin.github.io/footbet/reference/evaluate_dc.md)
  : Walk-forward evaluation for Dixon-Coles model
- [`fit_brms_poisson()`](https://johngavin.github.io/footbet/reference/fit_brms_poisson.md)
  : Fit a hierarchical Bayesian Poisson model with brms
- [`fit_dixon_coles()`](https://johngavin.github.io/footbet/reference/fit_dixon_coles.md)
  : Fit a Dixon-Coles model using goalmodel
- [`fit_poisson_glm()`](https://johngavin.github.io/footbet/reference/fit_poisson_glm.md)
  : Fit a Poisson GLM baseline model
- [`fit_xgboost()`](https://johngavin.github.io/footbet/reference/fit_xgboost.md)
  : Fit XGBoost model for match outcome prediction
- [`kalman`](https://johngavin.github.io/footbet/reference/kalman.md) :
  Kalman Filter for Dynamic Team Strength Estimation
- [`kalman_strengths()`](https://johngavin.github.io/footbet/reference/kalman_strengths.md)
  : Run Kalman filter over a season for one league
- [`kalman_tune()`](https://johngavin.github.io/footbet/reference/kalman_tune.md)
  : Tune Kalman filter hyperparameters via innovation log-likelihood
- [`kalman_update()`](https://johngavin.github.io/footbet/reference/kalman_update.md)
  : Single-step Kalman update
- [`lambdas_from_hda()`](https://johngavin.github.io/footbet/reference/lambdas_from_hda.md)
  : Reverse-engineer Poisson lambdas from 1x2 probabilities
- [`oagd`](https://johngavin.github.io/footbet/reference/oagd.md) :
  Opposition-Adjusted Goal Difference (OAGD) Model
- [`oagd_add_odds()`](https://johngavin.github.io/footbet/reference/oagd_add_odds.md)
  : Add Pinnacle closing odds to match data
- [`oagd_fit_window()`](https://johngavin.github.io/footbet/reference/oagd_fit_window.md)
  : Fit OAGD model on a single matchday window
- [`oagd_form()`](https://johngavin.github.io/footbet/reference/oagd_form.md)
  : Compute exponentially-weighted form from residuals
- [`oagd_match_data()`](https://johngavin.github.io/footbet/reference/oagd_match_data.md)
  : Prepare match data for OAGD modelling
- [`oagd_predict`](https://johngavin.github.io/footbet/reference/oagd_predict.md)
  : OAGD Prediction: Skellam GD Distribution
- [`oagd_predict_all()`](https://johngavin.github.io/footbet/reference/oagd_predict_all.md)
  : Batch-predict probabilities for all matches in a dataset
- [`oagd_predict_match()`](https://johngavin.github.io/footbet/reference/oagd_predict_match.md)
  : Predict match outcome probabilities from OAGD model
- [`oagd_residuals()`](https://johngavin.github.io/footbet/reference/oagd_residuals.md)
  : Compute opposition-adjusted residuals
- [`oagd_roll_fits()`](https://johngavin.github.io/footbet/reference/oagd_roll_fits.md)
  : Fit OAGD model across all matchdays in a league-season
- [`plot_xgb_importance()`](https://johngavin.github.io/footbet/reference/plot_xgb_importance.md)
  : Plot XGBoost feature importance
- [`predict_ah()`](https://johngavin.github.io/footbet/reference/predict_ah.md)
  : Predict Asian Handicap cover probability from score matrix
- [`predict_brms()`](https://johngavin.github.io/footbet/reference/predict_brms.md)
  : Predict match outcome probabilities from a brms Poisson model
- [`predict_correct_score()`](https://johngavin.github.io/footbet/reference/predict_correct_score.md)
  : Predict correct score probabilities for a match
- [`predict_dc()`](https://johngavin.github.io/footbet/reference/predict_dc.md)
  : Predict match probabilities from a Dixon-Coles model
- [`predict_glm()`](https://johngavin.github.io/footbet/reference/predict_glm.md)
  : Predict match probabilities from a fitted Poisson GLM
- [`predict_matches_brms()`](https://johngavin.github.io/footbet/reference/predict_matches_brms.md)
  : Batch predict matches from a brms model
- [`predict_matches_dc()`](https://johngavin.github.io/footbet/reference/predict_matches_dc.md)
  : Predict 1X2 probabilities for all matches using Dixon-Coles
- [`predict_matches_glm()`](https://johngavin.github.io/footbet/reference/predict_matches_glm.md)
  : Predict 1X2 probabilities for all matches in a dataset
- [`predict_matches_xgb()`](https://johngavin.github.io/footbet/reference/predict_matches_xgb.md)
  : Predict matches with XGBoost model
- [`predict_ou()`](https://johngavin.github.io/footbet/reference/predict_ou.md)
  : Predict Over/Under probability from score matrix
- [`predict_xgboost()`](https://johngavin.github.io/footbet/reference/predict_xgboost.md)
  : Predict with XGBoost model
- [`prepare_xgb_features()`](https://johngavin.github.io/footbet/reference/prepare_xgb_features.md)
  : Prepare feature matrix for XGBoost
- [`score_matrix()`](https://johngavin.github.io/footbet/reference/score_matrix.md)
  : Predict score probabilities from a Poisson model
- [`score_matrix_probs()`](https://johngavin.github.io/footbet/reference/score_matrix_probs.md)
  : Extract match probabilities from a score matrix
- [`score_matrix_to_1x2()`](https://johngavin.github.io/footbet/reference/score_matrix_to_1x2.md)
  : Convert score matrix to 1X2 probabilities
- [`score_matrix_to_ah()`](https://johngavin.github.io/footbet/reference/score_matrix_to_ah.md)
  : Convert score matrix to Asian handicap probabilities
- [`score_matrix_to_ou()`](https://johngavin.github.io/footbet/reference/score_matrix_to_ou.md)
  : Convert score matrix to over/under 2.5 goals probabilities
- [`score_probability()`](https://johngavin.github.io/footbet/reference/score_probability.md)
  : Get probability for a specific scoreline
- [`temporal_split()`](https://johngavin.github.io/footbet/reference/temporal_split.md)
  : Split matches into train/validate/test periods
- [`top_scorelines()`](https://johngavin.github.io/footbet/reference/top_scorelines.md)
  : Get top N most likely scorelines
- [`tune_xgboost()`](https://johngavin.github.io/footbet/reference/tune_xgboost.md)
  : Hyperparameter grid search for XGBoost

## Model Evaluation

Evaluate model performance and calibration

- [`bet_returns()`](https://johngavin.github.io/footbet/reference/bet_returns.md)
  : Compute returns from bet results
- [`betting_sharpe_ratio()`](https://johngavin.github.io/footbet/reference/betting_sharpe_ratio.md)
  : Compute Sharpe ratio for betting returns
- [`brier_1x2()`](https://johngavin.github.io/footbet/reference/brier_1x2.md)
  : Compute Brier score for 1X2 predictions
- [`brier_decomposition()`](https://johngavin.github.io/footbet/reference/brier_decomposition.md)
  : Decompose Brier score into reliability, resolution, and uncertainty
- [`brier_decomposition_1x2()`](https://johngavin.github.io/footbet/reference/brier_decomposition_1x2.md)
  : Decompose Brier score for 1X2 predictions
- [`closing_line_value()`](https://johngavin.github.io/footbet/reference/closing_line_value.md)
  : Compute closing line value (CLV)
- [`clv_1x2()`](https://johngavin.github.io/footbet/reference/clv_1x2.md)
  : Compute CLV for 1X2 predictions
- [`collect_fold_predictions()`](https://johngavin.github.io/footbet/reference/collect_fold_predictions.md)
  : Collect match-level predictions from walk-forward CV
- [`compute_ensemble_weights()`](https://johngavin.github.io/footbet/reference/compute_ensemble_weights.md)
  : Compute optimal ensemble weights from historical performance
- [`consensus_implied()`](https://johngavin.github.io/footbet/reference/consensus_implied.md)
  : Market consensus implied probabilities (average bookmaker)
- [`evaluate_glm_baseline()`](https://johngavin.github.io/footbet/reference/evaluate_glm_baseline.md)
  : Run walk-forward evaluation for the Poisson GLM baseline
- [`evaluate_market_baselines()`](https://johngavin.github.io/footbet/reference/evaluate_market_baselines.md)
  : Evaluate market baselines (Pinnacle + consensus) against actual
  results
- [`evaluate_xgboost()`](https://johngavin.github.io/footbet/reference/evaluate_xgboost.md)
  : Evaluate XGBoost model performance
- [`log_loss()`](https://johngavin.github.io/footbet/reference/log_loss.md)
  : Compute log loss for probability predictions
- [`pinnacle_implied()`](https://johngavin.github.io/footbet/reference/pinnacle_implied.md)
  : Compute implied probabilities from Pinnacle odds (benchmark)
- [`ranger_walkforward_cv()`](https://johngavin.github.io/footbet/reference/ranger_walkforward_cv.md)
  : Walk-forward CV for Ranger random forest (1X2 classification)
- [`reliability_curve_data()`](https://johngavin.github.io/footbet/reference/reliability_curve_data.md)
  : Compute reliability curve data for calibration plots
- [`rps_1x2()`](https://johngavin.github.io/footbet/reference/rps_1x2.md)
  : Compute Ranked Probability Score for ordered outcomes
- [`summarise_betting_performance()`](https://johngavin.github.io/footbet/reference/summarise_betting_performance.md)
  : Summarise betting performance
- [`summarise_clv()`](https://johngavin.github.io/footbet/reference/summarise_clv.md)
  : Summarise CLV statistics
- [`summarise_cv()`](https://johngavin.github.io/footbet/reference/summarise_cv.md)
  : Summarise walk-forward evaluation results
- [`walk_forward_splits()`](https://johngavin.github.io/footbet/reference/walk_forward_splits.md)
  : Create walk-forward time splits
- [`xgboost_walkforward_cv()`](https://johngavin.github.io/footbet/reference/xgboost_walkforward_cv.md)
  : Walk-forward CV for XGBoost (1X2 multi-class)

## Probability Calibration

Platt scaling and isotonic regression for calibrating probabilities

- [`fit_isotonic_regression()`](https://johngavin.github.io/footbet/reference/fit_isotonic_regression.md)
  : Calibrate probabilities using isotonic regression
- [`fit_platt_scaling()`](https://johngavin.github.io/footbet/reference/fit_platt_scaling.md)
  : Calibrate probabilities using Platt scaling
- [`predict_isotonic()`](https://johngavin.github.io/footbet/reference/predict_isotonic.md)
  : Apply isotonic calibration to new predictions
- [`predict_platt()`](https://johngavin.github.io/footbet/reference/predict_platt.md)
  : Apply Platt scaling calibration to new predictions

## Meta-Analytics

Discrimination and stability metrics for statistic evaluation

- [`compute_meta_analytics()`](https://johngavin.github.io/footbet/reference/compute_meta_analytics.md)
  : Compute meta-analytics for multiple statistics
- [`stat_discrimination()`](https://johngavin.github.io/footbet/reference/stat_discrimination.md)
  : Compute discrimination meta-metric for a statistic
- [`stat_stability()`](https://johngavin.github.io/footbet/reference/stat_stability.md)
  : Compute stability meta-metric for a statistic

## Betting Strategy

Kelly criterion and bankroll management

- [`ah_bets_from_preds()`](https://johngavin.github.io/footbet/reference/ah_bets_from_preds.md)
  : Generate AH bets from any prediction dataframe
- [`apply_guardrails()`](https://johngavin.github.io/footbet/reference/apply_guardrails.md)
  : Apply drawdown guardrails to stake
- [`attach_clv()`](https://johngavin.github.io/footbet/reference/attach_clv.md)
  : Attach closing AH prices and compute per-bet CLV
- [`clv`](https://johngavin.github.io/footbet/reference/clv.md) :
  Closing Line Value (CLV) diagnostics for Asian Handicap bets
- [`expanding_clv_window()`](https://johngavin.github.io/footbet/reference/expanding_clv_window.md)
  : Expanding-window devigged CLV with baseline comparison
- [`find_value_bets()`](https://johngavin.github.io/footbet/reference/find_value_bets.md)
  : Find value bets across all matches for 1X2 market
- [`identify_value_bet()`](https://johngavin.github.io/footbet/reference/identify_value_bet.md)
  : Identify value bets from model vs market probabilities
- [`kelly_fraction()`](https://johngavin.github.io/footbet/reference/kelly_fraction.md)
  : Calculate fractional Kelly stake
- [`load_closing_ah_prices()`](https://johngavin.github.io/footbet/reference/load_closing_ah_prices.md)
  : Load closing Asian Handicap prices from raw football-data.co.uk CSVs
- [`oagd_backtest`](https://johngavin.github.io/footbet/reference/oagd_backtest.md)
  : OAGD Backtest Harness
- [`oagd_backtest_league()`](https://johngavin.github.io/footbet/reference/oagd_backtest_league.md)
  : Run OAGD backtest for one league-season
- [`oagd_backtest_summary()`](https://johngavin.github.io/footbet/reference/oagd_backtest_summary.md)
  : Summarise backtest results
- [`oagd_edge()`](https://johngavin.github.io/footbet/reference/oagd_edge.md)
  : Compute edge of model probability over implied probability
- [`oagd_grid()`](https://johngavin.github.io/footbet/reference/oagd_grid.md)
  : Generate hyperparameter grid for OAGD tuning
- [`oagd_pnl()`](https://johngavin.github.io/footbet/reference/oagd_pnl.md)
  : Compute PnL for a single bet
- [`oagd_stake()`](https://johngavin.github.io/footbet/reference/oagd_stake.md)
  : Determine stake from edge using tiered thresholds
- [`simulate_pnl()`](https://johngavin.github.io/footbet/reference/simulate_pnl.md)
  : Simulate betting P&L from a series of value bets
- [`summarise_ah_clv()`](https://johngavin.github.io/footbet/reference/summarise_ah_clv.md)
  : Summarise CLV metrics overall and by league
- [`summarise_pnl()`](https://johngavin.github.io/footbet/reference/summarise_pnl.md)
  : Summarise P&L simulation results

## Accumulators & Bankroll

Accumulator bets and bankroll simulation

- [`acca_ev()`](https://johngavin.github.io/footbet/reference/acca_ev.md)
  : Compute expected value of an accumulator
- [`acca_odds()`](https://johngavin.github.io/footbet/reference/acca_odds.md)
  : Compute combined accumulator odds
- [`adjust_for_league_strength()`](https://johngavin.github.io/footbet/reference/adjust_for_league_strength.md)
  : Adjust predictions for league strength
- [`analyze_steam_moves()`](https://johngavin.github.io/footbet/reference/analyze_steam_moves.md)
  : Analyze line movement by outcome
- [`bankroll_growth_target()`](https://johngavin.github.io/footbet/reference/bankroll_growth_target.md)
  : Compute bankroll growth target
- [`detect_flb()`](https://johngavin.github.io/footbet/reference/detect_flb.md)
  : Detect favourite-longshot bias in odds
- [`estimate_league_strength()`](https://johngavin.github.io/footbet/reference/estimate_league_strength.md)
  : Estimate relative league strengths
- [`find_best_accas()`](https://johngavin.github.io/footbet/reference/find_best_accas.md)
  : Find optimal accumulator combinations
- [`generate_bias_alerts()`](https://johngavin.github.io/footbet/reference/generate_bias_alerts.md)
  : Generate betting alerts based on bias detection
- [`line_movement()`](https://johngavin.github.io/footbet/reference/line_movement.md)
  : Compute opening-to-closing line movement
- [`multi_kelly_stakes()`](https://johngavin.github.io/footbet/reference/multi_kelly_stakes.md)
  : Compute stakes for multiple bets using Kelly criterion
- [`simulate_bankroll_growth()`](https://johngavin.github.io/footbet/reference/simulate_bankroll_growth.md)
  : Simulate bankroll trajectory
- [`standard_league_strengths()`](https://johngavin.github.io/footbet/reference/standard_league_strengths.md)
  : Get standard league strength coefficients
- [`summarize_flb()`](https://johngavin.github.io/footbet/reference/summarize_flb.md)
  : Summarize favourite-longshot bias

## Simulation

Monte Carlo simulation for accumulators and rare events

- [`accumulator_probability()`](https://johngavin.github.io/footbet/reference/accumulator_probability.md)
  : Compute accumulator (parlay) probability with correlation
- [`importance_sample_rare()`](https://johngavin.github.io/footbet/reference/importance_sample_rare.md)
  : Importance sampling for rare match outcomes
- [`joint_outcome_probability()`](https://johngavin.github.io/footbet/reference/joint_outcome_probability.md)
  : Compute joint outcome probabilities from correlated simulations
- [`simulate_correlated_matches()`](https://johngavin.github.io/footbet/reference/simulate_correlated_matches.md)
  : Simulate correlated match outcomes using Gaussian copula
- [`simulate_match_vr()`](https://johngavin.github.io/footbet/reference/simulate_match_vr.md)
  : Monte Carlo simulation with variance reduction
- [`simulation`](https://johngavin.github.io/footbet/reference/simulation.md)
  : Quant Simulation Methods

## Database

DuckDB storage and retrieval

- [`connect_db()`](https://johngavin.github.io/footbet/reference/connect_db.md)
  : Connect to the footbet DuckDB database
- [`create_predictions_schema()`](https://johngavin.github.io/footbet/reference/create_predictions_schema.md)
  : Create predictions table schema
- [`create_schema()`](https://johngavin.github.io/footbet/reference/create_schema.md)
  : Create the footbet database schema
- [`disconnect_db()`](https://johngavin.github.io/footbet/reference/disconnect_db.md)
  : Disconnect from the DuckDB database
- [`insert_match_odds()`](https://johngavin.github.io/footbet/reference/insert_match_odds.md)
  : Insert parsed odds data into DuckDB
- [`insert_matches()`](https://johngavin.github.io/footbet/reference/insert_matches.md)
  : Insert parsed match data into DuckDB
- [`insert_transfers()`](https://johngavin.github.io/footbet/reference/insert_transfers.md)
  : Insert transfer data into DuckDB
- [`log_prediction()`](https://johngavin.github.io/footbet/reference/log_prediction.md)
  : Log model prediction to database
- [`log_predictions_batch()`](https://johngavin.github.io/footbet/reference/log_predictions_batch.md)
  : Batch log predictions from a tibble
- [`query_predictions()`](https://johngavin.github.io/footbet/reference/query_predictions.md)
  : Query predictions for analysis
- [`update_prediction_outcome()`](https://johngavin.github.io/footbet/reference/update_prediction_outcome.md)
  : Update prediction outcomes after match completion
- [`write_matches_parquet()`](https://johngavin.github.io/footbet/reference/write_matches_parquet.md)
  : Write match data as partitioned Parquet
- [`write_odds_parquet()`](https://johngavin.github.io/footbet/reference/write_odds_parquet.md)
  : Write odds data as partitioned Parquet

## Visualization

Interactive plotly visualizations with dark theme

- [`COUNTRY_COLORS`](https://johngavin.github.io/footbet/reference/COUNTRY_COLORS.md)
  : Country color palette
- [`TIER_COLORS`](https://johngavin.github.io/footbet/reference/TIER_COLORS.md)
  : Tier color palette
- [`add_league_metadata()`](https://johngavin.github.io/footbet/reference/add_league_metadata.md)
  : Add league tier and country metadata
- [`add_time_slider()`](https://johngavin.github.io/footbet/reference/add_time_slider.md)
  : Add range slider to time series plotly
- [`plot_dark_bar()`](https://johngavin.github.io/footbet/reference/plot_dark_bar.md)
  : Create dark-themed plotly bar chart
- [`plot_dark_box()`](https://johngavin.github.io/footbet/reference/plot_dark_box.md)
  : Create dark-themed plotly box plot
- [`plot_dark_heatmap()`](https://johngavin.github.io/footbet/reference/plot_dark_heatmap.md)
  : Create dark-themed plotly heatmap
- [`plot_dark_line()`](https://johngavin.github.io/footbet/reference/plot_dark_line.md)
  : Create dark-themed plotly line chart
- [`theme_dark_plotly()`](https://johngavin.github.io/footbet/reference/theme_dark_plotly.md)
  : Dark theme for plotly plots

## Utilities

Helper functions

- [`fd_url()`](https://johngavin.github.io/footbet/reference/fd_url.md)
  : Build football-data.co.uk URL for a league/season CSV
- [`make_match_id()`](https://johngavin.github.io/footbet/reference/make_match_id.md)
  : Generate a unique match ID
- [`target_leagues()`](https://johngavin.github.io/footbet/reference/target_leagues.md)
  : Target leagues for data acquisition
- [`target_seasons()`](https://johngavin.github.io/footbet/reference/target_seasons.md)
  : Target seasons for data acquisition

## Diagrams

Auto-generated mermaid flowcharts for documentation

- [`generate_cv_walkforward_mermaid()`](https://johngavin.github.io/footbet/reference/generate_cv_walkforward_mermaid.md)
  : Generate walk-forward CV mermaid flowchart
- [`generate_data_pipeline_mermaid()`](https://johngavin.github.io/footbet/reference/generate_data_pipeline_mermaid.md)
  : Generate data pipeline mermaid flowchart
- [`generate_kelly_decision_mermaid()`](https://johngavin.github.io/footbet/reference/generate_kelly_decision_mermaid.md)
  : Generate Kelly decision tree mermaid flowchart
- [`wrap_mermaid_fenced()`](https://johngavin.github.io/footbet/reference/wrap_mermaid_fenced.md)
  : Wrap mermaid code in fenced block for README.md
- [`wrap_mermaid_html()`](https://johngavin.github.io/footbet/reference/wrap_mermaid_html.md)
  : Wrap mermaid code in HTML div for vignettes
