# Tests for league position feature functions

# ---- league_table ----

test_that("league_table computes standings correctly", {
  matches <- tibble::tibble(
    match_date = as.Date(c("2023-01-01", "2023-01-08", "2023-01-15")),
    home_team = c("A", "B", "C"),
    away_team = c("B", "C", "A"),
    ftr = c("H", "H", "D"),  # A beats B, B beats C, C draws A
    fthg = c(2L, 1L, 1L),
    ftag = c(1L, 0L, 1L)
  )

  result <- league_table(matches, as.Date("2023-02-01"))

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 3L)
  expect_true(all(c("position", "team", "played", "won", "drawn", "lost",
                    "gf", "ga", "gd", "points") %in% colnames(result)))

  # Check points: A=4 (W+D), B=3 (W), C=1 (D)
  a_row <- result[result$team == "A", ]
  expect_equal(a_row$points, 4L)
  expect_equal(a_row$won, 1L)
  expect_equal(a_row$drawn, 1L)

  # A should be top (4 points)
  expect_equal(result$team[1], "A")
})

test_that("league_table respects as_of_date", {
  matches <- tibble::tibble(
    match_date = as.Date(c("2023-01-01", "2023-01-08", "2023-01-15")),
    home_team = c("A", "B", "A"),
    away_team = c("B", "C", "C"),
    ftr = c("H", "H", "H"),
    fthg = c(2L, 1L, 3L),
    ftag = c(1L, 0L, 0L)
  )

  # As of Jan 10, only first 2 matches
  result <- league_table(matches, as.Date("2023-01-10"))

  # A: 1W (3pts), B: 1W 1L (3pts), C: 0W 1L (0pts)
  expect_equal(nrow(result), 3L)
  c_row <- result[result$team == "C", ]
  expect_equal(c_row$played, 1L)
  expect_equal(c_row$points, 0L)
})

test_that("league_table handles goal difference tiebreak", {
  matches <- tibble::tibble(
    match_date = as.Date(c("2023-01-01", "2023-01-08")),
    home_team = c("A", "B"),
    away_team = c("C", "D"),
    ftr = c("H", "H"),  # Both win
    fthg = c(3L, 1L),   # A wins 3-0, B wins 1-0
    ftag = c(0L, 0L)
  )

  result <- league_table(matches, as.Date("2023-02-01"))

  # A and B both have 3 points, but A has better GD (+3 vs +1)
  expect_equal(result$team[1], "A")
  expect_equal(result$team[2], "B")
})

test_that("league_table returns empty for no matches", {
  matches <- tibble::tibble(
    match_date = as.Date("2023-01-01"),
    home_team = "A",
    away_team = "B",
    ftr = "H",
    fthg = 2L,
    ftag = 1L
  )

  # No matches before this date
  result <- league_table(matches, as.Date("2022-01-01"))

  expect_equal(nrow(result), 0L)
})

test_that("league_table filters by league_code", {
  matches <- tibble::tibble(
    match_date = as.Date(c("2023-01-01", "2023-01-01")),
    home_team = c("A", "X"),
    away_team = c("B", "Y"),
    ftr = c("H", "H"),
    fthg = c(2L, 1L),
    ftag = c(1L, 0L),
    league_code = c("E0", "E1")
  )

  result <- league_table(matches, as.Date("2023-02-01"), league_code = "E0")

  # Only A and B from E0
  expect_equal(nrow(result), 2L)
  expect_true(all(result$team %in% c("A", "B")))
})

test_that("league_table validates required arguments", {
  matches <- tibble::tibble(
    match_date = as.Date("2023-01-01"),
    home_team = "A",
    away_team = "B",
    ftr = "H",
    fthg = 2L,
    ftag = 1L
  )

  expect_error(league_table(matches))
  expect_error(league_table())
})

# ---- team_position ----

test_that("team_position returns correct position", {
  matches <- tibble::tibble(
    match_date = as.Date(c("2023-01-01", "2023-01-08")),
    home_team = c("A", "B"),
    away_team = c("B", "C"),
    ftr = c("H", "H"),  # A beats B (3pts), B beats C (3pts)
    fthg = c(3L, 1L),   # A has better GD
    ftag = c(0L, 0L)
  )

  # A should be 1st (better GD), B should be 2nd
  expect_equal(team_position(matches, "A", as.Date("2023-02-01")), 1L)
  expect_equal(team_position(matches, "B", as.Date("2023-02-01")), 2L)
  expect_equal(team_position(matches, "C", as.Date("2023-02-01")), 3L)
})

test_that("team_position returns NA for unknown team", {
  matches <- tibble::tibble(
    match_date = as.Date("2023-01-01"),
    home_team = "A",
    away_team = "B",
    ftr = "H",
    fthg = 2L,
    ftag = 1L
  )

  result <- team_position(matches, "Z", as.Date("2023-02-01"))

  expect_true(is.na(result))
})

test_that("team_position returns NA for no matches", {
  matches <- tibble::tibble(
    match_date = as.Date("2023-01-01"),
    home_team = "A",
    away_team = "B",
    ftr = "H",
    fthg = 2L,
    ftag = 1L
  )

  result <- team_position(matches, "A", as.Date("2022-01-01"))

  expect_true(is.na(result))
})

test_that("team_position validates required arguments", {
  matches <- tibble::tibble(
    match_date = as.Date("2023-01-01"),
    home_team = "A",
    away_team = "B",
    ftr = "H",
    fthg = 2L,
    ftag = 1L
  )

  expect_error(team_position(matches, "A"))
  expect_error(team_position(matches))
  expect_error(team_position())
})

# ---- add_league_positions ----

test_that("add_league_positions adds position columns", {
  matches <- tibble::tibble(
    match_date = as.Date(c("2023-01-01", "2023-01-08", "2023-01-15")),
    home_team = c("A", "B", "A"),
    away_team = c("B", "C", "C"),
    ftr = c("H", "H", "H"),
    fthg = c(2L, 1L, 3L),
    ftag = c(1L, 0L, 0L)
  )

  result <- add_league_positions(matches)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 3L)
  expect_true("home_position" %in% colnames(result))
  expect_true("away_position" %in% colnames(result))
  expect_true("position_diff" %in% colnames(result))
})

test_that("add_league_positions uses only past data", {
  matches <- tibble::tibble(
    match_date = as.Date(c("2023-01-01", "2023-01-08")),
    home_team = c("A", "B"),
    away_team = c("B", "A"),
    ftr = c("H", "H"),  # A beats B, then B beats A
    fthg = c(2L, 2L),
    ftag = c(1L, 1L)
  )

  result <- add_league_positions(matches)

  # First match: no history
  expect_true(is.na(result$home_position[1]))
  expect_true(is.na(result$away_position[1]))

  # Second match: A is 1st (3pts), B is 2nd (0pts)
  expect_equal(result$home_position[2], 2L)  # B is home
  expect_equal(result$away_position[2], 1L)  # A is away
})

test_that("add_league_positions computes position_diff correctly", {
  matches <- tibble::tibble(
    match_date = as.Date(c("2023-01-01", "2023-01-08", "2023-01-15")),
    home_team = c("A", "B", "A"),
    away_team = c("C", "C", "B"),
    ftr = c("H", "H", "H"),  # A and B both win
    fthg = c(2L, 1L, 1L),
    ftag = c(0L, 0L, 0L)
  )

  result <- add_league_positions(matches)

  # Match 3: A is 1st (6pts, GD+3), B is 2nd (3pts)
  # position_diff = away_pos - home_pos = 2 - 1 = 1
  expect_equal(result$position_diff[3], 1L)  # Positive = home is higher
})

test_that("add_league_positions handles empty input", {
  matches <- tibble::tibble(
    match_date = as.Date(character()),
    home_team = character(),
    away_team = character(),
    ftr = character(),
    fthg = integer(),
    ftag = integer()
  )

  result <- add_league_positions(matches)

  expect_equal(nrow(result), 0L)
  expect_true("home_position" %in% colnames(result))
})

test_that("add_league_positions validates required argument", {
  expect_error(add_league_positions())
})
