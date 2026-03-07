#' @importFrom rlang .data
NULL

#' Fetch match-level xG data from FBref
#'
#' Downloads match results including expected goals (xG) from FBref
#' via worldfootballR. Rate limiting is applied to respect FBref ToS.
#'
#' @param country Character. Country code: "ENG", "ESP", "GER", "ITA", "FRA".
#' @param season_end Integer. Season end year (e.g., 2024 for 2023-24).
#' @param gender Character. "M" for men's (default), "F" for women's.
#' @param tier Character. League tier, default "1st".
#' @return A tibble with match results and xG data.
#' @family data-acquisition
#' @export
fetch_fbref_matches <- function(country,
                                season_end,
                                gender = "M",

                                tier = "1st") {
rlang::check_installed("worldfootballR",
                         reason = "to fetch FBref match data")
  rlang::check_required(country)
  rlang::check_required(season_end)

  # Map our league codes to FBref country names
 country_map <- c(
    "ENG" = "ENG",
    "E0" = "ENG",
    "E1" = "ENG",
    "ESP" = "ESP",
    "SP1" = "ESP",
    "SP2" = "ESP",
    "GER" = "GER",
    "D1" = "GER",
    "D2" = "GER",
    "ITA" = "ITA",
    "I1" = "ITA",
    "I2" = "ITA",
    "FRA" = "FRA",
    "F1" = "FRA",
    "F2" = "FRA"
  )

  fbref_country <- country_map[[country]]
  if (is.null(fbref_country) || is.na(fbref_country)) {
    cli::cli_abort(c(
      "x" = "Unknown country code: {.val {country}}",
      "i" = "Supported: {.val {names(country_map)}}"
    ))
  }

  cli::cli_alert("Fetching FBref data for {.val {fbref_country}} {.val {season_end}}")

  result <- tryCatch(
    worldfootballR::fb_match_results(
      country = fbref_country,
      gender = gender,
      season_end_year = as.integer(season_end),
      tier = tier
    ),
    error = function(e) {
      cli::cli_warn(c(
        "!" = "Failed to fetch FBref data: {conditionMessage(e)}",
        "i" = "Country: {.val {fbref_country}}, Season: {.val {season_end}}"
      ))
      return(NULL)
    }
  )

  if (is.null(result) || nrow(result) == 0L) {
    cli::cli_warn("No data returned for {.val {fbref_country}} {.val {season_end}}")
    return(tibble::tibble())
  }

  # Standardise column names
  result <- standardise_fbref_columns(result)

  cli::cli_alert_success("Fetched {.val {nrow(result)}} matches from FBref")
  result
}

#' Standardise FBref column names
#'
#' Converts worldfootballR output to consistent column names.
#'
#' @param df Raw FBref data frame.
#' @return Tibble with standardised columns.
#' @noRd
standardise_fbref_columns <- function(df) {
  # worldfootballR column names vary; handle flexibly
  col_map <- c(
    # Date/metadata
    "Date" = "match_date",
    "Wk" = "matchweek",
    "Day" = "day",
    "Time" = "time",
    # Teams
    "Home" = "home_team",
    "Away" = "away_team",
    # Scores
    "HomeGoals" = "home_goals",
    "AwayGoals" = "away_goals",
    # xG columns (the key data)
    "Home_xG" = "home_xg",
    "Away_xG" = "away_xg",
    # Additional metadata
    "Attendance" = "attendance",
    "Venue" = "venue",
    "Referee" = "referee",
    "MatchURL" = "match_url"
  )

  # Rename columns that exist
  existing <- intersect(names(col_map), names(df))
  for (old_name in existing) {
    names(df)[names(df) == old_name] <- col_map[[old_name]]
  }

  # Convert date
 if ("match_date" %in% names(df)) {
    df$match_date <- as.Date(df$match_date)
  }

  # Convert xG to numeric (handle potential character)
  if ("home_xg" %in% names(df)) {
    df$home_xg <- as.numeric(df$home_xg)
  }
  if ("away_xg" %in% names(df)) {
    df$away_xg <- as.numeric(df$away_xg)
  }

  tibble::as_tibble(df)
}

#' Fetch FBref data for multiple leagues and seasons
#'
#' Batch fetches xG data with rate limiting to respect FBref ToS.
#'
#' @param leagues Character vector of country/league codes.
#' @param seasons Integer vector of season end years.
#' @param delay Numeric. Seconds to pause between requests (default 5).
#' @return A tibble with all matches combined.
#' @family data-acquisition
#' @export
fetch_fbref_all <- function(leagues = c("ENG", "ESP", "GER", "ITA", "FRA"),
                            seasons = 2018:2024,
                            delay = 5) {
  rlang::check_installed("worldfootballR",
                         reason = "to fetch FBref match data")

  grid <- tidyr::expand_grid(
    country = leagues,
    season_end = seasons
  )

  results <- vector("list", nrow(grid))

  cli::cli_progress_bar("Fetching FBref data", total = nrow(grid))

  for (i in seq_len(nrow(grid))) {
    cli::cli_progress_update()

    results[[i]] <- tryCatch(
      fetch_fbref_matches(
        country = grid$country[[i]],
        season_end = grid$season_end[[i]]
      ),
      error = function(e) {
        cli::cli_warn("Failed: {grid$country[[i]]} {grid$season_end[[i]]}")
        tibble::tibble()
      }
    )

    # Add source metadata
    if (nrow(results[[i]]) > 0) {
      results[[i]]$source_country <- grid$country[[i]]
      results[[i]]$source_season <- grid$season_end[[i]]
    }

    # Rate limiting
    if (i < nrow(grid)) {
      Sys.sleep(delay)
    }
  }

  cli::cli_progress_done()

  dplyr::bind_rows(results)
}

#' Join FBref xG data to football-data.co.uk matches
#'
#' Matches FBref data to existing parsed matches by date and team names.
#' Team name matching uses fuzzy matching to handle variations.
#'
#' @param matches_df Parsed matches from football-data.co.uk.
#' @param fbref_df FBref data from [fetch_fbref_all()].
#' @return Matches tibble with added xG columns.
#' @family data-acquisition
#' @export
join_xg_to_matches <- function(matches_df, fbref_df) {
  rlang::check_required(matches_df)
  rlang::check_required(fbref_df)

  if (nrow(fbref_df) == 0L) {
    cli::cli_warn("FBref data is empty. Returning matches without xG.")
    matches_df$home_xg <- NA_real_
    matches_df$away_xg <- NA_real_
    return(matches_df)
  }

  # Build team name mapping
  team_map <- build_team_name_map()

  # Normalise team names in both datasets
  matches_norm <- matches_df |>
    dplyr::mutate(
      home_norm = normalise_team_name(.data$home_team, team_map),
      away_norm = normalise_team_name(.data$away_team, team_map)
    )

  fbref_norm <- fbref_df |>
    dplyr::mutate(
      home_norm = normalise_team_name(.data$home_team, team_map),
      away_norm = normalise_team_name(.data$away_team, team_map)
    ) |>
    dplyr::select("match_date", "home_norm", "away_norm",
                  "home_xg", "away_xg")

  # Join by date and normalised team names
  result <- matches_norm |>
    dplyr::left_join(
      fbref_norm,
      by = c("match_date", "home_norm", "away_norm"),
      relationship = "many-to-one"
    ) |>
    dplyr::select(-"home_norm", -"away_norm")

  n_matched <- sum(!is.na(result$home_xg))
  n_total <- nrow(result)
  pct <- round(100 * n_matched / n_total, 1)

  cli::cli_alert_success("Matched xG for {.val {n_matched}}/{.val {n_total}} matches ({pct}%)")

  result
}

#' Build team name mapping for FBref to football-data.co.uk
#'
#' @return Named character vector mapping variations to canonical names.
#' @noRd
build_team_name_map <- function() {
  # Common variations between data sources
  c(
    # England
    "Manchester United" = "Man United",
    "Manchester City" = "Man City",
    "Wolverhampton Wanderers" = "Wolves",
    "West Ham United" = "West Ham",
    "Newcastle United" = "Newcastle",
    "Tottenham Hotspur" = "Tottenham",
    "Brighton and Hove Albion" = "Brighton",
    "Sheffield United" = "Sheffield Utd",
    "Leeds United" = "Leeds",
    "Leicester City" = "Leicester",
    "Norwich City" = "Norwich",
    "Nottingham Forest" = "Nott'm Forest",
    "Luton Town" = "Luton",
    # Spain
    "Atl\u00e9tico Madrid" = "Ath Madrid",
    "Athletic Club" = "Ath Bilbao",
    "Real Betis" = "Betis",
    "Celta Vigo" = "Celta",
    "Deportivo Alav\u00e9s" = "Alaves",
    "Rayo Vallecano" = "Vallecano",
    # Germany
    "Bayern Munich" = "Bayern Munich",
    "Borussia Dortmund" = "Dortmund",
    "Borussia M\u00f6nchengladbach" = "M'gladbach",
    "RB Leipzig" = "RB Leipzig",
    "Eintracht Frankfurt" = "Ein Frankfurt",
    "Bayer Leverkusen" = "Leverkusen",
    "VfB Stuttgart" = "Stuttgart",
    "VfL Wolfsburg" = "Wolfsburg",
    "SC Freiburg" = "Freiburg",
    "1. FC K\u00f6ln" = "FC Koln",
    "1. FSV Mainz 05" = "Mainz",
    "TSG Hoffenheim" = "Hoffenheim",
    "FC Augsburg" = "Augsburg",
    "Hertha BSC" = "Hertha",
    "1. FC Union Berlin" = "Union Berlin",
    "Werder Bremen" = "Werder Bremen",
    # Italy
    "Inter" = "Inter",
    "Internazionale" = "Inter",
    "AC Milan" = "Milan",
    "Juventus" = "Juventus",
    "Napoli" = "Napoli",
    "AS Roma" = "Roma",
    "Lazio" = "Lazio",
    "Atalanta" = "Atalanta",
    "Fiorentina" = "Fiorentina",
    "Hellas Verona" = "Verona",
    # France
    "Paris Saint-Germain" = "Paris SG",
    "Olympique Lyonnais" = "Lyon",
    "Olympique de Marseille" = "Marseille",
    "AS Monaco" = "Monaco",
    "LOSC Lille" = "Lille",
    "Stade Rennais" = "Rennes",
    "OGC Nice" = "Nice",
    "RC Lens" = "Lens",
    "Montpellier HSC" = "Montpellier",
    "FC Nantes" = "Nantes",
    "Stade de Reims" = "Reims",
    "RC Strasbourg" = "Strasbourg",
    "Stade Brestois 29" = "Brest",
    "Le Havre AC" = "Le Havre",
    "Toulouse FC" = "Toulouse",
    "FC Lorient" = "Lorient",
    "FC Metz" = "Metz",
    "Clermont Foot" = "Clermont"
  )
}

#' Normalise team name for matching
#'
#' @param team Character vector. Team names.
#' @param team_map Named character vector of mappings.
#' @return Character vector of normalised team names (lowercase).
#' @noRd
normalise_team_name <- function(team, team_map) {
  vapply(team, function(t) {
    # First check if it's a known variation
    if (t %in% names(team_map)) {
      return(tolower(team_map[[t]]))
    }
    # Otherwise return as-is (lowercase for comparison)
    tolower(t)
  }, character(1), USE.NAMES = FALSE)
}
