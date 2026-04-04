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

#' Dixon-Coles correction factor for low-scoring games
#'
#' Multiplies bivariate Poisson probabilities for scorelines 0-0, 1-0,
#' 0-1, and 1-1 by a correction factor tau that accounts for the
#' negative correlation between goals in low-scoring matches.
#'
#' @param home_goals Integer. Home goals (0 or 1 for correction, else 1).
#' @param away_goals Integer. Away goals (0 or 1 for correction, else 1).
#' @param lambda1 Numeric. Home expected goals.
#' @param lambda2 Numeric. Away expected goals.
#' @param rho Numeric. Correlation parameter (typically -0.10 to -0.15).
#' @return Numeric. Multiplicative correction factor.
#' @family models
#' @export
dc_tau <- function(home_goals, away_goals, lambda1, lambda2, rho) {
  if (home_goals == 0L && away_goals == 0L) {
    return(1 - lambda1 * lambda2 * rho)
  }
  if (home_goals == 0L && away_goals == 1L) {
    return(1 + lambda1 * rho)
  }
  if (home_goals == 1L && away_goals == 0L) {
    return(1 + lambda2 * rho)
  }
  if (home_goals == 1L && away_goals == 1L) {
    return(1 - rho)
  }
  1
}

#' Build Dixon-Coles corrected score matrix
#'
#' Constructs a bivariate Poisson score probability matrix with
#' the Dixon-Coles tau correction applied to low-scoring cells.
#'
#' @param lambda1 Numeric. Home expected goals.
#' @param lambda2 Numeric. Away expected goals.
#' @param rho Numeric. Correlation parameter (default -0.13).
#' @param max_goals Integer. Maximum goals per side (default 8).
#' @return A (max_goals+1) x (max_goals+1) matrix of probabilities.
#'   Rows = home goals, columns = away goals.
#' @family models
#' @export
dc_score_matrix <- function(lambda1, lambda2, rho = -0.13, max_goals = 8L) {
  g <- 0:max_goals
  ph <- stats::dpois(g, lambda1)
  pa <- stats::dpois(g, lambda2)
  mat <- outer(ph, pa)

  # Apply DC correction to the four low-score cells
  for (h in 0:1) {
    for (a in 0:1) {
      mat[h + 1L, a + 1L] <- mat[h + 1L, a + 1L] *
        dc_tau(h, a, lambda1, lambda2, rho)
    }
  }

  # Renormalise
  mat / sum(mat)
}

#' Extract match probabilities from a score matrix
#'
#' @param mat A score matrix from [dc_score_matrix()].
#' @return A list with `prob_h`, `prob_d`, `prob_a`.
#' @family models
#' @export
score_matrix_probs <- function(mat) {
  list(
    prob_h = sum(mat[row(mat) > col(mat)]),
    prob_d = sum(diag(mat)),
    prob_a = sum(mat[row(mat) < col(mat)])
  )
}

#' Predict match outcome probabilities from OAGD model
#'
#' Given team attack/defence strengths, intercepts, and form signals,
#' computes expected goals via log-link Poisson and converts to
#' P(H), P(D), P(A) via the Skellam distribution.
#'
#' @param attack_home Numeric. Home team attack strength.
#' @param defence_home Numeric. Home team defence (higher = leaks more).
#' @param attack_away Numeric. Away team attack strength.
#' @param defence_away Numeric. Away team defence.
#' @param eta_home Numeric. Home goals intercept (log-scale).
#' @param eta_away Numeric. Away goals intercept (log-scale).
#' @param form_home Numeric. Home team form signal (default 0).
#' @param form_away Numeric. Away team form signal (default 0).
#' @param beta Numeric. Weight on form (default 0.3).
#' @return A list with `mu` (expected GD), `lambda_home`,
#'   `lambda_away`, `prob_h`, `prob_d`, `prob_a`, and
#'   `gd_dist` (tibble of GD probabilities from -8 to +8).
#' @family models
#' @export
oagd_predict_match <- function(attack_home = 0,
                               defence_home = 0,
                               attack_away = 0,
                               defence_away = 0,
                               eta_home = 0.3,
                               eta_away = 0.1,
                               form_home = 0,
                               form_away = 0,
                               beta = 0.3) {
  # Log-link Poisson: lambda = exp(intercept + attack - defence + form)
  lambda_home <- max(0.15, exp(eta_home + attack_home + defence_away + beta * form_home))
  lambda_away <- max(0.15, exp(eta_away + attack_away + defence_home + beta * form_away))
  mu <- lambda_home - lambda_away

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
          lookup <- function(col, team) {
            v <- s[[col]][s$team == team]
            if (length(v) == 0L) 0 else v[[1L]]
          }
          att_h <- lookup("attack", ht)
          def_h <- lookup("defence", ht)
          att_a <- lookup("attack", at)
          def_a <- lookup("defence", at)

          fh <- form_tbl$form[form_tbl$team == ht & form_tbl$matchday == md]
          fa <- form_tbl$form[form_tbl$team == at & form_tbl$matchday == md]
          fh <- if (length(fh) == 0L) 0 else fh[[1L]]
          fa <- if (length(fa) == 0L) 0 else fa[[1L]]

          oagd_predict_match(
            attack_home = att_h, defence_home = def_h,
            attack_away = att_a, defence_away = def_a,
            eta_home = f$eta_home, eta_away = f$eta_away,
            form_home = fh, form_away = fa, beta = beta
          )
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
