# Integration tests for OAGD model (requires lme4 + DuckDB data)

test_that("oagd_match_data returns expected structure", {
  skip_if_not_installed("lme4")
  skip_if_not(
    file.exists(here::here("inst/extdata/footbet.duckdb")),
    "DuckDB not available"
  )

  con <- connect_db(here::here("inst/extdata/footbet.duckdb"))
  on.exit(DBI::dbDisconnect(con))

  data <- oagd_match_data(con, seasons = "2425", leagues = "E0")

  expect_s3_class(data, "tbl_df")
  expect_true(all(c("match_id", "season", "league_code", "match_date",
                     "matchday", "home_team", "away_team", "gd_home") %in%
                    names(data)))
  expect_equal(unique(data$season), "2425")
  expect_equal(unique(data$league_code), "E0")
  # E0 has 20 teams, 38 matchdays, 380 matches
  expect_equal(nrow(data), 380L)
  expect_equal(max(data$matchday), 38L)
  # Each matchday should have 10 matches
  expect_true(all(
    data |> dplyr::count(matchday) |> dplyr::pull(n) == 10L
  ))
})

test_that("oagd_add_odds joins and devigs correctly", {
  skip_if_not_installed("lme4")
  skip_if_not(
    file.exists(here::here("inst/extdata/footbet.duckdb")),
    "DuckDB not available"
  )

  con <- connect_db(here::here("inst/extdata/footbet.duckdb"))
  on.exit(DBI::dbDisconnect(con))

  data <- oagd_match_data(con, seasons = "2425", leagues = "E0")
  with_odds <- oagd_add_odds(data, con)

  expect_true(all(c("odds_h", "implied_h", "implied_d", "implied_a") %in%
                    names(with_odds)))
  # Devigged implied probs should sum to ~1 per match
  sums <- with_odds$implied_h + with_odds$implied_d + with_odds$implied_a
  sums <- sums[!is.na(sums)]
  expect_true(all(dplyr::near(sums, 1, tol = 1e-6)))
})

test_that("oagd_fit_window produces shrunk estimates", {
  skip_if_not_installed("lme4")
  skip_if_not(
    file.exists(here::here("inst/extdata/footbet.duckdb")),
    "DuckDB not available"
  )

  con <- connect_db(here::here("inst/extdata/footbet.duckdb"))
  on.exit(DBI::dbDisconnect(con))

  data <- oagd_match_data(con, seasons = "2425", leagues = "E0")
  fit <- oagd_fit_window(data, target_matchday = 10L, window = 10L)

  expect_type(fit, "list")
  expect_true("eta" %in% names(fit))
  expect_true("strengths" %in% names(fit))

  # Home advantage should be positive
  expect_true(fit$eta > 0)

  # Strengths should be shrunk compared to raw GD
  raw <- data |>
    dplyr::filter(matchday <= 10L) |>
    dplyr::group_by(home_team) |>
    dplyr::summarise(mean_gd = mean(gd_home), .groups = "drop")

  # Max random effect should be smaller than max raw GD (shrinkage)
  expect_true(max(abs(fit$strengths$alpha)) < max(abs(raw$mean_gd)))
})

test_that("oagd_roll_fits converges for most matchdays", {
  skip_if_not_installed("lme4")
  skip_if_not(
    file.exists(here::here("inst/extdata/footbet.duckdb")),
    "DuckDB not available"
  )

  con <- connect_db(here::here("inst/extdata/footbet.duckdb"))
  on.exit(DBI::dbDisconnect(con))

  data <- oagd_match_data(con, seasons = "2425", leagues = "E0")
  fits <- oagd_roll_fits(data, window = 8L)

  n_total <- length(fits)
  n_ok <- sum(!purrr::map_lgl(fits, is.null))

  # At least 90% should converge

  expect_true(n_ok / n_total > 0.90)
})

test_that("snapshot: oagd_fit_window strengths for E0 2425 matchday 10", {
  skip_if_not_installed("lme4")
  skip_if_not(
    file.exists(here::here("inst/extdata/footbet.duckdb")),
    "DuckDB not available"
  )

  con <- connect_db(here::here("inst/extdata/footbet.duckdb"))
  on.exit(DBI::dbDisconnect(con))

  data <- oagd_match_data(con, seasons = "2425", leagues = "E0")
  fit <- oagd_fit_window(data, target_matchday = 10L, window = 10L)

  snap <- fit$strengths |>
    dplyr::mutate(dplyr::across(dplyr::where(is.numeric), \(x) round(x, 3))) |>
    dplyr::arrange(dplyr::desc(alpha))

  expect_snapshot(snap)
})

test_that("snapshot: full pipeline E0 2425 predictions sample", {
  skip_if_not_installed("lme4")
  skip_if_not(
    file.exists(here::here("inst/extdata/footbet.duckdb")),
    "DuckDB not available"
  )

  con <- connect_db(here::here("inst/extdata/footbet.duckdb"))
  on.exit(DBI::dbDisconnect(con))

  data <- oagd_match_data(con, seasons = "2425", leagues = "E0")
  fits <- oagd_roll_fits(data, window = 8L)
  data_resid <- oagd_residuals(data, fits)
  form_tbl <- oagd_form(data_resid, K = 4L, half_life = 2)
  preds <- oagd_predict_all(data, fits, form_tbl,
                            beta = 0.3, avg_total_goals = 2.7)

  # Snapshot matchday 20 predictions (mid-season, stable estimates)
  snap <- preds |>
    dplyr::filter(matchday == 20L) |>
    dplyr::select(home_team, away_team, gd_home, pred_h, pred_d, pred_a) |>
    dplyr::mutate(dplyr::across(dplyr::where(is.numeric), \(x) round(x, 3))) |>
    dplyr::arrange(home_team)

  expect_snapshot(snap)
})

test_that("snapshot: backtest summary E0 2425", {
  skip_if_not_installed("lme4")
  skip_if_not(
    file.exists(here::here("inst/extdata/footbet.duckdb")),
    "DuckDB not available"
  )

  con <- connect_db(here::here("inst/extdata/footbet.duckdb"))
  on.exit(DBI::dbDisconnect(con))

  data <- oagd_match_data(con, seasons = "2425", leagues = "E0")
  odds_data <- oagd_add_odds(data, con)

  bets <- oagd_backtest_league(data, odds_data,
    window = 8L, K = 4L, half_life = 2,
    beta = 0.3, tau_min = 0.05, tau_double = 0.10)

  snap <- oagd_backtest_summary(bets, outcome_bet) |>
    dplyr::mutate(dplyr::across(dplyr::where(is.numeric), \(x) round(x, 2)))

  expect_snapshot(snap)
})