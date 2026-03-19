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

#' Find value bets across all matches for 1X2 market
#'
#' Scans model predictions against devigged odds to find bets where
#' the model edge exceeds the minimum threshold.
#'
#' @param preds A tibble with `match_id`, `pred_h`, `pred_d`, `pred_a`.
#' @param devigged A tibble with `match_id`, `fair_h`, `fair_d`, `fair_a`.
#' @param odds A tibble with `match_id`, `psh`, `psd`, `psa`
#'   (raw Pinnacle decimal odds).
#' @param min_edge Numeric. Minimum edge (default 0.03).
#' @param min_odds Numeric. Minimum odds (default 1.50).
#' @param max_odds Numeric. Maximum odds (default 10.0).
#' @return A tibble of value bets with columns: `match_id`, `outcome`,
#'   `model_prob`, `market_prob`, `decimal_odds`, `edge`, `kelly_stake`.
#' @family decisions
#' @export
find_value_bets <- function(preds,
                            devigged,
                            odds,
                            min_edge = 0.03,
                            min_odds = 1.50,
                            max_odds = 10.0) {
  rlang::check_required(preds)
  rlang::check_required(devigged)
  rlang::check_required(odds)

  if (!is.data.frame(preds) || !is.data.frame(devigged) || !is.data.frame(odds)) {
    cli::cli_abort("All inputs must be data frames.")
  }

  # Join all three sources
  combined <- dplyr::inner_join(preds, devigged, by = "match_id") |>
    dplyr::inner_join(odds[, c("match_id", "psh", "psd", "psa")], by = "match_id")

  if (nrow(combined) == 0L) {
    return(tibble::tibble(
      match_id = character(), outcome = character(),
      model_prob = numeric(), market_prob = numeric(),
      decimal_odds = numeric(), edge = numeric(), kelly_stake = numeric()
    ))
  }

  results <- list()

  for (i in seq_len(nrow(combined))) {
    row <- combined[i, ]

    # Check each outcome: H, D, A
    outcomes <- list(
      list(out = "H", mp = row$pred_h, fp = row$fair_h, odds = row$psh),
      list(out = "D", mp = row$pred_d, fp = row$fair_d, odds = row$psd),
      list(out = "A", mp = row$pred_a, fp = row$fair_a, odds = row$psa)
    )

    for (o in outcomes) {
      if (is.na(o$mp) || is.na(o$fp) || is.na(o$odds)) next
      if (o$odds <= 1) next

      edge <- o$mp - o$fp
      if (edge > min_edge && o$odds >= min_odds && o$odds <= max_odds) {
        prob_clamped <- min(max(o$mp, 1e-10), 1 - 1e-10)
        stake <- kelly_fraction(prob_clamped, o$odds)

        results <- c(results, list(tibble::tibble(
          match_id = row$match_id,
          outcome = o$out,
          model_prob = o$mp,
          market_prob = o$fp,
          decimal_odds = o$odds,
          edge = edge,
          kelly_stake = stake
        )))
      }
    }
  }

  dplyr::bind_rows(results)
}

#' Simulate betting P&L from a series of value bets
#'
#' Processes bets in chronological order with configurable staking strategy.
#' Supports Kelly compounding, flat stakes, or tiered staking by predicted edge.
#'
#' @param bets A tibble of value bets with `match_id`, `outcome`,
#'   `decimal_odds`, `kelly_stake`, `edge`. Must also include `ftr` (actual
#'   result) and `match_date`.
#' @param initial_bankroll Numeric. Starting bankroll (default 1000).
#' @param drawdown_threshold Numeric. Drawdown to trigger halving (default 0.20).
#' @param max_stake Numeric. Max stake fraction (default 0.03).
#' @param transaction_cost Numeric 0-1. Cost per bet as fraction of stake (default 0).
#' @param max_bankroll Numeric. Cap effective bankroll for stake calc (default Inf).
#' @param slippage Numeric 0-1. Reduce odds by this fraction (default 0).
#' @param stake_mode Character. `"kelly"` (compounding), `"flat"` (fixed amount),
#'   or `"tiered"` (variable stake by predicted edge).
#' @param flat_stake Numeric. Fixed stake per bet in flat mode (default 10).
#' @param edge_tiers Numeric vector. Edge breakpoints for tiered mode
#'   (default `c(0.03, 0.05, 0.08, 0.12)`). Bets with edge < 0.03 get the
#'   lowest tier, edge 0.03-0.05 the next, etc.
#' @param tier_stakes Numeric vector. Stake per tier (default `c(5, 10, 15, 20, 25)`).
#'   Must be one element longer than `edge_tiers`.
#' @return A tibble with one row per bet: `match_id`, `match_date`, `outcome`,
#'   `decimal_odds`, `stake_frac`, `stake_amount`, `pnl`, `bankroll`,
#'   `peak_bankroll`, `drawdown`.
#' @family decisions
#' @export
simulate_pnl <- function(bets,
                         initial_bankroll = 1000,
                         drawdown_threshold = 0.20,
                         max_stake = 0.03,
                         transaction_cost = 0,
                         max_bankroll = Inf,
                         slippage = 0,
                         stake_mode = c("kelly", "flat", "tiered"),
                         flat_stake = 10,
                         edge_tiers = c(0.03, 0.05, 0.08, 0.12),
                         tier_stakes = c(5, 10, 15, 20, 25)) {
  stake_mode <- match.arg(stake_mode)
  rlang::check_required(bets)
  if (!is.data.frame(bets)) {
    cli::cli_abort("{.arg bets} must be a data frame, not {.cls {class(bets)}}.")
  }

  if (nrow(bets) == 0L) {
    return(tibble::tibble(
      match_id = character(), match_date = as.Date(character()),
      outcome = character(), decimal_odds = numeric(),
      stake_frac = numeric(), stake_amount = numeric(),
      pnl = numeric(), bankroll = numeric(),
      peak_bankroll = numeric(), drawdown = numeric()
    ))
  }

  # Sort by date
  bets <- bets[order(bets$match_date), ]

  n <- nrow(bets)
  bankroll <- initial_bankroll
  peak <- initial_bankroll

  results <- vector("list", n)

  for (i in seq_len(n)) {
    bet <- bets[i, ]

    # Cap bankroll for compounding (prevents runaway growth)
    effective_bankroll <- min(bankroll, max_bankroll)

    if (stake_mode == "kelly") {
      # Apply guardrails (suppress warning messages during simulation)
      stake_frac <- suppressMessages(
        apply_guardrails(
          stake = bet$kelly_stake,
          current_bankroll = effective_bankroll,
          peak_bankroll = peak,
          drawdown_threshold = drawdown_threshold,
          max_stake = max_stake
        )
      )
      stake_amount <- effective_bankroll * stake_frac
    } else if (stake_mode == "tiered") {
      # Tiered staking: larger stakes for higher predicted edge
      # edge_tiers = c(0.03, 0.05, 0.08, 0.12) defines breakpoints
      # tier_stakes = c(5, 10, 15, 20, 25) defines stake per tier
      bet_edge <- bet$edge
      tier_idx <- findInterval(bet_edge, edge_tiers) + 1L
      tier_idx <- min(tier_idx, length(tier_stakes))
      tier_amount <- tier_stakes[tier_idx]
      stake_frac <- tier_amount / effective_bankroll
      stake_amount <- min(tier_amount, effective_bankroll * 0.5)
    } else {
      # Flat stakes — fixed amount per bet
      stake_frac <- flat_stake / effective_bankroll
      stake_amount <- min(flat_stake, effective_bankroll * 0.5)
    }

    # Apply slippage (reduce odds by slippage %)
    effective_odds <- bet$decimal_odds * (1 - slippage)

    # Determine if bet won
    won <- !is.na(bet$ftr) && bet$outcome == bet$ftr
    gross_pnl <- if (won) {
      stake_amount * (effective_odds - 1)
    } else {
      -stake_amount
    }

    # Deduct transaction cost (applied to stake, win or lose)
    cost <- stake_amount * transaction_cost
    pnl <- gross_pnl - cost

    bankroll <- bankroll + pnl
    if (bankroll <= 0) bankroll <- 0  # Bust
    peak <- max(peak, bankroll)
    dd <- if (peak > 0) 1 - bankroll / peak else 1

    results[[i]] <- tibble::tibble(
      match_id = bet$match_id,
      match_date = bet$match_date,
      outcome = bet$outcome,
      decimal_odds = bet$decimal_odds,
      stake_frac = stake_frac,
      stake_amount = stake_amount,
      pnl = pnl,
      bankroll = bankroll,
      peak_bankroll = peak,
      drawdown = dd
    )
  }

  dplyr::bind_rows(results)
}

#' Summarise P&L simulation results
#'
#' @param pnl_df A tibble from [simulate_pnl()].
#' @param initial_bankroll Numeric. Starting bankroll for ROI calculation.
#' @return A tibble with summary statistics.
#' @family decisions
#' @export
summarise_pnl <- function(pnl_df, initial_bankroll = 1000) {
  rlang::check_required(pnl_df)
  if (nrow(pnl_df) == 0L) {
    return(tibble::tibble(
      n_bets = 0L, total_pnl = 0, roi_pct = 0,
      max_drawdown = 0, final_bankroll = initial_bankroll,
      win_rate = NA_real_, avg_odds = NA_real_
    ))
  }

  wins <- sum(pnl_df$pnl > 0)
  final <- pnl_df$bankroll[nrow(pnl_df)]

  tibble::tibble(
    n_bets = nrow(pnl_df),
    total_pnl = sum(pnl_df$pnl),
    roi_pct = (final - initial_bankroll) / initial_bankroll * 100,
    max_drawdown = max(pnl_df$drawdown, na.rm = TRUE),
    final_bankroll = final,
    win_rate = wins / nrow(pnl_df),
    avg_odds = mean(pnl_df$decimal_odds)
  )
}
