test_that("fd_url builds correct URL", {
  url <- fd_url("E0", "2324")
  expect_equal(
    url,
    "https://www.football-data.co.uk/mmz4281/2324/E0.csv"
  )
})

test_that("fd_url rejects invalid season format", {
  expect_error(fd_url("E0", "23"), "4-digit")
  expect_error(fd_url("E0", "abcd"), "4-digit")
})

test_that("target_leagues returns 10 leagues", {
  leagues <- target_leagues()
  expect_s3_class(leagues, "tbl_df")
  expect_equal(nrow(leagues), 10L)
  expect_named(leagues, c("country", "league_code", "division"))
})

test_that("target_seasons generates correct codes", {
  seasons <- target_seasons(2020L, 2022L)
  expect_equal(seasons, c("2021", "2122", "2223"))
})

test_that("make_match_id produces deterministic IDs", {
  id <- make_match_id("E0", "2024-01-15", "Arsenal", "Liverpool")
  expect_equal(id, "E0_2024-01-15_Arsenal_Liverpool")
})
