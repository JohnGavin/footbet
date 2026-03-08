# Tests for betting performance metrics

# ---- betting_sharpe_ratio ----

test_that("betting_sharpe_ratio computes ratio for positive returns", {
  # Consistent positive returns
  returns <- c(0.1, 0.15, 0.08, 0.12, 0.09, 0.11, 0.13, 0.07, 0.14, 0.10)

  result <- betting_sharpe_ratio(returns)

  expect_true(is.numeric(result))
  expect_true(result > 0)  # Should be positive for consistently profitable
})

test_that("betting_sharpe_ratio returns NA for single return", {
  expect_warning(
    result <- betting_sharpe_ratio(0.1),
    "at least 2 returns"
  )
  expect_true(is.na(result))
})

test_that("betting_sharpe_ratio returns NA for empty returns", {
  result <- betting_sharpe_ratio(numeric(0))
  expect_true(is.na(result))
})

test_that("betting_sharpe_ratio returns NA for constant returns", {
  # Zero variance = undefined Sharpe
  returns <- rep(0.05, 10)
  result <- betting_sharpe_ratio(returns)
  expect_true(is.na(result))
})

test_that("betting_sharpe_ratio handles mixed returns", {
  # Some wins, some losses
  returns <- c(0.5, -1, 0.8, -1, 0.3, -1, 1.2, -1, 0.4, 0.2)

  result <- betting_sharpe_ratio(returns)

  expect_true(is.numeric(result))
  expect_true(!is.na(result))
})

test_that("betting_sharpe_ratio validates numeric input", {
  expect_error(
    betting_sharpe_ratio("abc"),
    "must be numeric"
  )
})

test_that("betting_sharpe_ratio requires returns argument", {
  expect_error(betting_sharpe_ratio())
})

# ---- bet_returns ----

test_that("bet_returns computes winning returns", {
  won <- c(TRUE, TRUE, TRUE)
  odds <- c(2.0, 3.0, 1.5)

  result <- bet_returns(won, odds)

  expect_equal(result, c(1.0, 2.0, 0.5))  # odds - 1
})

test_that("bet_returns computes losing returns", {
  won <- c(FALSE, FALSE, FALSE)
  odds <- c(2.0, 3.0, 1.5)

  result <- bet_returns(won, odds)

  expect_equal(result, c(-1, -1, -1))  # Lose stake
})

test_that("bet_returns handles mixed results", {
  won <- c(TRUE, FALSE, TRUE)
  odds <- c(2.0, 3.0, 1.5)

  result <- bet_returns(won, odds)

  expect_equal(result, c(1.0, -1, 0.5))
})

test_that("bet_returns validates same length", {
  expect_error(
    bet_returns(c(TRUE, FALSE), c(2.0)),
    "same length"
  )
})

test_that("bet_returns requires arguments", {
  expect_error(bet_returns(TRUE))
  expect_error(bet_returns())
})

# ---- summarise_betting_performance ----

test_that("summarise_betting_performance computes all stats", {
  returns <- c(0.5, -1, 0.8, -1, 0.3, -1, 1.2, -1, 0.4, 0.2)

  result <- summarise_betting_performance(returns)

  expect_s3_class(result, "tbl_df")
  expect_equal(result$n_bets, 10L)
  expect_true("total_return" %in% colnames(result))
  expect_true("roi_pct" %in% colnames(result))
  expect_true("win_rate" %in% colnames(result))
  expect_true("sharpe" %in% colnames(result))
  expect_true("max_drawdown" %in% colnames(result))
})

test_that("summarise_betting_performance computes correct ROI", {
  returns <- c(1.0, 1.0, 1.0, 1.0)  # Win 1 unit each

  result <- summarise_betting_performance(returns)

  expect_equal(result$total_return, 4.0)
  expect_equal(result$roi_pct, 100)  # 100% ROI
  expect_equal(result$win_rate, 100)  # 100% win rate
})

test_that("summarise_betting_performance handles empty returns", {
  result <- summarise_betting_performance(numeric(0))

  expect_equal(result$n_bets, 0L)
  expect_true(is.na(result$total_return))
})

test_that("summarise_betting_performance computes max drawdown", {
  # Sequence: +1, +1, -2, -1, +5
  returns <- c(1, 1, -2, -1, 5)
  # Cumulative: 1, 2, 0, -1, 4
  # Running max: 1, 2, 2, 2, 4
  # Drawdown: 0, 0, 2, 3, 0

  result <- summarise_betting_performance(returns)

  expect_equal(result$max_drawdown, 3)  # Peak of 2, trough of -1
})

test_that("summarise_betting_performance requires argument", {
  expect_error(summarise_betting_performance())
})
