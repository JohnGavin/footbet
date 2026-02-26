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
