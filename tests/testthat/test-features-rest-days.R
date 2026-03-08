# Tests for rest days feature functions

# ---- rest_days ----

test_that("rest_days computes days since last match", {
  matches <- tibble::tibble(
    match_date = as.Date(c("2023-01-01", "2023-01-08", "2023-01-15")),
    home_team = c("A", "B", "A"),
    away_team = c("B", "A", "C")
  )

  # A's last match was Jan 8 (away at B), so rest = 7 days as of Jan 15
  result <- rest_days(matches, "A", as.Date("2023-01-15"))

  expect_equal(result, 7L)
})

test_that("rest_days returns NA for no previous matches", {
  matches <- tibble::tibble(
    match_date = as.Date("2023-01-01"),
    home_team = "A",
    away_team = "B"
  )

  # Team C has no matches
  result <- rest_days(matches, "C", as.Date("2023-01-15"))

  expect_true(is.na(result))
})

test_that("rest_days respects as_of_date", {
  matches <- tibble::tibble(
    match_date = as.Date(c("2023-01-01", "2023-01-08", "2023-01-15")),
    home_team = c("A", "A", "A"),
    away_team = c("B", "C", "D")
  )

  # As of Jan 10, A's last match was Jan 8 (2 days ago)
  result <- rest_days(matches, "A", as.Date("2023-01-10"))

  expect_equal(result, 2L)
})

test_that("rest_days handles team playing at home and away", {
  matches <- tibble::tibble(
    match_date = as.Date(c("2023-01-01", "2023-01-05")),
    home_team = c("A", "B"),
    away_team = c("B", "A")  # A played away on Jan 5
  )

  # A's last match was Jan 5 (away)
  result <- rest_days(matches, "A", as.Date("2023-01-12"))

  expect_equal(result, 7L)
})

test_that("rest_days validates required arguments", {
  matches <- tibble::tibble(
    match_date = as.Date("2023-01-01"),
    home_team = "A",
    away_team = "B"
  )

  expect_error(rest_days(matches, "A"))
  expect_error(rest_days(matches))
  expect_error(rest_days())
})

# ---- add_rest_days ----

test_that("add_rest_days adds rest columns to matches", {
  matches <- tibble::tibble(
    match_date = as.Date(c("2023-01-01", "2023-01-08", "2023-01-15")),
    home_team = c("A", "B", "A"),
    away_team = c("B", "C", "C")
  )

  result <- add_rest_days(matches)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 3L)
  expect_true("home_rest_days" %in% colnames(result))
  expect_true("away_rest_days" %in% colnames(result))
  expect_true("rest_advantage" %in% colnames(result))
})

test_that("add_rest_days computes correct values", {
  matches <- tibble::tibble(
    match_date = as.Date(c("2023-01-01", "2023-01-08", "2023-01-15")),
    home_team = c("A", "A", "A"),
    away_team = c("B", "B", "B")
  )

  result <- add_rest_days(matches)

  # First match: no history
  expect_true(is.na(result$home_rest_days[1]))
  expect_true(is.na(result$away_rest_days[1]))

  # Second match: both teams played 7 days ago
  expect_equal(result$home_rest_days[2], 7L)
  expect_equal(result$away_rest_days[2], 7L)
  expect_equal(result$rest_advantage[2], 0L)

  # Third match: both teams played 7 days ago
  expect_equal(result$home_rest_days[3], 7L)
  expect_equal(result$away_rest_days[3], 7L)
})

test_that("add_rest_days computes rest advantage correctly", {
  matches <- tibble::tibble(
    match_date = as.Date(c("2023-01-01", "2023-01-07", "2023-01-10")),
    home_team = c("A", "B", "A"),
    away_team = c("C", "D", "B")
    # A played Jan 1, B played Jan 7
    # Match 3 (Jan 10): A has 9 days rest, B has 3 days rest
  )

  result <- add_rest_days(matches)

  # Third match: A has 9 days rest, B has 3 days
  expect_equal(result$home_rest_days[3], 9L)
  expect_equal(result$away_rest_days[3], 3L)
  expect_equal(result$rest_advantage[3], 6L)  # 9 - 3 = 6 days advantage
})

test_that("add_rest_days handles empty input", {
  matches <- tibble::tibble(
    match_date = as.Date(character()),
    home_team = character(),
    away_team = character()
  )

  result <- add_rest_days(matches)

  expect_equal(nrow(result), 0L)
  expect_true("home_rest_days" %in% colnames(result))
})

test_that("add_rest_days validates required argument", {
  expect_error(add_rest_days())
})
