# Tests for parse_fd_csv, parse_fd_odds, and helper functions

test_that("parse_fd_csv rejects missing file", {
  expect_error(parse_fd_csv("/nonexistent.csv", "E0", "2324"), "not found")
})

test_that("parse_fd_odds rejects missing file", {
  expect_error(parse_fd_odds("/nonexistent.csv", "E0", "2324"), "not found")
})

test_that("extract_int_col handles missing columns", {
  df <- data.frame(a = 1:3)
  result <- footbet:::extract_int_col(df, "b", nrow(df))
  expect_length(result, 3)
  expect_true(all(is.na(result)))
  expect_type(result, "integer")
})

test_that("extract_num_col handles missing columns", {
  df <- data.frame(a = 1:3)
  result <- footbet:::extract_num_col(df, "b", nrow(df))
  expect_length(result, 3)
  expect_true(all(is.na(result)))
  expect_type(result, "double")
})

test_that("extract_char_col handles missing columns", {
  df <- data.frame(a = 1:3)
  result <- footbet:::extract_char_col(df, "b", nrow(df))
  expect_length(result, 3)
  expect_true(all(is.na(result)))
  expect_type(result, "character")
})

# ---- Integration tests with mock CSV ----

mock_fd_csv <- function(envir = parent.frame()) {
  tmp_dir <- withr::local_tempdir(.local_envir = envir)
  csv_path <- file.path(tmp_dir, "E0_2324.csv")
  writeLines(c(
    "Div,Date,Time,HomeTeam,AwayTeam,FTHG,FTAG,FTR,HTHG,HTAG,HTR,HS,AS,HST,AST,HC,AC,HF,AF,HY,AY,HR,AR,PSH,PSD,PSA,PAHH,PAHA,AHh,P>2.5,P<2.5,MaxH,MaxD,MaxA,AvgH,AvgD,AvgA",
    "E0,11/08/2023,20:00,Burnley,Man City,0,3,A,0,2,A,5,13,2,7,2,7,11,8,3,1,0,0,12.50,7.50,1.24,2.07,1.85,-1.50,1.63,2.37,13.00,8.50,1.25,11.00,6.80,1.22",
    "E0,12/08/2023,12:30,Arsenal,Nott'm Forest,2,1,H,1,0,H,18,7,7,3,5,3,9,12,1,2,0,0,1.25,6.50,12.00,1.90,2.02,1.50,1.72,2.18,1.28,7.00,13.00,1.23,6.20,11.50",
    "E0,12/08/2023,15:00,Bournemouth,West Ham,1,1,D,1,0,H,9,11,3,3,3,5,13,12,2,3,0,0,2.90,3.50,2.45,1.95,1.97,-0.25,2.10,1.80,3.00,3.60,2.55,2.75,3.40,2.40"
  ), csv_path)
  csv_path
}

test_that("parse_fd_csv produces correct structure", {
  csv_path <- mock_fd_csv()
  result <- parse_fd_csv(csv_path, "E0", "2324")

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 3L)

  # Required columns present
  expected_cols <- c("league_code", "season", "match_date", "home_team",
                     "away_team", "fthg", "ftag", "ftr", "match_id")
  expect_true(all(expected_cols %in% colnames(result)))

  # Values correct
  expect_equal(result$league_code, rep("E0", 3))
  expect_equal(result$season, rep("2324", 3))
  expect_equal(result$fthg, c(0L, 2L, 1L))
  expect_equal(result$ftag, c(3L, 1L, 1L))
  expect_equal(result$ftr, c("A", "H", "D"))
})

test_that("parse_fd_csv handles dates correctly", {
  csv_path <- mock_fd_csv()
  result <- parse_fd_csv(csv_path, "E0", "2324")

  expect_s3_class(result$match_date, "Date")
  expect_equal(result$match_date[1], as.Date("2023-08-11"))
  expect_equal(result$match_date[2], as.Date("2023-08-12"))
})

test_that("parse_fd_csv handles match stats", {
  csv_path <- mock_fd_csv()
  result <- parse_fd_csv(csv_path, "E0", "2324")

  # First match: Burnley 5 shots, Man City 13 shots
  expect_equal(result$hs[1], 5L)
  expect_equal(result$as_[1], 13L)
})

test_that("parse_fd_csv returns empty tibble for empty CSV", {
  tmp <- withr::local_tempdir()
  csv_path <- file.path(tmp, "empty.csv")
  writeLines(c(
    "Div,Date,HomeTeam,AwayTeam,FTHG,FTAG,FTR"
  ), csv_path)

  result <- suppressWarnings(parse_fd_csv(csv_path, "E0", "2324"))
  expect_equal(nrow(result), 0L)
})

test_that("make_match_id is deterministic", {
  id1 <- make_match_id("E0", "2023-08-11", "Burnley", "Man City")
  id2 <- make_match_id("E0", "2023-08-11", "Burnley", "Man City")
  expect_equal(id1, id2)
})

test_that("make_match_id is unique for different matches", {
  id1 <- make_match_id("E0", "2023-08-11", "Burnley", "Man City")
  id2 <- make_match_id("E0", "2023-08-12", "Arsenal", "Forest")
  expect_false(id1 == id2)
})

# ---- Odds parsing ----

test_that("parse_fd_odds extracts Pinnacle odds", {
  csv_path <- mock_fd_csv()
  result <- parse_fd_odds(csv_path, "E0", "2324")

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 3L)

  # Pinnacle 1X2 odds for first match (Burnley vs Man City)
  expect_equal(result$psh[1], 12.50)
  expect_equal(result$psd[1], 7.50)
  expect_equal(result$psa[1], 1.24)

  # Asian handicap
  expect_equal(result$ah_line[1], -1.50)

  # Over/under
  expect_equal(result$p_over25[1], 1.63)
  expect_equal(result$p_under25[1], 2.37)
})

test_that("parse_fd_odds extracts market aggregates", {
  csv_path <- mock_fd_csv()
  result <- parse_fd_odds(csv_path, "E0", "2324")

  expect_equal(result$max_h[1], 13.00)
  expect_equal(result$avg_a[2], 11.50)
})

test_that("parse_fd_odds match_ids align with parse_fd_csv", {
  csv_path <- mock_fd_csv()
  matches <- parse_fd_csv(csv_path, "E0", "2324")
  odds <- parse_fd_odds(csv_path, "E0", "2324")

  expect_equal(matches$match_id, odds$match_id)
})
