# footbet

European Football Betting Analytics with Sharp Odds.

Download, process, and model European football match data and sharp
bookmaker odds (Pinnacle). Implements Poisson/Dixon-Coles models, Elo
ratings, and Kelly-criterion staking for value betting on full-time and
half-time outcomes.

## Installation

### Standard R

``` r
# install.packages("remotes")
remotes::install_github("johngavin/footbet")
```

### Nix (Recommended)

``` bash
git clone https://github.com/johngavin/footbet.git
cd footbet
./default.sh
```

### rix Integration

``` r
library(rix)
rix(
  r_pkgs = c("dplyr", "arrow", "duckdb"),
  git_pkgs = list(
    list(
      package_name = "footbet",
      repo_url = "https://github.com/johngavin/footbet",
      commit = "HEAD"
    )
  ),
  ide = "none",
  project_path = ".",
  overwrite = TRUE
)
```

## Coverage

10 leagues (top 2 divisions) across 5 countries, 10 years of history:

| Country | Division 1          | Division 2         |
|---------|---------------------|--------------------|
| England | E0 (Premier League) | E1 (Championship)  |
| Germany | D1 (Bundesliga)     | D2 (2. Bundesliga) |
| Italy   | I1 (Serie A)        | I2 (Serie B)       |
| Spain   | SP1 (La Liga)       | SP2 (Segunda)      |
| France  | F1 (Ligue 1)        | F2 (Ligue 2)       |

## Model Pipeline

``` mermaid
flowchart LR
    subgraph Data["Data Acquisition"]
        FD[football-data.co.uk] --> Parse[parse_fd_csv]
        FD --> Odds[parse_fd_odds]
        FB[FBref/Understat] --> XG[fetch_fbref_matches]
    end
    subgraph Features["Feature Engineering"]
        Parse --> Roll[rolling_goals]
        XG --> Roll
        Roll --> Elo[compute_elo]
    end
    subgraph Models["Prediction Models"]
        Elo --> GLM[Poisson GLM]
        Elo --> DC[Dixon-Coles]
        GLM --> Eval[Walk-Forward CV]
        DC --> Eval
    end
    subgraph Betting["Accumulators & Bankroll"]
        Eval --> Value[find_value_bets]
        Odds --> Devig[devig_odds]
        Devig --> Value
        Value --> Kelly[kelly_fraction]
    end
```

## Project Structure

``` R
.
├── DESCRIPTION
├── LICENSE
├── LICENSE.md
├── NAMESPACE
├── R
│   ├── betting.R
│   ├── data_download.R
│   ├── data_fbref.R
│   ├── data_parse.R
│   ├── data_transfers.R
│   ├── data_understat.R
│   ├── data_validation.R
│   ├── database.R
│   ├── dev
│   │   └── issues
│   ├── devig.R
│   ├── diagrams.R
│   ├── features.R
│   ├── globals.R
│   ├── kelly.R
│   ├── models_baseline.R
│   ├── models_brms.R
│   ├── models_dc.R
│   ├── models_eval.R
│   ├── models_xgboost.R
│   ├── plot_theme.R
│   ├── simulation.R
│   ├── tar_plans
│   │   ├── plan_data_acquisition.R
│   │   ├── plan_data_validation.R
│   │   ├── plan_decisions.R
│   │   ├── plan_doc_examples.R
│   │   ├── plan_evaluation.R
│   │   ├── plan_features.R
│   │   ├── plan_models.R
│   │   ├── plan_models_brms.R
│   │   ├── plan_quality_control.R
│   │   ├── plan_transfers.R
│   │   ├── plan_vignette_outputs.R
│   │   └── plan_xg_features.R
│   └── utils.R
├── README.md
├── README.qmd
├── README.rmarkdown
├── _pkgdown.yml
├── _targets
│   ├── meta
│   │   ├── meta
│   │   ├── process
│   │   └── progress
│   ├── objects
│   │   ├── devigged_odds
│   │   ├── downloaded_files
│   │   ├── leagues
│   │   ├── matches_long
│   │   ├── parsed_matches
│   │   ├── parsed_odds
│   │   ├── pinnacle_benchmark
│   │   ├── qc_anomalies
│   │   ├── qc_match_completeness
│   │   ├── qc_pinnacle_coverage
│   │   ├── qc_summary
│   │   ├── readme_pipeline_mermaid
│   │   ├── rolling_10
│   │   ├── rolling_38
│   │   ├── rolling_5
│   │   ├── seasons
│   │   ├── vig_anomalies_table
│   │   ├── vig_completeness_plot
│   │   ├── vig_cv_html
│   │   ├── vig_data_source_summary
│   │   ├── vig_goals_distribution
│   │   ├── vig_goals_per_season_trend
│   │   ├── vig_home_advantage_by_league
│   │   ├── vig_home_trend_test
│   │   ├── vig_kelly_html
│   │   ├── vig_league_season_grid
│   │   ├── vig_matches_per_season_plot
│   │   ├── vig_missing_data_by_column
│   │   ├── vig_missing_data_heatmap
│   │   ├── vig_odds_columns_available
│   │   ├── vig_odds_vs_result
│   │   ├── vig_outlier_matches
│   │   ├── vig_overround_by_league
│   │   ├── vig_pinnacle_coverage_plot
│   │   ├── vig_pipeline_html
│   │   ├── vig_result_proportions
│   │   ├── vig_scoreline_heatmap
│   │   ├── vig_typical_match_stats
│   │   └── wf_splits
│   ├── user
│   └── workspaces
│       ├── dc_cv
│       ├── elo_ratings
│       ├── parsed_matches
│       ├── seasons
│       └── vig_poisson_test
├── _targets.R
├── _targets.yaml
├── default.R
├── default.nix
├── default.sh
├── inst
│   └── extdata
│       ├── parquet
│       ├── raw
│       └── vignettes
├── man
│   ├── acca_ev.Rd
│   ├── acca_odds.Rd
│   ├── accumulator_probability.Rd
│   ├── add_form_streaks.Rd
│   ├── add_h2h_features.Rd
│   ├── add_league_positions.Rd
│   ├── add_player_availability.Rd
│   ├── add_ratio_features.Rd
│   ├── add_rest_days.Rd
│   ├── add_time_slider.Rd
│   ├── add_understat_xg.Rd
│   ├── adjust_for_league_strength.Rd
│   ├── american_to_decimal.Rd
│   ├── analyze_steam_moves.Rd
│   ├── apply_guardrails.Rd
│   ├── bankroll_growth_target.Rd
│   ├── bet_returns.Rd
│   ├── betting_sharpe_ratio.Rd
│   ├── brier_1x2.Rd
│   ├── brier_decomposition.Rd
│   ├── brier_decomposition_1x2.Rd
│   ├── calc_overround.Rd
│   ├── closing_line_value.Rd
│   ├── clv_1x2.Rd
│   ├── compute_elo.Rd
│   ├── compute_ensemble_weights.Rd
│   ├── compute_gamestate_xg.Rd
│   ├── compute_meta_analytics.Rd
│   ├── compute_xg_features.Rd
│   ├── compute_xg_xag_composite.Rd
│   ├── connect_db.Rd
│   ├── convert_odds.Rd
│   ├── correct_score_value.Rd
│   ├── create_predictions_schema.Rd
│   ├── create_schema.Rd
│   ├── cumulative_xg_ratio.Rd
│   ├── cv_xgboost.Rd
│   ├── data_validation.Rd
│   ├── decimal_to_american.Rd
│   ├── decimal_to_fractional.Rd
│   ├── detect_flb.Rd
│   ├── devig_basic.Rd
│   ├── devig_odds.Rd
│   ├── devig_power.Rd
│   ├── devig_shin.Rd
│   ├── disconnect_db.Rd
│   ├── download_all_fd.Rd
│   ├── download_fd_csv.Rd
│   ├── empirical_bayes_shrink.Rd
│   ├── ensemble_predict.Rd
│   ├── estimate_league_strength.Rd
│   ├── evaluate_brms.Rd
│   ├── evaluate_dc.Rd
│   ├── evaluate_glm_baseline.Rd
│   ├── evaluate_xgboost.Rd
│   ├── fd_url.Rd
│   ├── fetch_fbref_all.Rd
│   ├── fetch_fbref_matches.Rd
│   ├── fetch_league_injuries.Rd
│   ├── fetch_league_suspensions.Rd
│   ├── fetch_league_transfers.Rd
│   ├── fetch_squad_values.Rd
│   ├── fetch_understat_xg.Rd
│   ├── find_best_accas.Rd
│   ├── find_value_bets.Rd
│   ├── first_reliable_matchday.Rd
│   ├── fit_brms_poisson.Rd
│   ├── fit_dixon_coles.Rd
│   ├── fit_isotonic_regression.Rd
│   ├── fit_platt_scaling.Rd
│   ├── fit_poisson_glm.Rd
│   ├── fit_xgboost.Rd
│   ├── footbet-package.Rd
│   ├── form_streak.Rd
│   ├── fractional_to_decimal.Rd
│   ├── generate_bias_alerts.Rd
│   ├── generate_cv_walkforward_mermaid.Rd
│   ├── generate_data_pipeline_mermaid.Rd
│   ├── generate_kelly_decision_mermaid.Rd
│   ├── h2h_record.Rd
│   ├── identify_value_bet.Rd
│   ├── importance_sample_rare.Rd
│   ├── insert_match_odds.Rd
│   ├── insert_matches.Rd
│   ├── insert_transfers.Rd
│   ├── join_understat_xg.Rd
│   ├── join_xg_to_matches.Rd
│   ├── joint_outcome_probability.Rd
│   ├── kelly_fraction.Rd
│   ├── key_players_unavailable.Rd
│   ├── league_table.Rd
│   ├── line_movement.Rd
│   ├── log_loss.Rd
│   ├── log_prediction.Rd
│   ├── log_predictions_batch.Rd
│   ├── make_match_id.Rd
│   ├── matches_to_long.Rd
│   ├── multi_kelly_stakes.Rd
│   ├── parse_fd_csv.Rd
│   ├── parse_fd_odds.Rd
│   ├── pinnacle_implied.Rd
│   ├── plot_dark_bar.Rd
│   ├── plot_dark_box.Rd
│   ├── plot_dark_heatmap.Rd
│   ├── plot_dark_line.Rd
│   ├── plot_xgb_importance.Rd
│   ├── predict_brms.Rd
│   ├── predict_correct_score.Rd
│   ├── predict_dc.Rd
│   ├── predict_glm.Rd
│   ├── predict_isotonic.Rd
│   ├── predict_matches_brms.Rd
│   ├── predict_matches_dc.Rd
│   ├── predict_matches_glm.Rd
│   ├── predict_matches_xgb.Rd
│   ├── predict_platt.Rd
│   ├── predict_xgboost.Rd
│   ├── prepare_xgb_features.Rd
│   ├── query_predictions.Rd
│   ├── ratio_normalize.Rd
│   ├── reliability_threshold.Rd
│   ├── rest_days.Rd
│   ├── rolling_goals.Rd
│   ├── rolling_xg.Rd
│   ├── rps_1x2.Rd
│   ├── score_matrix.Rd
│   ├── score_matrix_to_1x2.Rd
│   ├── score_matrix_to_ah.Rd
│   ├── score_matrix_to_ou.Rd
│   ├── score_probability.Rd
│   ├── shrink_team_strength.Rd
│   ├── simulate_bankroll_growth.Rd
│   ├── simulate_correlated_matches.Rd
│   ├── simulate_match_vr.Rd
│   ├── simulate_pnl.Rd
│   ├── simulation.Rd
│   ├── standard_league_strengths.Rd
│   ├── stat_discrimination.Rd
│   ├── stat_stability.Rd
│   ├── summarise_betting_performance.Rd
│   ├── summarise_clv.Rd
│   ├── summarise_cv.Rd
│   ├── summarise_pnl.Rd
│   ├── summarize_flb.Rd
│   ├── target_leagues.Rd
│   ├── target_seasons.Rd
│   ├── team_position.Rd
│   ├── theme_dark_plotly.Rd
│   ├── top_scorelines.Rd
│   ├── tune_xgboost.Rd
│   ├── understat_team_mapping.Rd
│   ├── update_prediction_outcome.Rd
│   ├── walk_forward_splits.Rd
│   ├── wrap_mermaid_fenced.Rd
│   ├── wrap_mermaid_html.Rd
│   ├── write_matches_parquet.Rd
│   ├── write_odds_parquet.Rd
│   └── xg_overperformance.Rd
├── package.nix
├── pkgdown
│   └── extra.css
├── plans
│   ├── PLAN_scaffold.md
│   └── PLAN_vignettes.md
├── push_to_cachix.sh
├── result
├── tests
│   ├── testthat
│   │   ├── _snaps
│   │   ├── test-adversarial-data.R
│   │   ├── test-adversarial-database.R
│   │   ├── test-adversarial-dc.R
│   │   ├── test-adversarial-devig.R
│   │   ├── test-adversarial-features.R
│   │   ├── test-adversarial-kelly.R
│   │   ├── test-adversarial-models.R
│   │   ├── test-adversarial-parse.R
│   │   ├── test-adversarial-transfers.R
│   │   ├── test-adversarial-utils.R
│   │   ├── test-betting-accumulators.R
│   │   ├── test-betting-advanced.R
│   │   ├── test-betting-kelly.R
│   │   ├── test-betting-performance.R
│   │   ├── test-data-understat.R
│   │   ├── test-data_download.R
│   │   ├── test-data_fbref.R
│   │   ├── test-data_parse.R
│   │   ├── test-data_transfers.R
│   │   ├── test-database-predictions.R
│   │   ├── test-database.R
│   │   ├── test-devig.R
│   │   ├── test-features-form-streaks.R
│   │   ├── test-features-h2h.R
│   │   ├── test-features-league-position.R
│   │   ├── test-features-rest-days.R
│   │   ├── test-features-xg-advanced.R
│   │   ├── test-features.R
│   │   ├── test-kelly.R
│   │   ├── test-models-clv.R
│   │   ├── test-models-correct-score.R
│   │   ├── test-models-ensemble.R
│   │   ├── test-models-eval-advanced.R
│   │   ├── test-models-xgboost.R
│   │   ├── test-models_baseline.R
│   │   ├── test-models_brms.R
│   │   ├── test-models_dc.R
│   │   ├── test-models_eval.R
│   │   ├── test-odds-conversion.R
│   │   ├── test-player-availability.R
│   │   ├── test-simulation.R
│   │   ├── test-utils.R
│   │   └── test-xg_features.R
│   └── testthat.R
└── vignettes
    └── football-analytics.qmd
```

## License

MIT
