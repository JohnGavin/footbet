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

# -- Dixon-Coles correction --------------------------------------------------

test_that("dc_tau returns 1 for scorelines > 1", {
  expect_equal(dc_tau(2L, 0L, 1.3, 0.9, -0.13), 1)
  expect_equal(dc_tau(3L, 2L, 1.3, 0.9, -0.13), 1)
})

test_that("dc_tau with rho=0 returns 1 for all scorelines", {
  for (h in 0:2) for (a in 0:2) {
    expect_equal(dc_tau(h, a, 1.3, 0.9, 0), 1)
  }
})

test_that("dc_tau with rho<0 increases 0-0 and 1-1 probability", {
  # rho < 0 in Dixon-Coles means goals are negatively correlated at low scores
  # This INCREASES P(0-0) and P(1-1) — Poisson underestimates these
  expect_true(dc_tau(0L, 0L, 1.3, 0.9, -0.13) > 1)
  expect_true(dc_tau(1L, 1L, 1.3, 0.9, -0.13) > 1)
  # But decreases P(1-0) and P(0-1) — compensating
  expect_true(dc_tau(1L, 0L, 1.3, 0.9, -0.13) < 1)
  expect_true(dc_tau(0L, 1L, 1.3, 0.9, -0.13) < 1)
})

test_that("dc_score_matrix with rho=0 matches independent Poisson", {
  mat_dc <- dc_score_matrix(1.3, 0.9, rho = 0)
  ph <- dpois(0:8, 1.3)
  pa <- dpois(0:8, 0.9)
  mat_pois <- outer(ph, pa)
  mat_pois <- mat_pois / sum(mat_pois)
  expect_equal(mat_dc, mat_pois, tolerance = 1e-10)
})

test_that("predict_ah: home -1.5 requires win by 2+", {
  mat <- dc_score_matrix(1.5, 1.0, rho = 0)
  p <- predict_ah(mat, line = -1.5)
  # P(home covers -1.5) = P(GD >= 2)
  p_manual <- sum(mat[row(mat) - col(mat) >= 2])
  expect_equal(p, p_manual, tolerance = 1e-10)
  expect_true(p > 0 && p < 1)
})

test_that("predict_ah: line = 0 equals P(home win) + 0.5*P(draw)", {
  mat <- dc_score_matrix(1.5, 1.0, rho = 0)
  p <- predict_ah(mat, line = 0)
  probs <- score_matrix_probs(mat)
  expect_equal(p, probs$prob_h + 0.5 * probs$prob_d, tolerance = 1e-10)
})

test_that("predict_ou: 2.5 goals", {
  mat <- dc_score_matrix(1.5, 1.0, rho = 0)
  ou <- predict_ou(mat, total_line = 2.5)
  expect_equal(ou$prob_over + ou$prob_under, 1, tolerance = 1e-10)
  expect_true(ou$prob_over > 0 && ou$prob_over < 1)
  # Manual: sum of all cells where h+a >= 3
  p_over_manual <- sum(mat[(row(mat) - 1) + (col(mat) - 1) >= 3])
  expect_equal(ou$prob_over, p_over_manual, tolerance = 1e-10)
})

test_that("predict_ou: higher lambdas → more overs", {
  mat_low <- dc_score_matrix(0.8, 0.6, rho = 0)
  mat_high <- dc_score_matrix(1.8, 1.5, rho = 0)
  expect_true(predict_ou(mat_high)$prob_over > predict_ou(mat_low)$prob_over)
})

test_that("dc_score_matrix with rho<0 increases P(draw)", {
  probs_0 <- score_matrix_probs(dc_score_matrix(1.3, 0.9, rho = 0))
  probs_dc <- score_matrix_probs(dc_score_matrix(1.3, 0.9, rho = -0.13))
  # rho < 0 increases low-score draws → P(D) goes up
  expect_true(probs_dc$prob_d > probs_0$prob_d)
  expect_equal(probs_dc$prob_h + probs_dc$prob_d + probs_dc$prob_a, 1, tolerance = 1e-6)
})

test_that("oagd_predict_match returns valid probabilities", {
  result <- oagd_predict_match(
    attack_home = 0.3, defence_home = -0.1,
    attack_away = 0.1, defence_away = 0.2,
    eta_home = 0.3, eta_away = 0.1
  )

  expect_equal(result$prob_h + result$prob_d + result$prob_a, 1,
               tolerance = 1e-4)
  expect_true(result$prob_h > 0)
  expect_true(result$prob_d > 0)
  expect_true(result$prob_a > 0)
  expect_true(result$lambda_home > 0)
  expect_true(result$lambda_away > 0)
})

test_that("oagd_predict_match: home advantage via intercept gap", {
  # eta_home > eta_away with equal teams => P(H) > P(A)
  result <- oagd_predict_match(
    attack_home = 0, defence_home = 0,
    attack_away = 0, defence_away = 0,
    eta_home = 0.4, eta_away = 0.1
  )
  expect_true(result$prob_h > result$prob_a)
  expect_true(result$mu > 0)
})

test_that("oagd_predict_match: equal teams equal intercepts", {
  result <- oagd_predict_match(
    attack_home = 0, defence_home = 0,
    attack_away = 0, defence_away = 0,
    eta_home = 0.2, eta_away = 0.2
  )
  expect_equal(result$prob_h, result$prob_a, tolerance = 1e-6)
})

test_that("oagd_predict_match: form shifts prediction", {
  base <- oagd_predict_match(form_home = 0, form_away = 0, beta = 0.5)
  hot <- oagd_predict_match(form_home = 1, form_away = 0, beta = 0.5)
  expect_true(hot$prob_h > base$prob_h)
  expect_true(hot$mu > base$mu)
})

test_that("oagd_predict_match: strong attack vs weak defence", {
  # Good attacker at home vs leaky defender away
  strong <- oagd_predict_match(
    attack_home = 0.5, defence_home = -0.2,
    attack_away = -0.2, defence_away = 0.4,
    eta_home = 0.3, eta_away = 0.1
  )
  # Weak attacker vs solid defender
  weak <- oagd_predict_match(
    attack_home = -0.2, defence_home = 0.4,
    attack_away = 0.5, defence_away = -0.2,
    eta_home = 0.3, eta_away = 0.1
  )
  expect_true(strong$prob_h > weak$prob_h)
})

test_that("oagd_stake applies tiered thresholds correctly", {
  expect_equal(oagd_stake(0.02, tau_min = 0.05, tau_double = 0.10), 0L)
  expect_equal(oagd_stake(0.06, tau_min = 0.05, tau_double = 0.10), 1L)
  expect_equal(oagd_stake(0.15, tau_min = 0.05, tau_double = 0.10), 2L)
  expect_equal(oagd_stake(0.10, tau_min = 0.05, tau_double = 0.10), 2L)
})

test_that("oagd_pnl computes correctly (no costs)", {
  # Win: stake * (odds - 1)
  expect_equal(oagd_pnl(1L, 2.5, TRUE, 0, 0), 1.5)
  expect_equal(oagd_pnl(2L, 3.0, TRUE, 0, 0), 4.0)
  # Lose: -stake
  expect_equal(oagd_pnl(1L, 2.5, FALSE, 0, 0), -1L)
  expect_equal(oagd_pnl(2L, 3.0, FALSE, 0, 0), -2L)
  # No bet
  expect_equal(oagd_pnl(0L, 2.5, TRUE, 0, 0), 0)
})

test_that("oagd_pnl applies transaction costs", {
  # 2% commission: gross 1.5 - 1*0.02 = 1.48
  expect_equal(oagd_pnl(1L, 2.5, TRUE, transaction_cost = 0.02, slippage = 0), 1.48)
  # Lose: -1 - 1*0.02 = -1.02
  expect_equal(oagd_pnl(1L, 2.5, FALSE, transaction_cost = 0.02, slippage = 0), -1.02)
})

test_that("oagd_pnl applies slippage", {
  # 1% slippage: effective odds = 2.5 * 0.99 = 2.475, win = 1.475
  expect_equal(oagd_pnl(1L, 2.5, TRUE, transaction_cost = 0, slippage = 0.01), 1.475)
  # Lose: -1 (slippage only affects winning side)
  expect_equal(oagd_pnl(1L, 2.5, FALSE, transaction_cost = 0, slippage = 0.01), -1)
})

test_that("oagd_pnl applies both costs", {
  # Win: 1 * (2.5 * 0.99 - 1) - 1 * 0.02 = 1.475 - 0.02 = 1.455
  expect_equal(oagd_pnl(1L, 2.5, TRUE, 0.02, 0.01), 1.455)
  # Lose: -1 - 0.02 = -1.02
  expect_equal(oagd_pnl(1L, 2.5, FALSE, 0.02, 0.01), -1.02)
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

test_that("oagd_backtest_summary computes finite Sharpe", {
  bets <- tibble::tibble(
    won = c(TRUE, FALSE, TRUE, FALSE, FALSE),
    stake = c(1L, 1L, 2L, 1L, 2L),
    pnl = c(1.5, -1, 3.0, -1, -2)
  )
  s <- oagd_backtest_summary(bets)
  expect_true(is.finite(s$sharpe))
  expect_equal(s$sharpe, round(mean(bets$pnl) / sd(bets$pnl), 3))
})

test_that("oagd_backtest_summary returns NA Sharpe for 1 bet", {
  bets <- tibble::tibble(won = TRUE, stake = 1L, pnl = 1.5)
  s <- oagd_backtest_summary(bets)
  expect_true(is.na(s$sharpe))
})

test_that("oagd_backtest_summary returns NA Sharpe for identical PnL", {
  bets <- tibble::tibble(won = c(TRUE, TRUE), stake = c(1L, 1L), pnl = c(1.5, 1.5))
  s <- oagd_backtest_summary(bets)
  expect_true(is.na(s$sharpe))
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
  # Strong home attacker vs leaky away defence
  result <- oagd_predict_match(
    attack_home = 0.3, defence_home = -0.1,
    attack_away = -0.1, defence_away = 0.2,
    eta_home = 0.35, eta_away = 0.1
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
    attack_home = 0, defence_home = 0,
    attack_away = 0, defence_away = 0,
    eta_home = 0.3, eta_away = 0.1,
    form_home = 0.8, form_away = -0.4, beta = 0.5
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
    attack_home = 0.2, defence_home = 0,
    attack_away = 0, defence_away = 0.1,
    eta_home = 0.3, eta_away = 0.1
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
