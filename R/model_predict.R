#' OAGD Prediction: Skellam GD Distribution
#'
#' Predicts the goal difference distribution for upcoming matches
#' using opposition-adjusted team strengths and form signals.
#'
#' @name oagd_predict
#' @family models
NULL

#' Skellam probability mass function
#'
#' Computes `P(X - Y = k)` where `X ~ Poisson(lambda1)` and
#' `Y ~ Poisson(lambda2)`, using base R `besselI()`.
#'
#' @param k Integer vector. Goal difference values.
#' @param lambda1 Numeric. Home team expected goals (must be > 0).
#' @param lambda2 Numeric. Away team expected goals (must be > 0).
#' @return Numeric vector of probabilities, same length as `k`.
#' @family models
#' @export
dskellam <- function(k, lambda1, lambda2) {
  if (lambda1 <= 0 || lambda2 <= 0) {
    cli::cli_abort("Skellam lambdas must be > 0, got {lambda1} and {lambda2}.")
  }
  exp(-(lambda1 + lambda2)) *
    (lambda1 / lambda2)^(k / 2) *
    besselI(2 * sqrt(lambda1 * lambda2), nu = abs(k))
}

#' Predict match outcome probabilities from OAGD model
#'
#' Given team strengths, home advantage, and form signals, computes
#' the expected GD and converts to P(H), P(D), P(A) via the Skellam
#' distribution.
#'
#' @param alpha_home Numeric. Home team combined strength (alpha).
#' @param alpha_away Numeric. Away team combined strength (alpha).
#' @param eta Numeric. Home advantage intercept.
#' @param form_home Numeric. Home team form signal (default 0).
#' @param form_away Numeric. Away team form signal (default 0).
#' @param beta Numeric. Weight on form difference (default 0.3).
#' @param avg_total_goals Numeric. Average total goals per match
#'   in this league (default 2.7). Used to anchor lambda sum.
#' @return A list with `mu` (expected GD), `lambda_home`,
#'   `lambda_away`, `prob_h`, `prob_d`, `prob_a`, and
#'   `gd_dist` (tibble of GD probabilities from -8 to +8).
#' @family models
#' @export
oagd_predict_match <- function(alpha_home,
                               alpha_away,
                               eta,
                               form_home = 0,
                               form_away = 0,
                               beta = 0.3,
                               avg_total_goals = 2.7) {
  # Expected GD = eta + alpha_home - alpha_away + beta * (form_h - form_a)

  mu <- eta + alpha_home - alpha_away + beta * (form_home - form_away)

  # Constrain lambdas: sum = avg_total_goals, difference = mu

  # lambda_home = (avg_total_goals + mu) / 2
  # lambda_away = (avg_total_goals - mu) / 2
  lambda_home <- max(0.15, (avg_total_goals + mu) / 2)
  lambda_away <- max(0.15, (avg_total_goals - mu) / 2)

  # Skellam GD distribution
  gd_range <- -8L:8L
  probs <- dskellam(gd_range, lambda_home, lambda_away)
  # Normalise to handle truncation at +/-8
  probs <- probs / sum(probs)

  prob_h <- sum(probs[gd_range > 0L])
  prob_d <- probs[gd_range == 0L]
  prob_a <- sum(probs[gd_range < 0L])

  list(
    mu = mu,
    lambda_home = lambda_home,
    lambda_away = lambda_away,
    prob_h = prob_h,
    prob_d = prob_d,
    prob_a = prob_a,
    gd_dist = tibble::tibble(gd = gd_range, prob = probs)
  )
}

#' Batch-predict probabilities for all matches in a dataset
#'
#' For each match, looks up team strengths from the prior matchday's
#' fit and form signals, then predicts via [oagd_predict_match()].
#'
#' @param data Tibble from [oagd_match_data()], one league-season.
#' @param fits List from [oagd_roll_fits()].
#' @param form_tbl Tibble from [oagd_form()].
#' @param beta Numeric. Form weight (default 0.3).
#' @param avg_total_goals Numeric. League average total goals.
#' @return `data` with added columns: `pred_h`, `pred_d`, `pred_a`,
#'   `mu_pred`, `lambda_home`, `lambda_away`.
#' @family models
#' @export
oagd_predict_all <- function(data, fits, form_tbl,
                             beta = 0.3, avg_total_goals = 2.7) {
  rlang::check_required(data)
  rlang::check_required(fits)
  rlang::check_required(form_tbl)

  data |>
    dplyr::mutate(
      pred = purrr::pmap(
        list(.data$matchday, .data$home_team, .data$away_team),
        function(md, ht, at) {
          # Use the fit from the PRIOR matchday (avoid lookahead)
          prior_md <- as.character(md - 1L)
          f <- fits[[prior_md]]
          if (is.null(f)) {
            return(list(
              prob_h = NA_real_, prob_d = NA_real_, prob_a = NA_real_,
              mu = NA_real_, lambda_home = NA_real_, lambda_away = NA_real_
            ))
          }

          s <- f$strengths
          ah <- s$alpha[s$team == ht]
          aa <- s$alpha[s$team == at]
          if (length(ah) == 0L) ah <- 0
          if (length(aa) == 0L) aa <- 0

          fh <- form_tbl$form[form_tbl$team == ht & form_tbl$matchday == md]
          fa <- form_tbl$form[form_tbl$team == at & form_tbl$matchday == md]
          # Take first value: a team can appear twice in a matchday when
          # fixtures are rearranged (e.g., rescheduled games same round)
          fh <- if (length(fh) == 0L) 0 else fh[[1L]]
          fa <- if (length(fa) == 0L) 0 else fa[[1L]]

          oagd_predict_match(ah, aa, f$eta, fh, fa, beta, avg_total_goals)
        }
      )
    ) |>
    dplyr::mutate(
      pred_h = purrr::map_dbl(.data$pred, "prob_h"),
      pred_d = purrr::map_dbl(.data$pred, "prob_d"),
      pred_a = purrr::map_dbl(.data$pred, "prob_a"),
      mu_pred = purrr::map_dbl(.data$pred, "mu"),
      lambda_home = purrr::map_dbl(.data$pred, "lambda_home"),
      lambda_away = purrr::map_dbl(.data$pred, "lambda_away")
    ) |>
    dplyr::select(-"pred")
}
