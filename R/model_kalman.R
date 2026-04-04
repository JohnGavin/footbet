#' Kalman Filter for Dynamic Team Strength Estimation
#'
#' Tracks team attack and defence strengths as hidden states that
#' evolve smoothly over time, using xG (or goals) as observations.
#'
#' @name kalman
#' @family models
NULL

#' Single-step Kalman update
#'
#' @param state Numeric vector. Current state estimate.
#' @param P Numeric matrix. State covariance.
#' @param observation Numeric. Observed value (xG or goals).
#' @param H Numeric vector. Observation model (maps state to observation).
#' @param Q Numeric matrix. Process noise covariance.
#' @param R Numeric. Observation noise variance.
#' @return A list with `state`, `P` (updated covariance), `innovation`.
#' @family models
#' @export
kalman_update <- function(state, P, observation, H, Q, R) {
  # Predict (random walk: F = I)
  state_pred <- state
  P_pred <- P + Q

  # Innovation
  H_mat <- matrix(H, nrow = 1)
  y_hat <- as.numeric(H_mat %*% state_pred)
  S <- as.numeric(H_mat %*% P_pred %*% t(H_mat)) + R
  K <- P_pred %*% t(H_mat) / S

  # Update
  state_new <- state_pred + as.numeric(K) * (observation - y_hat)
  P_new <- (diag(length(state)) - K %*% H_mat) %*% P_pred

  list(state = state_new, P = P_new, innovation = observation - y_hat)
}

#' Run Kalman filter over a season for one league
#'
#' Processes matches chronologically, updating team strengths after
#' each match. Each team has two state variables: attack and defence.
#'
#' @param matches Tibble with `match_date`, `home_team`, `away_team`,
#'   `home_xg` (or `fthg`), `away_xg` (or `ftag`). Must be sorted by date.
#' @param sigma_process Numeric. Process noise SD (default 0.05).
#'   Controls how fast team strength can change between matches.
#' @param sigma_obs Numeric. Observation noise SD (default 0.7).
#'   Single-match xG/goals noise.
#' @param use_xg Logical. If TRUE, use `home_xg`/`away_xg` columns.
#'   If FALSE, use `fthg`/`ftag` (default TRUE).
#' @return A tibble with `team`, `match_date`, `matchday`,
#'   `attack`, `defence` (pre-match strength estimates).
#' @family models
#' @export
kalman_strengths <- function(matches,
                             sigma_process = 0.05,
                             sigma_obs = 0.7,
                             use_xg = TRUE) {
  rlang::check_required(matches)

  # Choose observation columns
  if (use_xg && all(c("home_xg", "away_xg") %in% names(matches))) {
    home_col <- "home_xg"
    away_col <- "away_xg"
  } else {
    home_col <- "fthg"
    away_col <- "ftag"
  }

  matches <- matches |>
    dplyr::filter(!is.na(.data[[home_col]]), !is.na(.data[[away_col]])) |>
    dplyr::arrange(.data$match_date)

  if (nrow(matches) == 0L) {
    return(tibble::tibble(
      team = character(), match_date = as.Date(character()),
      attack = double(), defence = double()
    ))
  }

  teams <- sort(unique(c(matches$home_team, matches$away_team)))
  n_teams <- length(teams)
  team_idx <- stats::setNames(seq_along(teams), teams)

  # State: [attack_1, ..., attack_n, defence_1, ..., defence_n]
  state <- rep(0, 2 * n_teams)
  P <- diag(1, 2 * n_teams)
  Q <- diag(sigma_process^2, 2 * n_teams)
  R <- sigma_obs^2

  # Record pre-match strengths
  results <- vector("list", nrow(matches) * 2L)
  idx <- 1L

  for (i in seq_len(nrow(matches))) {
    ht <- matches$home_team[i]
    at <- matches$away_team[i]
    h_obs <- matches[[home_col]][i]
    a_obs <- matches[[away_col]][i]
    md <- if ("matchday" %in% names(matches)) matches$matchday[i] else i

    hi <- team_idx[ht]
    ai <- team_idx[at]

    # Record PRE-match strengths
    results[[idx]] <- list(
      team = ht, match_date = matches$match_date[i], matchday = md,
      attack = state[hi], defence = state[n_teams + hi]
    )
    results[[idx + 1L]] <- list(
      team = at, match_date = matches$match_date[i], matchday = md,
      attack = state[ai], defence = state[n_teams + ai]
    )
    idx <- idx + 2L

    # Update 1: home goals observed = f(home_attack, away_defence)
    H_home <- rep(0, 2 * n_teams)
    H_home[hi] <- 1          # home attack
    H_home[n_teams + ai] <- 1  # away defence (higher = leaks more)
    upd_h <- kalman_update(state, P, h_obs, H_home, Q, R)

    # Update 2: away goals observed = f(away_attack, home_defence)
    H_away <- rep(0, 2 * n_teams)
    H_away[ai] <- 1          # away attack
    H_away[n_teams + hi] <- 1  # home defence
    upd_a <- kalman_update(upd_h$state, upd_h$P, a_obs, H_away, Q, R)

    state <- upd_a$state
    P <- upd_a$P
  }

  dplyr::bind_rows(results)
}
