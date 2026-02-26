#' Calculate fractional Kelly stake
#'
#' Computes the Kelly criterion fraction for a single bet, scaled
#' by a fractional multiplier (default quarter Kelly).
#'
#' @param prob_win Numeric. Model probability of winning the bet.
#' @param decimal_odds Numeric. Decimal odds offered.
#' @param fraction Numeric. Kelly fraction (default 0.25 = quarter Kelly).
#' @return Numeric. Recommended stake as a fraction of bankroll.
#'   Returns 0 if there is no edge.
#' @family decisions
#' @export
kelly_fraction <- function(prob_win, decimal_odds, fraction = 0.25) {
  rlang::check_required(prob_win)
  rlang::check_required(decimal_odds)

  if (prob_win <= 0 || prob_win >= 1) {
    cli::cli_abort("{.arg prob_win} must be between 0 and 1 (exclusive).")
  }
  if (decimal_odds <= 1) {
    cli::cli_abort("{.arg decimal_odds} must be > 1.")
  }

  b <- decimal_odds - 1
  f <- (b * prob_win - (1 - prob_win)) / b
  max(0, f) * fraction
}

#' Identify value bets from model vs market probabilities
#'
#' Compares model-predicted probabilities to devigged market
#' probabilities and flags bets with sufficient edge.
#'
#' @param model_prob Numeric. Model probability.
#' @param market_prob Numeric. Devigged market probability.
#' @param decimal_odds Numeric. Available decimal odds.
#' @param min_edge Numeric. Minimum edge to consider (default 0.03 = 3%).
#' @param min_odds Numeric. Minimum acceptable odds (default 1.50).
#' @param max_odds Numeric. Maximum acceptable odds (default 10.0).
#' @return A list with `is_value`, `edge`, `kelly_stake`.
#' @family decisions
#' @export
identify_value_bet <- function(model_prob,
                               market_prob,
                               decimal_odds,
                               min_edge = 0.03,
                               min_odds = 1.50,
                               max_odds = 10.0) {
  edge <- model_prob - market_prob

  is_value <- edge > min_edge &
    decimal_odds >= min_odds &
    decimal_odds <= max_odds

  # Clamp probability to valid Kelly range (0, 1) exclusive
  kelly_prob <- min(max(model_prob, 1e-10), 1 - 1e-10)

  stake <- if (is_value) {
    kelly_fraction(kelly_prob, decimal_odds)
  } else {
    0
  }

  list(
    is_value = is_value,
    edge = edge,
    kelly_stake = stake,
    model_prob = model_prob,
    market_prob = market_prob,
    decimal_odds = decimal_odds
  )
}

#' Apply drawdown guardrails to stake
#'
#' Halves the stake when cumulative drawdown exceeds threshold.
#'
#' @param stake Numeric. Proposed stake fraction.
#' @param current_bankroll Numeric. Current bankroll.
#' @param peak_bankroll Numeric. Peak bankroll reached.
#' @param drawdown_threshold Numeric. Drawdown level to trigger halving
#'   (default 0.20 = 20%).
#' @param max_stake Numeric. Maximum stake as fraction of bankroll
#'   (default 0.03 = 3%).
#' @return Numeric. Adjusted stake fraction.
#' @family decisions
#' @export
apply_guardrails <- function(stake,
                             current_bankroll,
                             peak_bankroll,
                             drawdown_threshold = 0.20,
                             max_stake = 0.03) {
  if (peak_bankroll <= 0) {
    drawdown <- NA_real_
  } else {
    drawdown <- 1 - current_bankroll / peak_bankroll
  }

  adjusted <- min(stake, max_stake)

  if (!is.na(drawdown) && drawdown > drawdown_threshold) {
    adjusted <- adjusted / 2
    cli::cli_alert_warning(
      "Drawdown {.val {scales::percent(drawdown)}} exceeds threshold. Halving stake."
    )
  }

  adjusted
}
