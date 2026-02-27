# Adversarial QA: R/kelly.R exported functions
# Attack vectors: NULL, NA, boundary values, edge cases

# ---- kelly_fraction ----

test_that("kelly_fraction: NULL inputs", {
  expect_error(kelly_fraction(NULL, 2.0))
  expect_error(kelly_fraction(0.5, NULL))
})

test_that("kelly_fraction: NA inputs", {
  expect_error(kelly_fraction(NA, 2.0))
  expect_error(kelly_fraction(0.5, NA))
})

test_that("kelly_fraction: prob at boundaries", {
  expect_error(kelly_fraction(0, 2.0))
  expect_error(kelly_fraction(1, 2.0))
  expect_error(kelly_fraction(-0.1, 2.0))
  expect_error(kelly_fraction(1.1, 2.0))
})

test_that("kelly_fraction: odds at boundary", {
  expect_error(kelly_fraction(0.5, 1.0))
  expect_error(kelly_fraction(0.5, 0.5))
})

test_that("kelly_fraction: fraction = 0 always returns 0", {
  stake <- kelly_fraction(0.9, 2.0, fraction = 0)
  expect_equal(stake, 0)
})

test_that("kelly_fraction: fraction > 1 (aggressive)", {
  # Should still work, just scale up
  stake <- kelly_fraction(0.6, 2.0, fraction = 2.0)
  expect_true(stake > 0)
})

test_that("kelly_fraction: very small edge", {
  # P(win) = 0.501, odds = 2.0 → tiny edge
  stake <- kelly_fraction(0.501, 2.0, fraction = 1.0)
  expect_true(stake > 0)
  expect_true(stake < 0.01)
})

test_that("kelly_fraction: character input", {
  expect_error(kelly_fraction("0.5", 2.0))
})

# ---- identify_value_bet ----

test_that("identify_value_bet: zero model prob", {
  result <- identify_value_bet(0.0, 0.5, 2.0)
  expect_false(result$is_value)
})

test_that("identify_value_bet: model prob = 1 handled gracefully", {
  # Edge case: certainty — should not crash, clamps internally
  result <- identify_value_bet(1.0, 0.5, 2.0)
  expect_true(result$is_value)
  expect_true(result$kelly_stake > 0)
})

test_that("identify_value_bet: negative edge", {
  result <- identify_value_bet(0.40, 0.50, 2.0)
  expect_false(result$is_value)
  expect_true(result$edge < 0)
})

test_that("identify_value_bet: edge exactly at threshold", {
  result <- identify_value_bet(0.53, 0.50, 2.0, min_edge = 0.03)
  expect_true(result$is_value)
})

test_that("identify_value_bet: edge just below threshold", {
  result <- identify_value_bet(0.529, 0.50, 2.0, min_edge = 0.03)
  expect_false(result$is_value)
})

# ---- apply_guardrails ----

test_that("apply_guardrails: zero peak bankroll handled gracefully", {
  # peak_bankroll = 0 means drawdown is NA, function returns capped stake
  result <- apply_guardrails(0.02, 0, 0)
  expect_true(is.numeric(result))
  expect_equal(result, 0.02)  # No halving since drawdown is NA
})

test_that("apply_guardrails: zero current with nonzero peak", {
  # 100% drawdown
  result <- suppressWarnings(apply_guardrails(0.02, 0, 1000))
  expect_true(is.numeric(result))
  expect_true(result <= 0.015)  # Should halve
})

test_that("apply_guardrails: negative bankroll", {
  # Bankroll can go negative (margin trading)
  result <- apply_guardrails(0.02, -100, 1000, drawdown_threshold = 0.20)
  expect_true(result <= 0.01)  # Should halve
})

test_that("apply_guardrails: bankroll > peak (impossible but test)", {
  result <- apply_guardrails(0.02, 1200, 1000)
  expect_true(result <= 0.03)
})

test_that("apply_guardrails: drawdown exactly at threshold", {
  # 20% drawdown exactly
  result <- apply_guardrails(0.02, 800, 1000, drawdown_threshold = 0.20)
  # Drawdown = 0.20, not > 0.20, so should NOT halve
  expect_equal(result, 0.02)
})

# ---- find_value_bets ----

test_that("find_value_bets: NULL inputs error", {
  expect_error(find_value_bets(NULL, tibble::tibble(), tibble::tibble()))
  expect_error(find_value_bets(tibble::tibble(), NULL, tibble::tibble()))
  expect_error(find_value_bets(tibble::tibble(), tibble::tibble(), NULL))
})

test_that("find_value_bets: non-data.frame input errors", {
  expect_error(find_value_bets("x", tibble::tibble(), tibble::tibble()),
               "data frames")
})

test_that("find_value_bets: no matching match_ids returns empty", {
  preds <- tibble::tibble(
    match_id = "m1", pred_h = 0.55, pred_d = 0.25, pred_a = 0.20
  )
  devigged <- tibble::tibble(
    match_id = "m2", fair_h = 0.48, fair_d = 0.27, fair_a = 0.25
  )
  odds <- tibble::tibble(
    match_id = "m3", psh = 2.0, psd = 3.5, psa = 4.0
  )

  result <- find_value_bets(preds, devigged, odds)
  expect_equal(nrow(result), 0L)
})

test_that("find_value_bets: best value bet per match (takes H, D, or A)", {
  preds <- tibble::tibble(
    match_id = "m1", pred_h = 0.60, pred_d = 0.30, pred_a = 0.10
  )
  devigged <- tibble::tibble(
    match_id = "m1", fair_h = 0.50, fair_d = 0.25, fair_a = 0.25
  )
  odds <- tibble::tibble(
    match_id = "m1", psh = 2.0, psd = 3.5, psa = 4.0
  )

  result <- find_value_bets(preds, devigged, odds)
  # H edge = 0.10, D edge = 0.05 — both qualify, should return both
  expect_true(nrow(result) >= 1L)
  expect_true("H" %in% result$outcome)
})

# ---- simulate_pnl ----

test_that("simulate_pnl: NULL input errors", {
  expect_error(simulate_pnl(NULL))
})

test_that("simulate_pnl: non-data.frame input errors", {
  expect_error(simulate_pnl("not a df"), "data frame")
})

test_that("simulate_pnl: all losses drain bankroll", {
  bets <- tibble::tibble(
    match_id = paste0("m", 1:5),
    match_date = as.Date("2024-01-01") + 0:4,
    outcome = rep("H", 5),
    decimal_odds = rep(2.0, 5),
    kelly_stake = rep(0.03, 5),
    ftr = rep("A", 5)  # All losses
  )
  result <- simulate_pnl(bets, initial_bankroll = 1000)
  expect_true(all(result$pnl < 0))
  expect_true(result$bankroll[5] < 1000)
})

test_that("simulate_pnl: all wins grow bankroll", {
  bets <- tibble::tibble(
    match_id = paste0("m", 1:5),
    match_date = as.Date("2024-01-01") + 0:4,
    outcome = rep("H", 5),
    decimal_odds = rep(2.0, 5),
    kelly_stake = rep(0.02, 5),
    ftr = rep("H", 5)  # All wins
  )
  result <- simulate_pnl(bets, initial_bankroll = 1000)
  expect_true(all(result$pnl > 0))
  expect_true(result$bankroll[5] > 1000)
})

# ---- summarise_pnl ----

test_that("summarise_pnl: NULL input errors", {
  expect_error(summarise_pnl(NULL))
})

test_that("summarise_pnl: single bet", {
  pnl <- tibble::tibble(
    match_id = "m1", match_date = as.Date("2024-01-01"),
    outcome = "H", decimal_odds = 2.0,
    stake_frac = 0.02, stake_amount = 20,
    pnl = 20, bankroll = 1020,
    peak_bankroll = 1020, drawdown = 0
  )
  result <- summarise_pnl(pnl)
  expect_equal(result$n_bets, 1L)
  expect_equal(result$win_rate, 1)
})
