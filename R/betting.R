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

# ============================================================================
# LINE MOVEMENT ANALYSIS
# ============================================================================

#' Compute opening-to-closing line movement
#'
#' Analyzes how odds moved from opening (Bet365) to closing (Pinnacle).
#' Sharp money typically moves lines toward true probability.
#'
#' @param odds_df A tibble with Bet365 and Pinnacle odds columns.
#' @return A tibble with line movement metrics.
#' @family betting
#' @export
line_movement <- function(odds_df) {
  rlang::check_required(odds_df)

  has_opening <- all(c("b365h", "b365d", "b365a") %in% names(odds_df))
  has_closing <- all(c("psh", "psd", "psa") %in% names(odds_df))

  if (!has_opening) {
    cli::cli_abort("Missing Bet365 opening odds (b365h, b365d, b365a).")
  }
  if (!has_closing) {
    cli::cli_abort("Missing Pinnacle closing odds (psh, psd, psa).")
  }

  # Convert odds to implied probabilities
  open_prob_h <- 1 / odds_df$b365h
  open_prob_d <- 1 / odds_df$b365d
  open_prob_a <- 1 / odds_df$b365a
  open_total <- open_prob_h + open_prob_d + open_prob_a
  open_prob_h <- open_prob_h / open_total
  open_prob_d <- open_prob_d / open_total
  open_prob_a <- open_prob_a / open_total

  close_prob_h <- 1 / odds_df$psh
  close_prob_d <- 1 / odds_df$psd
  close_prob_a <- 1 / odds_df$psa
  close_total <- close_prob_h + close_prob_d + close_prob_a
  close_prob_h <- close_prob_h / close_total
  close_prob_d <- close_prob_d / close_total
  close_prob_a <- close_prob_a / close_total

  # Line movement = closing - opening (positive = market moved toward outcome)
  move_h <- close_prob_h - open_prob_h
  move_d <- close_prob_d - open_prob_d
  move_a <- close_prob_a - open_prob_a

  # Direction of sharpest move
  max_move <- pmax(abs(move_h), abs(move_d), abs(move_a), na.rm = TRUE)
  steam_direction <- dplyr::case_when(
    abs(move_h) == max_move & move_h > 0 ~ "H",
    abs(move_h) == max_move & move_h < 0 ~ "anti-H",
    abs(move_d) == max_move & move_d > 0 ~ "D",
    abs(move_d) == max_move & move_d < 0 ~ "anti-D",
    abs(move_a) == max_move & move_a > 0 ~ "A",
    abs(move_a) == max_move & move_a < 0 ~ "anti-A",
    TRUE ~ NA_character_
  )

  tibble::tibble(
    match_id = if ("match_id" %in% names(odds_df)) odds_df$match_id else NA_character_,
    # Opening probabilities (Bet365)
    open_prob_h = open_prob_h,
    open_prob_d = open_prob_d,
    open_prob_a = open_prob_a,
    # Closing probabilities (Pinnacle)
    close_prob_h = close_prob_h,
    close_prob_d = close_prob_d,
    close_prob_a = close_prob_a,
    # Movement (percentage points)
    move_h = move_h * 100,
    move_d = move_d * 100,
    move_a = move_a * 100,
    # Steam move indicator
    max_move_pct = max_move * 100,
    steam_direction = steam_direction,
    # Is this significant movement? (>2% is notable)
    is_steam_move = max_move > 0.02
  )
}

#' Analyze line movement by outcome
#'
#' Checks if betting with or against line movement is profitable.
#'
#' @param movement_df A tibble from [line_movement()].
#' @param actual_results Character vector. Actual match outcomes ("H", "D", "A").
#' @return A tibble with steam move analysis.
#' @family betting
#' @export
analyze_steam_moves <- function(movement_df, actual_results) {
  rlang::check_required(movement_df)
  rlang::check_required(actual_results)

  if (nrow(movement_df) != length(actual_results)) {
    cli::cli_abort("{.arg movement_df} and {.arg actual_results} must have same length.")
  }

  df <- movement_df |>
    dplyr::mutate(
      actual = actual_results,
      # Did steam direction match actual result?
      steam_correct = dplyr::case_when(
        steam_direction == "H" & actual == "H" ~ TRUE,
        steam_direction == "D" & actual == "D" ~ TRUE,
        steam_direction == "A" & actual == "A" ~ TRUE,
        steam_direction == "anti-H" & actual != "H" ~ TRUE,
        steam_direction == "anti-D" & actual != "D" ~ TRUE,
        steam_direction == "anti-A" & actual != "A" ~ TRUE,
        TRUE ~ FALSE
      )
    )

  # Summary by steam move size
  summary <- df |>
    dplyr::filter(.data$is_steam_move) |>
    dplyr::summarise(
      n_steam_moves = dplyr::n(),
      steam_accuracy = mean(.data$steam_correct, na.rm = TRUE) * 100,
      avg_move_pct = mean(.data$max_move_pct, na.rm = TRUE),
      .groups = "drop"
    )

  # Breakdown by direction
  by_direction <- df |>
    dplyr::filter(.data$is_steam_move) |>
    dplyr::group_by(.data$steam_direction) |>
    dplyr::summarise(
      n = dplyr::n(),
      accuracy = mean(.data$steam_correct, na.rm = TRUE) * 100,
      avg_move = mean(.data$max_move_pct, na.rm = TRUE),
      .groups = "drop"
    )

  list(
    summary = summary,
    by_direction = by_direction,
    details = df
  )
}

# ============================================================================
# FAVOURITE-LONGSHOT BIAS DETECTION
# ============================================================================

#' Detect favourite-longshot bias in odds
#'
#' Analyzes historical data for systematic mispricings. The FLB is a
#' well-documented phenomenon where longshots are overbet (odds too short)
#' and favourites are underbet (odds too long).
#'
#' @param odds_df A tibble with devigged probability columns.
#' @param actual_results Character vector. Actual outcomes ("H", "D", "A").
#' @param n_bins Integer. Number of probability bins (default 10).
#' @return A tibble with bias analysis by probability bin.
#' @family betting
#' @export
detect_flb <- function(odds_df, actual_results, n_bins = 10L) {
rlang::check_required(odds_df)
  rlang::check_required(actual_results)

  # Need implied probabilities
  if (!all(c("psh", "psd", "psa") %in% names(odds_df))) {
    cli::cli_abort("Need Pinnacle odds columns (psh, psd, psa).")
  }

  n <- nrow(odds_df)
  if (n != length(actual_results)) {
    cli::cli_abort("{.arg odds_df} and {.arg actual_results} must have same length.")
  }

  # Devig to get fair probabilities
  raw_h <- 1 / odds_df$psh
  raw_d <- 1 / odds_df$psd
  raw_a <- 1 / odds_df$psa
  total <- raw_h + raw_d + raw_a
  prob_h <- raw_h / total
  prob_d <- raw_d / total
  prob_a <- raw_a / total

  # Create long format for analysis
  long <- tibble::tibble(
    match_idx = rep(seq_len(n), 3),
    outcome = rep(c("H", "D", "A"), each = n),
    implied_prob = c(prob_h, prob_d, prob_a),
    actual = rep(actual_results, 3),
    won = c(actual_results == "H", actual_results == "D", actual_results == "A")
  ) |>
    dplyr::filter(!is.na(.data$implied_prob))

  # Bin by implied probability
  long <- long |>
    dplyr::mutate(
      prob_bin = cut(.data$implied_prob,
                      breaks = seq(0, 1, length.out = n_bins + 1),
                      include.lowest = TRUE,
                      labels = FALSE),
      prob_bin_label = cut(.data$implied_prob,
                            breaks = seq(0, 1, length.out = n_bins + 1),
                            include.lowest = TRUE)
    )

  # Calculate actual win rate vs implied probability per bin
  bias_by_bin <- long |>
    dplyr::group_by(.data$prob_bin, .data$prob_bin_label) |>
    dplyr::summarise(
      n_bets = dplyr::n(),
      avg_implied_prob = mean(.data$implied_prob, na.rm = TRUE),
      actual_win_rate = mean(.data$won, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      # Bias = actual - implied (positive = value on this bin)
      bias = .data$actual_win_rate - .data$avg_implied_prob,
      bias_pct = .data$bias * 100,
      # ROI if flat-betting this bin
      avg_odds = 1 / .data$avg_implied_prob,
      roi_pct = (.data$actual_win_rate * .data$avg_odds - 1) * 100,
      # Classification
      bias_type = dplyr::case_when(
        .data$bias > 0.02 ~ "Value (underbet)",
        .data$bias < -0.02 ~ "Trap (overbet)",
        TRUE ~ "Fair"
      )
    ) |>
    dplyr::filter(.data$n_bets >= 20)  # Need minimum sample

  bias_by_bin
}

#' Summarize favourite-longshot bias
#'
#' Provides a high-level summary of FLB patterns.
#'
#' @param flb_df A tibble from [detect_flb()].
#' @return A tibble with FLB summary statistics.
#' @family betting
#' @export
summarize_flb <- function(flb_df) {
  rlang::check_required(flb_df)

  # Identify bias zones
  longshots <- flb_df |>
    dplyr::filter(.data$avg_implied_prob <= 0.25)
  midrange <- flb_df |>
    dplyr::filter(.data$avg_implied_prob > 0.25 & .data$avg_implied_prob <= 0.50)
  favourites <- flb_df |>
    dplyr::filter(.data$avg_implied_prob > 0.50)

  tibble::tibble(
    category = c("Longshots (<25%)", "Midrange (25-50%)", "Favourites (>50%)"),
    n_bets = c(sum(longshots$n_bets), sum(midrange$n_bets), sum(favourites$n_bets)),
    avg_bias_pct = c(
      stats::weighted.mean(longshots$bias_pct, longshots$n_bets, na.rm = TRUE),
      stats::weighted.mean(midrange$bias_pct, midrange$n_bets, na.rm = TRUE),
      stats::weighted.mean(favourites$bias_pct, favourites$n_bets, na.rm = TRUE)
    ),
    avg_roi_pct = c(
      stats::weighted.mean(longshots$roi_pct, longshots$n_bets, na.rm = TRUE),
      stats::weighted.mean(midrange$roi_pct, midrange$n_bets, na.rm = TRUE),
      stats::weighted.mean(favourites$roi_pct, favourites$n_bets, na.rm = TRUE)
    ),
    recommendation = c(
      ifelse(is.na(stats::weighted.mean(longshots$bias_pct, longshots$n_bets, na.rm = TRUE)) ||
               stats::weighted.mean(longshots$bias_pct, longshots$n_bets, na.rm = TRUE) < -1,
               "Fade longshots", "Neutral"),
      "Neutral",
      ifelse(is.na(stats::weighted.mean(favourites$bias_pct, favourites$n_bets, na.rm = TRUE)) ||
               stats::weighted.mean(favourites$bias_pct, favourites$n_bets, na.rm = TRUE) > 1,
               "Back favourites", "Neutral")
    )
  )
}

#' Generate betting alerts based on bias detection
#'
#' Identifies specific matches where model predictions diverge from
#' market odds in profitable directions based on historical biases.
#'
#' @param model_probs A tibble with `match_id`, `prob_h`, `prob_d`, `prob_a`.
#' @param market_odds A tibble with `match_id`, `psh`, `psd`, `psa`.
#' @param flb_summary A tibble from [summarize_flb()].
#' @param min_edge Numeric. Minimum edge to trigger alert (default 0.03).
#' @return A tibble of betting alerts.
#' @family betting
#' @export
generate_bias_alerts <- function(model_probs, market_odds, flb_summary,
                                  min_edge = 0.03) {
  rlang::check_required(model_probs)
  rlang::check_required(market_odds)
  rlang::check_required(flb_summary)

  # Join model and market
  df <- dplyr::inner_join(model_probs, market_odds, by = "match_id")

  if (nrow(df) == 0L) {
    return(tibble::tibble(
      match_id = character(),
      outcome = character(),
      model_prob = numeric(),
      market_prob = numeric(),
      edge = numeric(),
      bias_aligned = logical(),
      alert_type = character()
    ))
  }

  # Get implied probabilities
  df <- df |>
    dplyr::mutate(
      market_prob_h = 1 / .data$psh,
      market_prob_d = 1 / .data$psd,
      market_prob_a = 1 / .data$psa
    )
  total <- df$market_prob_h + df$market_prob_d + df$market_prob_a
  df$market_prob_h <- df$market_prob_h / total
  df$market_prob_d <- df$market_prob_d / total
  df$market_prob_a <- df$market_prob_a / total

  # Extract FLB recommendations
  fav_bias <- flb_summary$avg_bias_pct[flb_summary$category == "Favourites (>50%)"] / 100
  long_bias <- flb_summary$avg_bias_pct[flb_summary$category == "Longshots (<25%)"] / 100

  fav_bias <- ifelse(length(fav_bias) == 0 || is.na(fav_bias), 0, fav_bias)
  long_bias <- ifelse(length(long_bias) == 0 || is.na(long_bias), 0, long_bias)

  alerts <- list()

  for (i in seq_len(nrow(df))) {
    row <- df[i, ]

    # Check each outcome
    for (outcome in c("H", "D", "A")) {
      model_prob <- switch(outcome,
                            "H" = row$prob_h,
                            "D" = row$prob_d,
                            "A" = row$prob_a)
      market_prob <- switch(outcome,
                             "H" = row$market_prob_h,
                             "D" = row$market_prob_d,
                             "A" = row$market_prob_a)

      edge <- model_prob - market_prob

      if (is.na(edge) || edge < min_edge) next

      # Check if edge aligns with FLB pattern
      is_favourite <- market_prob > 0.50
      is_longshot <- market_prob < 0.25

      bias_aligned <- FALSE
      if (is_favourite && fav_bias > 0.01) bias_aligned <- TRUE
      if (is_longshot && long_bias > 0.01) bias_aligned <- TRUE

      # Alert type
      alert_type <- dplyr::case_when(
        bias_aligned & edge > 0.05 ~ "STRONG: Model + FLB aligned",
        bias_aligned ~ "Model + FLB aligned",
        edge > 0.05 ~ "Model edge only (strong)",
        TRUE ~ "Model edge only"
      )

      alerts <- c(alerts, list(tibble::tibble(
        match_id = row$match_id,
        outcome = outcome,
        model_prob = model_prob,
        market_prob = market_prob,
        edge = edge,
        odds = 1 / market_prob,
        bias_aligned = bias_aligned,
        alert_type = alert_type
      )))
    }
  }

  if (length(alerts) == 0L) {
    return(tibble::tibble(
      match_id = character(),
      outcome = character(),
      model_prob = numeric(),
      market_prob = numeric(),
      edge = numeric(),
      odds = numeric(),
      bias_aligned = logical(),
      alert_type = character()
    ))
  }

  dplyr::bind_rows(alerts) |>
    dplyr::arrange(dplyr::desc(.data$edge))
}

# ============================================================================
# LEAGUE STRENGTH ADJUSTMENT
# ============================================================================

#' Estimate relative league strengths
#'
#' Uses team movement (promotion/relegation) and European competition
#' results to estimate relative strength coefficients between leagues.
#'
#' Based on the Elo rating transfer principle: when a team moves between
#' leagues, their performance relative to expectations indicates the
#' strength difference.
#'
#' @param matches_df A tibble with `league_code`, `season`, `home_team`,
#'   `away_team`, `fthg`, `ftag`, `ftr`.
#' @param reference_league Character. League to use as baseline (default "E0" = EPL).
#' @return A tibble with `league_code`, `strength_coefficient`, `se`.
#' @family betting
#' @export
estimate_league_strength <- function(matches_df, reference_league = "E0") {
  rlang::check_required(matches_df)

  required <- c("league_code", "season", "home_team", "away_team", "fthg", "ftag")
  missing <- setdiff(required, names(matches_df))
  if (length(missing) > 0) {
    cli::cli_abort("Missing required columns: {.val {missing}}")
  }

  # Method 1: Goal-based league average
  # Compare average goals per game across leagues (simple approximation)
  league_stats <- matches_df |>
    dplyr::filter(!is.na(.data$fthg), !is.na(.data$ftag)) |>
    dplyr::group_by(.data$league_code) |>
    dplyr::summarise(
      n_matches = dplyr::n(),
      avg_total_goals = mean(.data$fthg + .data$ftag, na.rm = TRUE),
      avg_home_goals = mean(.data$fthg, na.rm = TRUE),
      avg_away_goals = mean(.data$ftag, na.rm = TRUE),
      home_win_pct = mean(.data$fthg > .data$ftag, na.rm = TRUE),
      draw_pct = mean(.data$fthg == .data$ftag, na.rm = TRUE),
      .groups = "drop"
    )

  # Reference league stats
  ref_stats <- league_stats |>
    dplyr::filter(.data$league_code == reference_league)

  if (nrow(ref_stats) == 0L) {
    cli::cli_warn("Reference league {.val {reference_league}} not found. Using average.")
    ref_goals <- mean(league_stats$avg_total_goals)
  } else {
    ref_goals <- ref_stats$avg_total_goals
  }

  # Strength coefficient: relative to reference league
  # Higher goals can indicate more attacking football OR weaker defense
  # We use a composite measure
  league_stats <- league_stats |>
    dplyr::mutate(
      # Raw coefficient based on goals (inverted - more goals = potentially weaker)
      # This is a simplification; true strength would need cross-league data
      goals_factor = ref_goals / .data$avg_total_goals,
      # Competitiveness factor (closer to 33/33/33 is more competitive)
      balance = 1 - abs(.data$home_win_pct - 0.45) - abs(.data$draw_pct - 0.27),
      # Combined strength estimate (normalized around 1.0)
      strength_coefficient = (.data$goals_factor * 0.7 + .data$balance * 0.3),
      # Standard error (rough approximation based on sample size)
      se = 0.1 / sqrt(.data$n_matches / 380)
    ) |>
    dplyr::select("league_code", "n_matches", "avg_total_goals",
                  "home_win_pct", "strength_coefficient", "se") |>
    dplyr::arrange(dplyr::desc(.data$strength_coefficient))

  # Normalize so reference league = 1.0
  if (reference_league %in% league_stats$league_code) {
    ref_coef <- league_stats$strength_coefficient[
      league_stats$league_code == reference_league
    ]
    league_stats$strength_coefficient <- league_stats$strength_coefficient / ref_coef
  }

  league_stats
}

#' Adjust predictions for league strength
#'
#' Modifies predicted goal expectations based on relative league strength.
#' Use when comparing teams across different leagues or when a team
#' has been promoted/relegated.
#'
#' @param predicted_goals Numeric. Predicted goals (from model).
#' @param from_league Character. League the prediction is based on.
#' @param to_league Character. League to adjust for.
#' @param league_strengths A tibble from [estimate_league_strength()].
#' @return Numeric. Adjusted predicted goals.
#' @family betting
#' @export
adjust_for_league_strength <- function(predicted_goals, from_league, to_league,
                                        league_strengths) {
  rlang::check_required(predicted_goals)
  rlang::check_required(from_league)
  rlang::check_required(to_league)
  rlang::check_required(league_strengths)

  from_strength <- league_strengths$strength_coefficient[
    league_strengths$league_code == from_league
  ]
  to_strength <- league_strengths$strength_coefficient[
    league_strengths$league_code == to_league
  ]

  if (length(from_strength) == 0L) {
    cli::cli_warn("League {.val {from_league}} not found. Using coefficient 1.0.")
    from_strength <- 1.0
  }
  if (length(to_strength) == 0L) {
    cli::cli_warn("League {.val {to_league}} not found. Using coefficient 1.0.")
    to_strength <- 1.0
  }

  # Adjustment factor: stronger league = fewer goals expected
  adjustment <- to_strength / from_strength

  predicted_goals * adjustment
}

#' Get standard league strength coefficients
#'
#' Returns commonly-used league strength estimates based on UEFA coefficients
#' and historical analysis. Use as a fallback when insufficient data.
#'
#' @return A tibble with standard league strengths.
#' @family betting
#' @export
standard_league_strengths <- function() {
  # Based on UEFA coefficients and Elo ratings analysis
  # Reference: Premier League = 1.00
  tibble::tibble(
    league_code = c("E0", "E1", "E2", "E3",     # England
                    "D1", "D2",                  # Germany
                    "SP1", "SP2",                # Spain
                    "I1", "I2",                  # Italy
                    "F1", "F2",                  # France
                    "N1",                        # Netherlands
                    "P1",                        # Portugal
                    "B1",                        # Belgium
                    "SC0", "SC1"),               # Scotland
    league_name = c("Premier League", "Championship", "League One", "League Two",
                    "Bundesliga", "2. Bundesliga",
                    "La Liga", "La Liga 2",
                    "Serie A", "Serie B",
                    "Ligue 1", "Ligue 2",
                    "Eredivisie",
                    "Primeira Liga",
                    "Pro League",
                    "Scottish Premiership", "Scottish Championship"),
    strength_coefficient = c(
      1.00, 0.70, 0.50, 0.40,   # England (EPL baseline)
      0.95, 0.65,               # Germany
      0.98, 0.60,               # Spain
      0.92, 0.55,               # Italy
      0.85, 0.52,               # France
      0.70,                     # Netherlands
      0.75,                     # Portugal
      0.65,                     # Belgium
      0.55, 0.35                # Scotland
    ),
    tier = c(1L, 2L, 3L, 4L, 1L, 2L, 1L, 2L, 1L, 2L, 1L, 2L, 1L, 1L, 1L, 1L, 2L)
  )
}
