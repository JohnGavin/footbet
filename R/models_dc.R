#' Fit a Dixon-Coles model using goalmodel
#'
#' Wraps `goalmodel::goalmodel()` with the Dixon-Coles low-score
#' correction enabled and exponential time-decay weights.
#'
#' @param matches_df A tibble with `home_team`, `away_team`,
#'   `fthg`, `ftag`, `match_date`.
#' @param xi Numeric. Time-decay rate parameter (default 0.003).
#'   Higher values discount older matches more.
#' @return A goalmodel object.
#' @family models
#' @export
fit_dixon_coles <- function(matches_df, xi = 0.003) {
  rlang::check_installed("goalmodel",
    reason = "to fit Dixon-Coles models"
  )
  rlang::check_required(matches_df)

  # Compute time-decay weights
  max_date <- max(matches_df$match_date, na.rm = TRUE)
  days_ago <- as.numeric(difftime(max_date, matches_df$match_date, units = "days"))
  weights <- exp(-xi * days_ago)

  goalmodel::goalmodel(
    goals1 = matches_df$fthg,
    goals2 = matches_df$ftag,
    team1  = matches_df$home_team,
    team2  = matches_df$away_team,
    dc     = TRUE,
    weights = weights
  )
}

#' Predict match probabilities from a Dixon-Coles model
#'
#' @param model A goalmodel object from [fit_dixon_coles()].
#' @param home_team Character. Home team name.
#' @param away_team Character. Away team name.
#' @return A list with `score_matrix`, `probs_1x2`, `probs_ou25`,
#'   `probs_ah05`.
#' @family models
#' @export
predict_dc <- function(model, home_team, away_team) {
  rlang::check_installed("goalmodel")

  pred <- goalmodel::predict_result(
    model,
    team1 = home_team,
    team2 = away_team,
    return_df = TRUE
  )

  list(
    probs_1x2 = c(
      H = pred$p1,
      D = pred$pd,
      A = pred$p2
    )
  )
}
