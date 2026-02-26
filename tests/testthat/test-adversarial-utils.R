# Adversarial QA: R/utils.R exported functions
# Attack vectors: NULL, NA, wrong types, empty strings, special chars, boundary values

# ---- fd_url ----

test_that("fd_url: NULL inputs", {
  expect_error(fd_url(NULL, "2324"))
  expect_error(fd_url("E0", NULL))
})

test_that("fd_url: NA inputs", {
  expect_error(fd_url(NA, "2324"))
  expect_error(fd_url("E0", NA))
})

test_that("fd_url: empty string inputs", {
  # Empty league code is valid (URL just has empty segment)
  url <- fd_url("", "2324")
  expect_type(url, "character")
  # Empty season should fail validation
  expect_error(fd_url("E0", ""))
})

test_that("fd_url: numeric instead of character", {
  # Season as numeric should fail (not 4-digit string)
  expect_error(fd_url("E0", 2324))
})

test_that("fd_url: special characters in league code", {
  # Injection attempt
  url <- fd_url("E0/../../../etc", "2324")
  expect_type(url, "character")
})

test_that("fd_url: boundary season codes", {
  expect_type(fd_url("E0", "0001"), "character")
  expect_type(fd_url("E0", "9899"), "character")
  expect_error(fd_url("E0", "123"))   # Too short
  expect_error(fd_url("E0", "12345")) # Too long
})

# ---- target_leagues ----

test_that("target_leagues: returns expected structure", {
  leagues <- target_leagues()
  expect_s3_class(leagues, "tbl_df")
  expect_true(all(c("country", "league_code", "division") %in% names(leagues)))
  # All divisions are 1 or 2
  expect_true(all(leagues$division %in% 1:2))
  # No duplicates
  expect_equal(nrow(leagues), length(unique(leagues$league_code)))
})

# ---- target_seasons ----

test_that("target_seasons: reversed range", {
  # start > end should return empty
  seasons <- target_seasons(2025L, 2020L)
  expect_length(seasons, 0L)
})

test_that("target_seasons: single season", {
  seasons <- target_seasons(2020L, 2020L)
  expect_length(seasons, 1L)
  expect_equal(seasons, "2021")
})

test_that("target_seasons: century boundary", {
  seasons <- target_seasons(1999L, 2001L)
  expect_equal(seasons, c("9900", "0001", "0102"))
})

test_that("target_seasons: negative year", {
  # Should not crash, just produce weird codes
  expect_no_error(target_seasons(-1L, 0L))
})

# ---- make_match_id ----

test_that("make_match_id: NA values produce NA-containing IDs", {
  id <- make_match_id(NA, "2024-01-01", "Team A", "Team B")
  expect_true(grepl("NA", id))
})

test_that("make_match_id: empty strings", {
  id <- make_match_id("", "", "", "")
  expect_equal(id, "___")
})

test_that("make_match_id: special characters in team names", {
  id <- make_match_id("E0", "2024-01-01", "St. Pauli", "1. FC Köln")
  expect_type(id, "character")
  expect_true(nchar(id) > 0)
})

test_that("make_match_id: very long team names", {
  long_name <- paste(rep("A", 1000), collapse = "")
  id <- make_match_id("E0", "2024-01-01", long_name, "B")
  expect_type(id, "character")
})
