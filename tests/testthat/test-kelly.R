test_that("kelly_fraction returns 0 for no edge", {
  # P(win) = 0.5, odds = 2.0 → fair bet → 0 edge
  stake <- kelly_fraction(0.5, 2.0)
  expect_equal(stake, 0)
})

test_that("kelly_fraction returns positive for value bet", {
  # P(win) = 0.6, odds = 2.0 → edge exists
  stake <- kelly_fraction(0.6, 2.0, fraction = 1.0)
  expect_equal(stake, 0.2, tolerance = 1e-10)

  # Quarter Kelly
  stake_qk <- kelly_fraction(0.6, 2.0, fraction = 0.25)
  expect_equal(stake_qk, 0.05, tolerance = 1e-10)
})

test_that("kelly_fraction rejects invalid inputs", {
  expect_error(kelly_fraction(0, 2.0), "between 0 and 1")
  expect_error(kelly_fraction(1, 2.0), "between 0 and 1")
  expect_error(kelly_fraction(0.5, 0.9), "must be > 1")
})

test_that("identify_value_bet flags edge above threshold", {
  result <- identify_value_bet(
    model_prob = 0.55,
    market_prob = 0.50,
    decimal_odds = 2.0,
    min_edge = 0.03
  )
  expect_true(result$is_value)
  expect_equal(result$edge, 0.05)
  expect_true(result$kelly_stake > 0)
})

test_that("identify_value_bet rejects insufficient edge", {
  result <- identify_value_bet(
    model_prob = 0.51,
    market_prob = 0.50,
    decimal_odds = 2.0,
    min_edge = 0.03
  )
  expect_false(result$is_value)
  expect_equal(result$kelly_stake, 0)
})

test_that("identify_value_bet rejects odds outside range", {
  # Odds too low
  result <- identify_value_bet(
    model_prob = 0.80,
    market_prob = 0.70,
    decimal_odds = 1.20,
    min_odds = 1.50
  )
  expect_false(result$is_value)

  # Odds too high
  result <- identify_value_bet(
    model_prob = 0.15,
    market_prob = 0.05,
    decimal_odds = 15.0,
    max_odds = 10.0
  )
  expect_false(result$is_value)
})

test_that("apply_guardrails caps at max_stake", {
  stake <- apply_guardrails(
    stake = 0.10,
    current_bankroll = 1000,
    peak_bankroll = 1000,
    max_stake = 0.03
  )
  expect_equal(stake, 0.03)
})

test_that("apply_guardrails halves during drawdown", {
  stake <- apply_guardrails(
    stake = 0.02,
    current_bankroll = 750,
    peak_bankroll = 1000,
    drawdown_threshold = 0.20
  )
  expect_equal(stake, 0.01)
})
