#' Download a CSV from football-data.co.uk
#'
#' Downloads match data for a single league and season. Files are cached
#' locally to avoid repeated downloads.
#'
#' @param league_code Character. League code (e.g. "E0").
#' @param season Character. 4-digit season code (e.g. "2324").
#' @param cache_dir Character. Directory to store downloaded CSVs.
#'   Defaults to `inst/extdata/raw`.
#' @param overwrite Logical. Re-download even if cached? Default `FALSE`.
#' @return Character path to the downloaded CSV file (invisibly).
#' @family data-acquisition
#' @export
download_fd_csv <- function(league_code,
                            season,
                            cache_dir = here::here("inst", "extdata", "raw"),
                            overwrite = FALSE) {
  rlang::check_required(league_code)
  rlang::check_required(season)

  if (!dir.exists(cache_dir)) dir.create(cache_dir, recursive = TRUE)

  dest <- file.path(cache_dir, paste0(league_code, "_", season, ".csv"))

  if (file.exists(dest) && !overwrite) {
    cli::cli_alert_info("Using cached {.file {basename(dest)}}")
    return(invisible(dest))
  }

  url <- fd_url(league_code, season)
  cli::cli_alert("Downloading {.url {url}}")

  req <- httr2::request(url) |>
    httr2::req_retry(max_tries = 3, backoff = ~2) |>
    httr2::req_error(is_error = function(resp) FALSE)

  resp <- httr2::req_perform(req)

  if (httr2::resp_status(resp) != 200L) {
    cli::cli_warn(c(
      "!" = "HTTP {httr2::resp_status(resp)} for {.val {league_code}} season {.val {season}}.",
      "i" = "File not downloaded."
    ))
    return(invisible(NULL))
  }

  writeBin(httr2::resp_body_raw(resp), dest)
  cli::cli_alert_success("Saved {.file {basename(dest)}}")
  invisible(dest)
}

#' Download all target league/season combinations
#'
#' @param leagues A tibble with column `league_code`, as from [target_leagues()].
#' @param seasons Character vector of season codes, as from [target_seasons()].
#' @param cache_dir Character. Cache directory.
#' @param delay Numeric. Seconds to pause between requests (rate limiting).
#' @return A tibble with columns `league_code`, `season`, `file_path`.
#' @family data-acquisition
#' @export
download_all_fd <- function(leagues = target_leagues(),
                            seasons = target_seasons(),
                            cache_dir = here::here("inst", "extdata", "raw"),
                            delay = 1) {
  grid <- tidyr::expand_grid(
    league_code = leagues$league_code,
    season = seasons
  )

  paths <- character(nrow(grid))

  for (i in seq_len(nrow(grid))) {
    paths[[i]] <- download_fd_csv(
      grid$league_code[[i]],
      grid$season[[i]],
      cache_dir = cache_dir
    ) %||% NA_character_
    if (i < nrow(grid)) Sys.sleep(delay)
  }

  grid$file_path <- paths
  grid
}
