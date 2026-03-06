# Adversarial QA: R/data_download.R, R/data_parse.R, R/features.R
# Attack vectors: NULL, NA, missing files, empty data

# ---- download_fd_csv ----

test_that("download_fd_csv: NULL league_code", {
  expect_error(download_fd_csv(NULL, "2324"))
})

test_that("download_fd_csv: NULL season", {
  expect_error(download_fd_csv("E0", NULL))
})

# ---- parse_fd_csv ----

test_that("parse_fd_csv: NULL file_path", {
  expect_error(parse_fd_csv(NULL, "E0", "2324"))
})

test_that("parse_fd_csv: empty CSV returns empty tibble", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines("Date,HomeTeam,AwayTeam,FTHG,FTAG,FTR", tmp)
  # Expect warning about empty CSV
 expect_warning(
    result <- parse_fd_csv(tmp, "E0", "2324"),
    "Empty CSV"
  )
  expect_equal(nrow(result), 0L)
})

test_that("parse_fd_csv: CSV with only header", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines("Date,HomeTeam,AwayTeam,FTHG,FTAG,FTR", tmp)
  # Expect warning about empty CSV
  expect_warning(
    result <- parse_fd_csv(tmp, "E0", "2324"),
    "Empty CSV"
  )
  expect_s3_class(result, "tbl_df")
})

test_that("parse_fd_csv: CSV with missing columns gracefully fills NA", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines(c(
    "Date,HomeTeam,AwayTeam,FTHG,FTAG,FTR",
    "15/01/2024,Arsenal,Liverpool,2,0,H"
  ), tmp)
  result <- parse_fd_csv(tmp, "E0", "2324")
  expect_equal(nrow(result), 1L)
  # Missing stats columns should be NA
  expect_true(is.na(result$hs[1]))
  expect_true(is.na(result$hc[1]))
})

test_that("parse_fd_csv: malformed date", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines(c(
    "Date,HomeTeam,AwayTeam,FTHG,FTAG,FTR",
    "not-a-date,Arsenal,Liverpool,2,0,H"
  ), tmp)
  # Expect lubridate warning about failed date parsing
  suppressWarnings(
    result <- parse_fd_csv(tmp, "E0", "2324")
  )
  expect_true(is.na(result$match_date[1]))
})

# ---- parse_fd_odds ----

test_that("parse_fd_odds: NULL file_path", {
  expect_error(parse_fd_odds(NULL, "E0", "2324"))
})

test_that("parse_fd_odds: CSV without Pinnacle columns returns NA", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines(c(
    "Date,HomeTeam,AwayTeam",
    "15/01/2024,Arsenal,Liverpool"
  ), tmp)
  result <- parse_fd_odds(tmp, "E0", "2324")
  expect_equal(nrow(result), 1L)
  expect_true(is.na(result$psh[1]))
  expect_true(is.na(result$psd[1]))
})

# ---- rolling_goals ----

test_that("rolling_goals: NULL input", {
  expect_error(rolling_goals(NULL))
})

test_that("rolling_goals: empty dataframe", {
  empty <- tibble::tibble(
    home_team = character(),
    away_team = character(),
    match_date = as.Date(character()),
    fthg = integer(),
    ftag = integer()
  )
  result <- rolling_goals(empty)
  expect_equal(nrow(result), 0L)
})

test_that("rolling_goals: single match", {
  single <- tibble::tibble(
    home_team = "A",
    away_team = "B",
    match_date = as.Date("2024-01-01"),
    fthg = 2L,
    ftag = 1L
  )
  result <- rolling_goals(single, window = 5L)
  expect_equal(nrow(result), 2L)  # One row per team
})

test_that("rolling_goals: window larger than match history", {
  matches <- tibble::tibble(
    home_team = c("A", "B"),
    away_team = c("B", "A"),
    match_date = as.Date(c("2024-01-01", "2024-01-08")),
    fthg = c(2L, 1L),
    ftag = c(1L, 0L)
  )
  result <- rolling_goals(matches, window = 100L)
  expect_true(all(!is.na(result$rolling_gf) | is.na(result$rolling_gf)))
})

# ---- matches_to_long ----

test_that("matches_to_long: doubles row count", {
  matches <- tibble::tibble(
    match_id = "test_1",
    match_date = as.Date("2024-01-01"),
    season = "2324",
    league_code = "E0",
    home_team = "A",
    away_team = "B",
    fthg = 2L,
    ftag = 1L
  )
  long <- matches_to_long(matches)
  expect_equal(nrow(long), 2L)
  expect_true("home" %in% names(long))
})

test_that("matches_to_long: empty input", {
  empty <- tibble::tibble(
    match_id = character(), match_date = as.Date(character()),
    season = character(), league_code = character(),
    home_team = character(), away_team = character(),
    fthg = integer(), ftag = integer()
  )
  result <- matches_to_long(empty)
  expect_equal(nrow(result), 0L)
})
