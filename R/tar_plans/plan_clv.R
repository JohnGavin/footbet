# Closing Line Value (CLV) diagnostic targets
#
# Post-hoc evaluation of walk-forward AH bet tibbles against market
# closing AH prices. See R/clv.R for the underlying functions and
# plans/MODEL_CATALOGUE.md for the rationale.
#
# Note: parse_fd_odds() does not currently emit the closing AH columns,
# so these targets re-parse the raw CSVs via load_closing_ah_prices().
# This keeps the diagnostic isolated and avoids schema-level cache busts
# on the main odds pipeline.

plan_clv <- list(
  # Closing AH prices keyed by match_id, sourced directly from raw CSVs.
  targets::tar_target(
    closing_ah_prices,
    load_closing_ah_prices("inst/extdata/raw")
  ),

  # Per-bet CLV for each walk-forward AH bet tibble.
  targets::tar_target(
    oos_ah_ranger_clv,
    attach_clv(oos_ah_ranger, closing_ah_prices)
  ),
  targets::tar_target(
    oos_ah_ensemble_clv,
    attach_clv(oos_ah_ensemble, closing_ah_prices)
  ),

  # CLV + beat-the-close summaries, overall + stratified by league.
  targets::tar_target(
    oos_ah_ranger_clv_summary,
    summarise_ah_clv(oos_ah_ranger_clv, scenario = "Ranger AH")
  ),
  targets::tar_target(
    oos_ah_ensemble_clv_summary,
    summarise_ah_clv(oos_ah_ensemble_clv, scenario = "Ensemble AH")
  ),

  # Combined summary for vignettes and the null-result writeup.
  targets::tar_target(
    oos_ah_clv_summary,
    dplyr::bind_rows(
      oos_ah_ranger_clv_summary,
      oos_ah_ensemble_clv_summary
    )
  )
)
