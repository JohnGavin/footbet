# Tests for H2H feature functions

# ---- h2h_record ----

test_that("h2h_record computes record between two teams", {
  matches <- tibble::tibble(
    match_date = as.Date(c("2023-01-01", "2023-02-01", "2023-03-01",
                           "2023-04-01", "2023-05-01")),
    home_team = c("A", "B", "A", "B", "A"),
    away_team = c("B", "A", "B", "A", "B"),
    ftr = c("H", "H", "D", "A", "A"),
    fthg = c(2L, 1L, 1L, 0L, 1L),
    ftag = c(1L, 0L, 1L, 2L, 2L)
  )

  # A vs B, as of 2023-06-01 (includes all 5 matches)
  result <- h2h_record(matches, "A", "B", as.Date("2023-06-01"))
  
  expect_s3_class(result, "tbl_df")
  expect_equal(result$n_matches, 5L)
  expect_equal(result$home_team, "A")
  expect_equal(result$away_team, "B")
  
  # A wins: match 1 (H), match 2 (A from B's home), = 2
  # But from A's perspective when A is playing at home in this fixture:
  # Match 1: A home won (H), Match 3: A home draw (D), Match 5: A home lost (A)
  # Match 2: B home won (A from B perspective = A lost away)
  # Match 4: B home lost (A from B perspective = A won away)
  expect_equal(result$home_wins, 2L)  # A's perspective
  expect_equal(result$draws, 1L)
  expect_equal(result$away_wins, 2L)
})

test_that("h2h_record respects as_of_date", {
  matches <- tibble::tibble(
    match_date = as.Date(c("2023-01-01", "2023-02-01", "2023-03-01",
                           "2023-04-01", "2023-05-01")),
    home_team = c("A", "B", "A", "B", "A"),
    away_team = c("B", "A", "B", "A", "B"),
    ftr = c("H", "H", "D", "A", "A"),
    fthg = c(2L, 1L, 1L, 0L, 1L),
    ftag = c(1L, 0L, 1L, 2L, 2L)
  )

  # Only include matches before March 15
  result <- h2h_record(matches, "A", "B", as.Date("2023-03-15"))
  
  expect_equal(result$n_matches, 3L)  # First 3 matches only
})

test_that("h2h_record limits to n past meetings", {
  matches <- tibble::tibble(
    match_date = as.Date("2023-01-01") + 0:19,
    home_team = rep(c("A", "B"), 10),
    away_team = rep(c("B", "A"), 10),
    ftr = rep("H", 20),
    fthg = rep(2L, 20),
    ftag = rep(1L, 20)
  )

  result <- h2h_record(matches, "A", "B", as.Date("2023-02-01"), n = 5L)
  
  expect_equal(result$n_matches, 5L)
})

test_that("h2h_record returns NA stats when no history", {
  matches <- tibble::tibble(
    match_date = as.Date(c("2023-01-01", "2023-02-01")),
    home_team = c("A", "C"),
    away_team = c("B", "D"),
    ftr = c("H", "A"),
    fthg = c(2L, 0L),
    ftag = c(1L, 1L)
  )

  # A vs C have never played
  result <- h2h_record(matches, "A", "C", as.Date("2023-06-01"))
  
  expect_equal(result$n_matches, 0L)
  expect_true(is.na(result$home_wins))
  expect_true(is.na(result$draws))
  expect_true(is.na(result$home_win_pct))
})

test_that("h2h_record validates required arguments", {
  matches <- tibble::tibble(
    match_date = as.Date("2023-01-01"),
    home_team = "A",
    away_team = "B",
    ftr = "H",
    fthg = 2L,
    ftag = 1L
  )

  expect_error(h2h_record(matches))
  expect_error(h2h_record(matches, "A"))
  expect_error(h2h_record())
})

test_that("h2h_record handles single match history", {
  matches <- tibble::tibble(
    match_date = as.Date("2023-01-01"),
    home_team = "A",
    away_team = "B",
    ftr = "H",
    fthg = 2L,
    ftag = 1L
  )

  result <- h2h_record(matches, "A", "B", as.Date("2023-06-01"))
  
  expect_equal(result$n_matches, 1L)
  expect_equal(result$home_wins, 1L)
  expect_equal(result$draws, 0L)
  expect_equal(result$away_wins, 0L)
  expect_equal(result$home_win_pct, 1.0)
})

# ---- add_h2h_features ----

test_that("add_h2h_features adds H2H columns to matches", {
  matches <- tibble::tibble(
    match_date = as.Date(c("2023-01-01", "2023-02-01", "2023-03-01",
                           "2023-04-01", "2023-05-01")),
    home_team = c("A", "B", "A", "B", "A"),
    away_team = c("B", "A", "B", "A", "B"),
    ftr = c("H", "H", "D", "A", "A"),
    fthg = c(2L, 1L, 1L, 0L, 1L),
    ftag = c(1L, 0L, 1L, 2L, 2L)
  )

  result <- add_h2h_features(matches, n = 10L)
  
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), nrow(matches))
  
  # Check H2H columns were added
  expect_true("h2h_n_matches" %in% colnames(result))
  expect_true("h2h_home_wins" %in% colnames(result))
  expect_true("h2h_draws" %in% colnames(result))
  expect_true("h2h_away_wins" %in% colnames(result))
  expect_true("h2h_home_win_pct" %in% colnames(result))
  
  # First match should have 0 history
  expect_equal(result$h2h_n_matches[1], 0L)
})

test_that("add_h2h_features uses only past data for each match", {
  matches <- tibble::tibble(
    match_date = as.Date(c("2023-01-01", "2023-02-01", "2023-03-01")),
    home_team = c("A", "A", "A"),
    away_team = c("B", "B", "B"),
    ftr = c("H", "H", "H"),
    fthg = c(2L, 2L, 2L),
    ftag = c(1L, 1L, 1L)
  )

  result <- add_h2h_features(matches, n = 10L)
  
  # First match: no history
  expect_equal(result$h2h_n_matches[1], 0L)
  
  # Second match: 1 prior meeting
  expect_equal(result$h2h_n_matches[2], 1L)
  expect_equal(result$h2h_home_wins[2], 1L)
  
  # Third match: 2 prior meetings
  expect_equal(result$h2h_n_matches[3], 2L)
  expect_equal(result$h2h_home_wins[3], 2L)
})

test_that("add_h2h_features handles empty input", {
  matches <- tibble::tibble(
    match_date = as.Date(character()),
    home_team = character(),
    away_team = character(),
    ftr = character(),
    fthg = integer(),
    ftag = integer()
  )

  result <- add_h2h_features(matches)
  
  expect_equal(nrow(result), 0L)
  expect_true("h2h_n_matches" %in% colnames(result))
})

test_that("add_h2h_features validates required argument", {
  expect_error(add_h2h_features())
})

test_that("add_h2h_features handles different team pairs", {
  matches <- tibble::tibble(
    match_date = as.Date(c("2023-01-01", "2023-02-01", "2023-03-01",
                           "2023-04-01")),
    home_team = c("A", "C", "A", "C"),
    away_team = c("B", "D", "B", "D"),
    ftr = c("H", "A", "D", "H"),
    fthg = c(2L, 0L, 1L, 2L),
    ftag = c(1L, 1L, 1L, 1L)
  )

  result <- add_h2h_features(matches, n = 10L)
  
  # A vs B history should not affect C vs D
  expect_equal(result$h2h_n_matches[1], 0L)  # A-B first meeting
  expect_equal(result$h2h_n_matches[2], 0L)  # C-D first meeting
  expect_equal(result$h2h_n_matches[3], 1L)  # A-B second meeting
  expect_equal(result$h2h_n_matches[4], 1L)  # C-D second meeting
})
