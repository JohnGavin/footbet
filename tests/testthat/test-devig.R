test_that("devig_basic returns probabilities summing to 1", {
  odds <- c(2.10, 3.40, 3.50)
  probs <- devig_basic(odds)
  expect_length(probs, 3)
  expect_equal(sum(probs), 1, tolerance = 1e-10)
  # All probabilities positive

  expect_true(all(probs > 0))
})

test_that("devig_basic rejects odds <= 1", {
  expect_error(devig_basic(c(0.9, 2.0)), "must be > 1")
})

test_that("devig_power returns probabilities summing to 1", {
  odds <- c(1.90, 2.00)  # AH-style 2-way market
  probs <- devig_power(odds)
  expect_length(probs, 2)
  expect_equal(sum(probs), 1, tolerance = 1e-8)
})

test_that("devig_shin requires exactly 3 odds", {
  expect_error(devig_shin(c(1.5, 2.5)), "exactly 3")
})

test_that("devig_shin returns probabilities summing to 1", {
  odds <- c(2.10, 3.40, 3.50)
  probs <- devig_shin(odds)
  expect_length(probs, 3)
  expect_equal(sum(probs), 1, tolerance = 1e-8)
  expect_true(all(probs > 0))
})

test_that("calc_overround computes correctly", {
  odds <- c(2.10, 3.40, 3.50)
  or <- calc_overround(odds)
  expected <- 1/2.10 + 1/3.40 + 1/3.50
  expect_equal(or, expected, tolerance = 1e-10)
  expect_true(or > 1)  # Bookmaker margin
})

test_that("devig methods agree on fair market", {
  # If odds have no margin, all methods should return the same
  fair_probs <- c(0.5, 0.3, 0.2)
  fair_odds <- 1 / fair_probs

  basic <- devig_basic(fair_odds)
  shin <- devig_shin(fair_odds)

  expect_equal(basic, fair_probs, tolerance = 1e-6)
  expect_equal(shin, fair_probs, tolerance = 1e-4)
})
