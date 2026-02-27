# Tests for R/data_transfers.R
# Note: worldfootballR scrapes live websites, so we test internal helpers
# and standardisation logic without network calls.

# ---- parse_transfer_fee ----

test_that("parse_transfer_fee handles millions", {
  result <- footbet:::parse_transfer_fee(c("€30m", "€1.5m"))
  expect_equal(result, c(30e6, 1.5e6))
})

test_that("parse_transfer_fee handles thousands", {
  result <- footbet:::parse_transfer_fee("€500k")
  expect_equal(result, 500e3)
})

test_that("parse_transfer_fee handles free / NA", {
  result <- footbet:::parse_transfer_fee(c("free transfer", NA, ""))
  expect_equal(result[1], NA_real_)  # "free" has no digits
  expect_true(is.na(result[2]))
  expect_true(is.na(result[3]))
})

test_that("parse_transfer_fee handles plain numbers", {
  result <- footbet:::parse_transfer_fee("5000000")
  expect_equal(result, 5e6)
})

# ---- classify_fee ----

test_that("classify_fee categorises correctly", {
  result <- footbet:::classify_fee(c(
    "Free Transfer", "Loan", "€30m", "Undisclosed", NA, ""
  ))
  expect_equal(result, c("free", "loan", "paid", "undisclosed", NA, NA))
})

# ---- standardise_transfers ----

test_that("standardise_transfers produces correct structure", {
  # Mock raw output from worldfootballR::tm_team_transfers
  raw <- tibble::tibble(
    player_name = c("Player A", "Player B"),
    team_name = c("Arsenal", "Arsenal"),
    transfer_fee = c("€30m", "Free Transfer"),
    player_position = c("Centre-Forward", "Goalkeeper"),
    player_age = c(25L, 30L),
    transfer_type = c("Arrivals", "Departures"),
    transfer_date = as.Date(c("2024-07-01", "2024-08-15"))
  )

  result <- footbet:::standardise_transfers(raw, "England", 2024L)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2L)
  expect_true("transfer_id" %in% colnames(result))
  expect_true("season" %in% colnames(result))
  expect_equal(result$season, c("2425", "2425"))
  expect_equal(result$fee_eur[1], 30e6)
  expect_equal(result$fee_type[2], "free")
  expect_equal(result$position[1], "Centre-Forward")
  expect_equal(result$age_at_transfer[1], 25L)
})

test_that("standardise_transfers handles missing columns gracefully", {
  # Minimal raw output
  raw <- tibble::tibble(
    player_name = "Player C"
  )

  result <- footbet:::standardise_transfers(raw, "Germany", 2023L)
  expect_equal(nrow(result), 1L)
  expect_true(is.na(result$fee_eur))
  expect_true(is.na(result$position))
})

# ---- insert_transfers ----

test_that("insert_transfers inserts rows", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_schema(con)

  transfers <- tibble::tibble(
    transfer_id = "PlayerA_2425_NA_Arsenal",
    player_name = "Player A",
    transfer_date = as.Date("2024-07-01"),
    season = "2425",
    from_team = NA_character_,
    to_team = "Arsenal",
    league_from = "Spain",
    league_to = "England",
    fee_eur = 30e6,
    fee_type = "paid",
    position = "Centre-Forward",
    age_at_transfer = 25L
  )

  n <- insert_transfers(con, transfers)
  expect_equal(n, 1L)

  result <- DBI::dbGetQuery(con, "SELECT COUNT(*) AS n FROM transfers")
  expect_equal(result$n, 1L)
})

test_that("insert_transfers skips duplicates", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_schema(con)

  transfers <- tibble::tibble(
    transfer_id = "dup_test",
    player_name = "Player Dup",
    transfer_date = as.Date("2024-07-01"),
    season = "2425",
    from_team = "Club A",
    to_team = "Club B",
    league_from = "England",
    league_to = "England",
    fee_eur = 5e6,
    fee_type = "paid",
    position = "Midfielder",
    age_at_transfer = 22L
  )

  insert_transfers(con, transfers)
  n2 <- insert_transfers(con, transfers)
  expect_equal(n2, 0L)
})

test_that("insert_transfers handles empty tibble", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_schema(con)

  n <- insert_transfers(con, tibble::tibble())
  expect_equal(n, 0L)
})

# ---- fetch_league_transfers / fetch_squad_values ----

test_that("fetch_league_transfers requires country", {
  expect_error(fetch_league_transfers())
})

test_that("fetch_squad_values requires country", {
  expect_error(fetch_squad_values())
})
