# Tests for odds conversion utilities

# ---- decimal_to_fractional ----

test_that("decimal_to_fractional converts standard odds", {
  # 2.5 = 3/2 (1.5 profit)
  expect_equal(decimal_to_fractional(2.5), "3/2")

  # 2.0 = 1/1 (evens)
  expect_equal(decimal_to_fractional(2.0), "1/1")

  # 1.5 = 1/2
  expect_equal(decimal_to_fractional(1.5), "1/2")

  # 3.0 = 2/1
  expect_equal(decimal_to_fractional(3.0), "2/1")

  # 4.0 = 3/1
  expect_equal(decimal_to_fractional(4.0), "3/1")
})

test_that("decimal_to_fractional handles vector input", {
  result <- decimal_to_fractional(c(2.0, 2.5, 3.0))
  expect_equal(result, c("1/1", "3/2", "2/1"))
})

test_that("decimal_to_fractional handles NA", {
  expect_true(is.na(decimal_to_fractional(NA_real_)))
})

test_that("decimal_to_fractional returns NA for invalid odds", {
  expect_true(is.na(decimal_to_fractional(1.0)))  # No profit possible
  expect_true(is.na(decimal_to_fractional(0.5)))  # Negative odds invalid
})

test_that("decimal_to_fractional validates numeric input", {
  expect_error(decimal_to_fractional("abc"), "must be numeric")
})

test_that("decimal_to_fractional requires argument", {
  expect_error(decimal_to_fractional())
})

# ---- decimal_to_american ----

test_that("decimal_to_american converts underdog odds (positive)", {
  # 2.0 = +100
  expect_equal(decimal_to_american(2.0), 100)

  # 3.0 = +200
  expect_equal(decimal_to_american(3.0), 200)

  # 4.5 = +350
  expect_equal(decimal_to_american(4.5), 350)
})

test_that("decimal_to_american converts favourite odds (negative)", {
  # 1.5 = -200
  expect_equal(decimal_to_american(1.5), -200)

  # 1.25 = -400
  expect_equal(decimal_to_american(1.25), -400)

  # 1.1 = -1000
  expect_equal(decimal_to_american(1.1), -1000)
})

test_that("decimal_to_american handles vector input", {
  result <- decimal_to_american(c(1.5, 2.0, 3.0))
  expect_equal(result, c(-200, 100, 200))
})

test_that("decimal_to_american handles NA and invalid", {
  expect_true(is.na(decimal_to_american(NA_real_)))
  expect_true(is.na(decimal_to_american(0.5)))  # Invalid
})

test_that("decimal_to_american validates numeric input", {
  expect_error(decimal_to_american("abc"), "must be numeric")
})

test_that("decimal_to_american requires argument", {
  expect_error(decimal_to_american())
})

# ---- american_to_decimal ----

test_that("american_to_decimal converts positive (underdog)", {
  # +100 = 2.0
  expect_equal(american_to_decimal(100), 2.0)

  # +200 = 3.0
  expect_equal(american_to_decimal(200), 3.0)

  # +350 = 4.5
  expect_equal(american_to_decimal(350), 4.5)
})

test_that("american_to_decimal converts negative (favourite)", {
  # -200 = 1.5
  expect_equal(american_to_decimal(-200), 1.5)

  # -400 = 1.25
  expect_equal(american_to_decimal(-400), 1.25)

  # -100 = 2.0
  expect_equal(american_to_decimal(-100), 2.0)
})

test_that("american_to_decimal handles vector input", {
  result <- american_to_decimal(c(-200, 100, 200))
  expect_equal(result, c(1.5, 2.0, 3.0))
})

test_that("american_to_decimal handles NA and zero", {
  expect_true(is.na(american_to_decimal(NA_real_)))
  expect_true(is.na(american_to_decimal(0)))  # Invalid
})

test_that("american_to_decimal validates numeric input", {
  expect_error(american_to_decimal("abc"), "must be numeric")
})

test_that("american_to_decimal requires argument", {
  expect_error(american_to_decimal())
})

# ---- fractional_to_decimal ----

test_that("fractional_to_decimal converts standard fractions", {
  expect_equal(fractional_to_decimal("1/1"), 2.0)
  expect_equal(fractional_to_decimal("3/2"), 2.5)
  expect_equal(fractional_to_decimal("2/1"), 3.0)
  expect_equal(fractional_to_decimal("1/2"), 1.5)
  expect_equal(fractional_to_decimal("5/1"), 6.0)
})

test_that("fractional_to_decimal handles 'evens'", {
  expect_equal(fractional_to_decimal("evens"), 2.0)
  expect_equal(fractional_to_decimal("EVENS"), 2.0)
  expect_equal(fractional_to_decimal("evs"), 2.0)
})

test_that("fractional_to_decimal handles vector input", {
  result <- fractional_to_decimal(c("1/1", "3/2", "2/1"))
  expect_equal(result, c(2.0, 2.5, 3.0))
})

test_that("fractional_to_decimal handles whitespace", {
  expect_equal(fractional_to_decimal("  3/2  "), 2.5)
})

test_that("fractional_to_decimal handles NA and invalid", {
  expect_true(is.na(fractional_to_decimal(NA_character_)))
  expect_true(is.na(fractional_to_decimal("abc")))
  expect_true(is.na(fractional_to_decimal("1/0")))  # Division by zero
})

test_that("fractional_to_decimal validates character input", {
  expect_error(fractional_to_decimal(2.5), "must be character")
})

test_that("fractional_to_decimal requires argument", {
  expect_error(fractional_to_decimal())
})

# ---- convert_odds ----

test_that("convert_odds decimal to american and back", {
  original <- 2.5

  american <- convert_odds(original, "decimal", "american")
  back <- convert_odds(american, "american", "decimal")

  expect_equal(back, original)
})

test_that("convert_odds decimal to fractional and back", {
  original <- 2.5

  fractional <- convert_odds(original, "decimal", "fractional")
  back <- convert_odds(fractional, "fractional", "decimal")

  expect_equal(back, original)
})

test_that("convert_odds validates format arguments", {
  expect_error(convert_odds(2.0, "invalid", "decimal"), "must be one of")
  expect_error(convert_odds(2.0, "decimal", "invalid"), "must be one of")
})

test_that("convert_odds is case insensitive", {
  expect_equal(
    convert_odds(2.0, "DECIMAL", "AMERICAN"),
    convert_odds(2.0, "decimal", "american")
  )
})

test_that("convert_odds requires all arguments", {
  expect_error(convert_odds(2.0, "decimal"))
  expect_error(convert_odds(2.0))
  expect_error(convert_odds())
})

# ---- round trip tests ----

test_that("all conversions are consistent", {
  decimals <- c(1.5, 2.0, 2.5, 3.0, 4.0)

  for (d in decimals) {
    # Decimal -> American -> Decimal
    via_american <- american_to_decimal(decimal_to_american(d))
    expect_equal(via_american, d, tolerance = 1e-10)

    # Decimal -> Fractional -> Decimal
    via_fractional <- fractional_to_decimal(decimal_to_fractional(d))
    expect_equal(via_fractional, d, tolerance = 1e-10)
  }
})
