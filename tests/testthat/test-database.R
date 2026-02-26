# Tests for DuckDB database functions

test_that("connect_db creates in-memory connection", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  expect_s4_class(con, "duckdb_connection")
})

test_that("create_schema creates all tables", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))

  create_schema(con)

  tables <- DBI::dbListTables(con)
  expect_true("matches" %in% tables)
  expect_true("match_odds" %in% tables)
  expect_true("teams" %in% tables)
  expect_true("transfers" %in% tables)
})

test_that("create_schema is idempotent", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))

  create_schema(con)
  expect_no_error(create_schema(con))
})

# ---- insert_matches ----

test_that("insert_matches inserts rows", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_schema(con)

  df <- tibble::tibble(
    match_id    = "E0_2023-08-11_Burnley_Man City",
    season      = "2324",
    league_code = "E0",
    match_date  = as.Date("2023-08-11"),
    home_team   = "Burnley",
    away_team   = "Man City",
    fthg = 0L, ftag = 3L, ftr = "A",
    hthg = 0L, htag = 2L, htr = "A",
    hs = 5L, as_ = 13L, hst = 2L, ast = 7L,
    hc = 2L, ac = 7L, hf = 11L, af = 8L,
    hy = 3L, ay = 1L, hr = 0L, ar = 0L
  )

  n <- insert_matches(con, df)
  expect_equal(n, 1L)

  result <- DBI::dbGetQuery(con, "SELECT COUNT(*) AS n FROM matches")
  expect_equal(result$n, 1L)
})

test_that("insert_matches skips duplicates", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_schema(con)

  df <- tibble::tibble(
    match_id    = "E0_2023-08-11_Burnley_Man City",
    season      = "2324",
    league_code = "E0",
    match_date  = as.Date("2023-08-11"),
    home_team   = "Burnley",
    away_team   = "Man City",
    fthg = 0L, ftag = 3L, ftr = "A",
    hthg = 0L, htag = 2L, htr = "A",
    hs = 5L, as_ = 13L, hst = 2L, ast = 7L,
    hc = 2L, ac = 7L, hf = 11L, af = 8L,
    hy = 3L, ay = 1L, hr = 0L, ar = 0L
  )

  insert_matches(con, df)
  # Insert same data again — should skip
  n2 <- insert_matches(con, df)
  expect_equal(n2, 0L)

  result <- DBI::dbGetQuery(con, "SELECT COUNT(*) AS n FROM matches")
  expect_equal(result$n, 1L)
})

test_that("insert_matches handles empty tibble", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_schema(con)

  n <- insert_matches(con, tibble::tibble())
  expect_equal(n, 0L)
})

# ---- insert_match_odds ----

test_that("insert_match_odds inserts Pinnacle odds", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_schema(con)

  odds <- tibble::tibble(
    match_id  = "E0_2023-08-11_Burnley_Man City",
    psh       = 12.50,
    psd       = 7.50,
    psa       = 1.24,
    pahh      = 2.07,
    paha      = 1.85,
    ah_line   = -1.50,
    p_over25  = 1.63,
    p_under25 = 2.37,
    max_h     = 13.00,
    max_d     = 8.50,
    max_a     = 1.25,
    avg_h     = 11.00,
    avg_d     = 6.80,
    avg_a     = 1.22
  )

  n <- insert_match_odds(con, odds)
  expect_equal(n, 1L)

  result <- DBI::dbGetQuery(con, "SELECT * FROM match_odds")
  expect_equal(nrow(result), 1L)
  expect_equal(result$bookmaker, "pinnacle")
  expect_equal(result$odds_h, 12.50)

  # Overround should be computed
  expected_or <- (1/12.50 + 1/7.50 + 1/1.24) - 1
  expect_equal(result$overround, expected_or, tolerance = 1e-6)
})

test_that("insert_match_odds skips duplicates", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_schema(con)

  odds <- tibble::tibble(
    match_id  = "E0_2023-08-11_Burnley_Man City",
    psh = 12.50, psd = 7.50, psa = 1.24,
    pahh = 2.07, paha = 1.85, ah_line = -1.50,
    p_over25 = 1.63, p_under25 = 2.37,
    max_h = 13.00, max_d = 8.50, max_a = 1.25,
    avg_h = 11.00, avg_d = 6.80, avg_a = 1.22
  )

  insert_match_odds(con, odds)
  n2 <- insert_match_odds(con, odds)
  expect_equal(n2, 0L)
})

test_that("insert_match_odds handles missing Pinnacle odds", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_schema(con)

  # Match with no Pinnacle odds (post-Jul-2025)
  odds <- tibble::tibble(
    match_id  = "E0_2025-08-11_Arsenal_Chelsea",
    psh = NA_real_, psd = NA_real_, psa = NA_real_,
    pahh = NA_real_, paha = NA_real_, ah_line = NA_real_,
    p_over25 = NA_real_, p_under25 = NA_real_,
    max_h = 1.60, max_d = 4.00, max_a = 5.50,
    avg_h = 1.55, avg_d = 3.80, avg_a = 5.20
  )

  n <- insert_match_odds(con, odds)
  expect_equal(n, 1L)

  result <- DBI::dbGetQuery(con, "SELECT * FROM match_odds")
  expect_true(is.na(result$overround))
  expect_true(is.na(result$prob_h))
})

# ---- Full pipeline integration ----

test_that("parse + insert roundtrip works", {
  tmp <- withr::local_tempdir()
  csv_path <- file.path(tmp, "E0_2324.csv")
  writeLines(c(
    "Div,Date,Time,HomeTeam,AwayTeam,FTHG,FTAG,FTR,HTHG,HTAG,HTR,HS,AS,HST,AST,HC,AC,HF,AF,HY,AY,HR,AR,PSH,PSD,PSA,PAHH,PAHA,AHh,P>2.5,P<2.5,MaxH,MaxD,MaxA,AvgH,AvgD,AvgA",
    "E0,11/08/2023,20:00,Burnley,Man City,0,3,A,0,2,A,5,13,2,7,2,7,11,8,3,1,0,0,12.50,7.50,1.24,2.07,1.85,-1.50,1.63,2.37,13.00,8.50,1.25,11.00,6.80,1.22",
    "E0,12/08/2023,12:30,Arsenal,Nott'm Forest,2,1,H,1,0,H,18,7,7,3,5,3,9,12,1,2,0,0,1.25,6.50,12.00,1.90,2.02,1.50,1.72,2.18,1.28,7.00,13.00,1.23,6.20,11.50"
  ), csv_path)

  matches <- parse_fd_csv(csv_path, "E0", "2324")
  odds <- parse_fd_odds(csv_path, "E0", "2324")

  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_schema(con)

  n_m <- insert_matches(con, matches)
  n_o <- insert_match_odds(con, odds)

  expect_equal(n_m, 2L)
  expect_equal(n_o, 2L)

  # Query back and verify
  db_matches <- DBI::dbGetQuery(con, "SELECT * FROM matches ORDER BY match_date")
  expect_equal(nrow(db_matches), 2L)
  expect_equal(db_matches$home_team, c("Burnley", "Arsenal"))

  db_odds <- DBI::dbGetQuery(con, "SELECT * FROM match_odds ORDER BY odds_h DESC")
  expect_equal(nrow(db_odds), 2L)
})
