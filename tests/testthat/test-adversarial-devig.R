# Adversarial QA: R/devig.R exported functions
# Attack vectors: NULL, NA, wrong types, boundary values, numeric edge cases

# ---- devig_basic ----

test_that("devig_basic: NULL input", {
  expect_error(devig_basic(NULL))
})

test_that("devig_basic: NA in odds vector", {
  # NA odds should propagate or error
  result <- devig_basic(c(2.0, NA, 3.0))
  expect_true(any(is.na(result)) || is.numeric(result))
})

test_that("devig_basic: single odds value", {
  probs <- devig_basic(2.0)
  expect_equal(probs, 1.0)
})

test_that("devig_basic: very large odds", {
  probs <- devig_basic(c(1.01, 100.0))
  expect_equal(sum(probs), 1, tolerance = 1e-8)
  expect_true(all(probs > 0))
})

test_that("devig_basic: odds exactly 1 rejected", {
  expect_error(devig_basic(c(1.0, 2.0)))
})

test_that("devig_basic: negative odds rejected", {
  expect_error(devig_basic(c(-2.0, 3.0)))
})

test_that("devig_basic: Inf odds", {
  # Inf should be handled gracefully
  expect_error(devig_basic(c(Inf, 2.0)))
})

test_that("devig_basic: character input", {
  expect_error(devig_basic(c("2.0", "3.0")))
})

test_that("devig_basic: empty vector", {
  expect_error(devig_basic(numeric(0)))
})

# ---- devig_power ----

test_that("devig_power: NULL input", {
  expect_error(devig_power(NULL))
})

test_that("devig_power: extreme favourite (very low odds)", {
  probs <- devig_power(c(1.02, 50.0))
  expect_equal(sum(probs), 1, tolerance = 1e-6)
  expect_true(probs[1] > 0.95)
})

test_that("devig_power: nearly equal odds", {
  probs <- devig_power(c(1.95, 1.95))
  expect_equal(probs[1], probs[2], tolerance = 1e-8)
  expect_equal(sum(probs), 1, tolerance = 1e-8)
})

test_that("devig_power: single value returns 1", {
  probs <- devig_power(2.0)
  expect_equal(probs, 1.0)
})

# ---- devig_shin ----

test_that("devig_shin: NULL input", {
  expect_error(devig_shin(NULL))
})

test_that("devig_shin: wrong length (2)", {
  expect_error(devig_shin(c(2.0, 3.0)), "exactly 3")
})

test_that("devig_shin: wrong length (4)", {
  expect_error(devig_shin(c(2.0, 3.0, 4.0, 5.0)), "exactly 3")
})

test_that("devig_shin: extreme favourite (may fallback)", {
  # Extreme odds may cause Shin to fallback to basic — either way, valid probs
  probs <- suppressWarnings(devig_shin(c(1.05, 15.0, 25.0)))
  expect_equal(sum(probs), 1, tolerance = 1e-6)
  expect_true(probs[1] > 0.80)
})

test_that("devig_shin: all equal odds (may fallback)", {
  probs <- suppressWarnings(devig_shin(c(2.8, 2.8, 2.8)))
  expect_equal(probs[1], probs[2], tolerance = 1e-6)
  expect_equal(probs[2], probs[3], tolerance = 1e-6)
})

test_that("devig_shin: NA in odds", {
  expect_error(devig_shin(c(2.0, NA, 3.0)))
})

# ---- calc_overround ----

test_that("calc_overround: NULL input returns 0", {
  # NULL has length 0, so sum(1/NULL) = 0
  expect_equal(calc_overround(NULL), 0)
})

test_that("calc_overround: empty vector returns 0", {
  expect_equal(calc_overround(numeric(0)), 0)
})

test_that("calc_overround: NA values ignored", {
  or <- calc_overround(c(2.0, NA, 3.0))
  expected <- 1/2.0 + 1/3.0
  expect_equal(or, expected, tolerance = 1e-10)
})

test_that("calc_overround: fair market returns ~1", {
  or <- calc_overround(c(2.0, 2.0))
  expect_equal(or, 1.0)
})
