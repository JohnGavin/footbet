#' OAGD Backtest Harness
#'
#' Backtests the OAGD model against Pinnacle closing odds with
#' tiered staking thresholds.
#'
#' @name oagd_backtest
#' @family decisions
NULL

#' Compute edge of model probability over implied probability
#'
#' @param model_prob Numeric. Model probability for an outcome.
#' @param implied_prob Numeric. Devigged market implied probability.
#' @return Numeric. Edge (positive = model sees value).
#' @family decisions
#' @export
oagd_edge <- function(model_prob, implied_prob) {
  model_prob - implied_prob
}

#' Determine stake from edge using tiered thresholds
#'
#' Uses a small tolerance (`1e-9`) to guard against floating-point
#' boundary misses (e.g. `seq()` producing `0.09999...` instead of `0.10`).
#'
#' @param edge Numeric. Model edge over implied probability.
#' @param tau_min Numeric. Minimum edge to place 1-unit bet (default 0.05).
#' @param tau_double Numeric. Edge threshold for 2-unit bet (default 0.10).
#' @return Integer. Stake: 0, 1, or 2 units.
#' @family decisions
#' @export
oagd_stake <- function(edge, tau_min = 0.05, tau_double = 0.10) {
  tol <- 1e-9
  dplyr::case_when(
    edge >= tau_double - tol ~ 2L,
    edge >= tau_min - tol ~ 1L,
    TRUE ~ 0L
  )
}

#' Compute PnL for a single bet
#'
#' @param stake Integer. Units staked (0, 1, or 2).
#' @param odds Numeric. Decimal odds for the outcome bet on.
#' @param won Logical. Whether the outcome occurred.
#' @param transaction_cost Numeric. Proportional cost on stake
#'   (default 0, e.g. 0.02 = 2% commission).
#' @param slippage Numeric. Proportional reduction in effective odds
#'   (default 0, e.g. 0.01 = 1% worse than quoted).
#' @return Numeric. Profit/loss after costs.
#' @family decisions
#' @export
oagd_pnl <- function(stake, odds, won,
                     transaction_cost = 0, slippage = 0) {
  effective_odds <- odds * (1 - slippage)
  gross <- dplyr::if_else(won, stake * (effective_odds - 1), -stake)
  gross - stake * transaction_cost
}

#' Run OAGD backtest for one league-season
#'
#' Fits the rolling model, computes predictions, identifies value
#' bets, and returns PnL for each bet placed.
#'
#' @param data Tibble from [oagd_match_data()], one league-season.
#' @param odds_data Tibble from [oagd_add_odds()] (same matches).
#' @param window Integer. Rolling window size (default 8).
#' @param K Integer. Form lookback (default 4).
#' @param half_life Numeric. Form half-life (default 2).
#' @param beta Numeric. Form weight (default 0.3).
#' @param tau_min Numeric. Min edge to bet (default 0.05).
#' @param tau_double Numeric. Edge for double stake (default 0.10).
#' @param exclude_draws Logical. If `TRUE`, skip draw bets entirely
#'   (default `TRUE` — Skellam overestimates draws, see #78).
#' @param transaction_cost Numeric. Proportional cost on stake (default 0.02).
#' @param slippage Numeric. Proportional odds reduction (default 0.01).
#' @return A tibble of bets placed, with columns: `match_id`,
#'   `season`, `league_code`, `matchday`, `outcome_bet` (H/D/A),
#'   `model_prob`, `implied_prob`, `edge`, `stake`, `odds`, `won`, `pnl`.
#' @family decisions
#' @export
oagd_backtest_league <- function(data,
                                 odds_data,
                                 window = 8L,
                                 K = 4L,
                                 half_life = 2,
                                 beta = 0.3,
                                 tau_min = 0.05,
                                 tau_double = 0.10,
                                 exclude_draws = TRUE,
                                 transaction_cost = 0.02,
                                 slippage = 0.01) {
  rlang::check_required(data)
  rlang::check_required(odds_data)

  # Average total goals for this league-season
  avg_goals <- mean(abs(data$gd_home) + 2 * pmin(data$gd_home, 0) +
                      data$gd_home + 2 * pmax(-data$gd_home, 0),
                    na.rm = TRUE)
  # Simpler: home + away goals
  # gd_home = fthg - ftag, but we don't have individual goals here

  # Use league average ~2.7 as default; could refine per league
  avg_goals <- 2.7

  # Step 1: Rolling fits
  fits <- oagd_roll_fits(data, window = window)

  # Step 2: Residuals
  data_resid <- oagd_residuals(data, fits)

  # Step 3: Form
  form_tbl <- oagd_form(data_resid, K = K, half_life = half_life)

  # Step 4: Predictions
  preds <- oagd_predict_all(data, fits, form_tbl,
                            beta = beta, avg_total_goals = avg_goals)

  # Step 5: Join odds and identify bets
  preds_odds <- dplyr::left_join(
    preds,
    odds_data |>
      dplyr::select("match_id", "odds_h", "odds_d", "odds_a",
                     "implied_h", "implied_d", "implied_a"),
    by = "match_id"
  )

  # Check all 3 outcomes for value
  bets_h <- preds_odds |>
    dplyr::filter(!is.na(.data$pred_h), !is.na(.data$implied_h)) |>
    dplyr::transmute(
      match_id = .data$match_id,
      season = .data$season,
      league_code = .data$league_code,
      matchday = .data$matchday,
      outcome_bet = "H",
      model_prob = .data$pred_h,
      implied_prob = .data$implied_h,
      edge = oagd_edge(.data$pred_h, .data$implied_h),
      odds = .data$odds_h,
      actual_result = dplyr::case_when(
        .data$gd_home > 0L ~ "H",
        .data$gd_home == 0L ~ "D",
        TRUE ~ "A"
      )
    )

  bets_d <- preds_odds |>
    dplyr::filter(!is.na(.data$pred_d), !is.na(.data$implied_d)) |>
    dplyr::transmute(
      match_id = .data$match_id,
      season = .data$season,
      league_code = .data$league_code,
      matchday = .data$matchday,
      outcome_bet = "D",
      model_prob = .data$pred_d,
      implied_prob = .data$implied_d,
      edge = oagd_edge(.data$pred_d, .data$implied_d),
      odds = .data$odds_d,
      actual_result = dplyr::case_when(
        .data$gd_home > 0L ~ "H",
        .data$gd_home == 0L ~ "D",
        TRUE ~ "A"
      )
    )

  bets_a <- preds_odds |>
    dplyr::filter(!is.na(.data$pred_a), !is.na(.data$implied_a)) |>
    dplyr::transmute(
      match_id = .data$match_id,
      season = .data$season,
      league_code = .data$league_code,
      matchday = .data$matchday,
      outcome_bet = "A",
      model_prob = .data$pred_a,
      implied_prob = .data$implied_a,
      edge = oagd_edge(.data$pred_a, .data$implied_a),
      odds = .data$odds_a,
      actual_result = dplyr::case_when(
        .data$gd_home > 0L ~ "H",
        .data$gd_home == 0L ~ "D",
        TRUE ~ "A"
      )
    )

  bet_list <- if (exclude_draws) list(bets_h, bets_a) else list(bets_h, bets_d, bets_a)
  all_bets <- dplyr::bind_rows(bet_list) |>
    dplyr::mutate(
      stake = oagd_stake(.data$edge, tau_min, tau_double),
      won = .data$outcome_bet == .data$actual_result,
      pnl = oagd_pnl(.data$stake, .data$odds, .data$won,
                      transaction_cost, slippage)
    ) |>
    dplyr::filter(.data$stake > 0L)

  all_bets
}

#' Summarise backtest results
#'
#' @param bets Tibble from [oagd_backtest_league()] or multiple
#'   league-seasons combined.
#' @param ... Grouping columns (unquoted), e.g. `league_code, season`.
#' @return Summary tibble with `n_bets`, `n_wins`, `total_pnl`,
#'   `roi_pct`, `sharpe`.
#' @family decisions
#' @export
oagd_backtest_summary <- function(bets, ...) {
  rlang::check_required(bets)

  bets |>
    dplyr::group_by(...) |>
    dplyr::summarise(
      n_bets = dplyr::n(),
      n_wins = sum(.data$won),
      total_staked = sum(.data$stake),
      total_pnl = round(sum(.data$pnl), 2),
      roi_pct = round(100 * sum(.data$pnl) / sum(.data$stake), 1),
      sharpe = {
        n <- dplyr::n()
        s <- if (n >= 2L) stats::sd(.data$pnl) else NA_real_
        dplyr::if_else(!is.na(s) & s > 0, round(mean(.data$pnl) / s, 3), NA_real_)
      },
      max_drawdown = round(min(cumsum(.data$pnl)), 2),
      .groups = "drop"
    )
}

#' Generate hyperparameter grid for OAGD tuning
#'
#' @param windows Integer vector. Window sizes (default `c(6, 8, 10)`).
#' @param half_lives Numeric vector. Form half-lives (default `c(1, 2, 3)`).
#' @param tau_mins Numeric vector. Min edge thresholds (default `c(0.05, 0.07, 0.10)`).
#' @return A tibble with one row per combination.
#' @family decisions
#' @export
oagd_grid <- function(windows = c(6L, 8L, 10L),
                      half_lives = c(1, 2, 3),
                      tau_mins = c(0.05, 0.07, 0.10)) {
  tidyr::expand_grid(
    window = windows,
    half_life = half_lives,
    tau_min = tau_mins
  ) |>
    dplyr::mutate(
      K = 4L,
      beta = 0.3,
      tau_double = pmax(.data$tau_min * 2, 0.10)
    )
}
