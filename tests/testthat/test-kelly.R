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

# ---- find_value_bets ----

test_that("find_value_bets identifies bets with sufficient edge", {
  preds <- tibble::tibble(
    match_id = c("m1", "m2"),
    pred_h = c(0.55, 0.40),
    pred_d = c(0.25, 0.30),
    pred_a = c(0.20, 0.30)
  )
  devigged <- tibble::tibble(
    match_id = c("m1", "m2"),
    fair_h = c(0.48, 0.45),
    fair_d = c(0.27, 0.28),
    fair_a = c(0.25, 0.27)
  )
  odds <- tibble::tibble(
    match_id = c("m1", "m2"),
    psh = c(2.00, 2.20),
    psd = c(3.50, 3.50),
    psa = c(4.50, 3.50)
  )

  result <- find_value_bets(preds, devigged, odds)
  expect_s3_class(result, "tbl_df")
  # m1 home: edge = 0.55 - 0.48 = 0.07 > 0.03, odds 2.00 in range
  expect_true("m1" %in% result$match_id)
  expect_true(all(result$edge > 0.03))
  expect_true(all(result$kelly_stake > 0))
})

test_that("find_value_bets returns empty when no edge", {
  preds <- tibble::tibble(
    match_id = "m1", pred_h = 0.48, pred_d = 0.27, pred_a = 0.25
  )
  devigged <- tibble::tibble(
    match_id = "m1", fair_h = 0.48, fair_d = 0.27, fair_a = 0.25
  )
  odds <- tibble::tibble(
    match_id = "m1", psh = 2.00, psd = 3.50, psa = 4.00
  )

  result <- find_value_bets(preds, devigged, odds)
  expect_equal(nrow(result), 0L)
})

test_that("find_value_bets handles NA odds gracefully", {
  preds <- tibble::tibble(
    match_id = "m1", pred_h = 0.55, pred_d = 0.25, pred_a = 0.20
  )
  devigged <- tibble::tibble(
    match_id = "m1", fair_h = 0.48, fair_d = 0.27, fair_a = 0.25
  )
  odds <- tibble::tibble(
    match_id = "m1", psh = NA_real_, psd = NA_real_, psa = NA_real_
  )

  result <- find_value_bets(preds, devigged, odds)
  expect_equal(nrow(result), 0L)
})

# ---- simulate_pnl ----

test_that("simulate_pnl tracks bankroll correctly", {
  bets <- tibble::tibble(
    match_id = c("m1", "m2", "m3"),
    match_date = as.Date("2024-01-01") + c(0, 7, 14),
    outcome = c("H", "H", "A"),
    decimal_odds = c(2.0, 2.5, 3.0),
    kelly_stake = c(0.02, 0.02, 0.02),
    ftr = c("H", "D", "A")  # Win, Loss, Win
  )

  result <- simulate_pnl(bets, initial_bankroll = 1000)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 3L)

  # First bet: win, stake = 0.02 * 1000 = 20, profit = 20 * (2-1) = 20
  expect_equal(result$pnl[1], 20, tolerance = 0.1)
  expect_equal(result$bankroll[1], 1020, tolerance = 0.1)

  # Second bet: loss, stake = 0.02 * 1020 = 20.4, loss = -20.4
  expect_true(result$pnl[2] < 0)

  # Third bet: win
  expect_true(result$pnl[3] > 0)
})

test_that("simulate_pnl handles empty bets", {
  bets <- tibble::tibble(
    match_id = character(), match_date = as.Date(character()),
    outcome = character(), decimal_odds = numeric(),
    kelly_stake = numeric(), ftr = character()
  )
  result <- simulate_pnl(bets)
  expect_equal(nrow(result), 0L)
})

# ---- summarise_pnl ----

test_that("summarise_pnl computes correct metrics", {
  pnl <- tibble::tibble(
    match_id = c("m1", "m2", "m3"),
    match_date = as.Date("2024-01-01") + c(0, 7, 14),
    outcome = c("H", "H", "A"),
    decimal_odds = c(2.0, 2.5, 3.0),
    stake_frac = c(0.02, 0.02, 0.02),
    stake_amount = c(20, 20.4, 19.9),
    pnl = c(20, -20.4, 39.8),
    bankroll = c(1020, 999.6, 1039.4),
    peak_bankroll = c(1020, 1020, 1039.4),
    drawdown = c(0, 0.02, 0)
  )

  result <- summarise_pnl(pnl, initial_bankroll = 1000)
  expect_equal(result$n_bets, 3L)
  expect_equal(result$total_pnl, sum(pnl$pnl), tolerance = 0.01)
  expect_equal(result$max_drawdown, max(pnl$drawdown), tolerance = 1e-10)
  expect_equal(result$win_rate, 2 / 3, tolerance = 1e-10)
})

test_that("summarise_pnl handles empty input", {
  pnl <- tibble::tibble(
    match_id = character(), match_date = as.Date(character()),
    outcome = character(), decimal_odds = numeric(),
    stake_frac = numeric(), stake_amount = numeric(),
    pnl = numeric(), bankroll = numeric(),
    peak_bankroll = numeric(), drawdown = numeric()
  )
  result <- summarise_pnl(pnl)
  expect_equal(result$n_bets, 0L)
})
