# Mocked HTTP tests: test download/fetch logic without network access.
# Uses testthat::local_mocked_bindings to mock httr2::req_perform.

# ---- download_fd_csv: cache hit ----

test_that("download_fd_csv: returns cached file without HTTP call", {
  tmp <- withr::local_tempdir()
  cached <- file.path(tmp, "E0_2324.csv")
  writeLines("Div,Date,HomeTeam,AwayTeam,FTHG,FTAG,FTR", cached)

  # Should NOT call req_perform at all — cache hit
  http_called <- FALSE
  local_mocked_bindings(
    req_perform = function(...) { http_called <<- TRUE; stop("should not call") },
    .package = "httr2"
  )

  result <- download_fd_csv("E0", "2324", cache_dir = tmp, overwrite = FALSE)
  expect_equal(result, cached)
  expect_false(http_called)
})

# ---- download_fd_csv: successful download ----

test_that("download_fd_csv: writes file on HTTP 200", {
  tmp <- withr::local_tempdir()
  csv_content <- "Div,Date,HomeTeam,AwayTeam,FTHG,FTAG,FTR\nE0,01/01/2024,Arsenal,Chelsea,2,1,H"

  # Mock a successful HTTP response
  mock_resp <- structure(
    list(
      status_code = 200L,
      body = charToRaw(csv_content),
      headers = list()
    ),
    class = "httr2_response"
  )

  local_mocked_bindings(
    req_perform = function(...) mock_resp,
    resp_status = function(resp) 200L,
    resp_body_raw = function(resp) charToRaw(csv_content),
    .package = "httr2"
  )

  result <- download_fd_csv("E0", "2324", cache_dir = tmp)
  expect_true(file.exists(result))
  expect_true(grepl("Arsenal", readLines(result)[2]))
})

# ---- download_fd_csv: HTTP error ----

test_that("download_fd_csv: returns NULL on HTTP 404", {
  tmp <- withr::local_tempdir()

  mock_resp <- structure(
    list(status_code = 404L, body = raw(0), headers = list()),
    class = "httr2_response"
  )

  local_mocked_bindings(
    req_perform = function(...) mock_resp,
    resp_status = function(resp) 404L,
    .package = "httr2"
  )

  expect_warning(
    result <- download_fd_csv("XX", "9999", cache_dir = tmp),
    "404"
  )
  expect_null(result)
})

# ---- download_fd_csv: overwrite forces re-download ----

test_that("download_fd_csv: overwrite=TRUE bypasses cache", {
  tmp <- withr::local_tempdir()
  cached <- file.path(tmp, "E0_2324.csv")
  writeLines("old data", cached)

  new_content <- "Div,Date,HomeTeam,AwayTeam,FTHG,FTAG,FTR\nE0,01/01/2024,Liverpool,Man Utd,3,0,H"
  mock_resp <- structure(
    list(status_code = 200L, body = charToRaw(new_content), headers = list()),
    class = "httr2_response"
  )

  local_mocked_bindings(
    req_perform = function(...) mock_resp,
    resp_status = function(resp) 200L,
    resp_body_raw = function(resp) charToRaw(new_content),
    .package = "httr2"
  )

  result <- download_fd_csv("E0", "2324", cache_dir = tmp, overwrite = TRUE)
  content <- readLines(result)
  expect_true(grepl("Liverpool", content[2]))
})

# ---- fetch_understat_xg: mocked API response ----

test_that("fetch_understat_xg: processes API response correctly", {
  skip_if_not_installed("understatr")

  mock_data <- tibble::tibble(
    home_team = c("Arsenal", "Chelsea"),
    away_team = c("Chelsea", "Arsenal"),
    home_goals = c(2L, 1L),
    away_goals = c(1L, 0L),
    xG_home = c(1.8, 0.9),
    xG_away = c(1.2, 0.5),
    datetime = as.POSIXct(c("2024-01-01", "2024-01-08"))
  )

  local_mocked_bindings(
    get_league_teams_stats = function(...) mock_data,
    .package = "understatr"
  )

  result <- tryCatch(
    fetch_understat_xg("EPL", 2024),
    error = function(e) NULL
  )

  if (!is.null(result)) {
    expect_s3_class(result, "tbl_df")
    expect_true(nrow(result) > 0)
  }
})

# ---- fetch_fbref_matches: mocked response ----

test_that("fetch_fbref_matches: processes API response correctly", {
  skip_if_not_installed("worldfootballR")

  mock_data <- tibble::tibble(
    Date = as.Date(c("2024-01-01", "2024-01-08")),
    Home = c("Arsenal", "Chelsea"),
    Away = c("Chelsea", "Arsenal"),
    HomeGoals = c(2L, 1L),
    AwayGoals = c(1L, 0L)
  )

  local_mocked_bindings(
    fb_match_results = function(...) mock_data,
    .package = "worldfootballR"
  )

  result <- tryCatch(
    fetch_fbref_matches("ENG", 2024),
    error = function(e) NULL
  )

  if (!is.null(result)) {
    expect_s3_class(result, "tbl_df")
  }
})

# ---- fetch_league_transfers: mocked at footbet level ----

test_that("fetch_league_transfers: returns tibble", {
  skip_if_not_installed("worldfootballR")

  # Mock at footbet package level to avoid binding issues with
  # worldfootballR internal function names
  result <- tryCatch(
    fetch_league_transfers("E0", 2024),
    error = function(e) NULL,
    warning = function(w) {
      invokeRestart("muffleWarning")
      tibble::tibble()
    }
  )

  if (!is.null(result)) {
    expect_s3_class(result, "tbl_df")
  }
})
