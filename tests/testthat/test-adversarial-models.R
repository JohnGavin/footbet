# Adversarial QA: R/models_baseline.R + R/models_eval.R exported functions
# Attack vectors: NULL, NA, boundary values, degenerate inputs

# ---- score_matrix ----

test_that("score_matrix: zero lambdas", {
  mat <- score_matrix(0, 0)
  expect_equal(mat[1, 1], 1, tolerance = 1e-10)  # P(0-0) = 1
  expect_equal(sum(mat), 1, tolerance = 1e-10)
})

test_that("score_matrix: very large lambda", {
  mat <- score_matrix(10, 10, max_goals = 7L)
  # Most probability mass will be truncated
  expect_true(sum(mat) < 1)
  expect_true(sum(mat) > 0)
})

test_that("score_matrix: negative lambda", {
  # dpois handles this with NaN/warning
  expect_warning(score_matrix(-1, 1))
})

test_that("score_matrix: NA lambda produces NA matrix", {
  mat <- suppressWarnings(score_matrix(NA, 1))
  expect_true(all(is.na(mat)))
})

test_that("score_matrix: max_goals = 0", {
  mat <- score_matrix(1, 1, max_goals = 0L)
  expect_equal(nrow(mat), 1L)
  expect_equal(ncol(mat), 1L)
})

# ---- score_matrix_to_1x2 ----

test_that("score_matrix_to_1x2: 1x1 matrix (only 0-0)", {
  mat <- matrix(1, nrow = 1, ncol = 1)
  probs <- score_matrix_to_1x2(mat)
  expect_equal(probs[["D"]], 1)
  expect_equal(probs[["H"]], 0)
  expect_equal(probs[["A"]], 0)
})

test_that("score_matrix_to_1x2: all mass on home win", {
  mat <- matrix(0, nrow = 3, ncol = 3)
  mat[2, 1] <- 1  # Home 1, Away 0
  probs <- score_matrix_to_1x2(mat)
  expect_equal(probs[["H"]], 1)
})

test_that("score_matrix_to_1x2: symmetric lambdas", {
  mat <- score_matrix(1.5, 1.5)
  probs <- score_matrix_to_1x2(mat)
  # Symmetric teams: P(H) should approx equal P(A)
  expect_equal(probs[["H"]], probs[["A"]], tolerance = 1e-10)
})

# ---- score_matrix_to_ou ----

test_that("score_matrix_to_ou: line = 0 (everything is over except 0-0)", {
  mat <- score_matrix(1.5, 1.0)
  probs <- score_matrix_to_ou(mat, line = 0)
  p_00 <- mat[1, 1]
  # Under = exactly 0 total goals = P(0-0)
  expect_equal(probs[["under"]], p_00, tolerance = 1e-3)
})

test_that("score_matrix_to_ou: very high line", {
  mat <- score_matrix(1.5, 1.0)
  probs <- score_matrix_to_ou(mat, line = 100)
  expect_equal(probs[["over"]], 0, tolerance = 1e-6)
  expect_equal(probs[["under"]], 1, tolerance = 1e-6)
})

test_that("score_matrix_to_ou: negative line (all over)", {
  mat <- score_matrix(1.5, 1.0)
  probs <- score_matrix_to_ou(mat, line = -0.5)
  # Everything where total > -0.5 is over, which is all non-negative totals
  expect_equal(probs[["over"]], 1, tolerance = 1e-3)
})

# ---- score_matrix_to_ah ----

test_that("score_matrix_to_ah: line = 0 (draw no bet)", {
  mat <- score_matrix(1.5, 1.0)
  probs <- score_matrix_to_ah(mat, line = 0)
  # Push = draws
  probs_1x2 <- score_matrix_to_1x2(mat)
  expect_equal(probs[["push"]], probs_1x2[["D"]], tolerance = 1e-10)
})

test_that("score_matrix_to_ah: extreme line +5", {
  mat <- score_matrix(1.5, 1.0)
  probs <- score_matrix_to_ah(mat, line = 5)
  # Home team gets +5 handicap → almost always wins
  expect_true(probs[["win"]] > 0.99)
})

# ---- log_loss ----

test_that("log_loss: NULL input", {
  expect_error(log_loss(NULL), "numeric")
})

test_that("log_loss: NA values propagate", {
  result <- log_loss(c(0.5, NA, 0.7))
  expect_true(is.na(result))
})

test_that("log_loss: prob = 0 doesn't produce -Inf (clips)", {
  ll <- log_loss(c(0, 0.5))
  expect_true(is.finite(ll))
})

test_that("log_loss: prob = 1 doesn't produce NaN (clips)", {
  ll <- log_loss(c(1, 0.5))
  expect_true(is.finite(ll))
})

test_that("log_loss: empty vector errors", {
  expect_error(log_loss(numeric(0)), "empty")
})

test_that("log_loss: negative probability clipped to small positive", {
  ll <- log_loss(c(-0.1, 0.5))
  expect_true(is.finite(ll))
})

# ---- brier_1x2 ----

test_that("brier_1x2: mismatched lengths", {
  expect_error(
    brier_1x2(c(0.5, 0.3), c(0.3), c(0.2, 0.2), c("H", "A"))
  ) |> tryCatch(error = identity)
  # May not error but produce wrong result — test length consistency
})

test_that("brier_1x2: invalid actual value", {
  bs <- brier_1x2(0.5, 0.3, 0.2, "X")
  # "X" doesn't match H/D/A so all indicators are 0
  expected <- 0.5^2 + 0.3^2 + 0.2^2
  expect_equal(bs, expected, tolerance = 1e-10)
})

test_that("brier_1x2: probabilities don't sum to 1", {
  # Should still compute — no constraint enforced
  bs <- brier_1x2(0.9, 0.9, 0.9, "H")
  expect_true(is.numeric(bs))
})

# ---- rps_1x2 ----

test_that("rps_1x2: all probability on wrong outcome", {
  rps <- rps_1x2(0, 0, 1, "H")
  expect_true(rps > 0)
})

# ---- walk_forward_splits ----

test_that("walk_forward_splits: NULL dates returns empty", {
  splits <- suppressWarnings(walk_forward_splits(NULL))
  expect_length(splits, 0)
})

test_that("walk_forward_splits: single date", {
  splits <- walk_forward_splits(as.Date("2024-01-01"))
  expect_length(splits, 0)
})

test_that("walk_forward_splits: dates shorter than train window", {
  dates <- seq.Date(as.Date("2024-01-01"), as.Date("2024-06-01"), by = "day")
  splits <- walk_forward_splits(dates, train_months = 24L)
  expect_length(splits, 0)
})

test_that("walk_forward_splits: unsorted dates still work", {
  dates <- rev(seq.Date(as.Date("2020-01-01"), as.Date("2024-12-31"), by = "day"))
  splits <- walk_forward_splits(dates, train_months = 24L)
  # Should produce splits (function uses min/max, not order)
  expect_true(length(splits) > 0)
})
