#' @importFrom rlang .data
NULL

# ============================================================================
# UNDERSTAT xG DATA
# ============================================================================

#' Fetch match xG data from Understat
#'
#' Downloads expected goals (xG) data for a league-season from Understat.
#' Requires the `understatr` package.
#'
#' @param league Character. League name: "EPL", "La_liga", "Bundesliga",
#'   "Serie_A", "Ligue_1", "RFPL" (Russian Premier League).
#' @param season Integer. Season start year (e.g., 2023 for 2023-24).
#' @return A tibble with match xG data.
#' @family data
#' @export
fetch_understat_xg <- function(league, season) {
  rlang::check_installed("worldfootballR",
    reason = "to fetch Understat xG data (via worldfootballR)")
  rlang::check_required(league)
  rlang::check_required(season)

  valid_leagues <- c("EPL", "La Liga", "Bundesliga", "Serie A", "Ligue 1", "RFPL")
  if (!league %in% valid_leagues) {
    cli::cli_abort(c(
      "x" = "Invalid league: {.val {league}}",
      "i" = "Valid leagues: {.val {valid_leagues}}"
    ))
  }

  cli::cli_alert_info("Fetching Understat xG for {league} {season}...")

  # Fetch via worldfootballR (replaces archived understatr package)
  results <- tryCatch(
    worldfootballR::understat_league_match_results(league, season),
    error = function(e) {
      cli::cli_abort(c(
        "x" = "Failed to fetch Understat data",
        "i" = "Error: {e$message}"
      ))
    }
  )

  if (is.null(results) || nrow(results) == 0L) {
    cli::cli_warn("No data found for {league} {season}")
    return(tibble::tibble(
      understat_id = integer(),
      match_date = as.Date(character()),
      home_team = character(),
      away_team = character(),
      home_xg = numeric(),
      away_xg = numeric(),
      home_goals = integer(),
      away_goals = integer()
    ))
  }

  # Standardize column names (worldfootballR format)
  results |>
    dplyr::transmute(
      understat_id = as.integer(.data$match_id),
      match_date = as.Date(.data$datetime),
      home_team = .data$home_team,
      away_team = .data$away_team,
      home_xg = as.numeric(.data$home_xG),
      away_xg = as.numeric(.data$away_xG),
      home_goals = as.integer(.data$home_goals),
      away_goals = as.integer(.data$away_goals),
      season = as.character(season)
    )
}

#' Map Understat team names to football-data.co.uk names
#'
#' Returns a named vector mapping Understat names to FD names.
#' This is necessary because team names differ between sources.
#'
#' @param league Character. League code ("E0", "E1", "D1", etc.).
#' @return Named character vector (Understat name -> FD name).
#' @family data
#' @export
understat_team_mapping <- function(league) {
  rlang::check_required(league)


  # EPL mappings (most common differences)
  epl <- c(
    "Manchester United" = "Man United",
    "Manchester City" = "Man City",
    "Wolverhampton Wanderers" = "Wolves",
    "Brighton" = "Brighton",
    "Newcastle United" = "Newcastle",
    "Nottingham Forest" = "Nott'm Forest",
    "West Ham" = "West Ham",
    "Tottenham" = "Tottenham",
    "Sheffield United" = "Sheffield United",
    "Luton" = "Luton"
  )

  # La Liga mappings
  laliga <- c(
    "Atletico Madrid" = "Ath Madrid",
    "Athletic Club" = "Ath Bilbao",
    "Real Betis" = "Betis",
    "Celta Vigo" = "Celta",
    "Deportivo Alaves" = "Alaves",
    "Rayo Vallecano" = "Vallecano"
  )

  # Bundesliga mappings
  bundesliga <- c(
    "Borussia Dortmund" = "Dortmund",
    "Borussia M.Gladbach" = "M'gladbach",
    "Bayern Munich" = "Bayern Munich",
    "RasenBallsport Leipzig" = "RB Leipzig",
    "Bayer Leverkusen" = "Leverkusen",
    "Eintracht Frankfurt" = "Ein Frankfurt"
  )

  # Serie A mappings
  seriea <- c(
    "AC Milan" = "Milan",
    "Inter" = "Inter",
    "Napoli" = "Napoli",
    "Hellas Verona" = "Verona"
  )

  # Ligue 1 mappings
  ligue1 <- c(
    "Paris Saint Germain" = "Paris SG",
    "Olympique Marseille" = "Marseille",
    "Olympique Lyonnais" = "Lyon"
  )

  switch(
    league,
    "E0" = epl,
    "E1" = epl,  # Same country
    "D1" = bundesliga,
    "D2" = bundesliga,
    "I1" = seriea,
    "I2" = seriea,
    "SP1" = laliga,
    "SP2" = laliga,
    "F1" = ligue1,
    "F2" = ligue1,
    character()  # Default: empty mapping
 )
}

#' Join Understat xG to match data
#'
#' Matches Understat xG data to football-data.co.uk matches by
#' date and team names, applying name mappings as needed.
#'
#' @param matches_df A tibble of match data with `match_date`,
#'   `home_team`, `away_team`.
#' @param understat_df A tibble from [fetch_understat_xg()].
#' @param league_code Character. League code for team name mapping.
#' @return The matches_df with `understat_home_xg`, `understat_away_xg` columns.
#' @family data
#' @export
join_understat_xg <- function(matches_df, understat_df, league_code = "E0") {
  rlang::check_required(matches_df)
  rlang::check_required(understat_df)

  if (nrow(understat_df) == 0L) {
    return(dplyr::mutate(
      matches_df,
      understat_home_xg = NA_real_,
      understat_away_xg = NA_real_
    ))
  }

  # Get team name mapping
  mapping <- understat_team_mapping(league_code)

  # Apply mapping to Understat data
  understat_mapped <- understat_df |>
    dplyr::mutate(
      home_team_mapped = dplyr::coalesce(
        mapping[.data$home_team],
        .data$home_team
      ),
      away_team_mapped = dplyr::coalesce(
        mapping[.data$away_team],
        .data$away_team
      )
    )

  # Join by date and team names
  result <- matches_df |>
    dplyr::left_join(
      understat_mapped |>
        dplyr::select(
          match_date = "match_date",
          home_team = "home_team_mapped",
          away_team = "away_team_mapped",
          understat_home_xg = "home_xg",
          understat_away_xg = "away_xg"
        ),
      by = c("match_date", "home_team", "away_team")
    )

  # Report match rate
  matched <- sum(!is.na(result$understat_home_xg))
  total <- nrow(result)
  pct <- round(100 * matched / total, 1)
  cli::cli_alert_success("Matched {matched}/{total} matches ({pct}%) with Understat xG")

  result
}

#' Fetch and join Understat xG for multiple seasons
#'
#' Convenience function to fetch Understat data for multiple seasons
#' and join to match data.
#'
#' @param matches_df A tibble of match data.
#' @param understat_league Character. Understat league name.
#' @param seasons Integer vector. Season start years.
#' @param fd_league_code Character. Football-data.co.uk league code.
#' @return The matches_df with Understat xG columns.
#' @family data
#' @export
add_understat_xg <- function(matches_df, understat_league, seasons,
                              fd_league_code = "E0") {
  rlang::check_required(matches_df)
  rlang::check_required(understat_league)
  rlang::check_required(seasons)

  # Fetch all seasons
  all_xg <- purrr::map(seasons, function(s) {
    tryCatch(
      fetch_understat_xg(understat_league, s),
      error = function(e) {
        cli::cli_warn("Failed to fetch {understat_league} {s}: {e$message}")
        tibble::tibble()
      }
    )
  }) |>
    dplyr::bind_rows()

  if (nrow(all_xg) == 0L) {
    cli::cli_warn("No Understat data retrieved")
    return(dplyr::mutate(
      matches_df,
      understat_home_xg = NA_real_,
      understat_away_xg = NA_real_
    ))
  }

  join_understat_xg(matches_df, all_xg, league_code = fd_league_code)
}
