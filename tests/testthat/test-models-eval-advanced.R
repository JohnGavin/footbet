# Tests for advanced evaluation metrics: Brier decomposition, calibration,
# empirical Bayes shrinkage, and meta-analytics

# ---- brier_decomposition ----

test_that("brier_decomposition returns correct components", {
  set.seed(123)
  n <- 100
  predicted <- runif(n, 0.2, 0.8)
  actual <- rbinom(n, 1, predicted)  # Well-calibrated

  result <- brier_decomposition(predicted, actual)

  expect_s3_class(result, "tbl_df")
  expect_true("brier_score" %in% names(result))
  expect_true("reliability" %in% names(result))
  expect_true("resolution" %in% names(result))
  expect_true("uncertainty" %in% names(result))
  expect_true("brier_skill_score" %in% names(result))

  # Components should be non-negative (except BSS can be negative)
  expect_true(result$reliability >= 0)
  expect_true(result$resolution >= 0)
  expect_true(result$uncertainty >= 0)
})

test_that("brier_decomposition: perfect predictions", {
  predicted <- c(1, 1, 0, 0, 1)
  actual <- c(1, 1, 0, 0, 1)

  result <- brier_decomposition(predicted, actual)

  # Perfect predictions should have Brier score = 0

  expect_equal(result$brier_score, 0)
})

test_that("brier_decomposition_1x2 works for 3-way outcomes", {
  prob_h <- c(0.5, 0.6, 0.3, 0.7)
  prob_d <- c(0.3, 0.2, 0.4, 0.2)
  prob_a <- c(0.2, 0.2, 0.3, 0.1)
  actual <- c("H", "H", "D", "A")

  result <- brier_decomposition_1x2(prob_h, prob_d, prob_a, actual)

  expect_equal(nrow(result), 4)  # H, D, A, Overall
  expect_true("Overall" %in% result$outcome)
})

# ---- calibration ----

test_that("fit_platt_scaling returns a model", {
  set.seed(456)
  predicted <- runif(50, 0.1, 0.9)
  actual <- rbinom(50, 1, predicted)

  model <- fit_platt_scaling(predicted, actual)

  expect_s3_class(model, "glm")
})

test_that("predict_platt returns calibrated probabilities", {
  set.seed(789)
  # Training data
  pred_train <- runif(100, 0.1, 0.9)
  actual_train <- rbinom(100, 1, pred_train)

  model <- fit_platt_scaling(pred_train, actual_train)

  # Test data
  pred_test <- c(0.1, 0.5, 0.9)
  calibrated <- predict_platt(model, pred_test)

  expect_length(calibrated, 3)
  expect_true(all(calibrated >= 0 & calibrated <= 1))
})

test_that("fit_isotonic_regression returns isoreg object", {
  set.seed(101)
  predicted <- runif(50, 0.1, 0.9)
  actual <- rbinom(50, 1, predicted)

  model <- fit_isotonic_regression(predicted, actual)

  expect_s3_class(model, "isoreg")
})

test_that("predict_isotonic returns calibrated probabilities", {
  set.seed(202)
  pred_train <- runif(100, 0.1, 0.9)
  actual_train <- rbinom(100, 1, pred_train)

  model <- fit_isotonic_regression(pred_train, actual_train)

  pred_test <- c(0.1, 0.5, 0.9)
  calibrated <- predict_isotonic(model, pred_test)

  expect_length(calibrated, 3)
  expect_true(all(calibrated >= 0 & calibrated <= 1))
})

# ---- empirical_bayes_shrink ----

test_that("empirical_bayes_shrink shrinks extreme values toward mean", {
  # Team with 5 matches scoring 3 goals/match (extreme)
  # Team with 30 matches scoring 1.5 goals/match (typical)
  observed <- c(3.0, 1.5, 0.5, 1.5, 1.5)
  sample_size <- c(5, 30, 10, 25, 20)

  result <- empirical_bayes_shrink(observed, sample_size, type = "rate")

  expect_s3_class(result, "tbl_df")
  expect_true("shrunk" %in% names(result))
  expect_true("shrinkage_factor" %in% names(result))

  # Extreme value (3.0) should be shrunk more than typical value (1.5)
  shrunk_extreme <- result$shrunk[1]
  expect_true(shrunk_extreme < 3.0)  # Should be pulled toward mean
  expect_true(shrunk_extreme > result$grand_mean[1])  # But still above average

  # Higher sample size should have less shrinkage (higher shrinkage_factor)
  expect_true(result$shrinkage_factor[2] > result$shrinkage_factor[1])
})

test_that("shrink_team_strength adds shrunk columns", {
  team_stats <- tibble::tibble(
    team = c("A", "B", "C"),
    n_matches = c(5, 20, 38),
    attack = c(2.5, 1.5, 1.3),
    defense = c(0.8, 1.2, 1.0)
  )

  result <- shrink_team_strength(team_stats)

  expect_true("attack_shrunk" %in% names(result))
  expect_true("defense_shrunk" %in% names(result))
  expect_equal(nrow(result), 3)
})

# ---- meta-analytics ----

test_that("stat_discrimination computes valid coefficient", {
  set.seed(303)
  # Create data where teams have consistent differences (high discrimination)
  df <- tibble::tibble(
    team = rep(LETTERS[1:5], each = 10),
    season = rep(paste0("20", 15:24), 5),
    value = rep(c(1.0, 1.5, 2.0, 2.5, 3.0), each = 10) + rnorm(50, sd = 0.1)
  )

  disc <- stat_discrimination(df, "team", "value")

  expect_true(is.numeric(disc))
  expect_true(disc >= 0 && disc <= 1)
  # Should be high discrimination since teams have distinct values
  expect_true(disc > 0.8)
})

test_that("stat_discrimination: low discrimination with random data", {
  set.seed(404)
  # Random data - no team differences
  df <- tibble::tibble(
    team = rep(LETTERS[1:5], each = 10),
    season = rep(paste0("20", 15:24), 5),
    value = rnorm(50, mean = 1.5, sd = 0.5)
  )

  disc <- stat_discrimination(df, "team", "value")

  # Should have low discrimination
  expect_true(disc < 0.5)
})

test_that("stat_stability computes year-over-year correlation", {
  set.seed(505)
  # Create stable data: teams maintain relative rankings
  teams <- LETTERS[1:10]
  team_effects <- seq(1, 2, length.out = 10)
  names(team_effects) <- teams

  df <- tidyr::expand_grid(
    team = teams,
    season = paste0("20", 20:24)
  ) |>
    dplyr::mutate(
      value = team_effects[team] + rnorm(dplyr::n(), sd = 0.1)
    )

  stab <- stat_stability(df, "team", "value", "season")

  expect_true(is.numeric(stab))
  expect_true(stab >= 0 && stab <= 1)
  # Should be high stability since teams maintain rankings
  expect_true(stab > 0.8)
})

test_that("compute_meta_analytics combines discrimination and stability", {
  set.seed(606)
  df <- tibble::tibble(
    team = rep(LETTERS[1:5], each = 5),
    season = rep(paste0("20", 20:24), 5),
    goals = rep(c(1.0, 1.5, 2.0, 2.5, 3.0), each = 5) + rnorm(25, sd = 0.2),
    shots = rnorm(25, mean = 10, sd = 3),  # Random - low discrimination
    xg = rep(c(1.0, 1.4, 1.8, 2.2, 2.6), each = 5) + rnorm(25, sd = 0.15)
  )

  result <- compute_meta_analytics(
    df,
    entity_col = "team",
    season_col = "season",
    stat_cols = c("goals", "shots", "xg")
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 3)
  expect_true("discrimination" %in% names(result))
  expect_true("stability" %in% names(result))
  expect_true("composite" %in% names(result))

  # Goals should have higher composite than random shots
  goals_comp <- result$composite[result$stat == "goals"]
  shots_comp <- result$composite[result$stat == "shots"]
  expect_true(goals_comp > shots_comp)
})
