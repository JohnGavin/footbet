

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

1.  **Data**: football-data.co.uk match results + Pinnacle closing odds
2.  **Features**: Rolling goals, Elo ratings, devigged implied
    probabilities
3.  **Models**: Poisson GLM baseline, Dixon-Coles, Elo-based
4.  **Evaluation**: Walk-forward CV with log-loss, Brier score,
    calibration
5.  **Decisions**: Fractional Kelly staking with drawdown guardrails

## Project Structure

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
    │   ├── features.R
    │   ├── globals.R
    │   ├── kelly.R
    │   ├── models_baseline.R
    │   ├── models_brms.R
    │   ├── models_dc.R
    │   ├── models_eval.R
    │   ├── models_xgboost.R
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
    ├── README.qmd
    ├── README.rmarkdown
    ├── _pkgdown.yml
    ├── _targets
    │   ├── meta
    │   │   ├── meta
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
    │   │   ├── rolling_10
    │   │   ├── rolling_38
    │   │   ├── rolling_5
    │   │   ├── seasons
    │   │   └── wf_splits
    │   ├── user
    │   └── workspaces
    │       ├── parsed_matches
    │       └── seasons
    ├── _targets.R
    ├── default.R
    ├── default.nix
    ├── default.sh
    ├── inst
    │   └── extdata
    │       ├── parquet
    │       └── raw
    ├── man
    │   ├── acca_ev.Rd
    │   ├── acca_odds.Rd
    │   ├── accumulator_probability.Rd
    │   ├── add_form_streaks.Rd
    │   ├── add_h2h_features.Rd
    │   ├── add_league_positions.Rd
    │   ├── add_player_availability.Rd
    │   ├── add_rest_days.Rd
    │   ├── add_understat_xg.Rd
    │   ├── american_to_decimal.Rd
    │   ├── apply_guardrails.Rd
    │   ├── bankroll_growth_target.Rd
    │   ├── bet_returns.Rd
    │   ├── betting_sharpe_ratio.Rd
    │   ├── brier_1x2.Rd
    │   ├── calc_overround.Rd
    │   ├── closing_line_value.Rd
    │   ├── clv_1x2.Rd
    │   ├── compute_elo.Rd
    │   ├── compute_ensemble_weights.Rd
    │   ├── compute_xg_features.Rd
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
    │   ├── devig_basic.Rd
    │   ├── devig_odds.Rd
    │   ├── devig_power.Rd
    │   ├── devig_shin.Rd
    │   ├── disconnect_db.Rd
    │   ├── download_all_fd.Rd
    │   ├── download_fd_csv.Rd
    │   ├── ensemble_predict.Rd
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
    │   ├── fit_brms_poisson.Rd
    │   ├── fit_dixon_coles.Rd
    │   ├── fit_poisson_glm.Rd
    │   ├── fit_xgboost.Rd
    │   ├── footbet-package.Rd
    │   ├── form_streak.Rd
    │   ├── fractional_to_decimal.Rd
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
    │   ├── log_loss.Rd
    │   ├── log_prediction.Rd
    │   ├── log_predictions_batch.Rd
    │   ├── make_match_id.Rd
    │   ├── matches_to_long.Rd
    │   ├── multi_kelly_stakes.Rd
    │   ├── parse_fd_csv.Rd
    │   ├── parse_fd_odds.Rd
    │   ├── pinnacle_implied.Rd
    │   ├── plot_xgb_importance.Rd
    │   ├── predict_brms.Rd
    │   ├── predict_correct_score.Rd
    │   ├── predict_dc.Rd
    │   ├── predict_glm.Rd
    │   ├── predict_matches_brms.Rd
    │   ├── predict_matches_dc.Rd
    │   ├── predict_matches_glm.Rd
    │   ├── predict_matches_xgb.Rd
    │   ├── predict_xgboost.Rd
    │   ├── prepare_xgb_features.Rd
    │   ├── query_predictions.Rd
    │   ├── rest_days.Rd
    │   ├── rolling_goals.Rd
    │   ├── rolling_xg.Rd
    │   ├── rps_1x2.Rd
    │   ├── score_matrix.Rd
    │   ├── score_matrix_to_1x2.Rd
    │   ├── score_matrix_to_ah.Rd
    │   ├── score_matrix_to_ou.Rd
    │   ├── score_probability.Rd
    │   ├── simulate_bankroll_growth.Rd
    │   ├── simulate_correlated_matches.Rd
    │   ├── simulate_match_vr.Rd
    │   ├── simulate_pnl.Rd
    │   ├── simulation.Rd
    │   ├── summarise_betting_performance.Rd
    │   ├── summarise_clv.Rd
    │   ├── summarise_cv.Rd
    │   ├── summarise_pnl.Rd
    │   ├── target_leagues.Rd
    │   ├── target_seasons.Rd
    │   ├── team_position.Rd
    │   ├── top_scorelines.Rd
    │   ├── tune_xgboost.Rd
    │   ├── understat_team_mapping.Rd
    │   ├── update_prediction_outcome.Rd
    │   ├── walk_forward_splits.Rd
    │   ├── write_matches_parquet.Rd
    │   ├── write_odds_parquet.Rd
    │   └── xg_overperformance.Rd
    ├── package.nix
    ├── pkgdown
    │   └── extra.css
    ├── plans
    │   ├── PLAN_scaffold.md
    │   └── PLAN_vignettes.md
    ├── prompt_football.md
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
    │   │   ├── test-features.R
    │   │   ├── test-kelly.R
    │   │   ├── test-models-clv.R
    │   │   ├── test-models-correct-score.R
    │   │   ├── test-models-ensemble.R
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
        ├── betting-glossary.Rmd
        ├── data-cleaning.Rmd
        ├── data-sources.Rmd
        ├── eda.Rmd
        └── model-fitting.Rmd

## License

MIT
