#' @importFrom rlang .data
NULL

# ============================================================================
# ACCUMULATOR BET UTILITIES
# ============================================================================

#' Compute combined accumulator odds
#'
#' Calculates combined decimal odds for an accumulator bet.
#'
#' @param odds Numeric vector. Individual selection decimal odds.
#' @return Numeric. Combined decimal odds (product of all odds).
#' @family betting
#' @export
acca_odds <- function(odds) {
  rlang::check_required(odds)

  if (!is.numeric(odds)) {
    cli::cli_abort("{.arg odds} must be numeric.")
  }
  if (any(odds < 1, na.rm = TRUE)) {
    cli::cli_abort("All odds must be >= 1.")
  }
  if (any(is.na(odds))) {
    return(NA_real_)
  }

  prod(odds)
}

#' Compute expected value of an accumulator
#'
#' Calculates the expected value of an accumulator bet per unit staked.
#'
#' @param probs Numeric vector. Model probabilities for each selection.
#' @param odds Numeric vector. Decimal odds for each selection.
#' @return Numeric. Expected value (positive = profitable).
#' @family betting
#' @export
acca_ev <- function(probs, odds) {
  rlang::check_required(probs)
  rlang::check_required(odds)

  if (length(probs) != length(odds)) {
    cli::cli_abort("{.arg probs} and {.arg odds} must have same length.")
  }

  if (!is.numeric(probs) || !is.numeric(odds)) {
    cli::cli_abort("Arguments must be numeric.")
  }

  if (any(is.na(probs)) || any(is.na(odds))) {
    return(NA_real_)
  }

  combined_prob <- prod(probs)
  combined_odds <- prod(odds)

  # EV = p * (odds - 1) - (1 - p)
  combined_prob * (combined_odds - 1) - (1 - combined_prob)
}

#' Find optimal accumulator combinations
#'
#' Searches through possible accumulator combinations to find
#' those with positive expected value.
#'
#' @param selections A tibble with `prob` and `odds` columns for each selection.
#' @param min_legs Integer. Minimum legs in accumulator (default 2).
#' @param max_legs Integer. Maximum legs in accumulator (default 5).
#' @param min_ev Numeric. Minimum expected value to include (default 0).
#' @return A tibble of profitable accumulators sorted by EV.
#' @family betting
#' @export
find_best_accas <- function(selections, min_legs = 2L, max_legs = 5L,
                             min_ev = 0) {
  rlang::check_required(selections)

  if (!all(c("prob", "odds") %in% names(selections))) {
    cli::cli_abort("{.arg selections} must have {.val prob} and {.val odds} columns.")
  }

  n <- nrow(selections)
  if (n < min_legs) {
    cli::cli_warn("Not enough selections for {min_legs}-fold accumulator.")
    return(tibble::tibble(
      legs = integer(),
      selections = list(),
      combined_prob = numeric(),
      combined_odds = numeric(),
      expected_value = numeric()
    ))
  }

  max_legs <- min(max_legs, n)
  results <- list()

  for (k in min_legs:max_legs) {
    combos <- utils::combn(seq_len(n), k, simplify = FALSE)

    for (combo in combos) {
      probs <- selections$prob[combo]
      odds <- selections$odds[combo]

      combined_prob <- prod(probs)
      combined_odds <- prod(odds)
      ev <- acca_ev(probs, odds)

      if (!is.na(ev) && ev >= min_ev) {
        results <- c(results, list(tibble::tibble(
          legs = k,
          selections = list(combo),
          combined_prob = combined_prob,
          combined_odds = combined_odds,
          expected_value = ev
        )))
      }
    }
  }

  if (length(results) == 0L) {
    return(tibble::tibble(
      legs = integer(),
      selections = list(),
      combined_prob = numeric(),
      combined_odds = numeric(),
      expected_value = numeric()
    ))
  }

  dplyr::bind_rows(results) |>
    dplyr::arrange(dplyr::desc(.data$expected_value))
}

# ============================================================================
# BANKROLL MANAGEMENT
# ============================================================================

#' Compute stakes for multiple bets using Kelly criterion
#'
#' For simultaneous independent bets, computes Kelly fractions
#' and optionally normalizes if total exceeds a limit.
#' Uses the existing [kelly_fraction()] from kelly.R.
#'
#' @param probs Numeric vector. Win probabilities for each bet.
#' @param odds Numeric vector. Decimal odds for each bet.
#' @param fraction Numeric. Fraction of full Kelly (default 0.25).
#' @param max_total Numeric. Maximum total stake as fraction of bankroll (default 0.2).
#' @return A tibble with `kelly`, `stake`, `normalized_stake`.
#' @family betting
#' @export
multi_kelly_stakes <- function(probs, odds, fraction = 0.25, max_total = 0.2) {
  rlang::check_required(probs)
  rlang::check_required(odds)

  if (length(probs) != length(odds)) {
    cli::cli_abort("{.arg probs} and {.arg odds} must have same length.")
  }

  n <- length(probs)
  kelly_vals <- numeric(n)
  stake_vals <- numeric(n)

  for (i in seq_len(n)) {
    # Use existing kelly_fraction from kelly.R
    kelly_vals[[i]] <- kelly_fraction(probs[[i]], odds[[i]], fraction = 1.0)
    stake_vals[[i]] <- kelly_fraction(probs[[i]], odds[[i]], fraction = fraction)
  }

  # Normalize if total exceeds limit
  total <- sum(stake_vals)
  if (total > max_total && total > 0) {
    normalized_stake <- stake_vals * (max_total / total)
  } else {
    normalized_stake <- stake_vals
  }

  # Expected value per bet
  ev <- probs * (odds - 1) - (1 - probs)

  tibble::tibble(
    kelly_full = kelly_vals,
    stake = stake_vals,
    normalized_stake = normalized_stake,
    ev = ev
  )
}

#' Compute bankroll growth target
#'
#' Estimates the number of bets needed to reach a bankroll target
#' given average edge and stake sizing.
#'
#' @param current_bankroll Numeric. Current bankroll.
#' @param target_bankroll Numeric. Target bankroll.
#' @param avg_odds Numeric. Average decimal odds (default 2.0).
#' @param avg_edge Numeric. Average edge per bet (default 0.05 = 5%).
#' @param avg_stake_pct Numeric. Average stake as % of bankroll (default 0.02).
#' @return A tibble with growth projections.
#' @family betting
#' @export
bankroll_growth_target <- function(current_bankroll, target_bankroll,
                                    avg_odds = 2.0, avg_edge = 0.05,
                                    avg_stake_pct = 0.02) {
  rlang::check_required(current_bankroll)
  rlang::check_required(target_bankroll)

  if (current_bankroll <= 0) {
    cli::cli_abort("{.arg current_bankroll} must be positive.")
  }
  if (target_bankroll <= current_bankroll) {
    cli::cli_abort("{.arg target_bankroll} must exceed {.arg current_bankroll}.")
  }

  # Growth factor needed
  growth_factor <- target_bankroll / current_bankroll

  # Expected growth per bet
  avg_prob <- (1 / avg_odds) + avg_edge
  ev_per_bet <- avg_prob * (avg_odds - 1) - (1 - avg_prob)
  growth_per_bet <- 1 + avg_stake_pct * ev_per_bet

  if (growth_per_bet <= 1) {
    cli::cli_warn("Non-positive expected growth. Check parameters.")
    return(tibble::tibble(
      current_bankroll = current_bankroll,
      target_bankroll = target_bankroll,
      growth_factor = growth_factor,
      bets_needed = NA_real_,
      days_at_5_bets = NA_real_
    ))
  }

  # Bets needed: growth_factor = growth_per_bet ^ n
  bets_needed <- log(growth_factor) / log(growth_per_bet)

  tibble::tibble(
    current_bankroll = current_bankroll,
    target_bankroll = target_bankroll,
    growth_factor = growth_factor,
    growth_per_bet = growth_per_bet,
    ev_per_bet = ev_per_bet,
    bets_needed = ceiling(bets_needed),
    days_at_5_bets = ceiling(bets_needed / 5),
    days_at_10_bets = ceiling(bets_needed / 10)
  )
}

#' Simulate bankroll trajectory
#'
#' Monte Carlo simulation of bankroll evolution with Kelly staking.
#'
#' @param bankroll Numeric. Starting bankroll.
#' @param probs Numeric vector. True win probabilities for each bet.
#' @param odds Numeric vector. Decimal odds for each bet.
#' @param fraction Numeric. Kelly fraction (default 0.25).
#' @param n_sims Integer. Number of simulations (default 1000).
#' @return A tibble with simulation results.
#' @family betting
#' @export
simulate_bankroll_growth <- function(bankroll, probs, odds, fraction = 0.25,
                                      n_sims = 1000L) {
  rlang::check_required(bankroll)
  rlang::check_required(probs)
  rlang::check_required(odds)

  if (length(probs) != length(odds)) {
    cli::cli_abort("{.arg probs} and {.arg odds} must have same length.")
  }

  n_bets <- length(probs)

  # Compute stakes using existing kelly_fraction
  stakes <- numeric(n_bets)
  for (i in seq_len(n_bets)) {
    stakes[[i]] <- kelly_fraction(probs[[i]], odds[[i]], fraction = fraction)
  }

  # Run simulations
  final_bankrolls <- numeric(n_sims)

  for (sim in seq_len(n_sims)) {
    br <- bankroll
    for (i in seq_len(n_bets)) {
      if (stakes[[i]] > 0) {
        stake_amount <- br * stakes[[i]]
        won <- stats::runif(1) < probs[[i]]
        if (won) {
          br <- br + stake_amount * (odds[[i]] - 1)
        } else {
          br <- br - stake_amount
        }
      }
    }
    final_bankrolls[[sim]] <- br
  }

  tibble::tibble(
    starting_bankroll = bankroll,
    n_bets = n_bets,
    mean_final = mean(final_bankrolls),
    median_final = stats::median(final_bankrolls),
    pct_profitable = mean(final_bankrolls > bankroll) * 100,
    pct_bust = mean(final_bankrolls < bankroll * 0.1) * 100,
    p05 = stats::quantile(final_bankrolls, 0.05),
    p95 = stats::quantile(final_bankrolls, 0.95)
  )
}
