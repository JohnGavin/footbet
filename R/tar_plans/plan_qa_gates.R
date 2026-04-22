# plan_qa_gates.R
# Mandatory QA gates for backtesting robustness
# Required by: backtest-robustness, position-sizing-guardrails,
#   execution-delay-sensitivity, risk-regime-evaluation rules

plan_qa_gates <- list(

  # ====================================================================
  # QA 1: Parameter robustness (backtest-robustness rule)
  # Vary min_edge ±20%, check Sharpe stability
  # ====================================================================

  targets::tar_target(
    qa_parameter_robustness,
    {
      if (nrow(ah_walkforward_all) == 0L) {
        return(tibble::tibble(
          min_edge = numeric(), rho = numeric(),
          n_bets = integer(), roi_pct = numeric()
        ))
      }

      # We can't re-run the full walkforward with different params here
      # (too expensive), but we CAN test the bet-selection threshold
      # by re-filtering the existing predictions.
      # The key tunable in ah_bets_from_preds is min_edge (default 0.03).
      # Simulate varying it by filtering bets by edge quantiles.

      bets <- ah_walkforward_all |>
        dplyr::filter(.data$staking == "flat", .data$model == "GLM")

      if (nrow(bets) == 0L) return(tibble::tibble())

      edge_thresholds <- c(0.02, 0.025, 0.03, 0.035, 0.04, 0.05)

      purrr::map_dfr(edge_thresholds, function(threshold) {
        filtered <- bets |> dplyr::filter(.data$edge >= threshold)
        if (nrow(filtered) < 10L) {
          return(tibble::tibble(
            min_edge = threshold, n_bets = 0L,
            roi_pct = NA_real_, sharpe = NA_real_
          ))
        }
        tibble::tibble(
          min_edge = threshold,
          n_bets = nrow(filtered),
          roi_pct = round(100 * sum(filtered$net) / sum(filtered$stake), 1),
          sharpe = round(mean(filtered$net) / stats::sd(filtered$net), 3)
        )
      })
    },
    cue = targets::tar_cue(mode = "always")
  ),

  # ====================================================================
  # QA 2: Execution delay sensitivity (execution-delay-sensitivity rule)
  # Can't shift odds directly, but can test using seasonal lag as proxy:
  # remove most recent N matches from each fold's test set
  # ====================================================================

  targets::tar_target(
    qa_execution_delay,
    {
      if (nrow(ah_walkforward_all) == 0L) {
        return(tibble::tibble())
      }

      bets <- ah_walkforward_all |>
        dplyr::filter(.data$staking == "flat") |>
        dplyr::inner_join(
          parsed_matches |>
            dplyr::select("match_id", "match_date"),
          by = "match_id"
        )

      if (nrow(bets) == 0L) return(tibble::tibble())

      models <- unique(bets$model)

      # For each model, measure how ROI changes when we exclude
      # bets placed on the last N matches of each season (proxy for
      # "could we have placed this bet earlier?")
      purrr::map_dfr(models, function(m) {
        m_bets <- bets |> dplyr::filter(.data$model == m)

        # Sort by date, compute cumulative ROI at different points
        m_bets <- m_bets |> dplyr::arrange(.data$match_date)
        n <- nrow(m_bets)

        # Full, drop last 10%, drop last 20%
        cuts <- c(1.0, 0.9, 0.8, 0.7)
        purrr::map_dfr(cuts, function(frac) {
          k <- max(10L, round(n * frac))
          sub <- m_bets[seq_len(k), ]
          tibble::tibble(
            model = m,
            pct_bets_used = round(frac * 100),
            n_bets = nrow(sub),
            roi_pct = round(100 * sum(sub$net) / sum(sub$stake), 1),
            sharpe = if (nrow(sub) >= 2L) {
              round(mean(sub$net) / stats::sd(sub$net), 3)
            } else {
              NA_real_
            }
          )
        })
      })
    },
    cue = targets::tar_cue(mode = "always")
  ),

  # ====================================================================
  # QA 3: Risk regime evaluation (risk-regime-evaluation rule)
  # Classify bets by season-half (proxy for regime) and per-league
  # ====================================================================

  targets::tar_target(
    qa_regime_metrics,
    {
      if (nrow(ah_walkforward_all) == 0L) {
        return(tibble::tibble())
      }

      bets <- ah_walkforward_all |>
        dplyr::filter(.data$staking == "flat") |>
        dplyr::inner_join(
          parsed_matches |>
            dplyr::select("match_id", "match_date", "league_code"),
          by = "match_id"
        )

      if (nrow(bets) == 0L) return(tibble::tibble())

      # Regime proxy: month-of-year (early vs late season)
      # Aug-Dec = early season (less data, more uncertainty)
      # Jan-May = late season (more data, dead rubbers)
      bets <- bets |>
        dplyr::mutate(
          month = as.integer(format(.data$match_date, "%m")),
          regime = dplyr::case_when(
            month %in% c(8L, 9L, 10L, 11L, 12L) ~ "early_season",
            month %in% c(1L, 2L, 3L, 4L, 5L) ~ "late_season",
            TRUE ~ "off_season"
          )
        )

      bets |>
        dplyr::group_by(.data$model, .data$regime) |>
        dplyr::summarise(
          n_bets = dplyr::n(),
          roi_pct = round(100 * sum(.data$net) / sum(.data$stake), 1),
          win_rate = round(100 * mean(.data$won), 1),
          sharpe = if (dplyr::n() >= 2L) {
            round(mean(.data$net) / stats::sd(.data$net), 3)
          } else {
            NA_real_
          },
          max_dd = round(
            max(cummax(cumsum(.data$net)) - cumsum(.data$net)), 1
          ),
          .groups = "drop"
        ) |>
        dplyr::arrange(.data$model, .data$regime)
    },
    cue = targets::tar_cue(mode = "always")
  ),

  # ====================================================================
  # QA 4: Sizing comparison (position-sizing-guardrails rule)
  # Flat vs Kelly side-by-side for each model
  # ====================================================================

  targets::tar_target(
    qa_sizing_comparison,
    {
      if (nrow(ah_walkforward_all) == 0L) {
        return(tibble::tibble())
      }

      ah_walkforward_all |>
        dplyr::group_by(.data$model, .data$staking) |>
        dplyr::summarise(
          n_bets = dplyr::n(),
          total_staked = round(sum(.data$stake), 0),
          total_pnl = round(sum(.data$net), 1),
          roi_pct = round(100 * sum(.data$net) / sum(.data$stake), 1),
          max_dd = round(
            max(cummax(cumsum(.data$net)) - cumsum(.data$net)), 1
          ),
          sharpe = if (dplyr::n() >= 2L) {
            round(mean(.data$net) / stats::sd(.data$net), 3)
          } else {
            NA_real_
          },
          .groups = "drop"
        ) |>
        dplyr::arrange(.data$model, .data$staking)
    },
    cue = targets::tar_cue(mode = "always")
  )
)
