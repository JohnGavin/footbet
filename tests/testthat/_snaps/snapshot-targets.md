# vig_data_source_summary structure

    Code
      snapshot_structure(obj, "vig_data_source_summary")
    Output
      Target: vig_data_source_summary 
      Class: tbl_df, tbl, data.frame 
      Columns: country, league_code, division, n_seasons, n_matches, first_date, last_date 
      Rows: 10 

# vig_league_season_grid structure

    Code
      snapshot_structure(obj, "vig_league_season_grid")
    Output
      Target: vig_league_season_grid 
      Class: tbl_df, tbl, data.frame 
      Columns: league_code, 1516, 1617, 1718, 1819, 1920, 2021, 2122, 2223, 2324, 2425, 2526 
      Rows: 10 

# vig_typical_match_stats structure

    Code
      snapshot_structure(obj, "vig_typical_match_stats")
    Output
      Target: vig_typical_match_stats 
      Class: tbl_df, tbl, data.frame 
      Columns: league_code, hs, as_, hst, ast, hf, af, hc, ac, hy, ay, hr, ar, n_matches 
      Rows: 10 

# vig_goals_distribution structure

    Code
      snapshot_structure(obj, "vig_goals_distribution")
    Output
      Target: vig_goals_distribution 
      Class: plotly, htmlwidget 
      Type: htmlwidget/plotly

# vig_result_proportions structure

    Code
      snapshot_structure(obj, "vig_result_proportions")
    Output
      Target: vig_result_proportions 
      Class: plotly, htmlwidget 
      Type: htmlwidget/plotly

# vig_scoreline_heatmap structure

    Code
      snapshot_structure(obj, "vig_scoreline_heatmap")
    Output
      Target: vig_scoreline_heatmap 
      Class: plotly, htmlwidget 
      Type: htmlwidget/plotly

# vig_home_advantage_by_league structure

    Code
      snapshot_structure(obj, "vig_home_advantage_by_league")
    Output
      Target: vig_home_advantage_by_league 
      Class: plotly, htmlwidget 
      Type: htmlwidget/plotly

# vig_goals_per_season_trend structure

    Code
      snapshot_structure(obj, "vig_goals_per_season_trend")
    Output
      Target: vig_goals_per_season_trend 
      Class: plotly, htmlwidget 
      Type: htmlwidget/plotly

# vig_matches_per_season_plot structure

    Code
      snapshot_structure(obj, "vig_matches_per_season_plot")
    Output
      Target: vig_matches_per_season_plot 
      Class: plotly, htmlwidget 
      Type: htmlwidget/plotly

# vig_missing_data_by_column structure

    Code
      snapshot_structure(obj, "vig_missing_data_by_column")
    Output
      Target: vig_missing_data_by_column 
      Class: tbl_df, tbl, data.frame 
      Columns: column, description, n_missing, pct_missing, n_total 
      Rows: 21 

# vig_missing_data_heatmap structure

    Code
      snapshot_structure(obj, "vig_missing_data_heatmap")
    Output
      Target: vig_missing_data_heatmap 
      Class: plotly, htmlwidget 
      Type: htmlwidget/plotly

# vig_anomalies_table structure

    Code
      snapshot_structure(obj, "vig_anomalies_table")
    Output
      Target: vig_anomalies_table 
      Class: tbl_df, tbl, data.frame 
      Columns: match_id, league_code, season, match_date, home_team, away_team, fthg, ftag, flag 
      Rows: 2 

# vig_outlier_matches structure

    Code
      snapshot_structure(obj, "vig_outlier_matches")
    Output
      Target: vig_outlier_matches 
      Class: tbl_df, tbl, data.frame 
      Columns: match_id, league_code, season, match_date, home_team, away_team, fthg, ftag, total_goals 
      Rows: 258 

# vig_completeness_plot structure

    Code
      snapshot_structure(obj, "vig_completeness_plot")
    Output
      Target: vig_completeness_plot 
      Class: datatables, htmlwidget 
      Type: htmlwidget/plotly

# vig_odds_columns_available structure

    Code
      snapshot_structure(obj, "vig_odds_columns_available")
    Output
      Target: vig_odds_columns_available 
      Class: tbl_df, tbl, data.frame 
      Columns: league_code, season, n_matches, pct_1x2, pct_over_under 
      Rows: 110 

# vig_odds_vs_result structure

    Code
      snapshot_structure(obj, "vig_odds_vs_result")
    Output
      Target: vig_odds_vs_result 
      Class: plotly, htmlwidget 
      Type: htmlwidget/plotly

# vig_overround_by_league structure

    Code
      snapshot_structure(obj, "vig_overround_by_league")
    Output
      Target: vig_overround_by_league 
      Class: plotly, htmlwidget 
      Type: htmlwidget/plotly

# vig_pinnacle_coverage_plot structure

    Code
      snapshot_structure(obj, "vig_pinnacle_coverage_plot")
    Output
      Target: vig_pinnacle_coverage_plot 
      Class: plotly, htmlwidget 
      Type: htmlwidget/plotly

# vig_poisson_test structure

    Code
      snapshot_structure(obj, "vig_poisson_test")
    Output
      Target: vig_poisson_test 
      Class: tbl_df, tbl, data.frame 
      Columns: test, mean_goals, variance, dispersion_ratio, n_goals, conclusion 
      Rows: 1 

# vig_elo_spread_plot structure

    Code
      snapshot_structure(obj, "vig_elo_spread_plot")
    Output
      Target: vig_elo_spread_plot 
      Class: plotly, htmlwidget 
      Type: htmlwidget/plotly

# vig_shrinkage_plot structure

    Code
      snapshot_structure(obj, "vig_shrinkage_plot")
    Output
      Target: vig_shrinkage_plot 
      Class: ggplot2::ggplot, ggplot, ggplot2::gg, S7_object, gg 
      Type: ggplot

# vig_pp_check_goals structure

    Code
      snapshot_structure(obj, "vig_pp_check_goals")
    Output
      Target: vig_pp_check_goals 
      Class: ggplot2::ggplot, ggplot, ggplot2::gg, S7_object, gg 
      Type: ggplot

# vig_home_trend_test structure

    Code
      snapshot_structure(obj, "vig_home_trend_test")
    Output
      Target: vig_home_trend_test 
      Class: tbl_df, tbl, data.frame 
      Columns: trend_per_season, r_squared, n_seasons, conclusion 
      Rows: 1 

# vig_model_comparison_table structure

    Code
      snapshot_structure(obj, "vig_model_comparison_table")
    Output
      Target: vig_model_comparison_table 
      Class: tbl_df, tbl, data.frame 
      Columns: model, metric, model_mean, pinnacle, edge 
      Rows: 6 

# vig_model_comparison_test structure

    Code
      snapshot_structure(obj, "vig_model_comparison_test")
    Output
      Target: vig_model_comparison_test 
      Class: tbl_df, tbl, data.frame 
      Columns: mean_glm_logloss, mean_dc_logloss, mean_diff, n_folds, conclusion 
      Rows: 1 

# vig_cv_metrics_plot structure

    Code
      snapshot_structure(obj, "vig_cv_metrics_plot")
    Output
      Target: vig_cv_metrics_plot 
      Class: plotly, htmlwidget 
      Type: htmlwidget/plotly

# vig_cv_html structure

    Code
      snapshot_structure(obj, "vig_cv_html")
    Output
      Target: vig_cv_html 
      Class: html, character 
      Type: character, length: 1 

# vig_kelly_stake_distribution structure

    Code
      snapshot_structure(obj, "vig_kelly_stake_distribution")
    Output
      Target: vig_kelly_stake_distribution 
      Class: plotly, htmlwidget 
      Type: htmlwidget/plotly

# vig_kelly_html structure

    Code
      snapshot_structure(obj, "vig_kelly_html")
    Output
      Target: vig_kelly_html 
      Class: html, character 
      Type: character, length: 1 

# vig_edge_distribution structure

    Code
      snapshot_structure(obj, "vig_edge_distribution")
    Output
      Target: vig_edge_distribution 
      Class: plotly, htmlwidget 
      Type: htmlwidget/plotly

# vig_value_bets_summary structure

    Code
      snapshot_structure(obj, "vig_value_bets_summary")
    Output
      Target: vig_value_bets_summary 
      Class: tbl_df, tbl, data.frame 
      Columns: outcome, league_code, n_bets, mean_edge, mean_odds, mean_kelly 
      Rows: 30 

# vig_pnl_curve structure

    Code
      snapshot_structure(obj, "vig_pnl_curve")
    Output
      Target: vig_pnl_curve 
      Class: plotly, htmlwidget 
      Type: htmlwidget/plotly

# vig_drawdown_plot structure

    Code
      snapshot_structure(obj, "vig_drawdown_plot")
    Output
      Target: vig_drawdown_plot 
      Class: plotly, htmlwidget 
      Type: htmlwidget/plotly

# vig_pnl_summary_table structure

    Code
      snapshot_structure(obj, "vig_pnl_summary_table")
    Output
      Target: vig_pnl_summary_table 
      Class: tbl_df, tbl, data.frame 
      Columns: n_bets, total_pnl, roi_pct, max_drawdown, final_bankroll, win_rate, avg_odds 
      Rows: 1 

# vig_pipeline_html structure

    Code
      snapshot_structure(obj, "vig_pipeline_html")
    Output
      Target: vig_pipeline_html 
      Class: html, character 
      Type: character, length: 1 

