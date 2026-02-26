# Adversarial QA: R/database.R exported functions
# Attack vectors: NULL, invalid paths, empty data, double operations

# ---- connect_db ----

test_that("connect_db: invalid path errors", {
  expect_error(connect_db("/nonexistent/dir/db.duckdb"))
})

test_that("connect_db: empty string path", {
  expect_error(connect_db(""))
})

# ---- create_schema ----

test_that("create_schema: NULL connection", {
  expect_error(create_schema(NULL))
})

# ---- insert_matches ----

test_that("insert_matches: empty dataframe returns 0", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_schema(con)

  result <- insert_matches(con, tibble::tibble())
  expect_equal(result, 0L)
})

test_that("insert_matches: NULL connection", {
  expect_error(insert_matches(NULL, tibble::tibble(x = 1)))
})

test_that("insert_matches: duplicate match_id is skipped on re-insert", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_schema(con)

  df <- tibble::tibble(
    match_id = "adv_dup", season = "2324", league_code = "E0",
    match_date = as.Date("2024-01-01"), home_team = "A", away_team = "B",
    fthg = 1L, ftag = 0L, ftr = "H",
    hthg = 0L, htag = 0L, htr = "D",
    hs = NA_integer_, as_ = NA_integer_, hst = NA_integer_, ast = NA_integer_,
    hc = NA_integer_, ac = NA_integer_, hf = NA_integer_, af = NA_integer_,
    hy = NA_integer_, ay = NA_integer_, hr = NA_integer_, ar = NA_integer_
  )

  insert_matches(con, df)
  n2 <- insert_matches(con, df)
  expect_equal(n2, 0L)

  count <- DBI::dbGetQuery(con, "SELECT COUNT(*) AS n FROM matches")
  expect_equal(count$n, 1L)
})

# ---- insert_match_odds ----

test_that("insert_match_odds: empty tibble returns 0", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_schema(con)
  expect_equal(insert_match_odds(con, tibble::tibble()), 0L)
})

test_that("insert_match_odds: all-NA odds produce NA overround", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_schema(con)

  odds <- tibble::tibble(
    match_id = "adv_na_odds",
    psh = NA_real_, psd = NA_real_, psa = NA_real_,
    pahh = NA_real_, paha = NA_real_, ah_line = NA_real_,
    p_over25 = NA_real_, p_under25 = NA_real_,
    max_h = NA_real_, max_d = NA_real_, max_a = NA_real_,
    avg_h = NA_real_, avg_d = NA_real_, avg_a = NA_real_
  )

  n <- insert_match_odds(con, odds)
  expect_equal(n, 1L)
  result <- DBI::dbGetQuery(con, "SELECT overround, prob_h FROM match_odds")
  expect_true(is.na(result$overround))
  expect_true(is.na(result$prob_h))
})

test_that("insert_match_odds: partial Pinnacle gives NA overround", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_schema(con)

  odds <- tibble::tibble(
    match_id = "adv_partial",
    psh = 2.50, psd = NA_real_, psa = NA_real_,
    pahh = NA_real_, paha = NA_real_, ah_line = NA_real_,
    p_over25 = NA_real_, p_under25 = NA_real_,
    max_h = NA_real_, max_d = NA_real_, max_a = NA_real_,
    avg_h = NA_real_, avg_d = NA_real_, avg_a = NA_real_
  )

  insert_match_odds(con, odds)
  result <- DBI::dbGetQuery(con, "SELECT overround FROM match_odds")
  expect_true(is.na(result$overround))
})

test_that("insert_match_odds: duplicate is skipped", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_schema(con)

  odds <- tibble::tibble(
    match_id = "adv_dup_odds",
    psh = 2.00, psd = 3.50, psa = 4.00,
    pahh = NA_real_, paha = NA_real_, ah_line = NA_real_,
    p_over25 = NA_real_, p_under25 = NA_real_,
    max_h = NA_real_, max_d = NA_real_, max_a = NA_real_,
    avg_h = NA_real_, avg_d = NA_real_, avg_a = NA_real_
  )

  insert_match_odds(con, odds)
  n2 <- insert_match_odds(con, odds)
  expect_equal(n2, 0L)
})

test_that("insert_match_odds: overround computed correctly", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_schema(con)

  odds <- tibble::tibble(
    match_id = "adv_overround",
    psh = 2.00, psd = 3.00, psa = 4.00,
    pahh = NA_real_, paha = NA_real_, ah_line = NA_real_,
    p_over25 = NA_real_, p_under25 = NA_real_,
    max_h = NA_real_, max_d = NA_real_, max_a = NA_real_,
    avg_h = NA_real_, avg_d = NA_real_, avg_a = NA_real_
  )

  insert_match_odds(con, odds)
  result <- DBI::dbGetQuery(con, "SELECT overround, prob_h, prob_d, prob_a FROM match_odds")

  expected_or <- (1/2 + 1/3 + 1/4) - 1
  expect_equal(result$overround, expected_or, tolerance = 1e-10)

  # Implied probs should sum to 1
  expect_equal(result$prob_h + result$prob_d + result$prob_a, 1, tolerance = 1e-10)
})

# ---- write_matches_parquet ----

test_that("write_matches_parquet: empty tibble warns", {
  expect_warning(write_matches_parquet(tibble::tibble(), tempdir()))
})

# ---- write_odds_parquet ----

test_that("write_odds_parquet: empty tibble warns", {
  expect_warning(write_odds_parquet(tibble::tibble(), tempdir()))
})

# ---- disconnect_db ----

test_that("disconnect_db: NULL connection", {
  expect_error(disconnect_db(NULL))
})

test_that("disconnect_db: double disconnect warns", {
  con <- connect_db(":memory:")
  disconnect_db(con)
  expect_warning(disconnect_db(con))
})
