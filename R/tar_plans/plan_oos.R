# plan_oos.R
# Out-of-sample evaluation: train on 1516-1920, validate on 2021-2223.
# Test period (2324-2526) is in a separate issue (#67) — run ONCE only.

plan_oos <- list(

  # Temporal split
  targets::tar_target(
    oos_split,
    temporal_split(parsed_matches, train_end = "1920", validate_end = "2223")
  ),

  # Train-period data in long format
  targets::tar_target(
    oos_train_long,
    matches_to_long(oos_split$train)
  ),

  # GLM fitted on train period ONLY
  targets::tar_target(
    oos_glm_train,
    fit_poisson_glm(oos_train_long)
  ),

  # Dixon-Coles fitted on train period ONLY
  targets::tar_target(
    oos_dc_train,
    {
      if (!requireNamespace("goalmodel", quietly = TRUE)) {
        cli::cli_warn("goalmodel not available. Skipping DC train.")
        return(NULL)
      }
      tryCatch(
        fit_dixon_coles(oos_split$train),
        error = function(e) {
          cli::cli_warn("Dixon-Coles failed on train data: {e$message}")
          NULL
        }
      )
    }
  ),

  # Predictions on validate period using TRAIN-fitted GLM
  targets::tar_target(
    oos_validate_predictions,
    predict_matches_glm(oos_glm_train, oos_split$validate)
  ),

  # Devigged odds for validate period
  targets::tar_target(
    oos_validate_odds,
    {
      validate_odds <- dplyr::semi_join(
        parsed_odds, oos_split$validate, by = "match_id"
      )
      devig_odds(validate_odds)
    }
  ),

  # Value bets on validate period
  targets::tar_target(
    oos_validate_bets,
    {
      validate_odds_raw <- parsed_odds |>
        dplyr::semi_join(oos_split$validate, by = "match_id")

      find_value_bets(
        preds = oos_validate_predictions,
        devigged = oos_validate_odds,
        odds = validate_odds_raw,
        min_edge = 0.03,
        min_odds = 1.50,
        max_odds = 10.0
      )
    }
  ),

  # Simulate PnL on validate period with realistic costs
  targets::tar_target(
    oos_validate_pnl,
    {
      bets <- dplyr::inner_join(
        oos_validate_bets,
        dplyr::select(parsed_matches, match_id, ftr, match_date),
        by = "match_id"
      )

      simulate_pnl(
        bets = bets,
        initial_bankroll = 1000,
        transaction_cost = 0.02,
        slippage = 0.01,
        stake_mode = "tiered",
        edge_tiers = c(0.03, 0.05, 0.08, 0.12),
        tier_stakes = c(5, 10, 15, 20, 25)
      )
    }
  ),

  # Summary
  targets::tar_target(
    oos_validate_summary,
    summarise_pnl(oos_validate_pnl, initial_bankroll = 1000)
  ),

  # ====================================================================
  # Calibration (#68): isotonic + Platt on train predictions
  # ====================================================================

  # Train-period predictions (for calibration fitting)
  targets::tar_target(
    oos_train_predictions,
    predict_matches_glm(oos_glm_train, oos_split$train)
  ),

  # Fit isotonic calibration on train predictions vs actual results
  targets::tar_target(
    oos_isotonic,
    {
      train_with_results <- dplyr::inner_join(
        oos_train_predictions,
        dplyr::select(oos_split$train, match_id, ftr),
        by = "match_id"
      ) |>
        dplyr::filter(!is.na(pred_h), !is.na(ftr))

      # Calibrate home win probability
      fit_isotonic_regression(
        predicted = train_with_results$pred_h,
        actual = as.integer(train_with_results$ftr == "H")
      )
    }
  ),

  # Apply isotonic calibration to validate predictions
  targets::tar_target(
    oos_validate_calibrated,
    {
      calibrated <- oos_validate_predictions |>
        dplyr::mutate(
          pred_h_cal = predict_isotonic(oos_isotonic, pred_h),
          pred_a_cal = predict_isotonic(oos_isotonic, pred_a),
          # Renormalise so probs sum to 1
          pred_d_cal = pmax(1 - pred_h_cal - pred_a_cal, 0.01)
        ) |>
        dplyr::mutate(
          total = pred_h_cal + pred_d_cal + pred_a_cal,
          pred_h = pred_h_cal / total,
          pred_d = pred_d_cal / total,
          pred_a = pred_a_cal / total
        ) |>
        dplyr::select(-pred_h_cal, -pred_d_cal, -pred_a_cal, -total)

      calibrated
    }
  ),

  # Value bets using calibrated predictions
  targets::tar_target(
    oos_validate_bets_calibrated,
    {
      validate_odds_raw <- parsed_odds |>
        dplyr::semi_join(oos_split$validate, by = "match_id")

      find_value_bets(
        preds = oos_validate_calibrated,
        devigged = oos_validate_odds,
        odds = validate_odds_raw,
        min_edge = 0.03,
        min_odds = 1.50,
        max_odds = 10.0
      )
    }
  ),

  # PnL with calibrated predictions
  targets::tar_target(
    oos_validate_pnl_calibrated,
    {
      bets <- dplyr::inner_join(
        oos_validate_bets_calibrated,
        dplyr::select(parsed_matches, match_id, ftr, match_date),
        by = "match_id"
      )
      simulate_pnl(bets, initial_bankroll = 1000,
                    transaction_cost = 0.02, slippage = 0.01,
                    stake_mode = "tiered",
                    edge_tiers = c(0.03, 0.05, 0.08, 0.12),
                    tier_stakes = c(5, 10, 15, 20, 25))
    }
  ),

  targets::tar_target(
    oos_validate_summary_calibrated,
    summarise_pnl(oos_validate_pnl_calibrated, initial_bankroll = 1000)
  ),

  # ====================================================================
  # Rolling refit (#69): monthly model updates
  # ====================================================================

  targets::tar_target(
    oos_validate_pnl_rolling,
    {
      validate <- oos_split$validate |>
        dplyr::filter(!is.na(fthg), !is.na(ftag)) |>
        dplyr::arrange(match_date)

      all_matches <- parsed_matches |>
        dplyr::filter(!is.na(fthg), !is.na(ftag))

      # Refit quarterly (every 3 months) to reduce CPU: ~12 fits, not 36
      all_months <- sort(unique(format(validate$match_date, "%Y-%m")))
      validate_months <- all_months[seq(1, length(all_months), by = 3)]

      all_bets <- list()

      for (mo in validate_months) {
        # Current quarter matches (this month + next 2)
        mo_idx <- which(all_months == mo)
        quarter_months <- all_months[mo_idx:min(mo_idx + 2, length(all_months))]
        month_matches <- validate |>
          dplyr::filter(format(match_date, "%Y-%m") %in% quarter_months)
        if (nrow(month_matches) == 0) next

        # Train on preceding 24 months
        end_date <- min(month_matches$match_date)
        start_date <- end_date - 730  # ~24 months
        train_window <- all_matches |>
          dplyr::filter(match_date >= start_date, match_date < end_date)
        if (nrow(train_window) < 100) next

        # Fit GLM on window
        train_long <- matches_to_long(train_window)
        glm_fit <- tryCatch(
          fit_poisson_glm(train_long),
          error = function(e) NULL
        )
        if (is.null(glm_fit)) next

        # Predict current month then discard model (180MB each)
        preds <- tryCatch(
          predict_matches_glm(glm_fit, month_matches),
          error = function(e) NULL
        )
        rm(glm_fit, train_long); gc(verbose = FALSE)
        if (is.null(preds)) next

        # Devig odds for this month
        month_odds_raw <- parsed_odds |>
          dplyr::semi_join(month_matches, by = "match_id")
        month_odds <- devig_odds(month_odds_raw)

        # Find value bets
        month_bets <- tryCatch(
          find_value_bets(preds, month_odds, month_odds_raw,
                          min_edge = 0.03, min_odds = 1.50, max_odds = 10.0),
          error = function(e) tibble::tibble()
        )
        if (nrow(month_bets) > 0) {
          all_bets <- c(all_bets, list(month_bets))
        }
      }

      if (length(all_bets) == 0) {
        return(tibble::tibble(
          n_bets = 0L, total_pnl = 0, roi_pct = 0,
          max_drawdown = 0, final_bankroll = 1000,
          win_rate = NA_real_, avg_odds = NA_real_
        ))
      }

      rolling_bets <- dplyr::bind_rows(all_bets)

      bets_with_results <- dplyr::inner_join(
        rolling_bets,
        dplyr::select(parsed_matches, match_id, ftr, match_date),
        by = "match_id"
      )

      simulate_pnl(bets_with_results, initial_bankroll = 1000,
                    transaction_cost = 0.02, slippage = 0.01,
                    stake_mode = "tiered",
                    edge_tiers = c(0.03, 0.05, 0.08, 0.12),
                    tier_stakes = c(5, 10, 15, 20, 25))
    }
  ),

  targets::tar_target(
    oos_validate_summary_rolling,
    summarise_pnl(oos_validate_pnl_rolling, initial_bankroll = 1000)
  ),

  # ====================================================================
  # Vignette comparison table (all scenarios)
  # ====================================================================

  targets::tar_target(
    vig_oos_comparison,
    {
      scenarios <- list(
        oos_validate_summary |>
          dplyr::mutate(scenario = "OOS static GLM (tiered + costs)", .before = 1),
        oos_validate_summary_calibrated |>
          dplyr::mutate(scenario = "OOS static + isotonic calibration", .before = 1),
        oos_validate_summary_rolling |>
          dplyr::mutate(scenario = "OOS rolling refit (24m window)", .before = 1)
      )

      dplyr::bind_rows(scenarios) |>
        dplyr::mutate(
          dplyr::across(dplyr::where(is.numeric), ~ signif(.x, 4)),
          roi_pct = round(roi_pct, 1),
          max_drawdown = round(max_drawdown * 100, 1),
          win_rate = round(win_rate * 100, 1),
          avg_odds = round(avg_odds, 2)
        )
    }
  )
)
