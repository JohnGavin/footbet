#' Parse a football-data.co.uk CSV into standardised format
#'
#' Reads a downloaded CSV and returns a tibble with standardised column
#' names, parsed dates, and a unique match ID.
#'
#' @param file_path Character. Path to the CSV file.
#' @param league_code Character. League code for this file.
#' @param season Character. Season code for this file.
#' @return A tibble with standardised match data.
#' @family data-acquisition
#' @export
parse_fd_csv <- function(file_path, league_code, season) {
  rlang::check_required(file_path)
  if (!file.exists(file_path)) {
    cli::cli_abort("File not found: {.file {file_path}}")
  }

  raw <- utils::read.csv(file_path, stringsAsFactors = FALSE, check.names = FALSE)

  if (nrow(raw) == 0L) {
    cli::cli_warn("Empty CSV: {.file {file_path}}")
    return(tibble::tibble())
  }

  cols <- colnames(raw)

  # Parse date — football-data.co.uk uses DD/MM/YYYY or DD/MM/YY
  date_col <- raw[["Date"]]
  match_date <- lubridate::dmy(date_col)

  result <- tibble::tibble(
    league_code = league_code,
    season      = season,
    match_date  = match_date,
    home_team   = trimws(raw[["HomeTeam"]]),
    away_team   = trimws(raw[["AwayTeam"]]),
    fthg        = safe_int(raw, "FTHG"),
    ftag        = safe_int(raw, "FTAG"),
    ftr         = raw[["FTR"]],
    hthg        = safe_int(raw, "HTHG"),
    htag        = safe_int(raw, "HTAG"),
    htr         = safe_int_or_char(raw, "HTR"),
    # Match stats
    hs  = safe_int(raw, "HS"),
    as_ = safe_int(raw, "AS"),
    hst = safe_int(raw, "HST"),
    ast = safe_int(raw, "AST"),
    hc  = safe_int(raw, "HC"),
    ac  = safe_int(raw, "AC"),
    hf  = safe_int(raw, "HF"),
    af  = safe_int(raw, "AF"),
    hy  = safe_int(raw, "HY"),
    ay  = safe_int(raw, "AY"),
    hr  = safe_int(raw, "HR"),
    ar  = safe_int(raw, "AR")
  )

  result$match_id <- make_match_id(
    result$league_code, result$match_date,
    result$home_team, result$away_team
  )

  result
}

#' Parse Pinnacle odds columns from a football-data.co.uk CSV
#'
#' @param file_path Character. Path to the CSV file.
#' @param league_code Character. League code.
#' @param season Character. Season code.
#' @return A tibble with match_id and Pinnacle odds columns.
#' @family data-acquisition
#' @export
parse_fd_odds <- function(file_path, league_code, season) {
  rlang::check_required(file_path)
  if (!file.exists(file_path)) {
    cli::cli_abort("File not found: {.file {file_path}}")
  }

  raw <- utils::read.csv(file_path, stringsAsFactors = FALSE, check.names = FALSE)

  if (nrow(raw) == 0L) return(tibble::tibble())

  match_date <- lubridate::dmy(raw[["Date"]])

  match_id <- make_match_id(
    league_code, match_date,
    trimws(raw[["HomeTeam"]]), trimws(raw[["AwayTeam"]])
  )

  tibble::tibble(
    match_id    = match_id,
    # Pinnacle 1X2
    psh         = safe_num(raw, "PSH"),
    psd         = safe_num(raw, "PSD"),
    psa         = safe_num(raw, "PSA"),
    # Pinnacle Asian Handicap
    pahh        = safe_num(raw, "PAHH"),
    paha        = safe_num(raw, "PAHA"),
    ah_line     = safe_num(raw, "AHh"),
    # Pinnacle Over/Under 2.5
    p_over25    = safe_num(raw, "P>2.5"),
    p_under25   = safe_num(raw, "P<2.5"),
    # Market aggregates
    max_h       = safe_num(raw, "MaxH"),
    max_d       = safe_num(raw, "MaxD"),
    max_a       = safe_num(raw, "MaxA"),
    avg_h       = safe_num(raw, "AvgH"),
    avg_d       = safe_num(raw, "AvgD"),
    avg_a       = safe_num(raw, "AvgA")
  )
}


# ---- Internal helpers ----

#' Safely extract an integer column
#' @noRd
safe_int <- function(df, col) {
  if (col %in% colnames(df)) {
    suppressWarnings(as.integer(df[[col]]))
  } else {
    rep(NA_integer_, nrow(df))
  }
}

#' Safely extract a numeric column
#' @noRd
safe_num <- function(df, col) {
  if (col %in% colnames(df)) {
    suppressWarnings(as.numeric(df[[col]]))
  } else {
    rep(NA_real_, nrow(df))
  }
}

#' Safely extract a column that might be integer or character
#' @noRd
safe_int_or_char <- function(df, col) {
  if (col %in% colnames(df)) {
    as.character(df[[col]])
  } else {
    rep(NA_character_, nrow(df))
  }
}
