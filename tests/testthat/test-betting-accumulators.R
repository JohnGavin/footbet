# Tests for accumulator betting functions

# ---- acca_odds ----

test_that("acca_odds multiplies odds", {
  odds <- c(2.0, 3.0, 1.5)

  result <- acca_odds(odds)

  expect_equal(result, 2.0 * 3.0 * 1.5)
})

test_that("acca_odds validates minimum odds", {
  expect_error(acca_odds(c(2.0, 0.5)), ">= 1")
})

test_that("acca_odds returns NA for NA input", {
  expect_true(is.na(acca_odds(c(2.0, NA))))
})

test_that("acca_odds requires argument", {
  expect_error(acca_odds())
})

# ---- acca_ev ----

test_that("acca_ev computes expected value", {
  # Two 50% bets at 2.0 each
  probs <- c(0.5, 0.5)
  odds <- c(2.0, 2.0)

  result <- acca_ev(probs, odds)

  # Combined prob = 0.25, combined odds = 4.0
  # EV = 0.25 * 3 - 0.75 = 0
  expect_equal(result, 0, tolerance = 1e-10)
})

test_that("acca_ev positive for value accumulator", {
  # Two 60% bets at 2.0 each = value
  probs <- c(0.6, 0.6)
  odds <- c(2.0, 2.0)

  result <- acca_ev(probs, odds)

  # Combined prob = 0.36, combined odds = 4.0
  # EV = 0.36 * 3 - 0.64 = 0.44
  expect_true(result > 0)
})

test_that("acca_ev negative for poor accumulator", {
  # Two 40% bets at 2.0 each = negative EV
  probs <- c(0.4, 0.4)
  odds <- c(2.0, 2.0)

  result <- acca_ev(probs, odds)

  expect_true(result < 0)
})

test_that("acca_ev validates same length", {
  expect_error(acca_ev(c(0.5, 0.6), c(2.0)), "same length")
})

test_that("acca_ev requires arguments", {
  expect_error(acca_ev(c(0.5)))
  expect_error(acca_ev())
})

# ---- find_best_accas ----

test_that("find_best_accas finds positive EV combos", {
  selections <- tibble::tibble(
    prob = c(0.6, 0.65, 0.55, 0.5),
    odds = c(2.0, 1.8, 2.2, 2.5)
  )

  result <- find_best_accas(selections, min_legs = 2, max_legs = 3, min_ev = 0)

  expect_s3_class(result, "tbl_df")
  expect_true(all(result$expected_value >= 0))
  expect_true("legs" %in% colnames(result))
  expect_true("combined_odds" %in% colnames(result))
})

test_that("find_best_accas returns empty for no value", {
  selections <- tibble::tibble(
    prob = c(0.3, 0.3),  # Poor probabilities
    odds = c(2.0, 2.0)
  )

  result <- find_best_accas(selections, min_ev = 0)

  expect_equal(nrow(result), 0L)
})

test_that("find_best_accas warns for insufficient selections", {
  selections <- tibble::tibble(
    prob = 0.5,
    odds = 2.0
  )

  expect_warning(
    result <- find_best_accas(selections, min_legs = 2),
    "Not enough selections"
  )
})

test_that("find_best_accas validates required columns", {
  selections <- tibble::tibble(x = 1, y = 2)

  expect_error(find_best_accas(selections), "prob.*odds")
})

test_that("find_best_accas requires argument", {
  expect_error(find_best_accas())
})
