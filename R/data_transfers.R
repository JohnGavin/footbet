#' Fetch league transfers from Transfermarkt via worldfootballR
#'
#' Gets team URLs for a league/season, then fetches transfers for
#' each team with rate limiting. Standardises output columns.
#'
#' @param country Character. Country name (e.g. "England").
#' @param start_year Integer. Season start year (e.g. 2024 for 2024/25).
#' @param transfer_window Character. "all", "summer", or "winter".
#' @param delay Numeric. Seconds to pause between requests (default 7).
#' @return A tibble of transfer records with standardised columns.
#' @family data-acquisition
#' @export
fetch_league_transfers <- function(country,
                                   start_year = 2024L,
                                   transfer_window = "all",
                                   delay = 7) {
  rlang::check_installed("worldfootballR",
    reason = "to fetch transfer data from Transfermarkt"
  )
  rlang::check_required(country)
  if (!rlang::is_string(country)) {
    cli::cli_abort("{.arg country} must be a single string, not {.cls {class(country)}}.")
  }

  cli::cli_alert("Fetching team URLs for {.val {country}} {start_year}/{start_year + 1L}")

  team_urls <- tryCatch(
    worldfootballR::tm_league_team_urls(
      country_name = country,
      start_year = start_year
    ),
    error = function(e) {
      cli::cli_warn(c(
        "!" = "Failed to get team URLs for {.val {country}} {start_year}.",
        "i" = "{conditionMessage(e)}"
      ))
      return(character(0))
    }
  )

  if (length(team_urls) == 0L) {
    cli::cli_warn("No team URLs found for {.val {country}} {start_year}.")
    return(tibble::tibble())
  }

  cli::cli_alert("Found {length(team_urls)} teams. Fetching transfers...")

  dfs <- vector("list", length(team_urls))
  for (i in seq_along(team_urls)) {
    cli::cli_alert_info("[{i}/{length(team_urls)}] {team_urls[[i]]}")
    dfs[[i]] <- tryCatch(
      worldfootballR::tm_team_transfers(
        team_url = team_urls[[i]],
        transfer_window = transfer_window
      ),
      error = function(e) {
        cli::cli_warn("Failed for {.url {team_urls[[i]]}}: {conditionMessage(e)}")
        NULL
      }
    )
    if (i < length(team_urls)) Sys.sleep(delay)
  }

  raw <- dplyr::bind_rows(dfs)
  if (nrow(raw) == 0L) return(tibble::tibble())

  standardise_transfers(raw, country, start_year)
}

#' Fetch squad market values from Transfermarkt
#'
#' @param country Character. Country name.
#' @param start_year Integer. Season start year.
#' @return A tibble with team names and squad values.
#' @family data-acquisition
#' @export
fetch_squad_values <- function(country, start_year = 2024L) {
  rlang::check_installed("worldfootballR",
    reason = "to fetch squad values from Transfermarkt"
  )
  rlang::check_required(country)
  if (!rlang::is_string(country)) {
    cli::cli_abort("{.arg country} must be a single string, not {.cls {class(country)}}.")
  }

  cli::cli_alert("Fetching squad values for {.val {country}} {start_year}")

  raw <- tryCatch(
    worldfootballR::tm_player_market_values(
      country_name = country,
      start_year = start_year
    ),
    error = function(e) {
      cli::cli_warn(c(
        "!" = "Failed to fetch squad values for {.val {country}} {start_year}.",
        "i" = "{conditionMessage(e)}"
      ))
      return(tibble::tibble())
    }
  )

  if (nrow(raw) == 0L) return(tibble::tibble())

  # Aggregate to team level
  squad_col <- intersect(c("squad", "team_name", "comp_name"), colnames(raw))
  value_col <- intersect(c("player_market_value_euro", "market_value_in_eur"), colnames(raw))

  if (length(squad_col) == 0L || length(value_col) == 0L) {
    cli::cli_warn("Unexpected column names from tm_player_market_values(). Returning raw.")
    return(raw)
  }

  raw |>
    dplyr::group_by(team = .data[[squad_col[[1]]]]) |>
    dplyr::summarise(
      squad_value_eur = sum(.data[[value_col[[1]]]], na.rm = TRUE),
      n_players = dplyr::n(),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      country = country,
      season = paste0(
        formatC(start_year %% 100, width = 2, flag = "0"),
        formatC((start_year + 1L) %% 100, width = 2, flag = "0")
      )
    )
}

#' Insert transfer data into DuckDB
#'
#' @param con A DBI connection.
#' @param transfers_df A tibble from [fetch_league_transfers()] after
#'   standardisation, or any tibble with columns matching the transfers schema.
#' @return Number of rows inserted (invisibly).
#' @family storage
#' @export
insert_transfers <- function(con, transfers_df) {
  if (nrow(transfers_df) == 0L) return(invisible(0L))

  cols <- c("transfer_id", "player_name", "transfer_date", "season",
            "from_team", "to_team", "league_from", "league_to",
            "fee_eur", "fee_type", "position", "age_at_transfer")
  transfers_df <- transfers_df[, intersect(cols, colnames(transfers_df))]

  DBI::dbWriteTable(con, "transfers_staging", transfers_df, overwrite = TRUE)
  col_list <- paste(colnames(transfers_df), collapse = ", ")
  n <- DBI::dbExecute(con, glue::glue("
    INSERT INTO transfers ({col_list})
    SELECT {col_list} FROM transfers_staging
    ON CONFLICT (transfer_id) DO NOTHING
  "))
  DBI::dbExecute(con, "DROP TABLE IF EXISTS transfers_staging")
  invisible(n)
}


# ---- Internal helpers ----

#' Standardise worldfootballR transfer output
#' @noRd
standardise_transfers <- function(raw, country, start_year) {
  season_code <- paste0(
    formatC(start_year %% 100, width = 2, flag = "0"),
    formatC((start_year + 1L) %% 100, width = 2, flag = "0")
  )

  # worldfootballR column names vary by version; handle flexibly
  name_col <- intersect(c("player_name", "Player"), colnames(raw))[[1]]
  from_col <- intersect(c("team_name", "Team"), colnames(raw))
  fee_col <- intersect(c("transfer_fee", "Fee"), colnames(raw))
  pos_col <- intersect(c("player_position", "Position"), colnames(raw))
  age_col <- intersect(c("player_age", "Age"), colnames(raw))
  window_col <- intersect(c("transfer_period", "Window", "window"), colnames(raw))

  result <- tibble::tibble(
    player_name = as.character(raw[[name_col[[1]]]]),
    season = season_code,
    from_team = if (length(from_col)) as.character(raw[[from_col[[1]]]]) else NA_character_,
    to_team = NA_character_,
    league_from = country,
    league_to = NA_character_,
    fee_eur = if (length(fee_col)) parse_transfer_fee(raw[[fee_col[[1]]]]) else NA_real_,
    fee_type = if (length(fee_col)) classify_fee(raw[[fee_col[[1]]]]) else NA_character_,
    position = if (length(pos_col)) as.character(raw[[pos_col[[1]]]]) else NA_character_,
    age_at_transfer = if (length(age_col)) readr::parse_integer(as.character(raw[[age_col[[1]]]])) else NA_integer_
  )

  # Detect arrivals vs departures if available
  dir_col <- intersect(c("transfer_type", "Type", "type"), colnames(raw))
  if (length(dir_col) > 0L) {
    direction <- tolower(as.character(raw[[dir_col[[1]]]]))
    is_arrival <- grepl("arrival|in|join", direction)
    # For arrivals, swap from/to
    if (any(is_arrival) && length(from_col) > 0L) {
      result$to_team[is_arrival] <- result$from_team[is_arrival]
      result$from_team[is_arrival] <- NA_character_
    }
  }

  # Transfer date
  date_col <- intersect(c("transfer_date", "Date"), colnames(raw))
  if (length(date_col) > 0L) {
    result$transfer_date <- as.Date(raw[[date_col[[1]]]])
  } else {
    result$transfer_date <- as.Date(rep(NA_character_, nrow(raw)))
  }

  # Generate transfer_id
  result$transfer_id <- paste(
    result$player_name, result$season,
    result$from_team, result$to_team,
    sep = "_"
  )

  result
}

#' Parse transfer fee strings to numeric EUR
#' @noRd
parse_transfer_fee <- function(fee_strings) {
  vapply(fee_strings, function(s) {
    if (is.na(s) || !nzchar(s)) return(NA_real_)
    s <- gsub("[^0-9.kmKMb]", "", s)
    s <- tolower(s)
    if (grepl("m$", s)) {
      return(as.numeric(sub("m$", "", s)) * 1e6)
    }
    if (grepl("k$", s)) {
      return(as.numeric(sub("k$", "", s)) * 1e3)
    }
    if (grepl("b$", s)) {
      return(as.numeric(sub("b$", "", s)) * 1e9)
    }
    suppressWarnings(as.numeric(s))
  }, numeric(1), USE.NAMES = FALSE)
}

#' Classify fee type from transfer fee string
#' @noRd
classify_fee <- function(fee_strings) {
  vapply(fee_strings, function(s) {
    if (is.na(s) || !nzchar(s)) return(NA_character_)
    s_lower <- tolower(s)
    if (grepl("free", s_lower)) return("free")
    if (grepl("loan", s_lower)) return("loan")
    if (grepl("undisclosed", s_lower)) return("undisclosed")
    if (grepl("[0-9]", s)) return("paid")
    "unknown"
  }, character(1), USE.NAMES = FALSE)
}


# ---- Player Availability Functions (Issue #36) ----

#' Fetch current league injuries from Transfermarkt
#'
#' Downloads the list of currently injured players in a league
#' via worldfootballR. Includes injury type, expected return date,
#' and player market value.
#'
#' @param country Character. Country name (e.g. "England").
#' @param start_year Integer. Season start year (e.g. 2024 for 2024/25).
#' @return A tibble of currently injured players with columns:
#'   `player_name`, `team`, `position`, `injury`, `injured_since`,
#'   `expected_return`, `days_injured`, `market_value_eur`.
#' @family data-acquisition
#' @export
fetch_league_injuries <- function(country, start_year = 2024L) {
rlang::check_required(country)
  if (!rlang::is_string(country)) {
    cli::cli_abort("{.arg country} must be a single string, not {.cls {class(country)}}.")
  }
  rlang::check_installed("worldfootballR",
    reason = "to fetch injury data from Transfermarkt"
  )

  cli::cli_alert("Fetching injuries for {.val {country}} {start_year}/{start_year + 1L}")

  raw <- tryCatch(
    worldfootballR::tm_league_injuries(country_name = country),
    error = function(e) {
      cli::cli_warn(c(
        "!" = "Failed to fetch injuries for {.val {country}}.",
        "i" = "{conditionMessage(e)}"
      ))
      return(tibble::tibble())
    }
  )

  if (nrow(raw) == 0L) return(tibble::tibble())

  standardise_injuries(raw, country, start_year)
}

#' Fetch league suspensions from Transfermarkt
#'
#' Downloads the list of currently suspended players in a league
#' (yellow card accumulations, red cards, etc.).
#'
#' @param country Character. Country name (e.g. "England").
#' @param start_year Integer. Season start year.
#' @return A tibble of suspended players with columns:
#'   `player_name`, `team`, `position`, `suspension_type`,
#'   `games_remaining`, `market_value_eur`.
#' @family data-acquisition
#' @export
fetch_league_suspensions <- function(country, start_year = 2024L) {
  rlang::check_required(country)
  if (!rlang::is_string(country)) {
    cli::cli_abort("{.arg country} must be a single string, not {.cls {class(country)}}.")
  }
  rlang::check_installed("worldfootballR",
    reason = "to fetch suspension data from Transfermarkt"
  )

  cli::cli_alert("Fetching suspensions for {.val {country}} {start_year}/{start_year + 1L}")

  if (!exists("tm_get_suspensions", asNamespace("worldfootballR"))) {
    cli::cli_warn(c(
      "!" = "{.fn worldfootballR::tm_get_suspensions} is no longer available.",
      "i" = "This function was removed from {.pkg worldfootballR}.",
      "i" = "Returning empty tibble."
    ))
    return(tibble::tibble())
  }

  raw <- tryCatch(
    worldfootballR::tm_get_suspensions(country_name = country),
    error = function(e) {
      cli::cli_warn(c(
        "!" = "Failed to fetch suspensions for {.val {country}}.",
        "i" = "{conditionMessage(e)}"
      ))
      return(tibble::tibble())
    }
  )

  if (nrow(raw) == 0L) return(tibble::tibble())

  standardise_suspensions(raw, country, start_year)
}

#' Check key player availability for a team
#'
#' Determines if a team's most valuable players are available
#' by cross-referencing squad values with injuries and suspensions.
#' Useful as a predictive feature.
#'
#' @param team Character. Team name (must match Transfermarkt spelling).
#' @param injuries_df A tibble from [fetch_league_injuries()].
#' @param suspensions_df A tibble from [fetch_league_suspensions()].
#' @param squad_values_df A tibble from [fetch_squad_values()] with
#'   player-level data (requires `player_name` and `market_value_eur`).
#' @param top_n Integer. Number of top players to check (default 5).
#' @return A list with `n_unavailable`, `unavailable_value_eur`,
#'   `pct_value_missing`, `key_players_out` (character vector).
#' @family features
#' @export
key_players_unavailable <- function(team,
                                    injuries_df,
                                    suspensions_df,
                                    squad_values_df,
                                    top_n = 5L) {
  rlang::check_required(team)
  if (!rlang::is_string(team)) {
    cli::cli_abort("{.arg team} must be a single string.")
  }


  # Get team's players sorted by value
  team_players <- squad_values_df |>
    dplyr::filter(tolower(.data$team) == tolower(!!team)) |>
    dplyr::arrange(dplyr::desc(.data$market_value_eur))

  if (nrow(team_players) == 0L) {
    cli::cli_warn("No player data found for team {.val {team}}.")
    return(list(
      n_unavailable = NA_integer_,
      unavailable_value_eur = NA_real_,
      pct_value_missing = NA_real_,
      key_players_out = character(0)
    ))
  }

  # Top N players by value
  key_players <- team_players |>
    dplyr::slice_head(n = top_n)

  total_key_value <- sum(key_players$market_value_eur, na.rm = TRUE)

  # Find who is unavailable
  unavailable_names <- character(0)

  if (nrow(injuries_df) > 0L) {
    injured <- injuries_df |>
      dplyr::filter(tolower(.data$team) == tolower(!!team)) |>
      dplyr::pull(.data$player_name)
    unavailable_names <- c(unavailable_names, injured)
  }

  if (nrow(suspensions_df) > 0L) {
    suspended <- suspensions_df |>
      dplyr::filter(tolower(.data$team) == tolower(!!team)) |>
      dplyr::pull(.data$player_name)
    unavailable_names <- c(unavailable_names, suspended)
  }

  unavailable_names <- unique(unavailable_names)

  # Match with key players
  key_out <- key_players |>
    dplyr::filter(.data$player_name %in% unavailable_names)

  list(
    n_unavailable = nrow(key_out),
    unavailable_value_eur = sum(key_out$market_value_eur, na.rm = TRUE),
    pct_value_missing = if (total_key_value > 0) {
      100 * sum(key_out$market_value_eur, na.rm = TRUE) / total_key_value
    } else {
      NA_real_
    },
    key_players_out = key_out$player_name
  )
}

#' Add player availability features to match data
#'
#' For each match, computes the percentage of key player value
#' missing due to injuries/suspensions for both home and away teams.
#'
#' @param matches A tibble with `home_team`, `away_team` columns.
#' @param injuries_df A tibble from [fetch_league_injuries()].
#' @param suspensions_df A tibble from [fetch_league_suspensions()].
#' @param squad_values_df Player-level values from Transfermarkt.
#' @param top_n Integer. Number of top players to consider (default 5).
#' @return The matches tibble with added columns:
#'   `home_key_out`, `away_key_out`, `home_value_missing_pct`,
#'   `away_value_missing_pct`, `availability_advantage`.
#' @family features
#' @export
add_player_availability <- function(matches,
                                    injuries_df,
                                    suspensions_df,
                                    squad_values_df,
                                    top_n = 5L) {
  rlang::check_required(matches)
  if (!all(c("home_team", "away_team") %in% colnames(matches))) {
    cli::cli_abort("{.arg matches} must have {.code home_team} and {.code away_team} columns.")
  }

  # Compute availability for each unique team
  all_teams <- unique(c(matches$home_team, matches$away_team))

  availability_cache <- lapply(all_teams, function(tm) {
    key_players_unavailable(
      team = tm,
      injuries_df = injuries_df,
      suspensions_df = suspensions_df,
      squad_values_df = squad_values_df,
      top_n = top_n
    )
  })
  names(availability_cache) <- all_teams

  # Add features (use unname to avoid named vector issues)
  matches |>
    dplyr::mutate(
      home_key_out = unname(vapply(.data$home_team, function(t) {
        availability_cache[[t]]$n_unavailable
      }, integer(1))),
      away_key_out = unname(vapply(.data$away_team, function(t) {
        availability_cache[[t]]$n_unavailable
      }, integer(1))),
      home_value_missing_pct = unname(vapply(.data$home_team, function(t) {
        availability_cache[[t]]$pct_value_missing
      }, numeric(1))),
      away_value_missing_pct = unname(vapply(.data$away_team, function(t) {
        availability_cache[[t]]$pct_value_missing
      }, numeric(1))),
      availability_advantage = .data$away_value_missing_pct - .data$home_value_missing_pct
    )
}


# ---- Internal standardisation helpers ----

#' Standardise injury data from worldfootballR
#' @noRd
standardise_injuries <- function(raw, country, start_year) {
  # Column names may vary; handle flexibly
  player_col <- intersect(c("player_name", "Player", "player"), colnames(raw))[[1]]
  team_col <- intersect(c("club", "team", "Team", "squad"), colnames(raw))
  pos_col <- intersect(c("position", "Position"), colnames(raw))
  injury_col <- intersect(c("injury", "Injury", "reason"), colnames(raw))
  since_col <- intersect(c("injured_since", "since", "Since", "date"), colnames(raw))
  return_col <- intersect(c("expected_return", "return", "Return", "until"), colnames(raw))
  days_col <- intersect(c("days_injured", "days", "Days"), colnames(raw))
  value_col <- intersect(c("market_value", "Market Value", "player_market_value_euro"), colnames(raw))

  tibble::tibble(
    player_name = as.character(raw[[player_col]]),
    team = if (length(team_col)) as.character(raw[[team_col[[1]]]]) else NA_character_,
    position = if (length(pos_col)) as.character(raw[[pos_col[[1]]]]) else NA_character_,
    injury = if (length(injury_col)) as.character(raw[[injury_col[[1]]]]) else NA_character_,
    injured_since = if (length(since_col)) as.Date(raw[[since_col[[1]]]]) else as.Date(NA),
    expected_return = if (length(return_col)) as.Date(raw[[return_col[[1]]]]) else as.Date(NA),
    days_injured = if (length(days_col)) as.integer(raw[[days_col[[1]]]]) else NA_integer_,
    market_value_eur = if (length(value_col)) parse_transfer_fee(as.character(raw[[value_col[[1]]]])) else NA_real_,
    country = country,
    season = paste0(
      formatC(start_year %% 100, width = 2, flag = "0"),
      formatC((start_year + 1L) %% 100, width = 2, flag = "0")
    )
  )
}

#' Standardise suspension data from worldfootballR
#' @noRd
standardise_suspensions <- function(raw, country, start_year) {
  player_col <- intersect(c("player_name", "Player", "player"), colnames(raw))[[1]]
  team_col <- intersect(c("club", "team", "Team", "squad"), colnames(raw))
  pos_col <- intersect(c("position", "Position"), colnames(raw))
  reason_col <- intersect(c("reason", "Reason", "type", "Type"), colnames(raw))
  games_col <- intersect(c("games", "Games", "matches", "games_remaining"), colnames(raw))
  value_col <- intersect(c("market_value", "Market Value", "player_market_value_euro"), colnames(raw))

  tibble::tibble(
    player_name = as.character(raw[[player_col]]),
    team = if (length(team_col)) as.character(raw[[team_col[[1]]]]) else NA_character_,
    position = if (length(pos_col)) as.character(raw[[pos_col[[1]]]]) else NA_character_,
    suspension_type = if (length(reason_col)) as.character(raw[[reason_col[[1]]]]) else NA_character_,
    games_remaining = if (length(games_col)) as.integer(raw[[games_col[[1]]]]) else NA_integer_,
    market_value_eur = if (length(value_col)) parse_transfer_fee(as.character(raw[[value_col[[1]]]])) else NA_real_,
    country = country,
    season = paste0(
      formatC(start_year %% 100, width = 2, flag = "0"),
      formatC((start_year + 1L) %% 100, width = 2, flag = "0")
    )
  )
}
