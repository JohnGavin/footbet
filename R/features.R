#' @importFrom rlang .data
NULL

#' Compute rolling goal averages for each team
#'
#' Calculates rolling mean goals scored and conceded over a window
#' of recent matches, using only information available before each match.
#'
#' @param matches_df A tibble of match data with `match_date`, `home_team`,
#'   `away_team`, `fthg`, `ftag`.
#' @param window Integer. Number of past matches to include (default 5).
#' @return A tibble with columns `team`, `match_date`, `rolling_gf`,
#'   `rolling_ga`, `rolling_gd`.
#' @family features
#' @export
rolling_goals <- function(matches_df, window = 5L) {
  rlang::check_required(matches_df)

  # Long format: one row per team per match
  home <- matches_df |>
    dplyr::transmute(
      team = .data$home_team,
      opponent = .data$away_team,
      match_date = .data$match_date,
      goals_for = .data$fthg,
      goals_against = .data$ftag,
      is_home = TRUE
    )

  away <- matches_df |>
    dplyr::transmute(
      team = .data$away_team,
      opponent = .data$home_team,
      match_date = .data$match_date,
      goals_for = .data$ftag,
      goals_against = .data$fthg,
      is_home = FALSE
    )

  long <- dplyr::bind_rows(home, away) |>
    dplyr::arrange(.data$team, .data$match_date)

  long |>
    dplyr::group_by(.data$team) |>
    dplyr::mutate(
      rolling_gf = dplyr::lag(
        slider_mean(.data$goals_for, window),
        default = NA_real_
      ),
      rolling_ga = dplyr::lag(
        slider_mean(.data$goals_against, window),
        default = NA_real_
      ),
      rolling_gd = .data$rolling_gf - .data$rolling_ga
    ) |>
    dplyr::ungroup()
}

#' Simple sliding window mean
#'
#' @param x Numeric vector.
#' @param window Integer window size.
#' @return Numeric vector of rolling means.
#' @noRd
slider_mean <- function(x, window) {
  n <- length(x)
  result <- rep(NA_real_, n)
  for (i in seq_along(x)) {
    start <- max(1L, i - window + 1L)
    result[[i]] <- mean(x[start:i], na.rm = TRUE)
  }
  result
}

#' Convert match results to long format for Poisson modelling
#'
#' Creates a "long" dataset with one row per team per match,
#' suitable for GLM/GLMM Poisson regression.
#'
#' @param matches_df A tibble of match data.
#' @return A tibble with columns: `match_id`, `match_date`, `season`,
#'   `league_code`, `team`, `opponent`, `goals`, `home`.
#' @family features
#' @export
matches_to_long <- function(matches_df) {
  home <- matches_df |>
    dplyr::transmute(
      match_id = .data$match_id,
      match_date = .data$match_date,
      season = .data$season,
      league_code = .data$league_code,
      team = .data$home_team,
      opponent = .data$away_team,
      goals = .data$fthg,
      home = 1L
    )

  away <- matches_df |>
    dplyr::transmute(
      match_id = .data$match_id,
      match_date = .data$match_date,
      season = .data$season,
      league_code = .data$league_code,
      team = .data$away_team,
      opponent = .data$home_team,
      goals = .data$ftag,
      home = 0L
    )

  dplyr::bind_rows(home, away)
}
