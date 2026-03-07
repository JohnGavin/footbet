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

  # Read with explicit column types
  raw <- readr::read_csv(
    file_path,
    col_types = fd_match_col_spec(),
    locale = readr::locale(encoding = "latin1"),
    na = c("", "NA", "N/A", "n/a", "-", "NULL"),
    show_col_types = FALSE,
    name_repair = "check_unique"
  )

  # Check for parse problems
  parsing_problems <- readr::problems(raw)
  if (nrow(parsing_problems) > 0L) {
    cli::cli_inform(c(
      "i" = "{nrow(parsing_problems)} parse issue(s) in {.file {basename(file_path)}}",
      "i" = "Use readr::problems() to inspect"
    ))
  }

  if (nrow(raw) == 0L) {
    cli::cli_warn("Empty CSV: {.file {file_path}}")
    return(tibble::tibble())
  }

  # Parse date - football-data.co.uk uses DD/MM/YYYY or DD/MM/YY
  match_date <- lubridate::dmy(raw[["Date"]])

  n_rows <- nrow(raw)

  result <- tibble::tibble(
    league_code = league_code,
    season      = season,
    match_date  = match_date,
    home_team   = trimws(raw[["HomeTeam"]]),
    away_team   = trimws(raw[["AwayTeam"]]),
    fthg        = extract_int_col(raw, "FTHG", n_rows),
    ftag        = extract_int_col(raw, "FTAG", n_rows),
    ftr         = extract_char_col(raw, "FTR", n_rows),
    hthg        = extract_int_col(raw, "HTHG", n_rows),
    htag        = extract_int_col(raw, "HTAG", n_rows),
    htr         = extract_char_col(raw, "HTR", n_rows),
    # Match stats
    hs  = extract_int_col(raw, "HS", n_rows),
    as_ = extract_int_col(raw, "AS", n_rows),
    hst = extract_int_col(raw, "HST", n_rows),
    ast = extract_int_col(raw, "AST", n_rows),
    hc  = extract_int_col(raw, "HC", n_rows),
    ac  = extract_int_col(raw, "AC", n_rows),
    hf  = extract_int_col(raw, "HF", n_rows),
    af  = extract_int_col(raw, "AF", n_rows),
    hy  = extract_int_col(raw, "HY", n_rows),
    ay  = extract_int_col(raw, "AY", n_rows),
    hr  = extract_int_col(raw, "HR", n_rows),
    ar  = extract_int_col(raw, "AR", n_rows)
  )

  result$match_id <- make_match_id(
    result$league_code, result$match_date,
    result$home_team, result$away_team
  )

  # Preserve problems attribute for downstream validation
  attr(result, "problems") <- parsing_problems

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

  raw <- readr::read_csv(
    file_path,
    col_types = fd_odds_col_spec(),
    locale = readr::locale(encoding = "latin1"),
    na = c("", "NA", "N/A", "n/a", "-", "NULL"),
    show_col_types = FALSE,
    name_repair = "check_unique"
  )

  # Check for parse problems
  parsing_problems <- readr::problems(raw)
  if (nrow(parsing_problems) > 0L) {
    cli::cli_inform(c(
      "i" = "{nrow(parsing_problems)} parse issue(s) in odds from {.file {basename(file_path)}}",
      "i" = "Use readr::problems() to inspect"
    ))
  }

  if (nrow(raw) == 0L) return(tibble::tibble())

  n_rows <- nrow(raw)
  match_date <- lubridate::dmy(raw[["Date"]])

  match_id <- make_match_id(
    league_code, match_date,
    trimws(raw[["HomeTeam"]]), trimws(raw[["AwayTeam"]])
  )

  result <- tibble::tibble(
    match_id    = match_id,
    # Pinnacle 1X2
    psh         = extract_num_col(raw, "PSH", n_rows),
    psd         = extract_num_col(raw, "PSD", n_rows),
    psa         = extract_num_col(raw, "PSA", n_rows),
    # Pinnacle Asian Handicap
    pahh        = extract_num_col(raw, "PAHH", n_rows),
    paha        = extract_num_col(raw, "PAHA", n_rows),
    ah_line     = extract_num_col(raw, "AHh", n_rows),
    # Pinnacle Over/Under 2.5
    p_over25    = extract_num_col(raw, "P>2.5", n_rows),
    p_under25   = extract_num_col(raw, "P<2.5", n_rows),
    # Market aggregates
    max_h       = extract_num_col(raw, "MaxH", n_rows),
    max_d       = extract_num_col(raw, "MaxD", n_rows),
    max_a       = extract_num_col(raw, "MaxA", n_rows),
    avg_h       = extract_num_col(raw, "AvgH", n_rows),
    avg_d       = extract_num_col(raw, "AvgD", n_rows),
    avg_a       = extract_num_col(raw, "AvgA", n_rows)
  )

  # Preserve problems attribute for downstream validation
  attr(result, "problems") <- parsing_problems

  result
}


# ---- Column Specifications ----

#' Column specification for football-data.co.uk match CSVs
#'
#' Defines explicit types for all expected columns. Unknown columns
#' default to character to avoid silent coercion issues.
#'
#' @return A readr col_spec object.
#' @noRd
fd_match_col_spec <- function() {
  readr::cols(
    # Required columns
    Date = readr::col_character(),
    HomeTeam = readr::col_character(),
    AwayTeam = readr::col_character(),
    FTHG = readr::col_integer(),
    FTAG = readr::col_integer(),
    FTR = readr::col_character(),
    # Half-time (optional)
    HTHG = readr::col_integer(),
    HTAG = readr::col_integer(),
    HTR = readr::col_character(),
    # Match stats (optional)
    HS = readr::col_integer(),
    AS = readr::col_integer(),
    HST = readr::col_integer(),
    AST = readr::col_integer(),
    HC = readr::col_integer(),
    AC = readr::col_integer(),
    HF = readr::col_integer(),
    AF = readr::col_integer(),
    HY = readr::col_integer(),
    AY = readr::col_integer(),
    HR = readr::col_integer(),
    AR = readr::col_integer(),
    # All other columns default to character
    .default = readr::col_character()
  )
}

#' Column specification for football-data.co.uk odds CSVs
#'
#' Defines explicit types for odds columns. Numeric columns are
#' parsed as double since odds have decimal precision.
#'
#' @return A readr col_spec object.
#' @noRd
fd_odds_col_spec <- function() {
  readr::cols(
    # Match identifiers
    Date = readr::col_character(),
    HomeTeam = readr::col_character(),
    AwayTeam = readr::col_character(),
    # Pinnacle 1X2
    PSH = readr::col_double(),
    PSD = readr::col_double(),
    PSA = readr::col_double(),
    # Pinnacle Asian Handicap
    PAHH = readr::col_double(),
    PAHA = readr::col_double(),
    AHh = readr::col_double(),
    # Pinnacle Over/Under
    `P>2.5` = readr::col_double(),
    `P<2.5` = readr::col_double(),
    # Market aggregates
    MaxH = readr::col_double(),
    MaxD = readr::col_double(),
    MaxA = readr::col_double(),
    AvgH = readr::col_double(),
    AvgD = readr::col_double(),
    AvgA = readr::col_double(),
    # All other columns default to character
    .default = readr::col_character()
  )
}


# ---- Internal helpers ----

#' Safely extract an integer column from a data frame
#'
#' Returns the column if it exists, otherwise returns NA_integer_ vector.
#'
#' @param df Data frame.
#' @param col Column name.
#' @param n_rows Number of rows (used when column is missing).
#' @return Integer column vector or NA vector.
#' @noRd
extract_int_col <- function(df, col, n_rows) {
  if (col %in% colnames(df)) {
    df[[col]]
  } else {
    rep(NA_integer_, n_rows)
  }
}

#' Safely extract a character column from a data frame
#'
#' Returns the column if it exists, otherwise returns NA_character_ vector.
#'
#' @param df Data frame.
#' @param col Column name.
#' @param n_rows Number of rows (used when column is missing).
#' @return Character column vector or NA vector.
#' @noRd
extract_char_col <- function(df, col, n_rows) {
  if (col %in% colnames(df)) {
    as.character(df[[col]])
  } else {
    rep(NA_character_, n_rows)
  }
}

#' Safely extract a numeric column from a data frame
#'
#' Returns the column if it exists, otherwise returns NA_real_ vector.
#'
#' @param df Data frame.
#' @param col Column name.
#' @param n_rows Number of rows (used when column is missing).
#' @return Numeric column vector or NA vector.
#' @noRd
extract_num_col <- function(df, col, n_rows) {
  if (col %in% colnames(df)) {
    df[[col]]
  } else {
    rep(NA_real_, n_rows)
  }
}
