# plan_transfers.R
# Fetches transfer data from Transfermarkt via worldfootballR.
# NOTE: This is SLOW and rate-limited. Run sparingly.

plan_transfers <- list(

 # Countries to fetch transfers for (matches target_leagues countries)
  targets::tar_target(
    transfer_countries,
    c("England", "Germany", "Italy", "Spain", "France")
  ),

  # Seasons for transfer data (last 3 complete seasons + current)
  targets::tar_target(
    transfer_seasons,
    {
      current_year <- as.integer(format(Sys.Date(), "%Y"))
      # If before August, current season started last year
      if (as.integer(format(Sys.Date(), "%m")) < 8) {
        current_year <- current_year - 1L
      }
      seq(current_year - 2L, current_year)
    }
  ),

  # Fetch transfers for all countries/seasons
  # Uses dynamic branching over countries x seasons
  targets::tar_target(
    transfers_raw,
    {
      # Only run if worldfootballR is available
      if (!requireNamespace("worldfootballR", quietly = TRUE)) {
        cli::cli_warn("worldfootballR not available. Skipping transfer fetch.")
        return(tibble::tibble())
      }

      # Fetch for each country/season combination
      results <- list()
      for (country in transfer_countries) {
        for (year in transfer_seasons) {
          cli::cli_alert_info("Fetching {country} {year}/{year + 1L} transfers...")
          tryCatch({
            df <- fetch_league_transfers(
              country = country,
              start_year = year,
              transfer_window = "all",
              delay = 7  # Rate limit: ~8 requests/min for Transfermarkt
            )
            if (nrow(df) > 0L) {
              results[[length(results) + 1L]] <- df
            }
          }, error = function(e) {
            cli::cli_warn("Failed {country} {year}: {conditionMessage(e)}")
          })
          Sys.sleep(3)  # Extra delay between country/season combos
        }
      }
      dplyr::bind_rows(results)
    },
    # Only rebuild if explicitly requested (transfer data changes rarely)
    cue = targets::tar_cue(mode = "never")
  ),

  # Squad values for all countries (current season only)
  targets::tar_target(
    squad_values_raw,
    {
      if (!requireNamespace("worldfootballR", quietly = TRUE)) {
        cli::cli_warn("worldfootballR not available. Skipping squad values.")
        return(tibble::tibble())
      }

      current_year <- max(transfer_seasons)
      results <- list()
      for (country in transfer_countries) {
        cli::cli_alert_info("Fetching {country} squad values...")
        tryCatch({
          df <- fetch_squad_values(country = country, start_year = current_year)
          if (nrow(df) > 0L) {
            results[[length(results) + 1L]] <- df
          }
        }, error = function(e) {
          cli::cli_warn("Failed {country}: {conditionMessage(e)}")
        })
        Sys.sleep(5)
      }
      dplyr::bind_rows(results)
    },
    cue = targets::tar_cue(mode = "never")
  ),

  # Insert transfers into DuckDB
  targets::tar_target(
    transfers_db,
    {
      if (nrow(transfers_raw) == 0L) {
        return(list(n_inserted = 0L, timestamp = Sys.time()))
      }
      db_path <- here::here("inst", "extdata", "footbet.duckdb")
      con <- connect_db(db_path)
      on.exit(disconnect_db(con))
      n <- insert_transfers(con, transfers_raw)
      list(n_inserted = n, timestamp = Sys.time())
    }
  ),

  # Aggregate net spend per team/season for feature engineering
  targets::tar_target(
    team_net_spend,
    {
      if (nrow(transfers_raw) == 0L) return(tibble::tibble())

      # Calculate arrivals (spending) and departures (income)
      arrivals <- transfers_raw |>
        dplyr::filter(!is.na(to_team), !is.na(fee_eur), fee_eur > 0) |>
        dplyr::group_by(team = to_team, season) |>
        dplyr::summarise(
          spend_eur = sum(fee_eur, na.rm = TRUE),
          n_arrivals = dplyr::n(),
          .groups = "drop"
        )

      departures <- transfers_raw |>
        dplyr::filter(!is.na(from_team), !is.na(fee_eur), fee_eur > 0) |>
        dplyr::group_by(team = from_team, season) |>
        dplyr::summarise(
          income_eur = sum(fee_eur, na.rm = TRUE),
          n_departures = dplyr::n(),
          .groups = "drop"
        )

      dplyr::full_join(arrivals, departures, by = c("team", "season")) |>
        dplyr::mutate(
          spend_eur = dplyr::coalesce(spend_eur, 0),
          income_eur = dplyr::coalesce(income_eur, 0),
          n_arrivals = dplyr::coalesce(n_arrivals, 0L),
          n_departures = dplyr::coalesce(n_departures, 0L),
          net_spend_eur = spend_eur - income_eur
        )
    }
  )
)
