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
  # Dixon-Coles per-league (#70)
  # ====================================================================

  # Fit DC separately per league on train period
  targets::tar_target(
    oos_dc_per_league,
    {
      if (!requireNamespace("goalmodel", quietly = TRUE)) {
        cli::cli_warn("goalmodel not available. Skipping DC per-league.")
        return(NULL)
      }

      train <- oos_split$train |>
        dplyr::filter(!is.na(fthg), !is.na(ftag))
      leagues <- unique(train$league_code)

      models <- list()
      for (lc in leagues) {
        league_data <- dplyr::filter(train, league_code == lc)
        models[[lc]] <- tryCatch(
          fit_dixon_coles(league_data),
          error = function(e) {
            cli::cli_warn("DC failed for {lc}: {e$message}")
            NULL
          }
        )
      }
      models
    }
  ),

  # Predict validate period using per-league DC models
  targets::tar_target(
    oos_validate_predictions_dc,
    {
      if (is.null(oos_dc_per_league)) {
        return(oos_validate_predictions)  # fallback to GLM
      }

      validate <- oos_split$validate
      leagues <- unique(validate$league_code)
      all_preds <- list()

      for (lc in leagues) {
        model <- oos_dc_per_league[[lc]]
        if (is.null(model)) next
        league_matches <- dplyr::filter(validate, league_code == lc)
        preds <- tryCatch(
          predict_matches_dc(model, league_matches),
          error = function(e) NULL
        )
        if (!is.null(preds)) all_preds <- c(all_preds, list(preds))
      }

      if (length(all_preds) == 0) return(oos_validate_predictions)
      dplyr::bind_rows(all_preds)
    }
  ),

  # Value bets using DC predictions
  targets::tar_target(
    oos_validate_bets_dc,
    {
      validate_odds_raw <- parsed_odds |>
        dplyr::semi_join(oos_split$validate, by = "match_id")

      find_value_bets(
        preds = oos_validate_predictions_dc,
        devigged = oos_validate_odds,
        odds = validate_odds_raw,
        min_edge = 0.03, min_odds = 1.50, max_odds = 10.0
      )
    }
  ),

  # DC OOS summary (flat-stake)
  targets::tar_target(
    oos_validate_summary_dc,
    {
      bets <- dplyr::inner_join(
        oos_validate_bets_dc,
        dplyr::select(parsed_matches, match_id, ftr, match_date),
        by = "match_id"
      ) |>
        dplyr::mutate(
          won = outcome == ftr,
          net = dplyr::if_else(won,
            10 * (decimal_odds * 0.99 - 1), -10) - 10 * 0.02
        )

      tibble::tibble(
        scenario = "OOS Dixon-Coles per-league",
        n_bets = nrow(bets),
        roi_pct = round(sum(bets$net) / (nrow(bets) * 10) * 100, 1),
        win_rate = round(mean(bets$won, na.rm = TRUE) * 100, 1),
        avg_odds = round(mean(bets$decimal_odds), 2)
      )
    }
  ),

  # ====================================================================
  # Market-implied blend (#44)
  # ====================================================================

  # Blend GLM predictions with Pinnacle market probabilities
  # Optimal weight found on TRAIN data, applied to VALIDATE
  targets::tar_target(
    oos_blend_result,
    {
      train_preds <- oos_train_predictions
      train_market <- devigged_odds |>
        dplyr::semi_join(oos_split$train, by = "match_id")
      train_actuals <- oos_split$train |>
        dplyr::select(match_id, ftr) |>
        dplyr::filter(!is.na(ftr))

      blend_with_market(train_preds, train_market, train_actuals)
    }
  ),

  # Apply best blend weight to validate predictions
  targets::tar_target(
    oos_validate_blended,
    {
      w <- oos_blend_result$best_weight
      combined <- dplyr::inner_join(
        oos_validate_predictions, oos_validate_odds, by = "match_id"
      ) |> dplyr::filter(!is.na(pred_h), !is.na(fair_h))

      combined |>
        dplyr::mutate(
          pred_h = (w * pred_h + (1 - w) * fair_h),
          pred_d = (w * pred_d + (1 - w) * fair_d),
          pred_a = (w * pred_a + (1 - w) * fair_a),
          total = pred_h + pred_d + pred_a,
          pred_h = pred_h / total,
          pred_d = pred_d / total,
          pred_a = pred_a / total
        ) |>
        dplyr::select(match_id, pred_h, pred_d, pred_a)
    }
  ),

  # Value bets from blended predictions
  targets::tar_target(
    oos_validate_bets_blended,
    {
      validate_odds_raw <- parsed_odds |>
        dplyr::semi_join(oos_split$validate, by = "match_id")

      find_value_bets(
        preds = oos_validate_blended,
        devigged = oos_validate_odds,
        odds = validate_odds_raw,
        min_edge = 0.03, min_odds = 1.50, max_odds = 10.0
      )
    }
  ),

  # Blended OOS summary (flat-stake)
  targets::tar_target(
    oos_validate_summary_blended,
    {
      bets <- dplyr::inner_join(
        oos_validate_bets_blended,
        dplyr::select(parsed_matches, match_id, ftr, match_date),
        by = "match_id"
      ) |> dplyr::mutate(
        won = outcome == ftr,
        net = dplyr::if_else(won, 10 * (decimal_odds * 0.99 - 1), -10) - 10 * 0.02
      )
      tibble::tibble(
        scenario = paste0("OOS GLM+market blend (",
                          round(oos_blend_result$best_weight * 100), "% model)"),
        n_bets = nrow(bets),
        roi_pct = round(sum(bets$net) / (nrow(bets) * 10) * 100, 1),
        win_rate = round(mean(bets$won, na.rm = TRUE) * 100, 1),
        avg_odds = round(mean(bets$decimal_odds), 2)
      )
    }
  ),

  # ====================================================================
  # XGBoost (#37 / Constantinou 2019)
  # ====================================================================

  targets::tar_target(
    oos_validate_summary_xgb,
    {
      if (!requireNamespace("xgboost", quietly = TRUE)) {
        return(tibble::tibble(
          scenario = "OOS XGBoost (not available)",
          n_bets = NA_integer_, roi_pct = NA_real_,
          win_rate = NA_real_, avg_odds = NA_real_
        ))
      }

      # Use feature matrix with temporal split
      fm <- feature_matrix
      train_fm <- fm |> dplyr::filter(season <= "1920") |>
        dplyr::filter(!is.na(ftr), !is.na(home_elo), !is.na(fair_h))
      validate_fm <- fm |> dplyr::filter(season > "1920", season <= "2223") |>
        dplyr::filter(!is.na(ftr), !is.na(home_elo), !is.na(fair_h))

      feature_cols <- c("home_elo", "away_elo", "elo_diff",
                         "home_roll_gf", "home_roll_ga", "home_roll_gd",
                         "away_roll_gf", "away_roll_ga", "away_roll_gd",
                         "fair_h", "fair_d", "fair_a")
      available <- intersect(feature_cols, names(train_fm))

      xgb_model <- fit_xgboost(
        matches = train_fm,
        features = available,
        target = "ftr",
        objective = "multi:softprob",
        nrounds = 100,
        early_stopping_rounds = 10
      )

      # Predict validate
      preds <- predict_xgboost(xgb_model, validate_fm, features = available)

      pred_df <- tibble::tibble(
        match_id = validate_fm$match_id,
        pred_h = preds[, 1],
        pred_d = preds[, 2],
        pred_a = preds[, 3]
      )

      # Find value bets
      validate_odds_raw <- parsed_odds |>
        dplyr::semi_join(validate_fm, by = "match_id")
      validate_odds_dev <- devig_odds(validate_odds_raw)

      xgb_bets <- find_value_bets(
        preds = pred_df, devigged = validate_odds_dev,
        odds = validate_odds_raw,
        min_edge = 0.03, min_odds = 1.50, max_odds = 10.0
      )

      # Flat-stake ROI
      bets <- dplyr::inner_join(xgb_bets,
        dplyr::select(parsed_matches, match_id, ftr, match_date),
        by = "match_id"
      ) |> dplyr::mutate(
        won = outcome == ftr,
        net = dplyr::if_else(won, 10 * (decimal_odds * 0.99 - 1), -10) - 10 * 0.02
      )

      tibble::tibble(
        scenario = "OOS XGBoost",
        n_bets = nrow(bets),
        roi_pct = round(sum(bets$net) / (nrow(bets) * 10) * 100, 1),
        win_rate = round(mean(bets$won, na.rm = TRUE) * 100, 1),
        avg_odds = round(mean(bets$decimal_odds), 2)
      )
    }
  ),

  # ====================================================================
  # Ranger random forest (alternative to XGBoost, available in nix)
  # ====================================================================

  targets::tar_target(
    oos_validate_summary_ranger,
    {
      if (!requireNamespace("ranger", quietly = TRUE)) {
        return(tibble::tibble(
          scenario = "OOS ranger RF (not available)",
          n_bets = NA_integer_, roi_pct = NA_real_,
          win_rate = NA_real_, avg_odds = NA_real_
        ))
      }

      fm <- feature_matrix
      train_fm <- fm |>
        dplyr::filter(season <= "1920", !is.na(ftr), !is.na(home_elo), !is.na(fair_h))
      validate_fm <- fm |>
        dplyr::filter(season > "1920", season <= "2223", !is.na(ftr), !is.na(home_elo), !is.na(fair_h))

      feature_cols <- c("home_elo", "away_elo", "elo_diff",
                         "home_roll_gf", "home_roll_ga", "home_roll_gd",
                         "away_roll_gf", "away_roll_ga", "away_roll_gd",
                         "fair_h", "fair_d", "fair_a")
      available <- intersect(feature_cols, names(train_fm))
      train_fm$ftr_factor <- factor(train_fm$ftr, levels = c("H", "D", "A"))

      # Fit ranger
      rf <- ranger::ranger(
        ftr_factor ~ .,
        data = train_fm[, c("ftr_factor", available)] |> tidyr::drop_na(),
        num.trees = 500,
        probability = TRUE,
        seed = 42
      )

      # Predict validate
      validate_clean <- validate_fm[, available] |> tidyr::drop_na()
      valid_idx <- complete.cases(validate_fm[, available])
      preds <- stats::predict(rf, validate_clean)$predictions

      pred_df <- tibble::tibble(
        match_id = validate_fm$match_id[valid_idx],
        pred_h = preds[, "H"],
        pred_d = preds[, "D"],
        pred_a = preds[, "A"]
      )

      # Find value bets
      validate_odds_raw <- parsed_odds |>
        dplyr::semi_join(validate_fm[valid_idx, ], by = "match_id")
      validate_odds_dev <- devig_odds(validate_odds_raw)

      rf_bets <- find_value_bets(
        preds = pred_df, devigged = validate_odds_dev,
        odds = validate_odds_raw,
        min_edge = 0.03, min_odds = 1.50, max_odds = 10.0
      )

      bets <- dplyr::inner_join(rf_bets,
        dplyr::select(parsed_matches, match_id, ftr, match_date),
        by = "match_id"
      ) |> dplyr::mutate(
        won = outcome == ftr,
        net = dplyr::if_else(won, 10 * (decimal_odds * 0.99 - 1), -10) - 10 * 0.02
      )

      tibble::tibble(
        scenario = "OOS ranger RF",
        n_bets = nrow(bets),
        roi_pct = round(sum(bets$net) / (nrow(bets) * 10) * 100, 1),
        win_rate = round(mean(bets$won, na.rm = TRUE) * 100, 1),
        avg_odds = round(mean(bets$decimal_odds), 2)
      )
    }
  ),

  # ====================================================================
  # Ranger RF WITHOUT market features (#83 leakage investigation)
  # ====================================================================

  targets::tar_target(
    oos_validate_summary_ranger_clean,
    {
      if (!requireNamespace("ranger", quietly = TRUE)) {
        return(tibble::tibble(
          scenario = "OOS ranger RF (no market features)",
          n_bets = NA_integer_, roi_pct = NA_real_,
          win_rate = NA_real_, avg_odds = NA_real_
        ))
      }

      fm <- feature_matrix
      train_fm <- fm |>
        dplyr::filter(season <= "1920", !is.na(ftr), !is.na(home_elo))
      validate_fm <- fm |>
        dplyr::filter(season > "1920", season <= "2223", !is.na(ftr), !is.na(home_elo))

      # NO market features (fair_h, fair_d, fair_a removed)
      feature_cols <- c("home_elo", "away_elo", "elo_diff",
                         "home_roll_gf", "home_roll_ga", "home_roll_gd",
                         "away_roll_gf", "away_roll_ga", "away_roll_gd")
      available <- intersect(feature_cols, names(train_fm))
      train_fm$ftr_factor <- factor(train_fm$ftr, levels = c("H", "D", "A"))

      rf <- ranger::ranger(
        ftr_factor ~ .,
        data = train_fm[, c("ftr_factor", available)] |> tidyr::drop_na(),
        num.trees = 500,
        probability = TRUE,
        seed = 42
      )

      validate_clean <- validate_fm[, available] |> tidyr::drop_na()
      valid_idx <- complete.cases(validate_fm[, available])
      preds <- stats::predict(rf, validate_clean)$predictions

      pred_df <- tibble::tibble(
        match_id = validate_fm$match_id[valid_idx],
        pred_h = preds[, "H"],
        pred_d = preds[, "D"],
        pred_a = preds[, "A"]
      )

      validate_odds_raw <- parsed_odds |>
        dplyr::semi_join(validate_fm[valid_idx, ], by = "match_id")
      validate_odds_dev <- devig_odds(validate_odds_raw)

      rf_bets <- find_value_bets(
        preds = pred_df, devigged = validate_odds_dev,
        odds = validate_odds_raw,
        min_edge = 0.03, min_odds = 1.50, max_odds = 10.0
      )

      bets <- dplyr::inner_join(rf_bets,
        dplyr::select(parsed_matches, match_id, ftr, match_date),
        by = "match_id"
      ) |> dplyr::mutate(
        won = outcome == ftr,
        net = dplyr::if_else(won, 10 * (decimal_odds * 0.99 - 1), -10) - 10 * 0.02
      )

      tibble::tibble(
        scenario = "OOS ranger RF (no market features)",
        n_bets = nrow(bets),
        roi_pct = round(sum(bets$net) / (nrow(bets) * 10) * 100, 1),
        win_rate = round(mean(bets$won, na.rm = TRUE) * 100, 1),
        avg_odds = round(mean(bets$decimal_odds), 2)
      )
    }
  ),

  # ====================================================================
  # CLV strategy: bet where B365 > Pinnacle closing (soft vs sharp)
  # ====================================================================

  targets::tar_target(
    oos_validate_summary_clv,
    {
      validate <- oos_split$validate |>
        dplyr::filter(!is.na(ftr))

      validate_odds <- parsed_odds |>
        dplyr::semi_join(validate, by = "match_id") |>
        dplyr::filter(!is.na(psh), !is.na(b365h))

      # CLV = betting where Bet365 offers better odds than Pinnacle closing
      # This captures market inefficiency in soft bookmakers
      clv_bets <- list()
      for (i in seq_len(nrow(validate_odds))) {
        row <- validate_odds[i, ]
        for (outcome_info in list(
          list(out = "H", b365 = row$b365h, pin = row$psh),
          list(out = "D", b365 = row$b365d, pin = row$psd),
          list(out = "A", b365 = row$b365a, pin = row$psa)
        )) {
          if (is.na(outcome_info$b365) || is.na(outcome_info$pin)) next
          if (outcome_info$b365 <= 1 || outcome_info$pin <= 1) next
          # CLV = B365 implied prob < Pinnacle implied prob (B365 offers better odds)
          b365_prob <- 1 / outcome_info$b365
          pin_prob <- 1 / outcome_info$pin
          clv <- pin_prob - b365_prob  # positive = B365 is generous
          if (clv > 0.02 && outcome_info$b365 >= 1.5 && outcome_info$b365 <= 10) {
            clv_bets <- c(clv_bets, list(tibble::tibble(
              match_id = row$match_id,
              outcome = outcome_info$out,
              decimal_odds = outcome_info$b365,
              edge = clv,
              kelly_stake = 0.02
            )))
          }
        }
      }

      if (length(clv_bets) == 0) {
        return(tibble::tibble(
          scenario = "OOS CLV (B365 vs Pinnacle)", n_bets = 0L,
          roi_pct = NA_real_, win_rate = NA_real_, avg_odds = NA_real_
        ))
      }

      all_clv <- dplyr::bind_rows(clv_bets) |>
        dplyr::inner_join(
          dplyr::select(validate, match_id, ftr, match_date),
          by = "match_id"
        ) |> dplyr::mutate(
          won = outcome == ftr,
          # Bet at B365 odds with 2% cost (B365 has wider spread, so 0% slippage)
          net = dplyr::if_else(won, 10 * (decimal_odds - 1), -10) - 10 * 0.02
        )

      tibble::tibble(
        scenario = "OOS CLV (B365 vs Pinnacle)",
        n_bets = nrow(all_clv),
        roi_pct = round(sum(all_clv$net) / (nrow(all_clv) * 10) * 100, 1),
        win_rate = round(mean(all_clv$won, na.rm = TRUE) * 100, 1),
        avg_odds = round(mean(all_clv$decimal_odds), 2)
      )
    }
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
  # brms OOS ROI (#59)
  # ====================================================================

  # Fit brms on train period only (not the full brms_full_model which uses all data)
  targets::tar_target(
    oos_brms_train,
    {
      if (!requireNamespace("brms", quietly = TRUE)) {
        cli::cli_warn("brms not available. Skipping brms OOS.")
        return(NULL)
      }

      train_long <- oos_train_long
      tryCatch(
        fit_brms_poisson(train_long,
                         iter = 2000L, warmup = 1000L,
                         chains = 4L, cores = 4L, seed = 42L),
        error = function(e) {
          cli::cli_warn("brms train fit failed: {conditionMessage(e)}")
          NULL
        }
      )
    },
    cue = targets::tar_cue(mode = "thorough")
  ),

  # Predict validate period using train-fitted brms
  targets::tar_target(
    oos_validate_predictions_brms,
    {
      if (is.null(oos_brms_train)) return(tibble::tibble())
      tryCatch(
        predict_matches_brms(oos_brms_train, oos_split$validate),
        error = function(e) {
          cli::cli_warn("brms predict failed: {conditionMessage(e)}")
          tibble::tibble()
        }
      )
    }
  ),

  # Value bets using brms predictions
  targets::tar_target(
    oos_validate_bets_brms,
    {
      if (nrow(oos_validate_predictions_brms) == 0L) return(tibble::tibble())

      validate_odds_raw <- parsed_odds |>
        dplyr::semi_join(oos_split$validate, by = "match_id")

      find_value_bets(
        preds = oos_validate_predictions_brms,
        devigged = oos_validate_odds,
        odds = validate_odds_raw,
        min_edge = 0.03, min_odds = 1.50, max_odds = 10.0
      )
    }
  ),

  # brms OOS summary
  targets::tar_target(
    oos_validate_summary_brms,
    {
      if (nrow(oos_validate_bets_brms) == 0L) {
        return(tibble::tibble(
          scenario = "OOS brms Poisson",
          n_bets = 0L, roi_pct = NA_real_,
          win_rate = NA_real_, avg_odds = NA_real_
        ))
      }

      bets <- dplyr::inner_join(
        oos_validate_bets_brms,
        dplyr::select(parsed_matches, match_id, ftr, match_date),
        by = "match_id"
      ) |> dplyr::mutate(
        won = outcome == ftr,
        net = dplyr::if_else(won, 10 * (decimal_odds * 0.99 - 1), -10) - 10 * 0.02
      )

      tibble::tibble(
        scenario = "OOS brms Poisson",
        n_bets = nrow(bets),
        roi_pct = round(sum(bets$net) / (nrow(bets) * 10) * 100, 1),
        win_rate = round(mean(bets$won, na.rm = TRUE) * 100, 1),
        avg_odds = round(mean(bets$decimal_odds), 2)
      )
    }
  ),

  # ====================================================================
  # Vignette comparison table (all scenarios)
  # ====================================================================

  targets::tar_target(
    vig_oos_comparison,
    {
      # Flat-stake ROI helper
      flat_roi <- function(bets_name, label) {
        bets <- tryCatch(
          dplyr::inner_join(
            targets::tar_read_raw(bets_name),
            dplyr::select(parsed_matches, match_id, ftr, match_date),
            by = "match_id"
          ) |> dplyr::mutate(
            won = outcome == ftr,
            net = dplyr::if_else(won, 10 * (decimal_odds * 0.99 - 1), -10) - 10 * 0.02
          ),
          error = function(e) NULL
        )
        if (is.null(bets) || nrow(bets) == 0) return(NULL)
        tibble::tibble(
          scenario = label,
          n_bets = nrow(bets),
          roi_pct = round(sum(bets$net) / (nrow(bets) * 10) * 100, 1),
          win_rate = round(mean(bets$won, na.rm = TRUE) * 100, 1),
          avg_odds = round(mean(bets$decimal_odds), 2)
        )
      }

      scenarios <- list(
        flat_roi("oos_validate_bets", "OOS static GLM"),
        flat_roi("oos_validate_bets_calibrated", "OOS GLM + isotonic"),
        oos_validate_summary_dc,
        oos_validate_summary_blended,
        oos_validate_summary_ranger,
        oos_validate_summary_ranger_clean,
        oos_validate_summary_clv,
        oos_validate_summary_brms
      )

      # Keep only common columns (scenario, n_bets, roi_pct, win_rate, avg_odds)
      common_cols <- c("scenario", "n_bets", "roi_pct", "win_rate", "avg_odds")
      scenarios_clean <- lapply(scenarios, function(s) {
        if (is.null(s)) return(NULL)
        s[, intersect(common_cols, names(s)), drop = FALSE]
      })
      dplyr::bind_rows(scenarios_clean)
    }
  )
)
