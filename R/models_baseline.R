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

  stats::glm(
    goals ~ home + team + opponent,
    family = stats::poisson(),
    data = long_df
  )
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
