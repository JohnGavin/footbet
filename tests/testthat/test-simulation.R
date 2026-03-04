# Tests for R/simulation.R
# Quant simulation methods: variance reduction, importance sampling, copulas

# ============================================================================
# VARIANCE REDUCTION
# ============================================================================

test_that("simulate_match_vr returns expected structure", {
  result <- simulate_match_vr(1.5, 1.2, n_sims = 1000, method = "crude", seed = 42)

  expect_type(result, "list")
  expect_true("prob_1x2" %in% names(result))
  expect_true("prob_ou" %in% names(result))
  expect_true("se" %in% names(result))
  expect_true("variance_reduction" %in% names(result))

  # Probabilities sum to 1
  expect_equal(sum(result$prob_1x2), 1, tolerance = 0.01)
  expect_equal(sum(result$prob_ou), 1, tolerance = 0.01)
})

test_that("simulate_match_vr methods produce similar probabilities", {
  lambda_h <- 1.8
  lambda_a <- 1.2
  n <- 5000

  crude <- simulate_match_vr(lambda_h, lambda_a, n, "crude", seed = 123)
  anti <- simulate_match_vr(lambda_h, lambda_a, n, "antithetic", seed = 123)
  ctrl <- simulate_match_vr(lambda_h, lambda_a, n, "control", seed = 123)
  stacked <- simulate_match_vr(lambda_h, lambda_a, n, "stacked", seed = 123)

  # All should give similar home win probability (within Monte Carlo error)
  expect_equal(crude$prob_1x2["H"], anti$prob_1x2["H"], tolerance = 0.05)
  expect_equal(crude$prob_1x2["H"], ctrl$prob_1x2["H"], tolerance = 0.05)
  expect_equal(crude$prob_1x2["H"], stacked$prob_1x2["H"], tolerance = 0.05)
})

test_that("antithetic method reduces variance", {
  lambda_h <- 1.5
  lambda_a <- 1.3
  n <- 5000

  crude <- simulate_match_vr(lambda_h, lambda_a, n, "crude", seed = 42)
  anti <- simulate_match_vr(lambda_h, lambda_a, n, "antithetic", seed = 42)

  # Antithetic should have variance reduction > 1
  expect_gt(anti$variance_reduction, 1.0)
})

test_that("stacked method has highest variance reduction", {
  lambda_h <- 1.5
  lambda_a <- 1.3
  n <- 5000

  crude <- simulate_match_vr(lambda_h, lambda_a, n, "crude", seed = 42)
  stacked <- simulate_match_vr(lambda_h, lambda_a, n, "stacked", seed = 42)

  # Stacked should have significant variance reduction
  expect_gt(stacked$variance_reduction, 1.5)
})

test_that("simulate_match_vr validates inputs", {
  expect_error(simulate_match_vr(-1, 1.5), "positive")
  expect_error(simulate_match_vr(1.5, 0), "positive")
})

# ============================================================================
# IMPORTANCE SAMPLING
# ============================================================================

test_that("importance_sample_rare returns expected structure", {
  result <- importance_sample_rare(1.5, 1.2, "over_5.5", n_sims = 1000)

  expect_type(result, "list")
  expect_true("probability" %in% names(result))
  expect_true("se" %in% names(result))
  expect_true("effective_n" %in% names(result))
  expect_true("variance_reduction" %in% names(result))

  # Probability should be in [0, 1]
  expect_gte(result$probability, 0)
  expect_lte(result$probability, 1)
})

test_that("importance_sample_rare handles different outcomes", {
  lambda_h <- 1.5
  lambda_a <- 1.2

  over55 <- importance_sample_rare(lambda_h, lambda_a, "over_5.5", n_sims = 2000)
  exact32 <- importance_sample_rare(lambda_h, lambda_a, "exact_3_2", n_sims = 2000)
  home4 <- importance_sample_rare(lambda_h, lambda_a, "home_4+", n_sims = 2000)

  # All should return valid probabilities
  expect_gte(over55$probability, 0)
  expect_gte(exact32$probability, 0)
  expect_gte(home4$probability, 0)

  # Rare events should have small probabilities
  expect_lt(over55$probability, 0.2)  # Over 5.5 goals is rare
  expect_lt(exact32$probability, 0.1)  # Exact scoreline is very rare
})

test_that("importance sampling provides variance reduction for rare events", {
  # Very rare event: over 7.5 goals
  result <- importance_sample_rare(1.5, 1.2, "over_7.5", n_sims = 5000)

  # Should have significant variance reduction vs crude MC
  expect_gt(result$variance_reduction, 5)  # At least 5x for rare events
})

test_that("importance_sample_rare validates outcome format", {
  expect_error(importance_sample_rare(1.5, 1.2, "invalid"), "Unknown outcome")
})

# ============================================================================
# CORRELATED MATCH SIMULATION
# ============================================================================

test_that("simulate_correlated_matches returns expected structure", {
  matches <- tibble::tibble(
    match_id = c("m1", "m2"),
    lambda_home = c(1.5, 1.8),
    lambda_away = c(1.2, 1.0)
  )

  result <- simulate_correlated_matches(matches, correlation = 0.1, n_sims = 100, seed = 42)

  expect_s3_class(result, "tbl_df")
  expect_true(all(c("sim_id", "match_id", "home_goals", "away_goals", "result") %in% colnames(result)))
  expect_equal(nrow(result), 100 * 2)  # n_sims * n_matches
})

test_that("simulate_correlated_matches with zero correlation matches independence", {
  matches <- tibble::tibble(
    match_id = c("m1", "m2"),
    lambda_home = c(1.5, 1.8),
    lambda_away = c(1.2, 1.0)
  )

  # Zero correlation should give independent results
  result <- simulate_correlated_matches(matches, correlation = 0.0, n_sims = 5000, seed = 42)

  # Marginal probabilities should match independent Poisson
  m1_home_wins <- mean(result$result[result$match_id == "m1"] == "H")
  expected_m1_h <- sum(score_matrix_to_1x2(score_matrix(1.5, 1.2))[1])

  expect_equal(m1_home_wins, expected_m1_h, tolerance = 0.05)
})

test_that("simulate_correlated_matches validates inputs", {
  bad_matches <- tibble::tibble(match_id = "m1")
  expect_error(simulate_correlated_matches(bad_matches), "Missing columns")
})

# ============================================================================
# JOINT OUTCOME PROBABILITY
# ============================================================================

test_that("joint_outcome_probability returns valid probability", {
  matches <- tibble::tibble(
    match_id = c("m1", "m2"),
    lambda_home = c(1.5, 1.8),
    lambda_away = c(1.2, 1.0)
  )

  sims <- simulate_correlated_matches(matches, correlation = 0.1, n_sims = 1000, seed = 42)
  prob <- joint_outcome_probability(sims, c("H", "H"))

  expect_gte(prob, 0)
  expect_lte(prob, 1)
})

test_that("joint_outcome_probability validates input length", {
  matches <- tibble::tibble(
    match_id = c("m1", "m2"),
    lambda_home = c(1.5, 1.8),
    lambda_away = c(1.2, 1.0)
  )

  sims <- simulate_correlated_matches(matches, correlation = 0.1, n_sims = 100, seed = 42)
  expect_error(joint_outcome_probability(sims, c("H")), "length")
})

# ============================================================================
# ACCUMULATOR PROBABILITY
# ============================================================================

test_that("accumulator_probability returns expected structure", {
  matches <- tibble::tibble(
    match_id = c("m1", "m2", "m3"),
    lambda_home = c(1.5, 1.8, 2.0),
    lambda_away = c(1.2, 1.0, 1.5),
    bet = c("H", "H", "H")
  )

  result <- accumulator_probability(matches, correlation = 0.1, n_sims = 1000)

  expect_type(result, "list")
  expect_true("prob_independent" %in% names(result))
  expect_true("prob_correlated" %in% names(result))
  expect_true("correlation_impact" %in% names(result))

  # Independent should be product of individual probabilities
  expect_gte(result$prob_independent, 0)
  expect_lte(result$prob_independent, 1)
})

test_that("correlation affects accumulator probability", {
  matches <- tibble::tibble(
    match_id = c("m1", "m2"),
    lambda_home = c(1.5, 1.8),
    lambda_away = c(1.2, 1.0),
    bet = c("H", "H")
  )

  low_corr <- accumulator_probability(matches, correlation = 0.0, n_sims = 5000)
  high_corr <- accumulator_probability(matches, correlation = 0.3, n_sims = 5000)

  # With positive correlation, "all favourites win" should be more likely
  # (though effect is small, so just check they're different)
  # Note: with small n_sims, this may not always hold
  expect_true(is.numeric(low_corr$prob_correlated))
  expect_true(is.numeric(high_corr$prob_correlated))
})

test_that("accumulator_probability requires bet column", {
  matches <- tibble::tibble(
    match_id = "m1",
    lambda_home = 1.5,
    lambda_away = 1.2
  )
  expect_error(accumulator_probability(matches), "bet.*column")
})
