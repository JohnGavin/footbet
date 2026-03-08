# Tests for Understat xG data functions

# ---- fetch_understat_xg ----

test_that("fetch_understat_xg validates league argument", {
  skip_if_not_installed("understatr")

  expect_error(
    fetch_understat_xg("Invalid", 2023),
    "Invalid league"
  )
})

test_that("fetch_understat_xg requires arguments", {
  expect_error(fetch_understat_xg("EPL"))
  expect_error(fetch_understat_xg())
})

# Note: Actual API tests should be skipped in CI
test_that("fetch_understat_xg returns expected structure", {
  skip_if_not_installed("understatr")
  skip_on_cran()
  skip_on_ci()  # Skip network tests in CI

  result <- fetch_understat_xg("EPL", 2022)

  expect_s3_class(result, "tbl_df")
  expect_true("match_date" %in% colnames(result))
  expect_true("home_team" %in% colnames(result))
  expect_true("away_team" %in% colnames(result))
  expect_true("home_xg" %in% colnames(result))
  expect_true("away_xg" %in% colnames(result))
})

# ---- understat_team_mapping ----

test_that("understat_team_mapping returns EPL mappings", {
  result <- understat_team_mapping("E0")

  expect_true(is.character(result))
  expect_true("Manchester United" %in% names(result))
  expect_equal(result[["Manchester United"]], "Man United")
})

test_that("understat_team_mapping returns La Liga mappings", {
  result <- understat_team_mapping("SP1")

  expect_true("Atletico Madrid" %in% names(result))
})

test_that("understat_team_mapping returns Bundesliga mappings", {
  result <- understat_team_mapping("D1")

  expect_true("Borussia Dortmund" %in% names(result))
})

test_that("understat_team_mapping returns empty for unknown league", {
  result <- understat_team_mapping("XX")

  expect_equal(length(result), 0L)
})

test_that("understat_team_mapping requires argument", {
  expect_error(understat_team_mapping())
})

# ---- join_understat_xg ----

test_that("join_understat_xg matches by date and team", {
  matches <- tibble::tibble(
    match_date = as.Date(c("2023-01-01", "2023-01-08")),
    home_team = c("Arsenal", "Liverpool"),
    away_team = c("Liverpool", "Chelsea")
  )

  understat <- tibble::tibble(
    match_date = as.Date(c("2023-01-01", "2023-01-08")),
    home_team = c("Arsenal", "Liverpool"),
    away_team = c("Liverpool", "Chelsea"),
    home_xg = c(1.5, 2.0),
    away_xg = c(0.8, 1.2)
  )

  result <- suppressMessages(join_understat_xg(matches, understat, "E0"))

  expect_equal(nrow(result), 2L)
  expect_true("understat_home_xg" %in% colnames(result))
  expect_true("understat_away_xg" %in% colnames(result))
  expect_equal(result$understat_home_xg[1], 1.5)
})

test_that("join_understat_xg handles missing matches", {
  matches <- tibble::tibble(
    match_date = as.Date(c("2023-01-01", "2023-01-08")),
    home_team = c("Arsenal", "Wolves"),
    away_team = c("Liverpool", "Brighton")
  )

  understat <- tibble::tibble(
    match_date = as.Date("2023-01-01"),
    home_team = "Arsenal",
    away_team = "Liverpool",
    home_xg = 1.5,
    away_xg = 0.8
  )

  result <- suppressMessages(join_understat_xg(matches, understat, "E0"))

  expect_equal(result$understat_home_xg[1], 1.5)
  expect_true(is.na(result$understat_home_xg[2]))  # No match
})

test_that("join_understat_xg applies team name mapping", {
  matches <- tibble::tibble(
    match_date = as.Date("2023-01-01"),
    home_team = "Man United",  # FD name
    away_team = "Wolves"
  )

  understat <- tibble::tibble(
    match_date = as.Date("2023-01-01"),
    home_team = "Manchester United",  # Understat name
    away_team = "Wolverhampton Wanderers",
    home_xg = 2.1,
    away_xg = 0.9
  )

  result <- suppressMessages(join_understat_xg(matches, understat, "E0"))

  expect_equal(result$understat_home_xg[1], 2.1)
})

test_that("join_understat_xg handles empty understat data", {
  matches <- tibble::tibble(
    match_date = as.Date("2023-01-01"),
    home_team = "Arsenal",
    away_team = "Liverpool"
  )

  understat <- tibble::tibble(
    match_date = as.Date(character()),
    home_team = character(),
    away_team = character(),
    home_xg = numeric(),
    away_xg = numeric()
  )

  result <- join_understat_xg(matches, understat, "E0")

  expect_true(is.na(result$understat_home_xg[1]))
})

test_that("join_understat_xg requires arguments", {
  matches <- tibble::tibble(
    match_date = as.Date("2023-01-01"),
    home_team = "A",
    away_team = "B"
  )

  expect_error(join_understat_xg(matches))
  expect_error(join_understat_xg())
})

# ---- add_understat_xg ----

test_that("add_understat_xg requires arguments", {
  matches <- tibble::tibble(
    match_date = as.Date("2023-01-01"),
    home_team = "A",
    away_team = "B"
  )

  expect_error(add_understat_xg(matches, "EPL"))
  expect_error(add_understat_xg(matches))
  expect_error(add_understat_xg())
})
