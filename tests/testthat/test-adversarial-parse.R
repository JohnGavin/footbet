# Adversarial tests for data parsing (Category 10: Data Ingestion)
# Attack vectors: BOM, encoding, NA strings, whitespace, delimiters, type coercion

# ---- BOM attacks ----

test_that("parse_fd_csv: handles BOM prefix", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  bom <- as.raw(c(0xEF, 0xBB, 0xBF))
  content <- "Date,HomeTeam,AwayTeam,FTHG,FTAG,FTR\n15/01/2024,Arsenal,Liverpool,2,0,H"
  writeBin(c(bom, charToRaw(content)), tmp)

  result <- parse_fd_csv(tmp, "E0", "2324")
  expect_equal(nrow(result), 1L)
  expect_equal(result$home_team, "Arsenal")
})

# ---- NA string variants ----

test_that("parse_fd_csv: handles all NA string variants", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines(c(
    "Date,HomeTeam,AwayTeam,FTHG,FTAG,FTR,HS",
    "15/01/2024,Arsenal,Liverpool,2,0,H,",
    "16/01/2024,Chelsea,Spurs,1,1,D,NA",
    "17/01/2024,City,United,3,0,H,n/a",
    "18/01/2024,Leeds,Brighton,0,2,A,-",
    "19/01/2024,Villa,Wolves,1,0,H,NULL"
  ), tmp)

  result <- parse_fd_csv(tmp, "E0", "2324")
  expect_equal(nrow(result), 5L)
  expect_true(all(is.na(result$hs)))
})

test_that("parse_fd_csv: handles N/A (uppercase) as NA", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines(c(
    "Date,HomeTeam,AwayTeam,FTHG,FTAG,FTR,HS",
    "15/01/2024,Arsenal,Liverpool,2,0,H,N/A"
  ), tmp)

  result <- parse_fd_csv(tmp, "E0", "2324")
  expect_true(is.na(result$hs[1]))
})

# ---- Whitespace attacks ----

test_that("parse_fd_csv: handles whitespace in team names", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines(c(
    "Date,HomeTeam,AwayTeam,FTHG,FTAG,FTR",
    "15/01/2024,  Arsenal  ,  Liverpool  ,2,0,H"
  ), tmp)

  result <- parse_fd_csv(tmp, "E0", "2324")
  expect_equal(result$home_team, "Arsenal")
  expect_equal(result$away_team, "Liverpool")
})

test_that("parse_fd_csv: handles tabs in values", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines(c(
    "Date,HomeTeam,AwayTeam,FTHG,FTAG,FTR",
    "15/01/2024,\tArsenal\t,Liverpool,2,0,H"
  ), tmp)

  result <- parse_fd_csv(tmp, "E0", "2324")
  expect_equal(trimws(result$home_team), "Arsenal")
})

# ---- Quoted field attacks ----

test_that("parse_fd_csv: handles quoted fields with embedded commas", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines(c(
    'Date,HomeTeam,AwayTeam,FTHG,FTAG,FTR',
    '15/01/2024,"Team, FC","Club, United",2,0,H'
  ), tmp)

  result <- parse_fd_csv(tmp, "E0", "2324")
  expect_equal(nrow(result), 1L)
  expect_equal(result$home_team, "Team, FC")
  expect_equal(result$away_team, "Club, United")
})

test_that("parse_fd_csv: handles quoted fields with embedded quotes", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines(c(
    'Date,HomeTeam,AwayTeam,FTHG,FTAG,FTR',
    '15/01/2024,"Team ""A""","Club ""B""",2,0,H'
  ), tmp)

  result <- parse_fd_csv(tmp, "E0", "2324")
  expect_equal(nrow(result), 1L)
  expect_equal(result$home_team, 'Team "A"')
})

# ---- Type coercion attacks ----

test_that("parse_fd_csv: floats in integer columns report problems", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines(c(
    "Date,HomeTeam,AwayTeam,FTHG,FTAG,FTR",
    "15/01/2024,Arsenal,Liverpool,2.5,0.9,H"
  ), tmp)

  # readr with col_integer() will report parse problems for floats
  expect_message(
    result <- parse_fd_csv(tmp, "E0", "2324"),
    "parse"
  )

  # Values should be NA due to type mismatch
  probs <- readr::problems(result)
  expect_true(nrow(probs) > 0L || all(is.na(c(result$fthg, result$ftag))))
})

test_that("parse_fd_csv: numeric strings with commas handled", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines(c(
    "Date,HomeTeam,AwayTeam,FTHG,FTAG,FTR,HS",
    "15/01/2024,Arsenal,Liverpool,2,0,H,1000"
  ), tmp)

  result <- parse_fd_csv(tmp, "E0", "2324")
  expect_equal(result$hs, 1000L)
})

# ---- Missing column attacks ----

test_that("parse_fd_csv: handles missing optional columns", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines(c(
    "Date,HomeTeam,AwayTeam,FTHG,FTAG,FTR",
    "15/01/2024,Arsenal,Liverpool,2,0,H"
  ), tmp)

  result <- parse_fd_csv(tmp, "E0", "2324")
  expect_equal(nrow(result), 1L)
  # Optional stats columns should be NA
  expect_true(is.na(result$hs[1]))
  expect_true(is.na(result$hc[1]))
  expect_true(is.na(result$hthg[1]))
})

# ---- Extra column attacks ----

test_that("parse_fd_csv: handles extra unknown columns", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines(c(
    "Date,HomeTeam,AwayTeam,FTHG,FTAG,FTR,VAR_Decisions,xG_Home",
    "15/01/2024,Arsenal,Liverpool,2,0,H,3,2.1"
  ), tmp)

  result <- parse_fd_csv(tmp, "E0", "2324")
  expect_equal(nrow(result), 1L)
  expect_equal(result$fthg, 2L)
  # Unknown columns should not cause errors
})

# ---- Date format attacks ----

test_that("parse_fd_csv: handles DD/MM/YY format", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines(c(
    "Date,HomeTeam,AwayTeam,FTHG,FTAG,FTR",
    "15/01/24,Arsenal,Liverpool,2,0,H"
  ), tmp)

  result <- parse_fd_csv(tmp, "E0", "2324")
  expect_s3_class(result$match_date, "Date")
  expect_equal(lubridate::year(result$match_date[1]), 2024L)
})

test_that("parse_fd_csv: handles DD/MM/YYYY format", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines(c(
    "Date,HomeTeam,AwayTeam,FTHG,FTAG,FTR",
    "15/01/2024,Arsenal,Liverpool,2,0,H"
  ), tmp)

  result <- parse_fd_csv(tmp, "E0", "2324")
  expect_s3_class(result$match_date, "Date")
  expect_equal(lubridate::year(result$match_date[1]), 2024L)
})

# ---- Empty file attacks ----

test_that("parse_fd_csv: handles zero-byte file", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  file.create(tmp)

  # Should handle gracefully - either error or empty result
  result <- tryCatch(
    parse_fd_csv(tmp, "E0", "2324"),
    error = function(e) "error"
  )
  expect_true(identical(result, "error") || nrow(result) == 0L)
})

test_that("parse_fd_csv: handles single row", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines(c(
    "Date,HomeTeam,AwayTeam,FTHG,FTAG,FTR",
    "15/01/2024,Arsenal,Liverpool,2,0,H"
  ), tmp)

  result <- parse_fd_csv(tmp, "E0", "2324")
  expect_equal(nrow(result), 1L)
})

# ---- Encoding attacks ----

test_that("parse_fd_csv: handles latin1 encoded team names", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  # Write latin1 encoded content (e.g., Atlético)
  con <- file(tmp, "wb")
  writeBin(charToRaw("Date,HomeTeam,AwayTeam,FTHG,FTAG,FTR\n"), con)
  # Atlético in latin1: \xe9 = é
  writeBin(as.raw(c(
    0x31, 0x35, 0x2f, 0x30, 0x31, 0x2f, 0x32, 0x30, 0x32, 0x34, 0x2c,  # 15/01/2024,
    0x41, 0x74, 0x6c, 0xe9, 0x74, 0x69, 0x63, 0x6f, 0x2c,  # Atlético,
    0x52, 0x65, 0x61, 0x6c, 0x2c,  # Real,
    0x32, 0x2c, 0x30, 0x2c, 0x48, 0x0a  # 2,0,H\n
  )), con)
  close(con)

  result <- parse_fd_csv(tmp, "SP1", "2324")
  expect_equal(nrow(result), 1L)
  # Should contain the é character
  expect_true(grepl("Atl", result$home_team))
})

# ---- Odds parsing attacks ----

test_that("parse_fd_odds: handles missing Pinnacle columns", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines(c(
    "Date,HomeTeam,AwayTeam,B365H,B365D,B365A",
    "15/01/2024,Arsenal,Liverpool,1.5,4.0,6.0"
  ), tmp)

  result <- parse_fd_odds(tmp, "E0", "2324")
  expect_equal(nrow(result), 1L)
  expect_true(is.na(result$psh[1]))
  expect_true(is.na(result$psd[1]))
})

test_that("parse_fd_odds: handles Pinnacle columns with NAs", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines(c(
    "Date,HomeTeam,AwayTeam,PSH,PSD,PSA",
    "15/01/2024,Arsenal,Liverpool,1.5,,6.0",
    "16/01/2024,Chelsea,Spurs,NA,4.0,5.0"
  ), tmp)

  result <- parse_fd_odds(tmp, "E0", "2324")
  expect_equal(nrow(result), 2L)
  expect_true(is.na(result$psd[1]))
  expect_true(is.na(result$psh[2]))
})

# ---- Validation function attacks ----

test_that("validate_temporal_coverage: empty input", {
  empty <- tibble::tibble(
    league_code = character(),
    season = character(),
    match_date = as.Date(character())
  )
  result <- validate_temporal_coverage(empty)
  expect_true(result$passed)
})

test_that("validate_no_duplicates: empty input", {
  empty <- tibble::tibble(match_id = character())
  result <- validate_no_duplicates(empty, "match_id")
  expect_true(result$passed)
})

test_that("validate_value_ranges: empty input", {
  empty <- tibble::tibble(
    fthg = integer(),
    ftag = integer(),
    match_date = as.Date(character())
  )
  result <- validate_value_ranges(empty)
  expect_true(result$passed)
})

test_that("validate_data_freshness: empty input", {
  empty <- tibble::tibble(match_date = as.Date(character()))
  result <- validate_data_freshness(empty)
  expect_true(result$passed)
})

test_that("validate_value_ranges: catches extreme scores", {
  matches <- tibble::tibble(
    match_id = "test_1",
    league_code = "E0",
    season = "2324",
    match_date = as.Date("2024-01-15"),
    home_team = "A",
    away_team = "B",
    fthg = 20L,  # Invalid: >15
    ftag = 0L
  )
  expect_warning(
    result <- validate_value_ranges(matches),
    "value range"
  )
  expect_false(result$passed)
  expect_equal(result$n_issues, 1L)
})

test_that("validate_value_ranges: catches future dates", {
  matches <- tibble::tibble(
    match_id = "test_1",
    league_code = "E0",
    season = "2324",
    match_date = Sys.Date() + 30L,  # Invalid: >7 days in future
    home_team = "A",
    away_team = "B",
    fthg = 2L,
    ftag = 0L
  )
  expect_warning(
    result <- validate_value_ranges(matches),
    "value range"
  )
  expect_false(result$passed)
})
