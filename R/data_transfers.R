#' Fetch league transfers from Transfermarkt via worldfootballR
#'
#' Wraps `worldfootballR::tm_league_transfers()` with rate limiting
#' and error handling.
#'
#' @param country Character. Country name (e.g. "England").
#' @param start_year Integer. First season start year.
#' @param end_year Integer. Last season start year.
#' @param transfer_window Character. "summer" or "winter".
#' @return A tibble of transfer records.
#' @family data-acquisition
#' @export
fetch_league_transfers <- function(country,
                                   start_year = 2015L,
                                   end_year = 2025L,
                                   transfer_window = "all") {
  rlang::check_installed("worldfootballR",
    reason = "to fetch transfer data from Transfermarkt"
  )

  cli::cli_alert("Fetching transfers for {.val {country}} ({start_year}-{end_year})")
  cli::cli_alert_info("This may take several minutes due to rate limiting.")

  # TODO: Implement in PR #4
  # Will call worldfootballR::tm_league_transfers() per season
  # with rate limiting (Sys.sleep between requests)
  cli::cli_abort(c(
    "x" = "Transfer data fetching not yet implemented.",
    "i" = "Planned for PR #4."
  ))
}

#' Fetch squad market values from Transfermarkt
#'
#' @param country Character. Country name.
#' @param start_year Integer. Season start year.
#' @return A tibble with team names and squad values.
#' @family data-acquisition
#' @export
fetch_squad_values <- function(country, start_year = 2025L) {
  rlang::check_installed("worldfootballR",
    reason = "to fetch squad values from Transfermarkt"
  )

  # TODO: Implement in PR #4
  cli::cli_abort(c(
    "x" = "Squad value fetching not yet implemented.",
    "i" = "Planned for PR #4."
  ))
}
