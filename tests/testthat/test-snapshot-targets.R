# Snapshot tests for target output structure (class, columns, dimensions).
# Catches changes in data pipeline outputs that could break vignettes.
# Review changes with: testthat::snapshot_review()

skip_if(nzchar(Sys.getenv("_R_CHECK_PACKAGE_NAME_")), "skipping in R CMD check")

rds_dir <- here::here("inst", "extdata", "vignettes")

skip_if_no_targets <- function() {
  skip_if_not(dir.exists(rds_dir), "RDS vignette directory not found")
}

# Read from pre-computed RDS (avoids targets subprocess crash)
read_vig <- function(name) {
  rds <- file.path(rds_dir, paste0(name, ".rds"))
  if (!file.exists(rds)) skip(paste0("RDS not found: ", name))
  readRDS(rds)
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
  obj <- read_vig("vig_data_source_summary")
  expect_snapshot(snapshot_structure(obj, "vig_data_source_summary"))
})

test_that("vig_league_season_grid structure", {
  skip_if_no_targets()
  obj <- read_vig("vig_league_season_grid")
  expect_snapshot(snapshot_structure(obj, "vig_league_season_grid"))
})

test_that("vig_typical_match_stats structure", {
  skip_if_no_targets()
  obj <- read_vig("vig_typical_match_stats")
  expect_snapshot(snapshot_structure(obj, "vig_typical_match_stats"))
})

# ---- Distribution/plot targets ----

test_that("vig_goals_distribution structure", {
  skip_if_no_targets()
  obj <- read_vig("vig_goals_distribution")
  expect_snapshot(snapshot_structure(obj, "vig_goals_distribution"))
})

test_that("vig_result_proportions structure", {
  skip_if_no_targets()
  obj <- read_vig("vig_result_proportions")
  expect_snapshot(snapshot_structure(obj, "vig_result_proportions"))
})

test_that("vig_scoreline_heatmap structure", {
  skip_if_no_targets()
  obj <- read_vig("vig_scoreline_heatmap")
  expect_snapshot(snapshot_structure(obj, "vig_scoreline_heatmap"))
})

test_that("vig_home_advantage_by_league structure", {
  skip_if_no_targets()
  obj <- read_vig("vig_home_advantage_by_league")
  expect_snapshot(snapshot_structure(obj, "vig_home_advantage_by_league"))
})

test_that("vig_goals_per_season_trend structure", {
  skip_if_no_targets()
  obj <- read_vig("vig_goals_per_season_trend")
  expect_snapshot(snapshot_structure(obj, "vig_goals_per_season_trend"))
})

test_that("vig_matches_per_season_plot structure", {
  skip_if_no_targets()
  obj <- read_vig("vig_matches_per_season_plot")
  expect_snapshot(snapshot_structure(obj, "vig_matches_per_season_plot"))
})

# ---- Data quality targets ----

test_that("vig_missing_data_by_column structure", {
  skip_if_no_targets()
  obj <- read_vig("vig_missing_data_by_column")
  expect_snapshot(snapshot_structure(obj, "vig_missing_data_by_column"))
})

test_that("vig_missing_data_heatmap structure", {
  skip_if_no_targets()
  obj <- read_vig("vig_missing_data_heatmap")
  expect_snapshot(snapshot_structure(obj, "vig_missing_data_heatmap"))
})

test_that("vig_anomalies_table structure", {
  skip_if_no_targets()
  obj <- read_vig("vig_anomalies_table")
  expect_snapshot(snapshot_structure(obj, "vig_anomalies_table"))
})

test_that("vig_outlier_matches structure", {
  skip_if_no_targets()
  obj <- read_vig("vig_outlier_matches")
  expect_snapshot(snapshot_structure(obj, "vig_outlier_matches"))
})

test_that("vig_completeness_plot structure", {
  skip_if_no_targets()
  obj <- read_vig("vig_completeness_plot")
  expect_snapshot(snapshot_structure(obj, "vig_completeness_plot"))
})

# ---- Odds targets ----

test_that("vig_odds_columns_available structure", {
  skip_if_no_targets()
  obj <- read_vig("vig_odds_columns_available")
  expect_snapshot(snapshot_structure(obj, "vig_odds_columns_available"))
})

test_that("vig_odds_vs_result structure", {
  skip_if_no_targets()
  obj <- read_vig("vig_odds_vs_result")
  expect_snapshot(snapshot_structure(obj, "vig_odds_vs_result"))
})

test_that("vig_overround_by_league structure", {
  skip_if_no_targets()
  obj <- read_vig("vig_overround_by_league")
  expect_snapshot(snapshot_structure(obj, "vig_overround_by_league"))
})

test_that("vig_pinnacle_coverage_plot structure", {
  skip_if_no_targets()
  obj <- read_vig("vig_pinnacle_coverage_plot")
  expect_snapshot(snapshot_structure(obj, "vig_pinnacle_coverage_plot"))
})

# ---- Model targets ----

test_that("vig_poisson_test structure", {
  skip_if_no_targets()
  obj <- read_vig("vig_poisson_test")
  expect_snapshot(snapshot_structure(obj, "vig_poisson_test"))
})

test_that("vig_elo_spread_plot structure", {
  skip_if_no_targets()
  obj <- read_vig("vig_elo_spread_plot")
  expect_snapshot(snapshot_structure(obj, "vig_elo_spread_plot"))
})

test_that("vig_shrinkage_plot structure", {
  skip_if_no_targets()
  obj <- read_vig("vig_shrinkage_plot")
  expect_snapshot(snapshot_structure(obj, "vig_shrinkage_plot"))
})

test_that("vig_pp_check_goals structure", {
  skip_if_no_targets()
  obj <- read_vig("vig_pp_check_goals")
  expect_snapshot(snapshot_structure(obj, "vig_pp_check_goals"))
})

test_that("vig_home_trend_test structure", {
  skip_if_no_targets()
  obj <- read_vig("vig_home_trend_test")
  expect_snapshot(snapshot_structure(obj, "vig_home_trend_test"))
})

test_that("vig_model_comparison_table structure", {
  skip_if_no_targets()
  obj <- read_vig("vig_model_comparison_table")
  expect_snapshot(snapshot_structure(obj, "vig_model_comparison_table"))
})

test_that("vig_model_comparison_test structure", {
  skip_if_no_targets()
  obj <- read_vig("vig_model_comparison_test")
  expect_snapshot(snapshot_structure(obj, "vig_model_comparison_test"))
})

# ---- CV targets ----

test_that("vig_cv_metrics_plot structure", {
  skip_if_no_targets()
  obj <- read_vig("vig_cv_metrics_plot")
  expect_snapshot(snapshot_structure(obj, "vig_cv_metrics_plot"))
})

test_that("vig_cv_html structure", {
  skip_if_no_targets()
  obj <- read_vig("vig_cv_html")
  expect_snapshot(snapshot_structure(obj, "vig_cv_html"))
})

# ---- Betting/Kelly targets ----

test_that("vig_kelly_stake_distribution structure", {
  skip_if_no_targets()
  obj <- read_vig("vig_kelly_stake_distribution")
  expect_snapshot(snapshot_structure(obj, "vig_kelly_stake_distribution"))
})

test_that("vig_kelly_html structure", {
  skip_if_no_targets()
  obj <- read_vig("vig_kelly_html")
  expect_snapshot(snapshot_structure(obj, "vig_kelly_html"))
})

test_that("vig_edge_distribution structure", {
  skip_if_no_targets()
  obj <- read_vig("vig_edge_distribution")
  expect_snapshot(snapshot_structure(obj, "vig_edge_distribution"))
})

test_that("vig_value_bets_summary structure", {
  skip_if_no_targets()
  obj <- read_vig("vig_value_bets_summary")
  expect_snapshot(snapshot_structure(obj, "vig_value_bets_summary"))
})

# ---- PnL targets ----

test_that("vig_pnl_curve structure", {
  skip_if_no_targets()
  obj <- read_vig("vig_pnl_curve")
  expect_snapshot(snapshot_structure(obj, "vig_pnl_curve"))
})

test_that("vig_drawdown_plot structure", {
  skip_if_no_targets()
  obj <- read_vig("vig_drawdown_plot")
  expect_snapshot(snapshot_structure(obj, "vig_drawdown_plot"))
})

test_that("vig_pnl_summary_table structure", {
  skip_if_no_targets()
  obj <- read_vig("vig_pnl_summary_table")
  expect_snapshot(snapshot_structure(obj, "vig_pnl_summary_table"))
})

# ---- Pipeline HTML target ----

test_that("vig_pipeline_html structure", {
  skip_if_no_targets()
  obj <- read_vig("vig_pipeline_html")
  expect_snapshot(snapshot_structure(obj, "vig_pipeline_html"))
})
