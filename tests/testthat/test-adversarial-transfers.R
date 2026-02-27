# Adversarial QA: R/data_transfers.R exported + internal functions
# Attack vectors: NULL, NA, empty, malformed inputs

# ---- parse_transfer_fee ----

test_that("parse_transfer_fee: all NA input", {
  result <- footbet:::parse_transfer_fee(c(NA, NA, NA))
  expect_true(all(is.na(result)))
})

test_that("parse_transfer_fee: garbage strings", {
  result <- footbet:::parse_transfer_fee(c("abc", "---", "???"))
  expect_true(all(is.na(result)))
})

test_that("parse_transfer_fee: mixed valid and invalid", {
  result <- footbet:::parse_transfer_fee(c("€10m", "abc", "€500k"))
  expect_equal(result[1], 10e6)
  expect_true(is.na(result[2]))
  expect_equal(result[3], 500e3)
})

test_that("parse_transfer_fee: zero value", {
  result <- footbet:::parse_transfer_fee("0")
  expect_equal(result, 0)
})

# ---- classify_fee ----

test_that("classify_fee: empty and NA", {
  result <- footbet:::classify_fee(c(NA, "", "  "))
  expect_equal(result[1], NA_character_)
  expect_equal(result[2], NA_character_)
})

test_that("classify_fee: case insensitive", {
  result <- footbet:::classify_fee(c("FREE TRANSFER", "LOAN", "free"))
  expect_equal(result, c("free", "loan", "free"))
})

# ---- standardise_transfers ----

test_that("standardise_transfers: empty raw tibble", {
  raw <- tibble::tibble(player_name = character(0))
  result <- footbet:::standardise_transfers(raw, "England", 2024L)
  expect_equal(nrow(result), 0L)
})

test_that("standardise_transfers: season code wraps correctly at century", {
  # 2099/2100 season → "9900"
  raw <- tibble::tibble(player_name = "Test")
  result <- footbet:::standardise_transfers(raw, "England", 2099L)
  expect_equal(result$season, "9900")
})

# ---- insert_transfers ----

test_that("insert_transfers: NULL connection", {
  transfers <- tibble::tibble(
    transfer_id = "test", player_name = "A",
    transfer_date = as.Date("2024-01-01"), season = "2425",
    from_team = "X", to_team = "Y",
    league_from = "E", league_to = "E",
    fee_eur = 1e6, fee_type = "paid",
    position = "FW", age_at_transfer = 20L
  )
  expect_error(insert_transfers(NULL, transfers))
})

test_that("insert_transfers: tibble with extra columns (should be filtered)", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_schema(con)

  transfers <- tibble::tibble(
    transfer_id = "extra_col_test", player_name = "A",
    transfer_date = as.Date("2024-01-01"), season = "2425",
    from_team = "X", to_team = "Y",
    league_from = "E", league_to = "E",
    fee_eur = 1e6, fee_type = "paid",
    position = "FW", age_at_transfer = 20L,
    extra_column = "should be ignored"
  )

  n <- insert_transfers(con, transfers)
  expect_equal(n, 1L)
})

# ---- fetch functions ----

test_that("fetch_league_transfers: NULL country errors", {
  expect_error(fetch_league_transfers(NULL))
})

test_that("fetch_squad_values: NULL country errors", {
  expect_error(fetch_squad_values(NULL))
})
