# Tests for OAGD model (Opposition-Adjusted Goal Difference)

test_that("dskellam computes valid probabilities", {
  probs <- dskellam(-8:8, lambda1 = 1.3, lambda2 = 1.3)
  expect_length(probs, 17L)
  expect_true(all(probs >= 0))
  expect_equal(sum(probs), 1, tolerance = 1e-3)
})

test_that("dskellam is symmetric for equal lambdas", {
  probs <- dskellam(-5:5, lambda1 = 1.5, lambda2 = 1.5)
  # P(k) should equal P(-k)
  for (k in 1:5) {
    expect_equal(probs[6 + k], probs[6 - k], tolerance = 1e-10)
  }
})

test_that("dskellam rejects non-positive lambdas", {
  expect_error(dskellam(0, lambda1 = 0, lambda2 = 1), "must be > 0")
  expect_error(dskellam(0, lambda1 = 1, lambda2 = -1), "must be > 0")
})

test_that("oagd_predict_match returns valid probabilities", {
  result <- oagd_predict_match(
    alpha_home = 0.5, alpha_away = -0.3, eta = 0.3,
    form_home = 0, form_away = 0, beta = 0.3
  )

  expect_equal(result$prob_h + result$prob_d + result$prob_a, 1,
               tolerance = 1e-4)
  expect_true(result$prob_h > 0)
  expect_true(result$prob_d > 0)
  expect_true(result$prob_a > 0)
  expect_true(result$lambda_home > 0)
  expect_true(result$lambda_away > 0)
})

test_that("oagd_predict_match: equal teams with home advantage", {
  result <- oagd_predict_match(
    alpha_home = 0, alpha_away = 0, eta = 0.4,
    form_home = 0, form_away = 0
  )
  expect_true(result$prob_h > result$prob_a)
  expect_true(result$mu > 0)
})

test_that("oagd_predict_match: equal teams no home advantage", {
  result <- oagd_predict_match(
    alpha_home = 0, alpha_away = 0, eta = 0,
    form_home = 0, form_away = 0
  )
  expect_equal(result$prob_h, result$prob_a, tolerance = 1e-6)
})

test_that("oagd_predict_match: form shifts prediction", {
  base <- oagd_predict_match(0, 0, 0.3, form_home = 0, form_away = 0, beta = 0.5)
  hot <- oagd_predict_match(0, 0, 0.3, form_home = 1, form_away = 0, beta = 0.5)
  expect_true(hot$prob_h > base$prob_h)
  expect_true(hot$mu > base$mu)
})

test_that("oagd_stake applies tiered thresholds correctly", {
  expect_equal(oagd_stake(0.02, tau_min = 0.05, tau_double = 0.10), 0L)
  expect_equal(oagd_stake(0.06, tau_min = 0.05, tau_double = 0.10), 1L)
  expect_equal(oagd_stake(0.15, tau_min = 0.05, tau_double = 0.10), 2L)
  expect_equal(oagd_stake(0.10, tau_min = 0.05, tau_double = 0.10), 2L)
})

test_that("oagd_pnl computes correctly", {
  # Win: stake * (odds - 1)
  expect_equal(oagd_pnl(1L, 2.5, TRUE), 1.5)
  expect_equal(oagd_pnl(2L, 3.0, TRUE), 4.0)
  # Lose: -stake

  expect_equal(oagd_pnl(1L, 2.5, FALSE), -1L)
  expect_equal(oagd_pnl(2L, 3.0, FALSE), -2L)
  # No bet
  expect_equal(oagd_pnl(0L, 2.5, TRUE), 0)
})

test_that("oagd_edge computes difference", {
  expect_equal(oagd_edge(0.55, 0.50), 0.05)
  expect_equal(oagd_edge(0.40, 0.50), -0.10)
})

test_that("oagd_grid generates correct dimensions", {
  grid <- oagd_grid()
  expect_equal(nrow(grid), 27L)  # 3 * 3 * 3
  expect_true(all(c("window", "half_life", "tau_min", "K", "beta", "tau_double") %in%
                    names(grid)))
  # tau_double >= 2 * tau_min
  expect_true(all(grid$tau_double >= grid$tau_min * 2))
})

# -- Snapshot tests ----------------------------------------------------------

test_that("snapshot: Skellam distribution shape (equal lambdas)", {
  probs <- dskellam(-8:8, lambda1 = 1.3, lambda2 = 1.3)
  out <- data.frame(gd = -8:8, prob = round(probs, 6))
  expect_snapshot(out)
})

test_that("snapshot: Skellam distribution shape (home-skewed)", {
  probs <- dskellam(-8:8, lambda1 = 1.8, lambda2 = 0.9)
  out <- data.frame(gd = -8:8, prob = round(probs, 6))
  expect_snapshot(out)
})

test_that("snapshot: predict_match canonical scenario", {
  # Strong home team vs weak away, moderate home advantage, no form
  result <- oagd_predict_match(
    alpha_home = 0.5, alpha_away = -0.3, eta = 0.35,
    form_home = 0, form_away = 0, beta = 0.3, avg_total_goals = 2.7
  )
  snap <- data.frame(
    metric = c("mu", "lambda_home", "lambda_away",
               "prob_h", "prob_d", "prob_a"),
    value = round(c(result$mu, result$lambda_home, result$lambda_away,
                    result$prob_h, result$prob_d, result$prob_a), 4)
  )
  expect_snapshot(snap)
})

test_that("snapshot: predict_match with form signal", {
  # Equal teams but home on a hot streak
  result <- oagd_predict_match(
    alpha_home = 0, alpha_away = 0, eta = 0.3,
    form_home = 0.8, form_away = -0.4, beta = 0.5, avg_total_goals = 2.6
  )
  snap <- data.frame(
    metric = c("mu", "lambda_home", "lambda_away",
               "prob_h", "prob_d", "prob_a"),
    value = round(c(result$mu, result$lambda_home, result$lambda_away,
                    result$prob_h, result$prob_d, result$prob_a), 4)
  )
  expect_snapshot(snap)
})

test_that("snapshot: predict_match GD distribution", {
  result <- oagd_predict_match(
    alpha_home = 0.3, alpha_away = 0.1, eta = 0.3,
    form_home = 0, form_away = 0, beta = 0.3, avg_total_goals = 2.7
  )
  gd <- result$gd_dist
  gd$prob <- round(gd$prob, 5)
  expect_snapshot(gd)
})

test_that("snapshot: staking across edge range", {
  edges <- seq(-0.05, 0.20, by = 0.01)
  stakes <- oagd_stake(edges, tau_min = 0.05, tau_double = 0.10)
  out <- data.frame(edge = edges, stake = stakes)
  expect_snapshot(out)
})

test_that("snapshot: grid structure", {
  grid <- oagd_grid()
  expect_snapshot(grid)
})
