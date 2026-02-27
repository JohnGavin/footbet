# plan_decisions.R
# Decision layer: value bets, Kelly staking, P&L simulation

plan_decisions <- list(

  # Find value bets using GLM baseline predictions
  targets::tar_target(
    value_bets_glm,
    {
      # Get GLM predictions for all matches
      long <- matches_long
      model <- fit_poisson_glm(long)
      preds <- predict_matches_glm(model, parsed_matches)

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

  # P&L summary
  targets::tar_target(
    pnl_summary,
    summarise_pnl(pnl_glm, initial_bankroll = 1000)
  )
)
