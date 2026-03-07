#' Data Validation Functions
#'
#' Functions for validating parsed football match data.
#' Used by plan_data_validation.R targets.
#'
#' @name data_validation
#' @keywords internal
NULL

# Constants for expected match counts
EXPECTED_MATCHES_EPL <- 380L
EXPECTED_MATCHES_OTHER <- 306L
MIN_COVERAGE_ABORT <- 30
MIN_COVERAGE_WARN <- 80

#' Validate temporal coverage
#'
#' Checks that each league/season has sufficient match coverage.
#' Aborts if coverage falls below 30%, warns if below 80%.
#'
#' @param matches Parsed matches tibble with league_code, season columns.
#' @return List with passed flag and coverage stats tibble.
#' @noRd
validate_temporal_coverage <- function(matches) {
  if (nrow(matches) == 0L) {
    return(list(passed = TRUE, coverage = tibble::tibble()))
  }

  coverage <- matches |>
    dplyr::group_by(.data$league_code, .data$season) |>
    dplyr::summarise(
      n_actual = dplyr::n(),
      n_expected = dplyr::case_when(
        .data$league_code == "E0" ~ EXPECTED_MATCHES_EPL,
        .data$league_code == "E1" ~ 552L,
        TRUE ~ EXPECTED_MATCHES_OTHER
      ),
      coverage_pct = 100 * .data$n_actual / .data$n_expected,
      .groups = "drop"
    )

  # Abort if any coverage < 30%

abort_issues <- coverage |> dplyr::filter(.data$coverage_pct < MIN_COVERAGE_ABORT)
  if (nrow(abort_issues) > 0L) {
    cli::cli_abort(c(
      "x" = "Coverage < 30% for {nrow(abort_issues)} league/season(s)",
      "i" = "Affected: {paste(abort_issues$league_code, abort_issues$season, collapse = ', ')}"
    ))
  }

  # Warn if any coverage < 80%
  warn_issues <- coverage |> dplyr::filter(.data$coverage_pct < MIN_COVERAGE_WARN)
  if (nrow(warn_issues) > 0L) {
    cli::cli_warn(c(
      "!" = "Coverage < 80% for {nrow(warn_issues)} league/season(s)",
      "i" = "Affected: {paste(warn_issues$league_code, warn_issues$season, collapse = ', ')}"
    ))
  }

  list(passed = TRUE, coverage = coverage)
}

#' Validate no duplicate primary keys
#'
#' Checks that a data frame has no duplicate values in a key column.
#'
#' @param df Data frame to check.
#' @param key_col Name of the key column.
#' @return List with passed flag and duplicate count.
#' @noRd
validate_no_duplicates <- function(df, key_col) {
  if (nrow(df) == 0L) {
    return(list(passed = TRUE, n_duplicates = 0L))
  }

  dups <- df |>
    dplyr::group_by(.data[[key_col]]) |>
    dplyr::filter(dplyr::n() > 1L) |>
    dplyr::ungroup()

  if (nrow(dups) > 0L) {
    dup_keys <- unique(dups[[key_col]])
    cli::cli_abort(c(
      "x" = "{length(dup_keys)} duplicate {key_col}(s) found",
      "i" = "First duplicates: {paste(utils::head(dup_keys, 5), collapse = ', ')}"
    ))
  }

  list(passed = TRUE, n_duplicates = 0L)
}

#' Validate readr parse problems
#'
#' Checks that parsing didn't produce too many problems.
#' This function inspects the problems attribute added by readr.
#'
#' @param ... Parsed tibbles to check for problems.
#' @param max_problems Maximum allowed problems before warning (default 10).
#' @return List with passed flag and combined problems tibble.
#' @noRd
validate_parse_problems <- function(..., max_problems = 10L) {
  dfs <- list(...)
  all_problems <- lapply(dfs, function(df) {
    probs <- readr::problems(df)
    if (nrow(probs) > 0L) probs else NULL
  })
  all_problems <- all_problems[!vapply(all_problems, is.null, logical(1))]

  if (length(all_problems) == 0L) {
    return(list(passed = TRUE, n_problems = 0L, problems = tibble::tibble()))
  }

  combined <- dplyr::bind_rows(all_problems)
  n_probs <- nrow(combined)

  if (n_probs > max_problems) {
    cli::cli_warn(c(
      "!" = "{n_probs} parse problems detected (threshold: {max_problems})",
      "i" = "Use readr::problems() on the parsed tibbles to inspect"
    ))
  }

  list(passed = n_probs <= max_problems, n_problems = n_probs, problems = combined)
}

#' Validate value ranges
#'
#' Checks that numeric values fall within expected ranges.
#'
#' @param matches Parsed matches tibble.
#' @return List with passed flag, issue count, and issues tibble.
#' @noRd
validate_value_ranges <- function(matches) {
  if (nrow(matches) == 0L) {
    return(list(passed = TRUE, n_issues = 0L, issues = tibble::tibble()))
  }

  issues <- matches |>
    dplyr::mutate(
      .bad_fthg = !is.na(.data$fthg) & (.data$fthg < 0L | .data$fthg > 15L),
      .bad_ftag = !is.na(.data$ftag) & (.data$ftag < 0L | .data$ftag > 15L),
      .bad_date = !is.na(.data$match_date) & .data$match_date > Sys.Date() + 7L
    ) |>
    dplyr::filter(.data$.bad_fthg | .data$.bad_ftag | .data$.bad_date) |>
    dplyr::select(
      dplyr::any_of(c("match_id", "league_code", "season", "match_date",
                       "home_team", "away_team", "fthg", "ftag"))
    )

  if (nrow(issues) > 0L) {
    cli::cli_warn(c(
      "!" = "{nrow(issues)} matches with value range issues",
      "i" = "Check for scores >15, negative scores, or future dates"
    ))
  }

  list(passed = nrow(issues) == 0L, n_issues = nrow(issues), issues = issues)
}

#' Validate data freshness
#'
#' Checks that the most recent match is within expected window.
#'
#' @param matches Parsed matches tibble.
#' @param max_stale_days Maximum days since last match before warning.
#' @return List with passed flag, latest date, and staleness info.
#' @noRd
validate_data_freshness <- function(matches, max_stale_days = 14L) {
  if (nrow(matches) == 0L) {
    return(list(passed = TRUE, latest_date = NA, days_stale = NA))
  }

  latest_date <- max(matches$match_date, na.rm = TRUE)
  days_stale <- as.integer(Sys.Date() - latest_date)

  passed <- days_stale <= max_stale_days

  if (!passed) {
    cli::cli_warn(c(
      "!" = "Data is {days_stale} days old (threshold: {max_stale_days})",
      "i" = "Latest match: {format(latest_date, '%Y-%m-%d')}"
    ))
  }

  list(passed = passed, latest_date = latest_date, days_stale = days_stale)
}
