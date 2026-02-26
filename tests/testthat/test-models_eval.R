test_that("log_loss computes correctly for perfect prediction", {
  # Perfect: predicted prob = 1.0 for the event that happened
  ll <- log_loss(rep(1, 10))
  expect_equal(ll, 0, tolerance = 1e-10)
})

test_that("log_loss is higher for worse predictions", {
  good <- log_loss(c(0.9, 0.8, 0.7))
  bad <- log_loss(c(0.1, 0.2, 0.3))
  expect_true(bad > good)
})

test_that("brier_1x2 returns 0 for perfect predictions", {
  bs <- brier_1x2(
    prob_h = c(1, 0, 0),
    prob_d = c(0, 1, 0),
    prob_a = c(0, 0, 1),
    actual = c("H", "D", "A")
  )
  expect_equal(bs, 0)
})

test_that("brier_1x2 returns 2 for worst predictions", {
  # Predict 100% wrong outcome
  bs <- brier_1x2(
    prob_h = c(0, 1, 1),
    prob_d = c(1, 0, 0),
    prob_a = c(0, 0, 0),
    actual = c("H", "D", "A")
  )
  expect_equal(bs, 2)
})

test_that("rps_1x2 returns 0 for perfect predictions", {
  rps <- rps_1x2(
    prob_h = c(1, 0, 0),
    prob_d = c(0, 1, 0),
    prob_a = c(0, 0, 1),
    actual = c("H", "D", "A")
  )
  expect_equal(rps, 0)
})

test_that("walk_forward_splits creates non-empty splits", {
  dates <- seq.Date(as.Date("2020-01-01"), as.Date("2024-12-31"), by = "day")
  splits <- walk_forward_splits(dates, train_months = 24L, test_months = 1L)
  expect_true(length(splits) > 0)

  # Each split should have both train and test indices
  for (s in splits) {
    expect_true(length(s$train_idx) > 0)
    expect_true(length(s$test_idx) > 0)
    # Test dates should be after train dates
    expect_true(max(dates[s$train_idx]) < min(dates[s$test_idx]))
  }
})
