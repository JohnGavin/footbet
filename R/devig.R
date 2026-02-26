#' Remove bookmaker margin from odds (basic proportional method)
#'
#' Divides each implied probability by the overround to get fair
#' probabilities that sum to 1.
#'
#' @param odds Numeric vector of decimal odds (e.g. `c(2.10, 3.40, 3.50)`).
#' @return Numeric vector of fair probabilities.
#' @family devig
#' @export
devig_basic <- function(odds) {
  rlang::check_required(odds)
  validate_odds(odds)

  implied <- 1 / odds
  overround <- sum(implied, na.rm = TRUE)
  implied / overround
}

#' Remove margin using power method
#'
#' Solves for exponent `k` such that `sum(1/odds^k) = 1`.
#' Better for 2-way markets (Asian handicap, over/under)
#' as it corrects favourite-longshot bias.
#'
#' @param odds Numeric vector of decimal odds.
#' @param tol Numeric. Convergence tolerance (default 1e-8).
#' @return Numeric vector of fair probabilities.
#' @family devig
#' @export
devig_power <- function(odds, tol = 1e-8) {
  rlang::check_required(odds)
  validate_odds(odds)

  # Single odds: fair prob = 1
  if (length(odds) == 1L) return(1.0)

  # Find k such that sum(1/odds^k) = 1
  f <- function(k) sum(1 / odds^k) - 1

  # If market is already fair, k = 1
  if (abs(f(1)) < tol) return(1 / odds)

  result <- tryCatch(
    stats::uniroot(f, interval = c(0.01, 100), tol = tol),
    error = function(e) {
      cli::cli_abort(c(
        "x" = "Power devig failed to converge.",
        "i" = "Odds: {.val {odds}}",
        "i" = "Original error: {conditionMessage(e)}"
      ))
    }
  )
  k <- result$root

  probs <- 1 / odds^k
  probs / sum(probs)
}

#' Remove margin using Shin's model (1993)
#'
#' Estimates the insider trading parameter `z` and derives fair
#' probabilities. Best for 3-way markets (1X2) where draws create
#' asymmetry.
#'
#' @param odds Numeric vector of decimal odds (length 3 for 1X2).
#' @param tol Numeric. Convergence tolerance.
#' @return Numeric vector of fair probabilities.
#' @family devig
#' @export
devig_shin <- function(odds, tol = 1e-8) {
  rlang::check_required(odds)
  if (length(odds) != 3L) {
    cli::cli_abort("Shin method requires exactly 3 odds (1X2). Got {.val {length(odds)}}.")
  }
  validate_odds(odds)

  implied <- 1 / odds
  sum_implied <- sum(implied)
  n <- length(odds)

  # If market is already fair (sum_implied ~ 1), return implied directly
  if (abs(sum_implied - 1) < tol) return(implied)

  # Shin (1993): solve for insider proportion z
  # Constraint: sum(sqrt(z^2 + 4*(1-z)*pi_i^2/S)) = 2*(1-z) + n*z
  f <- function(z) {
    lhs <- sum(sqrt(z^2 + 4 * (1 - z) * implied^2 / sum_implied))
    rhs <- 2 * (1 - z) + n * z
    lhs - rhs
  }

  z <- tryCatch(
    stats::uniroot(f, interval = c(1e-12, 1 - 1e-12), tol = tol)$root,
    error = function(e) {
      cli::cli_warn(c(
        "!" = "Shin devig failed to converge, falling back to basic method.",
        "i" = "Odds: {.val {odds}}"
      ))
      return(NA_real_)
    }
  )

  if (is.na(z)) return(devig_basic(odds))

  probs <- (sqrt(z^2 + 4 * (1 - z) * implied^2 / sum_implied) - z) / (2 * (1 - z))
  probs / sum(probs)
}

#' Calculate overround (vig) from decimal odds
#'
#' @param odds Numeric vector of decimal odds.
#' @return Numeric overround (e.g. 1.05 means 5% margin).
#' @family devig
#' @export
calc_overround <- function(odds) {
  rlang::check_required(odds)
  sum(1 / odds, na.rm = TRUE)
}

#' Validate odds input
#' @noRd
validate_odds <- function(odds) {
  if (length(odds) == 0L) {
    cli::cli_abort("Odds vector must not be empty.")
  }
  if (!is.numeric(odds)) {
    cli::cli_abort("Odds must be numeric. Got {.cls {class(odds)}}.")
  }
  if (any(is.infinite(odds))) {
    cli::cli_abort("Odds must be finite. Got Inf values.")
  }
  if (any(odds <= 1, na.rm = TRUE)) {
    cli::cli_abort("All odds must be > 1. Got minimum {.val {min(odds, na.rm = TRUE)}}.")
  }
  invisible(odds)
}
