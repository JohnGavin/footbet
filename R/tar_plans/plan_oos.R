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

  # Vignette comparison table
  targets::tar_target(
    vig_oos_comparison,
    {
      insample <- pnl_summary |>
        dplyr::mutate(scenario = "In-sample (all data, no costs)", .before = 1)
      insample_real <- pnl_summary_realistic |>
        dplyr::mutate(scenario = "In-sample (all data, tiered + costs)", .before = 1)
      oos <- oos_validate_summary |>
        dplyr::mutate(scenario = "Out-of-sample VALIDATE (2021-2223, tiered + costs)", .before = 1)

      dplyr::bind_rows(insample, insample_real, oos) |>
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
