# Tests for correct score prediction functions

# ---- score_probability ----

test_that("score_probability extracts correct probability", {
  # Create simple 3x3 matrix
  mat <- matrix(
    c(0.1, 0.15, 0.05,   # 0-0, 0-1, 0-2
      0.2, 0.25, 0.1,    # 1-0, 1-1, 1-2
      0.05, 0.08, 0.02), # 2-0, 2-1, 2-2
    nrow = 3, ncol = 3, byrow = TRUE
  )
  dimnames(mat) <- list(home = 0:2, away = 0:2)

  expect_equal(score_probability(mat, 0, 0), 0.1)
  expect_equal(score_probability(mat, 1, 0), 0.2)
  expect_equal(score_probability(mat, 1, 1), 0.25)
  expect_equal(score_probability(mat, 2, 1), 0.08)
})

test_that("score_probability returns NA for out of range", {
  mat <- matrix(0.25, nrow = 3, ncol = 3)
  dimnames(mat) <- list(home = 0:2, away = 0:2)

  expect_true(is.na(score_probability(mat, 3, 0)))  # Too many home goals
  expect_true(is.na(score_probability(mat, 0, 3)))  # Too many away goals
  expect_true(is.na(score_probability(mat, -1, 0))) # Negative
})

test_that("score_probability validates arguments", {
  mat <- matrix(0.25, nrow = 3, ncol = 3)

  expect_error(score_probability(mat, 0))
  expect_error(score_probability(mat))
  expect_error(score_probability())
})

# ---- top_scorelines ----

test_that("top_scorelines returns sorted results", {
  # Create a simple score matrix
  mat <- score_matrix(1.5, 1.0, max_goals = 4L)

  result <- top_scorelines(mat, n = 5L)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 5L)
  expect_true(all(c("home_goals", "away_goals", "probability", "scoreline") %in%
                    colnames(result)))

  # Should be sorted by probability descending
  expect_true(all(diff(result$probability) <= 0))
})

test_that("top_scorelines has correct scoreline format", {
  mat <- score_matrix(1.5, 1.0, max_goals = 3L)

  result <- top_scorelines(mat, n = 3L)

  # Scoreline should be "home-away" format
  expect_match(result$scoreline[1], "^[0-9]+-[0-9]+$")

  # Verify scoreline matches goals
  for (i in seq_len(nrow(result))) {
    expected <- paste0(result$home_goals[i], "-", result$away_goals[i])
    expect_equal(result$scoreline[i], expected)
  }
})

test_that("top_scorelines probabilities sum correctly", {
  mat <- score_matrix(1.2, 0.8, max_goals = 5L)

  result <- top_scorelines(mat, n = 100L)  # Get all

  # Sum of all probabilities should be close to 1
  expect_equal(sum(result$probability), 1, tolerance = 0.01)
})

test_that("top_scorelines validates arguments", {
  expect_error(top_scorelines())
})

# ---- predict_correct_score ----

test_that("predict_correct_score requires fitted model", {
  expect_error(predict_correct_score(NULL, "A", "B"))
})

# Note: Full predict_correct_score tests require a fitted model

# ---- correct_score_value ----

test_that("correct_score_value identifies value bet", {
  # Model thinks 10% chance, odds offer 12.0 (8.3% implied)
  result <- correct_score_value(0.10, 12.0)

  expect_true(result$is_value)
  expect_equal(result$model_prob, 0.10)
  expect_equal(result$implied_prob, 1/12.0, tolerance = 1e-6)
  expect_true(result$edge > 0)
})

test_that("correct_score_value identifies non-value bet", {
  # Model thinks 5% chance, odds offer 15.0 (6.7% implied)
  result <- correct_score_value(0.05, 15.0)

  expect_false(result$is_value)
  expect_true(result$edge < 0)
})

test_that("correct_score_value computes expected value", {
  # 50% chance at 2.0 odds = 0 EV
  result <- correct_score_value(0.50, 2.0)

  expect_equal(result$expected_value, 0, tolerance = 1e-10)
})

test_that("correct_score_value positive EV for value bet", {
  # 60% chance at 2.0 odds = positive EV
  result <- correct_score_value(0.60, 2.0)

  expect_true(result$expected_value > 0)
  # EV = 0.6 * 1 - 0.4 = 0.2
  expect_equal(result$expected_value, 0.2, tolerance = 1e-10)
})

test_that("correct_score_value validates arguments", {
  expect_error(correct_score_value(0.1))
  expect_error(correct_score_value())
})
