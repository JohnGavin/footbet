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
    age_at_transfer = if (length(age_col)) suppressWarnings(as.integer(raw[[age_col[[1]]]])) else NA_integer_
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
