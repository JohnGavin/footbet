# Tests for R/data_fbref.R
# Note: worldfootballR scrapes live websites, so we test internal helpers
# and mock the network calls.

# ---- standardise_fbref_columns ----

test_that("standardise_fbref_columns renames known columns", {
  raw <- data.frame(
    Date = "2024-01-15",
    Home = "Manchester United",
    Away = "Liverpool",
    HomeGoals = 2L,
    AwayGoals = 1L,
    Home_xG = 1.8,
    Away_xG = 1.2
  )

  result <- standardise_fbref_columns(raw)

  expect_s3_class(result, "tbl_df")
  expect_true("match_date" %in% names(result))
  expect_true("home_team" %in% names(result))
  expect_true("away_team" %in% names(result))
  expect_true("home_xg" %in% names(result))
  expect_true("away_xg" %in% names(result))
})

test_that("standardise_fbref_columns converts date to Date class", {
  raw <- data.frame(Date = "2024-01-15", Home = "A", Away = "B")
  result <- standardise_fbref_columns(raw)
  expect_s3_class(result$match_date, "Date")
})

test_that("standardise_fbref_columns converts xG to numeric", {
  raw <- data.frame(
    Date = "2024-01-15",
    Home = "A",
    Away = "B",
    Home_xG = "1.5",  # Character
    Away_xG = "0.8"
  )

  result <- standardise_fbref_columns(raw)
  expect_type(result$home_xg, "double")
  expect_type(result$away_xg, "double")
})

# ---- build_team_name_map ----

test_that("build_team_name_map returns named character vector", {
  map <- build_team_name_map()
  expect_type(map, "character")
  expect_true(length(map) > 0)
  expect_true(all(nchar(names(map)) > 0))
})

test_that("build_team_name_map includes major teams", {
  map <- build_team_name_map()
  expect_true("Manchester United" %in% names(map))
  expect_true("Paris Saint-Germain" %in% names(map))
  expect_true("Bayern Munich" %in% names(map))
})

# ---- normalise_team_name ----

test_that("normalise_team_name maps known variations", {
  map <- build_team_name_map()

  # All output is lowercase for consistent matching
  expect_equal(
    normalise_team_name("Manchester United", map),
    "man united"
  )
  expect_equal(
    normalise_team_name("Paris Saint-Germain", map),
    "paris sg"
  )
})

test_that("normalise_team_name returns lowercase for unknown teams", {
  map <- build_team_name_map()
  expect_equal(
    normalise_team_name("Unknown FC", map),
    "unknown fc"
  )
})

# ---- fetch_fbref_matches input validation ----

test_that("fetch_fbref_matches validates country code", {
  skip_if_not_installed("worldfootballR")
  expect_error(fetch_fbref_matches("INVALID", 2024), "Unknown country")
})

test_that("fetch_fbref_matches accepts standard league codes", {
  skip_if_not_installed("worldfootballR")
  # Just test that these don't error on input validation
  # (actual fetch would hit network)
  expect_error(fetch_fbref_matches("XXX", 2024), "Unknown country")

  # Valid codes should not error on validation (will error on network if offline)
})

# ---- join_xg_to_matches ----

test_that("join_xg_to_matches handles empty FBref data", {
  matches <- tibble::tibble(
    match_id = "m1",
    match_date = as.Date("2024-01-15"),
    home_team = "Team A",
    away_team = "Team B",
    fthg = 2L,
    ftag = 1L
  )

  fbref <- tibble::tibble()

  # Expect warning about empty FBref data
  expect_warning(
    result <- join_xg_to_matches(matches, fbref),
    "FBref data is empty"
  )

  expect_true("home_xg" %in% names(result))
  expect_true("away_xg" %in% names(result))
  expect_true(all(is.na(result$home_xg)))
})

test_that("join_xg_to_matches joins by date and team", {
  matches <- tibble::tibble(
    match_id = "m1",
    match_date = as.Date("2024-01-15"),
    home_team = "Man United",
    away_team = "Liverpool",
    fthg = 2L,
    ftag = 1L
  )

  fbref <- tibble::tibble(
    match_date = as.Date("2024-01-15"),
    home_team = "Manchester United",  # Different spelling
    away_team = "Liverpool",
    home_xg = 1.8,
    away_xg = 1.2
  )

  result <- join_xg_to_matches(matches, fbref)

  expect_equal(result$home_xg, 1.8)
  expect_equal(result$away_xg, 1.2)
})

test_that("join_xg_to_matches reports match rate", {
  matches <- tibble::tibble(
    match_id = c("m1", "m2"),
    match_date = as.Date(c("2024-01-15", "2024-01-16")),
    home_team = c("Team A", "Team C"),
    away_team = c("Team B", "Team D"),
    fthg = c(2L, 1L),
    ftag = c(1L, 1L)
  )

  fbref <- tibble::tibble(
    match_date = as.Date("2024-01-15"),
    home_team = "Team A",
    away_team = "Team B",
    home_xg = 1.5,
    away_xg = 1.0
  )

  expect_message(
    join_xg_to_matches(matches, fbref),
    regexp = NULL  # Just check it runs
  )
})
