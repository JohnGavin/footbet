# plan_decisions.R
# Decision layer: value bets, Kelly staking, P&L simulation

plan_decisions <- list(

  # Find value bets using GLM baseline predictions
  targets::tar_target(
    value_bets_glm,
    {
      # Fit per-league to avoid 222-team design matrix (OOM)
      leagues <- unique(parsed_matches$league_code)
      all_preds <- purrr::map(leagues, function(lg) {
        lg_long <- matches_long[matches_long$league_code == lg, ]
        lg_matches <- parsed_matches[parsed_matches$league_code == lg, ]
        if (nrow(lg_long) < 100L) return(NULL)
        tryCatch({
          model <- fit_poisson_glm(lg_long)
          predict_matches_glm(model, lg_matches)
        }, error = function(e) NULL)
      })
      preds <- dplyr::bind_rows(all_preds)

      find_value_bets(
        preds = preds,
        devigged = devigged_odds,
        odds = parsed_odds,
        min_edge = 0.03,
        min_odds = 1.50,
        max_odds = 10.0
      )
    }
  ),

  # Simulate P&L for GLM value bets
  targets::tar_target(
    pnl_glm,
    {
      # Join value bets with actual results and dates
      bets <- dplyr::inner_join(
        value_bets_glm,
        dplyr::select(parsed_matches, match_id, ftr, match_date),
        by = "match_id"
      )

      simulate_pnl(
        bets = bets,
        initial_bankroll = 1000,
        drawdown_threshold = 0.20,
        max_stake = 0.03
      )
    }
  ),

  # P&L summary (optimistic — no costs)
  targets::tar_target(
    pnl_summary,
    summarise_pnl(pnl_glm, initial_bankroll = 1000)
  ),

  # Realistic P&L: 2% transaction cost, 1% slippage, tiered stakes by edge
  targets::tar_target(
    pnl_glm_realistic,
    {
      bets <- dplyr::inner_join(
        value_bets_glm,
        dplyr::select(parsed_matches, match_id, ftr, match_date),
        by = "match_id"
      )

      simulate_pnl(
        bets = bets,
        initial_bankroll = 1000,
        drawdown_threshold = 0.20,
        max_stake = 0.03,
        transaction_cost = 0.02,
        slippage = 0.01,
        stake_mode = "tiered",
        edge_tiers = c(0.03, 0.05, 0.08, 0.12),
        tier_stakes = c(5, 10, 15, 20, 25)
      )
    }
  ),

  # Realistic P&L summary
  targets::tar_target(
    pnl_summary_realistic,
    summarise_pnl(pnl_glm_realistic, initial_bankroll = 1000)
  )
)
