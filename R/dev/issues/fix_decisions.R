# fix_decisions.R — Issue #14: Decision layer
#
# Changes made:
# 1. Added find_value_bets() to R/kelly.R — batch scan predictions vs odds
# 2. Added simulate_pnl() to R/kelly.R — P&L simulation with guardrails
# 3. Added summarise_pnl() to R/kelly.R — summary statistics
# 4. Completed plan_decisions.R with 3 targets:
#    - value_bets_glm (identified value bets)
#    - pnl_glm (simulated P&L)
#    - pnl_summary (summary metrics)
# 5. Tests: unit + adversarial for all new exported functions

if (FALSE) {
  devtools::load_all()

  # Mock data for testing
  preds <- tibble::tibble(
    match_id = paste0("m", 1:5),
    pred_h = c(0.55, 0.60, 0.40, 0.50, 0.70),
    pred_d = c(0.25, 0.20, 0.30, 0.30, 0.20),
    pred_a = c(0.20, 0.20, 0.30, 0.20, 0.10)
  )
  devigged <- tibble::tibble(
    match_id = paste0("m", 1:5),
    fair_h = c(0.48, 0.50, 0.45, 0.48, 0.60),
    fair_d = c(0.27, 0.25, 0.28, 0.27, 0.22),
    fair_a = c(0.25, 0.25, 0.27, 0.25, 0.18)
  )
  odds <- tibble::tibble(
    match_id = paste0("m", 1:5),
    psh = c(2.10, 2.00, 2.20, 2.10, 1.65),
    psd = c(3.40, 4.00, 3.50, 3.40, 4.50),
    psa = c(3.50, 4.00, 3.50, 4.00, 5.50)
  )

  vb <- find_value_bets(preds, devigged, odds)
  cat("Value bets found:", nrow(vb), "\n")
  print(vb)

  # Simulate P&L
  bets <- dplyr::mutate(vb,
    match_date = as.Date("2024-01-01") + seq_len(nrow(vb)),
    ftr = c("H", "D", "H")  # mock results
  )
  pnl <- simulate_pnl(bets)
  cat("\nP&L simulation:\n")
  print(summarise_pnl(pnl))
}
