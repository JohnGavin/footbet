# plan_oagd.R
# OAGD (Opposition-Adjusted Goal Difference) model pipeline
# Tracks: https://github.com/JohnGavin/footbet/issues/77

plan_oagd <- list(

  # Average total goals per league (for Skellam lambda anchoring)
  targets::tar_target(
    oagd_avg_goals,
    {
      con <- connect_db(here::here("inst/extdata/footbet.duckdb"))
      on.exit(DBI::dbDisconnect(con))
      dplyr::tbl(con, "matches") |>
        dplyr::filter(.data$season %in% c("2223", "2324", "2425")) |>
        dplyr::mutate(total_goals = .data$fthg + .data$ftag) |>
        dplyr::group_by(.data$league_code) |>
        dplyr::summarise(avg_goals = mean(.data$total_goals, na.rm = TRUE),
                         .groups = "drop") |>
        dplyr::collect()
    }
  ),

  # Match data for training (15-16 to 21-22) and validation (22-23 to 24-25)
  targets::tar_target(
    oagd_data_train,
    {
      con <- connect_db(here::here("inst/extdata/footbet.duckdb"))
      on.exit(DBI::dbDisconnect(con))
      oagd_match_data(
        con,
        seasons = c("1516", "1617", "1718", "1819", "1920", "2021", "2122")
      )
    }
  ),

  targets::tar_target(
    oagd_data_validate,
    {
      con <- connect_db(here::here("inst/extdata/footbet.duckdb"))
      on.exit(DBI::dbDisconnect(con))
      oagd_match_data(con, seasons = c("2223", "2324", "2425"))
    }
  ),

  # Odds for validation set
  targets::tar_target(
    oagd_odds_validate,
    {
      con <- connect_db(here::here("inst/extdata/footbet.duckdb"))
      on.exit(DBI::dbDisconnect(con))
      oagd_add_odds(oagd_data_validate, con)
    }
  ),

  # Backtest on validation set with default parameters
  targets::tar_target(
    oagd_backtest_default,
    {
      leagues <- unique(oagd_data_validate$league_code)
      seasons <- unique(oagd_data_validate$season)

      purrr::map2_dfr(
        rep(leagues, each = length(seasons)),
        rep(seasons, times = length(leagues)),
        function(lg, ssn) {
          d <- oagd_data_validate |>
            dplyr::filter(.data$league_code == lg, .data$season == ssn)
          o <- oagd_odds_validate |>
            dplyr::filter(.data$league_code == lg, .data$season == ssn)
          if (nrow(d) < 50L) return(tibble::tibble())
          tryCatch(
            oagd_backtest_league(d, o,
              window = 8L, K = 4L, half_life = 2,
              beta = 0.3, tau_min = 0.05, tau_double = 0.10),
            error = function(e) {
              cli::cli_warn("OAGD backtest failed for {lg} {ssn}: {conditionMessage(e)}")
              tibble::tibble()
            }
          )
        }
      )
    }
  ),

  # Summary by tier and league
  targets::tar_target(
    oagd_backtest_summary_tbl,
    {
      tier_map <- tibble::tibble(
        league_code = c("E0", "D1", "I1", "SP1", "F1",
                        "E1", "D2", "I2", "SP2", "F2"),
        tier = c(rep("Tier1", 5), rep("Tier2", 5))
      )
      oagd_backtest_default |>
        dplyr::left_join(tier_map, by = "league_code") |>
        oagd_backtest_summary(.data$tier, .data$league_code, .data$season)
    }
  )
)
