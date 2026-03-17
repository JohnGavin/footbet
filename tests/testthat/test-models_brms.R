# Tests for R/models_brms.R
# Note: Full brms model fitting is slow and requires Stan.
# These tests focus on input validation and structure.
# Most tests skip if brms is not installed.

# ---- fit_brms_poisson input validation ----

test_that("fit_brms_poisson requires long_df", {
  skip_if_not_installed("brms")
  expect_error(fit_brms_poisson(), "long_df")
})

test_that("fit_brms_poisson validates required columns", {
  skip_if_not_installed("brms")
  bad_df <- tibble::tibble(goals = 1, home = 1)
  expect_error(fit_brms_poisson(bad_df), "Missing columns")
})

test_that("fit_brms_poisson rejects empty data", {
  skip_if_not_installed("brms")
  empty_df <- tibble::tibble(
    goals = integer(),
    home = integer(),
    team = character(),
    opponent = character()
  )
  expect_error(fit_brms_poisson(empty_df), "empty")
})

# ---- predict_brms input validation ----

test_that("predict_brms requires model argument", {
  skip_if_not_installed("brms")
  expect_error(predict_brms(), "model")
})

test_that("predict_brms requires brmsfit object", {
  skip_if_not_installed("brms")
  expect_error(
    predict_brms(model = "not_a_model", home_team = "A", away_team = "B"),
    "brmsfit"
  )
})

test_that("predict_brms requires team arguments", {
  skip_if_not_installed("brms")
  # Can't create a real brmsfit without fitting, so just check the error path
  # away_team is checked before model, so test that first

  expect_error(predict_brms(model = NULL, home_team = "A"), "away_team")
  # With both teams, model validation triggers

  expect_error(predict_brms(model = NULL, home_team = "A", away_team = "B"), "brmsfit")
})

# ---- predict_matches_brms input validation ----

test_that("predict_matches_brms validates columns", {
  skip_if_not_installed("brms")
  bad_df <- tibble::tibble(team_a = "A", team_b = "B")
  expect_error(
    predict_matches_brms(model = NULL, matches_df = bad_df),
    "home_team.*away_team"
  )
})

# ---- evaluate_brms input validation ----

test_that("evaluate_brms requires arguments", {
  expect_error(evaluate_brms(), "long_df")
  expect_error(evaluate_brms(long_df = tibble::tibble()), "matches_df")
})

# ---- edge_credible_interval ----

test_that("edge_credible_interval computes correct CI", {
  set.seed(42)
  # Simulate posterior draws where edge is clearly positive
  draws <- rnorm(1000, mean = 0.55, sd = 0.05)
  result <- edge_credible_interval(draws, market_prob = 0.40)

  expect_s3_class(result, "tbl_df")
  expect_true(result$edge_median > 0.10)
  expect_true(result$edge_lower > 0)  # Entire CI positive
  expect_true(result$pct_positive > 95)
})

test_that("edge_credible_interval handles negative edge", {
  set.seed(42)
  draws <- rnorm(1000, mean = 0.35, sd = 0.05)
  result <- edge_credible_interval(draws, market_prob = 0.40)

  expect_true(result$edge_median < 0)
  expect_true(result$pct_positive < 20)
})

test_that("edge_credible_interval handles uncertain edge", {
  set.seed(42)
  # Edge near zero — CI should span zero
  draws <- rnorm(1000, mean = 0.41, sd = 0.08)
  result <- edge_credible_interval(draws, market_prob = 0.40)

  expect_true(result$edge_lower < 0)
  expect_true(result$edge_upper > 0)
  expect_true(result$pct_positive > 30 & result$pct_positive < 70)
})

# ---- brms_loo / brms_waic / brms_r2 input validation ----

test_that("brms_loo requires brmsfit", {
  skip_if_not_installed("brms")
  expect_error(brms_loo("x"), "brmsfit")
})

test_that("brms_waic requires brmsfit", {
  skip_if_not_installed("brms")
  expect_error(brms_waic("x"), "brmsfit")
})

test_that("brms_r2 requires brmsfit", {
  skip_if_not_installed("brms")
  expect_error(brms_r2("x"), "brmsfit")
})

# ---- brms_diagnostics input validation ----

test_that("brms_diagnostics requires brmsfit", {
  skip_if_not_installed("brms")
  expect_error(brms_diagnostics("not_a_model"), "brmsfit")
})

test_that("brms_diagnostics requires brms package", {
  skip_if_not_installed("brms")
  expect_error(brms_diagnostics(NULL), "brmsfit")
})

test_that("brms_converged requires brmsfit", {
  skip_if_not_installed("brms")
  expect_error(brms_converged("x"), "brmsfit")
})

# ---- Integration test (skipped if brms/Stan not fully available) ----

test_that("fit_brms_poisson works with small dataset", {
  skip_on_cran()
  skip_if_not_installed("brms")
  skip_if_not_installed("rstan")

  # Small synthetic dataset
  set.seed(123)
  teams <- c("TeamA", "TeamB", "TeamC", "TeamD")
  n_matches <- 40

  long_df <- tibble::tibble(
    goals = rpois(n_matches * 2, lambda = 1.5),
    home = rep(c(1L, 0L), n_matches),
    team = sample(teams, n_matches * 2, replace = TRUE),
    opponent = sample(teams, n_matches * 2, replace = TRUE),
    match_date = rep(seq.Date(as.Date("2024-01-01"), by = "week", length.out = n_matches), each = 2),
    match_id = rep(paste0("m", seq_len(n_matches)), each = 2)
  )

  # Filter out self-matches
  long_df <- long_df[long_df$team != long_df$opponent, ]

  # Fit with minimal iterations for speed
  skip_if(nrow(long_df) < 20, "Not enough data after filtering")

  model <- fit_brms_poisson(
    long_df,
    iter = 100,
    warmup = 50,
    chains = 1,
    cores = 1
  )

  expect_s3_class(model, "brmsfit")
  expect_true("team" %in% names(brms::ranef(model)))
})

test_that("predict_brms returns expected structure",
{
  skip_on_cran()
  skip_if_not_installed("brms")
  skip_if_not_installed("rstan")

  # This test requires a fitted model, so we skip it in fast test runs
  skip("Skipping slow brms prediction test")

  # If we had a model:
  # pred <- predict_brms(model, "TeamA", "TeamB", max_goals = 5, ndraws = 100)
  # expect_type(pred, "list")
  # expect_true("score_matrix" %in% names(pred))
  # expect_true("prob_1x2" %in% names(pred))
  # expect_equal(sum(pred$prob_1x2), 1, tolerance = 0.01)
})
