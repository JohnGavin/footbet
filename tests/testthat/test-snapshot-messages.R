# Snapshot tests for CLI error/warning messages.
# Ensures user-facing messages don't change unexpectedly.
# Review changes with: testthat::snapshot_review()

# ---- compute_elo error messages ----

test_that("compute_elo: error on NULL input", {
  expect_snapshot(error = TRUE, compute_elo(NULL))
})

test_that("compute_elo: error on missing matches_df", {
  expect_snapshot(error = TRUE, compute_elo())
})

# ---- devig error messages ----

test_that("devig_odds: error on NULL input", {
  expect_snapshot(error = TRUE, devig_odds(NULL))
})

# ---- database error messages ----

test_that("log_predictions_batch: error on missing columns", {
  skip_if_not_installed("duckdb")
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_predictions_schema(con)

  bad_df <- tibble::tibble(x = 1)
  expect_snapshot(error = TRUE, log_predictions_batch(con, bad_df))
})

# ---- data_transfers warning messages ----

test_that("tm_get_suspensions removed warning", {
  # The function should warn that tm_get_suspensions is no longer available
  skip_if_not_installed("worldfootballR")
  if (!exists("tm_get_suspensions", asNamespace("worldfootballR"))) {
    expect_warning(
      fetch_league_suspensions("E0", 2024),
      "no longer available"
    )
  }
})

# ---- kelly error messages ----

test_that("kelly_fraction: snapshot of edge case output", {
  # Negative edge → 0 stake
  expect_equal(kelly_fraction(0.3, 2.0), 0)
  # Snapshot the boundary behavior
  expect_snapshot({
    cat("prob=0.6, odds=2.0:", kelly_fraction(0.6, 2.0), "\n")
    cat("prob=0.3, odds=2.0:", kelly_fraction(0.3, 2.0), "\n")
    cat("prob=0.5, odds=2.0:", kelly_fraction(0.5, 2.0), "\n")
  })
})

# ---- mermaid diagram output stability ----

test_that("pipeline mermaid diagram structure is stable", {
  skip_if_not(file.exists(here::here("R", "diagrams.R")),
              "diagrams.R not found")
  expect_snapshot(generate_data_pipeline_mermaid(here::here()))
})

test_that("CV walkforward mermaid diagram structure is stable", {
  skip_if_not(file.exists(here::here("R", "diagrams.R")),
              "diagrams.R not found")
  expect_snapshot(generate_cv_walkforward_mermaid(here::here()))
})

test_that("Kelly decision mermaid diagram structure is stable", {
  skip_if_not(file.exists(here::here("R", "diagrams.R")),
              "diagrams.R not found")
  expect_snapshot(generate_kelly_decision_mermaid(here::here()))
})
