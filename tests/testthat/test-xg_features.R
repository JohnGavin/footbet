# Tests for xG features in R/features.R
# Rolling xG, cumulative xG ratio, xG overperformance

# ---- rolling_xg ----

test_that("rolling_xg returns expected structure", {
  matches <- tibble::tibble(
    match_id = paste0("m", 1:4),
    match_date = as.Date("2024-01-01") + c(0, 7, 14, 21),
    home_team = c("A", "B", "A", "B"),
    away_team = c("B", "A", "B", "A"),
    home_xg = c(1.5, 1.2, 2.0, 0.8),
    away_xg = c(1.0, 1.8, 0.5, 1.5)
  )

  result <- rolling_xg(matches, window = 2L)

  expect_s3_class(result, "tbl_df")
  expect_true(all(c("team", "match_date", "rolling_xg_for",
                    "rolling_xg_against", "rolling_xg_diff") %in% names(result)))
})

test_that("rolling_xg computes lagged values (no leakage)", {
  matches <- tibble::tibble(
    match_id = paste0("m", 1:3),
    match_date = as.Date("2024-01-01") + c(0, 7, 14),
    home_team = c("A", "A", "A"),
    away_team = c("B", "B", "B"),
    home_xg = c(1.0, 2.0, 3.0),
    away_xg = c(0.5, 0.5, 0.5)
  )

  result <- rolling_xg(matches, window = 5L) |>
    dplyr::filter(team == "A")

  # First match: NA (no history)
  expect_true(is.na(result$rolling_xg_for[1]))

  # Second match: should use first match only
  expect_equal(result$rolling_xg_for[2], 1.0)

  # Third match: should use first two matches
  expect_equal(result$rolling_xg_for[3], 1.5)  # mean(1.0, 2.0)
})

test_that("rolling_xg validates required columns", {
  bad_df <- tibble::tibble(home_team = "A", away_team = "B")
  expect_error(rolling_xg(bad_df), "Missing required columns")
})

# ---- cumulative_xg_ratio ----

test_that("cumulative_xg_ratio returns expected structure", {
  matches <- tibble::tibble(
    match_id = paste0("m", 1:4),
    match_date = as.Date("2024-01-01") + c(0, 7, 14, 21),
    season = "2324",
    home_team = c("A", "B", "A", "B"),
    away_team = c("B", "A", "B", "A"),
    home_xg = c(1.5, 1.2, 2.0, 0.8),
    away_xg = c(1.0, 1.8, 0.5, 1.5)
  )

  result <- cumulative_xg_ratio(matches)

  expect_s3_class(result, "tbl_df")
  expect_true(all(c("team", "match_date", "xg_ratio",
                    "cum_xg_for", "cum_xg_against") %in% names(result)))
})

test_that("cumulative_xg_ratio starts at 0.5 for first match", {
  matches <- tibble::tibble(
    match_id = "m1",
    match_date = as.Date("2024-01-01"),
    season = "2324",
    home_team = "A",
    away_team = "B",
    home_xg = 1.5,
    away_xg = 1.0
  )

  result <- cumulative_xg_ratio(matches)

  # First match should have xg_ratio = 0.5 (no prior data)
  expect_equal(result$xg_ratio[result$team == "A"], 0.5)
  expect_equal(result$xg_ratio[result$team == "B"], 0.5)
})

test_that("cumulative_xg_ratio accumulates within season", {
  matches <- tibble::tibble(
    match_id = paste0("m", 1:2),
    match_date = as.Date("2024-01-01") + c(0, 7),
    season = "2324",
    home_team = c("A", "A"),
    away_team = c("B", "B"),
    home_xg = c(2.0, 2.0),
    away_xg = c(1.0, 1.0)
  )

  result <- cumulative_xg_ratio(matches) |>
    dplyr::filter(team == "A") |>
    dplyr::arrange(match_date)

  # First match: 0.5 (no prior)
  expect_equal(result$xg_ratio[1], 0.5)

  # Second match: 2.0 / (2.0 + 1.0) = 0.667
  expect_equal(result$xg_ratio[2], 2/3, tolerance = 0.01)
})

test_that("cumulative_xg_ratio resets across seasons", {
  matches <- tibble::tibble(
    match_id = paste0("m", 1:2),
    match_date = as.Date(c("2024-01-01", "2024-08-15")),
    season = c("2324", "2425"),
    home_team = c("A", "A"),
    away_team = c("B", "B"),
    home_xg = c(2.0, 1.0),
    away_xg = c(1.0, 2.0)
  )

  result <- cumulative_xg_ratio(matches) |>
    dplyr::filter(team == "A") |>
    dplyr::arrange(match_date)

  # Both should be 0.5 (first match of each season)
  expect_equal(result$xg_ratio[1], 0.5)
  expect_equal(result$xg_ratio[2], 0.5)
})

# ---- xg_overperformance ----

test_that("xg_overperformance returns expected structure", {
  matches <- tibble::tibble(
    match_id = paste0("m", 1:3),
    match_date = as.Date("2024-01-01") + c(0, 7, 14),
    home_team = c("A", "B", "A"),
    away_team = c("B", "A", "B"),
    fthg = c(2L, 1L, 3L),
    ftag = c(1L, 2L, 0L),
    home_xg = c(1.5, 1.2, 2.0),
    away_xg = c(1.0, 1.8, 0.5)
  )

  result <- xg_overperformance(matches, window = 2L)

  expect_s3_class(result, "tbl_df")
  expect_true(all(c("team", "match_date",
                    "rolling_overperf_attack",
                    "rolling_overperf_defense") %in% names(result)))
})

test_that("xg_overperformance detects clinical finishing", {
  # Team A scores more than xG (clinical)
  matches <- tibble::tibble(
    match_id = paste0("m", 1:2),
    match_date = as.Date("2024-01-01") + c(0, 7),
    home_team = c("A", "A"),
    away_team = c("B", "B"),
    fthg = c(3L, 3L),  # Actual goals
    ftag = c(1L, 1L),
    home_xg = c(1.5, 1.5),  # Expected
    away_xg = c(1.0, 1.0)
  )

  result <- xg_overperformance(matches, window = 5L) |>
    dplyr::filter(team == "A") |>
    dplyr::arrange(match_date)

  # Second match should show positive overperformance from first match
  # overperf_attack = goals - xG = 3 - 1.5 = 1.5
  expect_equal(result$rolling_overperf_attack[2], 1.5, tolerance = 0.01)
})

test_that("xg_overperformance validates required columns", {
  bad_df <- tibble::tibble(home_team = "A", away_team = "B")
  expect_error(xg_overperformance(bad_df), "Missing required columns")
})

# ---- compute_xg_features ----

test_that("compute_xg_features combines all xG features", {
  matches <- tibble::tibble(
    match_id = paste0("m", 1:4),
    match_date = as.Date("2024-01-01") + c(0, 7, 14, 21),
    season = "2324",
    home_team = c("A", "B", "A", "B"),
    away_team = c("B", "A", "B", "A"),
    fthg = c(2L, 1L, 3L, 0L),
    ftag = c(1L, 2L, 0L, 2L),
    home_xg = c(1.5, 1.2, 2.0, 0.8),
    away_xg = c(1.0, 1.8, 0.5, 1.5)
  )

  result <- compute_xg_features(matches)

  expect_s3_class(result, "tbl_df")
  expect_true("rolling_xg_for" %in% names(result))
  expect_true("xg_ratio" %in% names(result))
  expect_true("rolling_overperf_attack" %in% names(result))
})

test_that("compute_xg_features warns on missing xG data", {
  matches <- tibble::tibble(
    match_id = "m1",
    match_date = as.Date("2024-01-01"),
    home_team = "A",
    away_team = "B"
  )

  expect_warning(
    compute_xg_features(matches),
    "No xG data"
  )
})

test_that("compute_xg_features handles matches without goals", {
  # Matches with xG but no goals columns
  matches <- tibble::tibble(
    match_id = paste0("m", 1:2),
    match_date = as.Date("2024-01-01") + c(0, 7),
    home_team = c("A", "A"),
    away_team = c("B", "B"),
    home_xg = c(1.5, 2.0),
    away_xg = c(1.0, 0.5)
  )

  result <- compute_xg_features(matches)

  # Should have rolling and ratio, but not overperformance
  expect_true("rolling_xg_for" %in% names(result))
  expect_true("xg_ratio" %in% names(result))
  # Overperformance requires goals
  expect_false("rolling_overperf_attack" %in% names(result))
})
