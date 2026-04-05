#' @keywords internal
"_PACKAGE"

#' Simple string similarity (bigram Jaccard)
#'
#' Computes similarity between two strings using character bigrams.
#' No external dependencies — used for fuzzy team name matching.
#'
#' @param a Character. First string.
#' @param b Character. Second string.
#' @return Numeric between 0 (no overlap) and 1 (identical bigrams).
#' @keywords internal
stringdist_sim <- function(a, b) {
  bigrams <- function(s) {
    s <- tolower(s)
    if (nchar(s) < 2L) return(s)
    vapply(seq_len(nchar(s) - 1L), function(i) substr(s, i, i + 1L), "")
  }
  mapply(function(x, y) {
    bx <- bigrams(x)
    by <- bigrams(y)
    if (length(bx) == 0L || length(by) == 0L) return(0)
    length(intersect(bx, by)) / length(union(bx, by))
  }, a, b, USE.NAMES = FALSE)
}

#' Build football-data.co.uk URL for a league/season CSV
#'
#' @param league_code Character. League code (e.g. "E0", "D1").
#' @param season Character. Season code (e.g. "2324" for 2023/24).
#' @return Character URL.
#' @family utilities
#' @export
fd_url <- function(league_code, season) {
  rlang::check_required(league_code)
  rlang::check_required(season)

  if (!rlang::is_string(league_code)) {
    cli::cli_abort("{.arg league_code} must be a single string.")
  }
  if (!rlang::is_string(season)) {
    cli::cli_abort("{.arg season} must be a single string.")
  }
  if (!grepl("^\\d{4}$", season)) {
    cli::cli_abort(c(
      "x" = "{.arg season} must be a 4-digit code like {.val 2324}.",
      "i" = "Got {.val {season}}."
    ))
  }
  base <- "https://www.football-data.co.uk/mmz4281"
  glue::glue("{base}/{season}/{league_code}.csv")
}

#' Target leagues for data acquisition
#'
#' Returns a tibble of the 10 target leagues (top 2 divisions for
#' England, Germany, Italy, Spain, France).
#'
#' @return A tibble with columns `country`, `league_code`, `division`.
#' @family utilities
#' @export
target_leagues <- function() {
  tibble::tribble(
    ~country,   ~league_code, ~division,
    "England",  "E0",         1L,
    "England",  "E1",         2L,
    "Germany",  "D1",         1L,
    "Germany",  "D2",         2L,
    "Italy",    "I1",         1L,
    "Italy",    "I2",         2L,
    "Spain",    "SP1",        1L,
    "Spain",    "SP2",        2L,
    "France",   "F1",         1L,
    "France",   "F2",         2L
  )
}

#' Target seasons for data acquisition
#'
#' @param start Integer. Start year of first season (default 2015).
#' @param end Integer. Start year of last season (default 2025).
#' @return Character vector of 4-digit season codes.
#' @family utilities
#' @export
target_seasons <- function(start = 2015L, end = 2025L) {
  if (start > end) return(character(0L))
  years <- seq(start, end)
  paste0(
    formatC(years %% 100, width = 2, flag = "0"),
    formatC((years + 1L) %% 100, width = 2, flag = "0")
  )
}

#' Generate a unique match ID
#'
#' Creates a deterministic match identifier from league, date, and teams.
#'
#' @param league_code Character.
#' @param match_date Date or character in ISO format.
#' @param home_team Character.
#' @param away_team Character.
#' @return Character match ID.
#' @family utilities
#' @export
make_match_id <- function(league_code, match_date, home_team, away_team) {
  paste(league_code, as.character(match_date), home_team, away_team, sep = "_")
}
