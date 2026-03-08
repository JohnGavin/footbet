# Tests for Kelly criterion and bankroll management functions
# Note: Basic kelly_fraction tests are in test-kelly.R

# ---- multi_kelly_stakes ----

test_that("multi_kelly_stakes computes stakes for multiple bets", {
  probs <- c(0.6, 0.55, 0.5)
  odds <- c(2.0, 2.0, 2.0)

  result <- multi_kelly_stakes(probs, odds, fraction = 0.25)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 3L)
  expect_true(all(c("kelly_full", "stake", "normalized_stake", "ev") %in%
                    colnames(result)))
})

test_that("multi_kelly_stakes normalizes when exceeding max", {
  # Two bets with high probability = high Kelly
  probs <- c(0.8, 0.8)
  odds <- c(2.0, 2.0)

  result <- multi_kelly_stakes(probs, odds, fraction = 1.0, max_total = 0.2)

  # Total normalized stake should not exceed max_total
  expect_true(sum(result$normalized_stake) <= 0.2 + 1e-10)
})

test_that("multi_kelly_stakes includes expected value", {
  probs <- c(0.6, 0.5)
  odds <- c(2.0, 2.0)

  result <- multi_kelly_stakes(probs, odds)

  # First bet has positive EV, second is zero
  expect_true(result$ev[1] > 0)
  expect_equal(result$ev[2], 0, tolerance = 1e-10)
})

test_that("multi_kelly_stakes validates same length", {
  expect_error(multi_kelly_stakes(c(0.5, 0.6), c(2.0)), "same length")
})

test_that("multi_kelly_stakes requires arguments", {
  expect_error(multi_kelly_stakes(c(0.5)))
  expect_error(multi_kelly_stakes())
})

# ---- bankroll_growth_target ----

test_that("bankroll_growth_target computes bets needed", {
  result <- bankroll_growth_target(
    current_bankroll = 1000,
    target_bankroll = 2000,
    avg_odds = 2.0,
    avg_edge = 0.05,
    avg_stake_pct = 0.02
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(result$current_bankroll, 1000)
  expect_equal(result$target_bankroll, 2000)
  expect_equal(result$growth_factor, 2)
  expect_true(result$bets_needed > 0)
})

test_that("bankroll_growth_target includes time estimates", {
  result <- bankroll_growth_target(1000, 1500)

  expect_true("days_at_5_bets" %in% colnames(result))
  expect_true("days_at_10_bets" %in% colnames(result))
})

test_that("bankroll_growth_target validates positive bankroll", {
  expect_error(
    bankroll_growth_target(0, 1000),
    "positive"
  )
})

test_that("bankroll_growth_target validates target exceeds current", {
  expect_error(
    bankroll_growth_target(1000, 500),
    "exceed"
  )
})

test_that("bankroll_growth_target warns for non-positive growth", {
  expect_warning(
    result <- bankroll_growth_target(1000, 2000, avg_edge = -0.1),
    "Non-positive"
  )
  expect_true(is.na(result$bets_needed))
})

test_that("bankroll_growth_target requires arguments", {
  expect_error(bankroll_growth_target(1000))
  expect_error(bankroll_growth_target())
})

# ---- simulate_bankroll_growth ----

test_that("simulate_bankroll_growth returns statistics", {
  set.seed(123)

  result <- simulate_bankroll_growth(
    bankroll = 1000,
    probs = c(0.6, 0.6, 0.6),
    odds = c(2.0, 2.0, 2.0),
    fraction = 0.25,
    n_sims = 100
  )

  expect_s3_class(result, "tbl_df")
  expect_true(all(c("mean_final", "median_final", "pct_profitable",
                    "pct_bust", "p05", "p95") %in% colnames(result)))
})

test_that("simulate_bankroll_growth positive EV has positive mean growth", {
  set.seed(42)

  # Strong edge
  result <- simulate_bankroll_growth(
    bankroll = 1000,
    probs = c(0.7, 0.7, 0.7, 0.7, 0.7),
    odds = c(2.0, 2.0, 2.0, 2.0, 2.0),
    fraction = 0.25,
    n_sims = 500
  )

  expect_true(result$mean_final > 1000)  # Should grow on average
})

test_that("simulate_bankroll_growth validates same length", {
  expect_error(
    simulate_bankroll_growth(1000, c(0.5, 0.6), c(2.0)),
    "same length"
  )
})

test_that("simulate_bankroll_growth requires arguments", {
  expect_error(simulate_bankroll_growth(1000, c(0.5)))
  expect_error(simulate_bankroll_growth(1000))
  expect_error(simulate_bankroll_growth())
})
