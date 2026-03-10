# Tests for advanced betting features: line movement, FLB detection, league strength

# ---- line_movement ----

test_that("line_movement computes movement correctly", {
  odds_df <- tibble::tibble(
    match_id = c("m1", "m2"),
    # Bet365 (opening)
    b365h = c(2.00, 1.50),
    b365d = c(3.50, 4.00),
    b365a = c(4.00, 7.00),
    # Pinnacle (closing) - odds shortened on home
    psh = c(1.80, 1.45),
    psd = c(3.60, 4.20),
    psa = c(4.50, 7.50)
  )

  result <- line_movement(odds_df)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_true("move_h" %in% names(result))
  expect_true("steam_direction" %in% names(result))

  # First match: home odds shortened, so movement toward H
  expect_true(result$move_h[1] > 0)
})

test_that("line_movement identifies steam moves", {
  # Big line movement (>2%)
  odds_df <- tibble::tibble(
    match_id = "steam",
    b365h = 2.50,  # Opening
    b365d = 3.20,
    b365a = 3.00,
    psh = 2.00,    # Closing - big move
    psd = 3.50,
    psa = 3.80
  )

  result <- line_movement(odds_df)

  expect_true(result$is_steam_move)
  expect_equal(result$steam_direction, "H")
})

test_that("analyze_steam_moves returns accuracy stats", {
  odds_df <- tibble::tibble(
    match_id = paste0("m", 1:5),
    b365h = c(2.00, 2.50, 1.80, 3.00, 2.20),
    b365d = c(3.50, 3.20, 3.60, 3.40, 3.30),
    b365a = c(4.00, 3.00, 4.50, 2.40, 3.50),
    psh = c(1.80, 2.30, 1.75, 2.80, 2.10),  # All moved toward home
    psd = c(3.60, 3.40, 3.70, 3.50, 3.40),
    psa = c(4.50, 3.30, 4.70, 2.60, 3.70)
  )

  movement_df <- line_movement(odds_df)
  actual_results <- c("H", "H", "D", "A", "H")  # 3/5 steam moves correct

  result <- analyze_steam_moves(movement_df, actual_results)

  expect_type(result, "list")
  expect_true("summary" %in% names(result))
  expect_true("by_direction" %in% names(result))
})

# ---- detect_flb ----

test_that("detect_flb computes bias by probability bin", {
  set.seed(123)
  n <- 200

  # Create odds with varying implied probabilities
  odds_df <- tibble::tibble(
    psh = runif(n, 1.2, 5.0),
    psd = runif(n, 2.5, 4.5),
    psa = runif(n, 1.5, 6.0)
  )

  # Generate results (slightly biased toward favourites)
  implied_h <- (1 / odds_df$psh) / ((1/odds_df$psh) + (1/odds_df$psd) + (1/odds_df$psa))
  actual_results <- sapply(implied_h, function(p) {
    r <- runif(1)
    if (r < p + 0.02) "H" else if (r < p + 0.35) "D" else "A"
  })

  result <- detect_flb(odds_df, actual_results)

  expect_s3_class(result, "tbl_df")
  expect_true("avg_implied_prob" %in% names(result))
  expect_true("actual_win_rate" %in% names(result))
  expect_true("bias_pct" %in% names(result))
  expect_true("roi_pct" %in% names(result))
})

test_that("summarize_flb categorizes by probability range", {
  flb_df <- tibble::tibble(
    prob_bin = 1:10,
    prob_bin_label = paste0("[", seq(0, 0.9, 0.1), ",", seq(0.1, 1, 0.1), "]"),
    n_bets = rep(100, 10),
    avg_implied_prob = seq(0.05, 0.95, 0.1),
    actual_win_rate = c(0.03, 0.12, 0.22, 0.33, 0.44, 0.57, 0.68, 0.78, 0.87, 0.96),
    bias = c(-0.02, -0.03, -0.03, -0.02, -0.01, 0.02, 0.03, 0.03, 0.02, 0.01),
    bias_pct = c(-2, -3, -3, -2, -1, 2, 3, 3, 2, 1),
    avg_odds = 1 / seq(0.05, 0.95, 0.1),
    roi_pct = c(-5, -10, -8, -3, 0, 5, 8, 6, 3, 1),
    bias_type = c(rep("Trap (overbet)", 4), "Fair", rep("Value (underbet)", 5))
  )

  result <- summarize_flb(flb_df)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 3)
  expect_true("Longshots (<25%)" %in% result$category)
  expect_true("Favourites (>50%)" %in% result$category)
})

test_that("generate_bias_alerts finds value bets", {
  model_probs <- tibble::tibble(
    match_id = c("m1", "m2", "m3"),
    prob_h = c(0.60, 0.40, 0.55),
    prob_d = c(0.25, 0.30, 0.25),
    prob_a = c(0.15, 0.30, 0.20)
  )

  market_odds <- tibble::tibble(
    match_id = c("m1", "m2", "m3"),
    psh = c(1.80, 2.80, 2.00),  # implied ~52%, 33%, 47%
    psd = c(3.60, 3.40, 3.80),
    psa = c(5.00, 2.80, 4.50)
  )

  flb_summary <- tibble::tibble(
    category = c("Longshots (<25%)", "Midrange (25-50%)", "Favourites (>50%)"),
    n_bets = c(1000, 2000, 3000),
    avg_bias_pct = c(-2, 0, 2),  # Value on favourites
    avg_roi_pct = c(-5, 0, 3),
    recommendation = c("Fade longshots", "Neutral", "Back favourites")
  )

  result <- generate_bias_alerts(model_probs, market_odds, flb_summary, min_edge = 0.03)

  expect_s3_class(result, "tbl_df")
  # Should find alerts where model prob > market prob by >3%
  expect_true(nrow(result) > 0)
  expect_true(all(result$edge >= 0.03))
})

# ---- league_strength ----

test_that("estimate_league_strength computes coefficients", {
  matches_df <- tibble::tibble(
    league_code = rep(c("E0", "E1", "D1"), each = 100),
    season = rep("2324", 300),
    home_team = paste0("Team", rep(1:10, 30)),
    away_team = paste0("Team", rep(11:20, 30)),
    fthg = c(rpois(100, 1.5), rpois(100, 1.3), rpois(100, 1.6)),
    ftag = c(rpois(100, 1.2), rpois(100, 1.1), rpois(100, 1.3))
  )

  result <- estimate_league_strength(matches_df, reference_league = "E0")

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 3)
  expect_true("strength_coefficient" %in% names(result))

  # Reference league should have coefficient ~1.0
  ref_coef <- result$strength_coefficient[result$league_code == "E0"]
  expect_equal(ref_coef, 1.0, tolerance = 0.01)
})

test_that("adjust_for_league_strength scales predictions", {
  league_strengths <- tibble::tibble(
    league_code = c("E0", "E1"),
    strength_coefficient = c(1.0, 0.7)
  )

  # Prediction from Championship-level model
  predicted <- 1.5

  # Adjust for Premier League (stronger league = fewer goals expected)
  adjusted <- adjust_for_league_strength(
    predicted,
    from_league = "E1",
    to_league = "E0",
    league_strengths = league_strengths
  )

  # Should increase prediction (E0 is harder than E1)
  expect_true(adjusted > predicted)
  expect_equal(adjusted, 1.5 * (1.0 / 0.7), tolerance = 0.01)
})

test_that("standard_league_strengths returns valid table", {
  result <- standard_league_strengths()

  expect_s3_class(result, "tbl_df")
  expect_true("league_code" %in% names(result))
  expect_true("strength_coefficient" %in% names(result))
  expect_true("E0" %in% result$league_code)

  # EPL should be reference (1.0)
  expect_equal(result$strength_coefficient[result$league_code == "E0"], 1.0)
})
