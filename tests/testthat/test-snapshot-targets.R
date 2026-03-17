# Snapshot tests for target output structure (class, columns, dimensions).
# Catches changes in data pipeline outputs that could break vignettes.
# Review changes with: testthat::snapshot_review()

store <- here::here("_targets")

skip_if_no_targets <- function() {
  skip_if_not(
    file.exists(file.path(store, "meta", "meta")),
    "targets store not found"
  )
}

# Helper to snapshot object structure
snapshot_structure <- function(obj, name) {
  cat("Target:", name, "\n")
  cat("Class:", paste(class(obj), collapse = ", "), "\n")
  if (is.data.frame(obj)) {
    cat("Columns:", paste(names(obj), collapse = ", "), "\n")
    cat("Rows:", nrow(obj), "\n")
  } else if (inherits(obj, "htmlwidget") || inherits(obj, "plotly")) {
    cat("Type: htmlwidget/plotly\n")
  } else if (inherits(obj, "gg") || inherits(obj, "ggplot")) {
    cat("Type: ggplot\n")
  } else if (is.character(obj)) {
    cat("Type: character, length:", length(obj), "\n")
  } else if (is.list(obj)) {
    cat("Type: list, length:", length(obj), "\n")
    if (!is.null(names(obj))) cat("Names:", paste(names(obj), collapse = ", "), "\n")
  }
}

# ---- Data summary targets ----

test_that("vig_data_source_summary structure", {
  skip_if_no_targets()
  obj <- targets::tar_read(vig_data_source_summary, store = store)
  expect_snapshot(snapshot_structure(obj, "vig_data_source_summary"))
})

test_that("vig_league_season_grid structure", {
  skip_if_no_targets()
  obj <- targets::tar_read(vig_league_season_grid, store = store)
  expect_snapshot(snapshot_structure(obj, "vig_league_season_grid"))
})

test_that("vig_typical_match_stats structure", {
  skip_if_no_targets()
  obj <- targets::tar_read(vig_typical_match_stats, store = store)
  expect_snapshot(snapshot_structure(obj, "vig_typical_match_stats"))
})

# ---- Distribution/plot targets ----

test_that("vig_goals_distribution structure", {
  skip_if_no_targets()
  obj <- targets::tar_read(vig_goals_distribution, store = store)
  expect_snapshot(snapshot_structure(obj, "vig_goals_distribution"))
})

test_that("vig_result_proportions structure", {
  skip_if_no_targets()
  obj <- targets::tar_read(vig_result_proportions, store = store)
  expect_snapshot(snapshot_structure(obj, "vig_result_proportions"))
})

test_that("vig_scoreline_heatmap structure", {
  skip_if_no_targets()
  obj <- targets::tar_read(vig_scoreline_heatmap, store = store)
  expect_snapshot(snapshot_structure(obj, "vig_scoreline_heatmap"))
})

test_that("vig_home_advantage_by_league structure", {
  skip_if_no_targets()
  obj <- targets::tar_read(vig_home_advantage_by_league, store = store)
  expect_snapshot(snapshot_structure(obj, "vig_home_advantage_by_league"))
})

test_that("vig_goals_per_season_trend structure", {
  skip_if_no_targets()
  obj <- targets::tar_read(vig_goals_per_season_trend, store = store)
  expect_snapshot(snapshot_structure(obj, "vig_goals_per_season_trend"))
})

test_that("vig_matches_per_season_plot structure", {
  skip_if_no_targets()
  obj <- targets::tar_read(vig_matches_per_season_plot, store = store)
  expect_snapshot(snapshot_structure(obj, "vig_matches_per_season_plot"))
})

# ---- Data quality targets ----

test_that("vig_missing_data_by_column structure", {
  skip_if_no_targets()
  obj <- targets::tar_read(vig_missing_data_by_column, store = store)
  expect_snapshot(snapshot_structure(obj, "vig_missing_data_by_column"))
})

test_that("vig_missing_data_heatmap structure", {
  skip_if_no_targets()
  obj <- targets::tar_read(vig_missing_data_heatmap, store = store)
  expect_snapshot(snapshot_structure(obj, "vig_missing_data_heatmap"))
})

test_that("vig_anomalies_table structure", {
  skip_if_no_targets()
  obj <- targets::tar_read(vig_anomalies_table, store = store)
  expect_snapshot(snapshot_structure(obj, "vig_anomalies_table"))
})

test_that("vig_outlier_matches structure", {
  skip_if_no_targets()
  obj <- targets::tar_read(vig_outlier_matches, store = store)
  expect_snapshot(snapshot_structure(obj, "vig_outlier_matches"))
})

test_that("vig_completeness_plot structure", {
  skip_if_no_targets()
  obj <- targets::tar_read(vig_completeness_plot, store = store)
  expect_snapshot(snapshot_structure(obj, "vig_completeness_plot"))
})

# ---- Odds targets ----

test_that("vig_odds_columns_available structure", {
  skip_if_no_targets()
  obj <- targets::tar_read(vig_odds_columns_available, store = store)
  expect_snapshot(snapshot_structure(obj, "vig_odds_columns_available"))
})

test_that("vig_odds_vs_result structure", {
  skip_if_no_targets()
  obj <- targets::tar_read(vig_odds_vs_result, store = store)
  expect_snapshot(snapshot_structure(obj, "vig_odds_vs_result"))
})

test_that("vig_overround_by_league structure", {
  skip_if_no_targets()
  obj <- targets::tar_read(vig_overround_by_league, store = store)
  expect_snapshot(snapshot_structure(obj, "vig_overround_by_league"))
})

test_that("vig_pinnacle_coverage_plot structure", {
  skip_if_no_targets()
  obj <- targets::tar_read(vig_pinnacle_coverage_plot, store = store)
  expect_snapshot(snapshot_structure(obj, "vig_pinnacle_coverage_plot"))
})

# ---- Model targets ----

test_that("vig_poisson_test structure", {
  skip_if_no_targets()
  obj <- targets::tar_read(vig_poisson_test, store = store)
  expect_snapshot(snapshot_structure(obj, "vig_poisson_test"))
})

test_that("vig_elo_spread_plot structure", {
  skip_if_no_targets()
  obj <- targets::tar_read(vig_elo_spread_plot, store = store)
  expect_snapshot(snapshot_structure(obj, "vig_elo_spread_plot"))
})

test_that("vig_shrinkage_plot structure", {
  skip_if_no_targets()
  obj <- targets::tar_read(vig_shrinkage_plot, store = store)
  expect_snapshot(snapshot_structure(obj, "vig_shrinkage_plot"))
})

test_that("vig_pp_check_goals structure", {
  skip_if_no_targets()
  obj <- targets::tar_read(vig_pp_check_goals, store = store)
  expect_snapshot(snapshot_structure(obj, "vig_pp_check_goals"))
})

test_that("vig_home_trend_test structure", {
  skip_if_no_targets()
  obj <- targets::tar_read(vig_home_trend_test, store = store)
  expect_snapshot(snapshot_structure(obj, "vig_home_trend_test"))
})

test_that("vig_model_comparison_table structure", {
  skip_if_no_targets()
  obj <- targets::tar_read(vig_model_comparison_table, store = store)
  expect_snapshot(snapshot_structure(obj, "vig_model_comparison_table"))
})

test_that("vig_model_comparison_test structure", {
  skip_if_no_targets()
  obj <- targets::tar_read(vig_model_comparison_test, store = store)
  expect_snapshot(snapshot_structure(obj, "vig_model_comparison_test"))
})

# ---- CV targets ----

test_that("vig_cv_metrics_plot structure", {
  skip_if_no_targets()
  obj <- targets::tar_read(vig_cv_metrics_plot, store = store)
  expect_snapshot(snapshot_structure(obj, "vig_cv_metrics_plot"))
})

test_that("vig_cv_html structure", {
  skip_if_no_targets()
  obj <- targets::tar_read(vig_cv_html, store = store)
  expect_snapshot(snapshot_structure(obj, "vig_cv_html"))
})

# ---- Betting/Kelly targets ----

test_that("vig_kelly_stake_distribution structure", {
  skip_if_no_targets()
  obj <- targets::tar_read(vig_kelly_stake_distribution, store = store)
  expect_snapshot(snapshot_structure(obj, "vig_kelly_stake_distribution"))
})

test_that("vig_kelly_html structure", {
  skip_if_no_targets()
  obj <- targets::tar_read(vig_kelly_html, store = store)
  expect_snapshot(snapshot_structure(obj, "vig_kelly_html"))
})

test_that("vig_edge_distribution structure", {
  skip_if_no_targets()
  obj <- targets::tar_read(vig_edge_distribution, store = store)
  expect_snapshot(snapshot_structure(obj, "vig_edge_distribution"))
})

test_that("vig_value_bets_summary structure", {
  skip_if_no_targets()
  obj <- targets::tar_read(vig_value_bets_summary, store = store)
  expect_snapshot(snapshot_structure(obj, "vig_value_bets_summary"))
})

# ---- PnL targets ----

test_that("vig_pnl_curve structure", {
  skip_if_no_targets()
  obj <- targets::tar_read(vig_pnl_curve, store = store)
  expect_snapshot(snapshot_structure(obj, "vig_pnl_curve"))
})

test_that("vig_drawdown_plot structure", {
  skip_if_no_targets()
  obj <- targets::tar_read(vig_drawdown_plot, store = store)
  expect_snapshot(snapshot_structure(obj, "vig_drawdown_plot"))
})

test_that("vig_pnl_summary_table structure", {
  skip_if_no_targets()
  obj <- targets::tar_read(vig_pnl_summary_table, store = store)
  expect_snapshot(snapshot_structure(obj, "vig_pnl_summary_table"))
})

# ---- Pipeline HTML target ----

test_that("vig_pipeline_html structure", {
  skip_if_no_targets()
  obj <- targets::tar_read(vig_pipeline_html, store = store)
  expect_snapshot(snapshot_structure(obj, "vig_pipeline_html"))
})
