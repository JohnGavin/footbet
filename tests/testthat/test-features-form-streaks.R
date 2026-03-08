# Tests for form streak feature functions

# ---- form_streak ----

test_that("form_streak computes win streak correctly", {
  matches <- tibble::tibble(
    match_date = as.Date(c("2023-01-01", "2023-01-08", "2023-01-15",
                           "2023-01-22", "2023-01-29")),
    home_team = c("A", "B", "A", "B", "A"),
    away_team = c("B", "A", "C", "A", "D"),
    ftr = c("H", "A", "H", "A", "H")  # A wins all 5
  )

  result <- form_streak(matches, "A", as.Date("2023-02-01"))

  expect_s3_class(result, "tbl_df")
  expect_equal(result$team, "A")
  expect_equal(result$win_streak, 5L)
  expect_equal(result$loss_streak, 0L)
  expect_equal(result$unbeaten_streak, 5L)
  expect_equal(result$winless_streak, 0L)
})

test_that("form_streak computes loss streak correctly", {
  matches <- tibble::tibble(
    match_date = as.Date(c("2023-01-01", "2023-01-08", "2023-01-15")),
    home_team = c("A", "B", "A"),
    away_team = c("B", "A", "C"),
    ftr = c("A", "H", "A")  # A loses all 3
  )

  result <- form_streak(matches, "A", as.Date("2023-02-01"))

  expect_equal(result$loss_streak, 3L)
  expect_equal(result$win_streak, 0L)
  expect_equal(result$winless_streak, 3L)
})

test_that("form_streak computes unbeaten streak with draws", {
  matches <- tibble::tibble(
    match_date = as.Date(c("2023-01-01", "2023-01-08", "2023-01-15",
                           "2023-01-22")),
    home_team = c("A", "B", "A", "A"),
    away_team = c("B", "A", "C", "D"),
    ftr = c("H", "D", "D", "H")  # W, D, D, W
  )

  result <- form_streak(matches, "A", as.Date("2023-02-01"))

  expect_equal(result$unbeaten_streak, 4L)
  expect_equal(result$win_streak, 1L)  # Only most recent win
  expect_equal(result$winless_streak, 0L)
})

test_that("form_streak respects as_of_date", {
  matches <- tibble::tibble(
    match_date = as.Date(c("2023-01-01", "2023-01-08", "2023-01-15",
                           "2023-01-22", "2023-01-29")),
    home_team = c("A", "A", "A", "A", "A"),
    away_team = c("B", "C", "D", "E", "F"),
    ftr = c("H", "H", "A", "H", "H")  # W, W, L, W, W
  )

  # As of Jan 20, see first 3 matches (Jan 1, 8, 15 are all < Jan 20)

  # In reverse order: L (Jan 15), W (Jan 8), W (Jan 1)
  # Most recent is L, so win_streak = 0
  result <- form_streak(matches, "A", as.Date("2023-01-20"))

  expect_equal(result$win_streak, 0L)  # Most recent is L
  expect_equal(result$n_matches, 3L)   # 3 matches before Jan 20
  expect_equal(result$loss_streak, 1L)
})

test_that("form_streak returns zeros for no history", {
  matches <- tibble::tibble(
    match_date = as.Date("2023-01-01"),
    home_team = "A",
    away_team = "B",
    ftr = "H"
  )

  # Team C has no history
  result <- form_streak(matches, "C", as.Date("2023-02-01"))

  expect_equal(result$win_streak, 0L)
  expect_equal(result$loss_streak, 0L)
  expect_equal(result$n_matches, 0L)
})

test_that("form_streak handles mixed results correctly", {
  matches <- tibble::tibble(
    match_date = as.Date(c("2023-01-01", "2023-01-08", "2023-01-15",
                           "2023-01-22", "2023-01-29")),
    home_team = c("A", "B", "A", "A", "B"),
    away_team = c("B", "A", "C", "D", "A"),
    ftr = c("H", "D", "A", "D", "H")
    # From A's perspective in chronological order: W, D, L, D, L
    # In reverse order (most recent first): L, D, L, D, W
  )

  result <- form_streak(matches, "A", as.Date("2023-02-01"))

  # Most recent is L (B beat A on Jan 29), so:
  expect_equal(result$win_streak, 0L)
  expect_equal(result$loss_streak, 1L)  # Only 1 L before D
  expect_equal(result$unbeaten_streak, 0L)
  expect_equal(result$winless_streak, 4L)  # L, D, L, D (stops at W)
})

test_that("form_streak validates required arguments", {
  matches <- tibble::tibble(
    match_date = as.Date("2023-01-01"),
    home_team = "A",
    away_team = "B",
    ftr = "H"
  )

  expect_error(form_streak(matches))
  expect_error(form_streak())
})

# ---- add_form_streaks ----

test_that("add_form_streaks adds streak columns to matches", {
  matches <- tibble::tibble(
    match_date = as.Date(c("2023-01-01", "2023-01-08", "2023-01-15")),
    home_team = c("A", "B", "A"),
    away_team = c("B", "C", "C"),
    ftr = c("H", "H", "H")
  )

  result <- add_form_streaks(matches)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 3L)
  expect_true("home_win_streak" %in% colnames(result))
  expect_true("home_loss_streak" %in% colnames(result))
  expect_true("home_unbeaten_streak" %in% colnames(result))
  expect_true("home_winless_streak" %in% colnames(result))
  expect_true("away_win_streak" %in% colnames(result))
  expect_true("away_loss_streak" %in% colnames(result))
})

test_that("add_form_streaks uses only past data", {
  matches <- tibble::tibble(
    match_date = as.Date(c("2023-01-01", "2023-01-08", "2023-01-15")),
    home_team = c("A", "A", "A"),
    away_team = c("B", "C", "D"),
    ftr = c("H", "H", "H")
  )

  result <- add_form_streaks(matches)

  # First match: no history
  expect_equal(result$home_win_streak[1], 0L)

  # Second match: 1 prior win

  expect_equal(result$home_win_streak[2], 1L)

  # Third match: 2 prior wins
  expect_equal(result$home_win_streak[3], 2L)
})

test_that("add_form_streaks handles empty input", {
  matches <- tibble::tibble(
    match_date = as.Date(character()),
    home_team = character(),
    away_team = character(),
    ftr = character()
  )

  result <- add_form_streaks(matches)

  expect_equal(nrow(result), 0L)
  expect_true("home_win_streak" %in% colnames(result))
})

test_that("add_form_streaks validates required argument", {
  expect_error(add_form_streaks())
})
