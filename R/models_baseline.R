#' Fit a Poisson GLM baseline model
#'
#' Fits a simple Poisson GLM on goals with attack/defence strengths
#' and home advantage. This is the mandatory baseline model that all
#' advanced models must beat.
#'
#' @param long_df A long-format tibble from [matches_to_long()].
#' @return A fitted `glm` object.
#' @family models
#' @export
fit_poisson_glm <- function(long_df) {
  rlang::check_required(long_df)

  required_cols <- c("goals", "home", "team", "opponent")
  missing <- setdiff(required_cols, colnames(long_df))
  if (length(missing) > 0L) {
    cli::cli_abort("Missing columns: {.val {missing}}")
  }

  model <- stats::glm(
    goals ~ home + team + opponent,
    family = stats::poisson(),
    data = long_df,
    model = FALSE  # Don't store model frame (~54MB saved)
  )

  # Strip heavy components not needed for predict()
  model$residuals <- NULL
  model$weights <- NULL
  model$fitted.values <- NULL
  model$prior.weights <- NULL
  model$linear.predictors <- NULL
  model$effects <- NULL
  model$data <- long_df[, c("team", "opponent")]  # Keep only factor levels for predict

  model
}

#' Predict score probabilities from a Poisson model
#'
#' Given expected goals for home and away teams, computes the
#' bivariate Poisson probability matrix P(home=i, away=j).
#'
#' @param lambda_home Numeric. Expected goals for home team.
#' @param lambda_away Numeric. Expected goals for away team.
#' @param max_goals Integer. Maximum goals to consider (default 7).
#' @return A matrix of probabilities with dim `(max_goals+1, max_goals+1)`.
#' @family models
#' @export
score_matrix <- function(lambda_home, lambda_away, max_goals = 7L) {
  goals <- 0:max_goals
  p_home <- stats::dpois(goals, lambda_home)
  p_away <- stats::dpois(goals, lambda_away)

  # Outer product — assumes independence (Dixon-Coles corrects this)
  mat <- outer(p_home, p_away)
  # Normalise to account for Poisson truncation at max_goals
  mat <- mat / sum(mat)
  dimnames(mat) <- list(home = goals, away = goals)
  mat
}

#' Convert score matrix to 1X2 probabilities
#'
#' @param mat A score probability matrix from [score_matrix()].
#' @return A named numeric vector with `H`, `D`, `A` probabilities.
#' @family models
#' @export
score_matrix_to_1x2 <- function(mat) {
  n <- nrow(mat)
  p_h <- sum(mat[lower.tri(mat, diag = FALSE)])
  # lower.tri gives row > col, but we need home > away
  # In our matrix, rows = home goals, cols = away goals
  # Home win: row index > col index
  p_h <- 0
  p_d <- 0
  p_a <- 0
  for (i in seq_len(n)) {
    for (j in seq_len(n)) {
      if (i > j) p_h <- p_h + mat[i, j]
      else if (i == j) p_d <- p_d + mat[i, j]
      else p_a <- p_a + mat[i, j]
    }
  }
  c(H = p_h, D = p_d, A = p_a)
}

#' Convert score matrix to over/under 2.5 goals probabilities
#'
#' @param mat A score probability matrix from [score_matrix()].
#' @param line Numeric. Goals line (default 2.5).
#' @return A named numeric vector with `over` and `under` probabilities.
#' @family models
#' @export
score_matrix_to_ou <- function(mat, line = 2.5) {
  n <- nrow(mat)
  p_over <- 0
  for (i in seq_len(n)) {
    for (j in seq_len(n)) {
      total <- (i - 1) + (j - 1)  # 0-indexed goals
      if (total > line) p_over <- p_over + mat[i, j]
    }
  }
  c(over = p_over, under = 1 - p_over)
}

#' Convert score matrix to Asian handicap probabilities
#'
#' @param mat A score probability matrix.
#' @param line Numeric. Asian handicap line for home team (e.g. -0.5, -1).
#' @return A named numeric vector with `win`, `push`, `lose` probabilities.
#' @family models
#' @export
score_matrix_to_ah <- function(mat, line = -0.5) {
  n <- nrow(mat)
  p_win <- 0
  p_push <- 0
  p_lose <- 0

  for (i in seq_len(n)) {
    for (j in seq_len(n)) {
      home_goals <- i - 1
      away_goals <- j - 1
      margin <- home_goals - away_goals + line
      if (margin > 0) {
        p_win <- p_win + mat[i, j]
      } else if (abs(margin) < 1e-10) {
        p_push <- p_push + mat[i, j]
      } else {
        p_lose <- p_lose + mat[i, j]
      }
    }
  }
  c(win = p_win, push = p_push, lose = p_lose)
}

#' Predict match probabilities from a fitted Poisson GLM
#'
#' Uses [stats::predict()] to get expected goals (lambda) for each team,
#' then builds a score matrix and derives 1X2, O/U, and AH probabilities.
#'
#' @param model A fitted `glm` object from [fit_poisson_glm()].
#' @param home_team Character. Home team name.
#' @param away_team Character. Away team name.
#' @param max_goals Integer. Maximum goals for score matrix (default 7).
#' @return A list with `lambda_home`, `lambda_away`, `score_mat`,
#'   `probs_1x2`, `probs_ou25`, `probs_ah05`.
#' @family models
#' @export
predict_glm <- function(model, home_team, away_team, max_goals = 7L) {
  rlang::check_required(model)

  # Predict expected goals
  new_home <- data.frame(
    home = 1L,
    team = home_team,
    opponent = away_team,
    stringsAsFactors = FALSE
  )
  new_away <- data.frame(
    home = 0L,
    team = away_team,
    opponent = home_team,
    stringsAsFactors = FALSE
  )

  lambda_home <- stats::predict(model, newdata = new_home, type = "response")
  lambda_away <- stats::predict(model, newdata = new_away, type = "response")

  mat <- score_matrix(lambda_home, lambda_away, max_goals = max_goals)

  list(
    lambda_home = as.numeric(lambda_home),
    lambda_away = as.numeric(lambda_away),
    score_mat = mat,
    probs_1x2 = score_matrix_to_1x2(mat),
    probs_ou25 = score_matrix_to_ou(mat),
    probs_ah05 = score_matrix_to_ah(mat, line = -0.5)
  )
}

#' Predict 1X2 probabilities for all matches in a dataset
#'
#' Applies [predict_glm()] to each row and returns a tibble of predictions.
#'
#' @param model A fitted `glm` object from [fit_poisson_glm()].
#' @param matches_df A tibble with `match_id`, `home_team`, `away_team`.
#' @return A tibble with `match_id`, `pred_h`, `pred_d`, `pred_a`,
#'   `pred_over25`, `pred_under25`.
#' @family models
#' @export
predict_matches_glm <- function(model, matches_df) {
  rlang::check_required(model)
  if (!inherits(model, "glm")) {
    cli::cli_abort("{.arg model} must be a {.cls glm} object, not {.cls {class(model)}}.")
  }

  rlang::check_required(matches_df)

  if (nrow(matches_df) == 0L) {
    return(tibble::tibble(
      match_id = character(),
      pred_h = numeric(), pred_d = numeric(), pred_a = numeric(),
      pred_over25 = numeric(), pred_under25 = numeric()
    ))
  }

  # Get teams that the model knows about
  model_teams <- unique(c(
    levels(model$data$team),
    as.character(unique(model$data$team))
  ))

  n <- nrow(matches_df)

  # Filter to predictable matches (both teams in training data)
  known <- matches_df$home_team %in% model_teams &
    matches_df$away_team %in% model_teams
  known_idx <- which(known)

  pred_h <- rep(NA_real_, n)
  pred_d <- rep(NA_real_, n)
  pred_a <- rep(NA_real_, n)
  pred_over25 <- rep(NA_real_, n)
  pred_under25 <- rep(NA_real_, n)

  if (length(known_idx) == 0L) {
    return(tibble::tibble(
      match_id = matches_df$match_id,
      pred_h = pred_h, pred_d = pred_d, pred_a = pred_a,
      pred_over25 = pred_over25, pred_under25 = pred_under25
    ))
  }

  # Batch predict: build newdata for all known matches at once
  nd_home <- data.frame(
    home = 1L,
    team = matches_df$home_team[known_idx],
    opponent = matches_df$away_team[known_idx],
    stringsAsFactors = FALSE
  )
  nd_away <- data.frame(
    home = 0L,
    team = matches_df$away_team[known_idx],
    opponent = matches_df$home_team[known_idx],
    stringsAsFactors = FALSE
  )

  lambda_home <- tryCatch(
    stats::predict(model, newdata = nd_home, type = "response"),
    error = function(e) rep(NA_real_, length(known_idx))
  )
  lambda_away <- tryCatch(
    stats::predict(model, newdata = nd_away, type = "response"),
    error = function(e) rep(NA_real_, length(known_idx))
  )

  # Vectorized score matrix -> 1X2 and O/U computation
  max_goals <- 7L
  goals <- 0:max_goals

  for (j in seq_along(known_idx)) {
    lh <- lambda_home[j]
    la <- lambda_away[j]
    if (is.na(lh) || is.na(la)) next

    p_home <- stats::dpois(goals, lh)
    p_away <- stats::dpois(goals, la)
    mat <- outer(p_home, p_away)
    mat <- mat / sum(mat)

    # 1X2 from score matrix (vectorized)
    ng <- max_goals + 1L
    row_idx <- rep(seq_len(ng), ng)
    col_idx <- rep(seq_len(ng), each = ng)
    ph <- sum(mat[row_idx > col_idx])
    pd <- sum(mat[row_idx == col_idx])
    pa <- sum(mat[row_idx < col_idx])

    # O/U 2.5
    total_goals <- rep(goals, ng) + rep(goals, each = ng)
    p_over <- sum(mat[total_goals > 2.5])

    idx <- known_idx[j]
    pred_h[idx] <- ph
    pred_d[idx] <- pd
    pred_a[idx] <- pa
    pred_over25[idx] <- p_over
    pred_under25[idx] <- 1 - p_over
  }

  tibble::tibble(
    match_id = matches_df$match_id,
    pred_h = pred_h,
    pred_d = pred_d,
    pred_a = pred_a,
    pred_over25 = pred_over25,
    pred_under25 = pred_under25
  )
}

# ============================================================================
# CORRECT SCORE PREDICTIONS
# ============================================================================

#' Get probability for a specific scoreline
#'
#' Extracts the probability of a specific home-away scoreline from
#' a score probability matrix.
#'
#' @param mat A score probability matrix from [score_matrix()].
#' @param home_goals Integer. Home team goals.
#' @param away_goals Integer. Away team goals.
#' @return Numeric probability, or NA if scoreline is out of range.
#' @family models
#' @export
score_probability <- function(mat, home_goals, away_goals) {
  rlang::check_required(mat)
  rlang::check_required(home_goals)
  rlang::check_required(away_goals)

  max_goals <- nrow(mat) - 1L

  if (home_goals < 0 || home_goals > max_goals ||
      away_goals < 0 || away_goals > max_goals) {
    return(NA_real_)
  }

  mat[home_goals + 1L, away_goals + 1L]
}

#' Get top N most likely scorelines
#'
#' Returns the most probable scorelines from a score matrix,
#' sorted by probability.
#'
#' @param mat A score probability matrix from [score_matrix()].
#' @param n Integer. Number of top scorelines to return (default 10).
#' @return A tibble with `home_goals`, `away_goals`, `probability`,
#'   sorted by probability descending.
#' @family models
#' @export
top_scorelines <- function(mat, n = 10L) {
  rlang::check_required(mat)

  max_goals <- nrow(mat) - 1L

  # Build all scorelines
  scorelines <- expand.grid(
    home_goals = 0:max_goals,
    away_goals = 0:max_goals
  )

  scorelines$probability <- mapply(
    function(h, a) mat[h + 1L, a + 1L],
    scorelines$home_goals,
    scorelines$away_goals
  )

  # Sort and take top n
  scorelines <- scorelines[order(-scorelines$probability), ]
  scorelines <- utils::head(scorelines, n)

  tibble::tibble(
    home_goals = scorelines$home_goals,
    away_goals = scorelines$away_goals,
    probability = scorelines$probability,
    scoreline = paste0(scorelines$home_goals, "-", scorelines$away_goals)
  )
}

#' Predict correct score probabilities for a match
#'
#' Computes probabilities for all scorelines and returns top predictions.
#'
#' @param model A fitted Poisson model (glm or similar).
#' @param home_team Character. Home team name.
#' @param away_team Character. Away team name.
#' @param max_goals Integer. Maximum goals to consider (default 7).
#' @param top_n Integer. Number of top scorelines to return (default 10).
#' @return A tibble with top scoreline predictions.
#' @family models
#' @export
predict_correct_score <- function(model, home_team, away_team,
                                   max_goals = 7L, top_n = 10L) {
  rlang::check_required(model)
  rlang::check_required(home_team)
  rlang::check_required(away_team)

  # Get score matrix
  pred <- predict_glm(model, home_team, away_team, max_goals = max_goals)

  result <- top_scorelines(pred$score_mat, n = top_n)
  result$home_team <- home_team
  result$away_team <- away_team
  result$lambda_home <- pred$lambda_home
  result$lambda_away <- pred$lambda_away

  result |>
    dplyr::select("home_team", "away_team", "lambda_home", "lambda_away",
                  "scoreline", "home_goals", "away_goals", "probability")
}

#' Correct score odds value check
#'
#' Compares model correct score probability to bookmaker odds
#' to identify value bets.
#'
#' @param model_prob Numeric. Model probability for the scoreline.
#' @param odds Numeric. Bookmaker decimal odds.
#' @return A list with `implied_prob`, `edge`, `is_value`.
#' @family models
#' @export
correct_score_value <- function(model_prob, odds) {
  rlang::check_required(model_prob)
  rlang::check_required(odds)

  implied_prob <- 1 / odds
  edge <- model_prob - implied_prob
  is_value <- edge > 0

  list(
    model_prob = model_prob,
    implied_prob = implied_prob,
    edge = edge,
    is_value = is_value,
    expected_value = model_prob * (odds - 1) - (1 - model_prob)
  )
}
