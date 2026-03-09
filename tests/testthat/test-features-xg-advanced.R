# Tests for advanced xG features: gamestate-aware xG, ratio normalization,
# reliability thresholds, and xG+xAG composite

# ---- ratio_normalize ----

test_that("ratio_normalize returns team share of total", {
  expect_equal(ratio_normalize(3, 1), 0.75)
  expect_equal(ratio_normalize(1, 1), 0.5)
  expect_equal(ratio_normalize(0, 4), 0)
  expect_equal(ratio_normalize(4, 0), 1)
})

test_that("ratio_normalize handles zero denominator", {
  expect_equal(ratio_normalize(0, 0), 0.5)  # default na_value
  expect_equal(ratio_normalize(0, 0, na_value = 0), 0)
})

test_that("ratio_normalize handles NA values", {
  expect_true(is.na(ratio_normalize(NA, 1)))
  expect_true(is.na(ratio_normalize(1, NA)))
  expect_true(is.na(ratio_normalize(NA, NA)))
})

test_that("ratio_normalize is vectorized", {
  result <- ratio_normalize(c(3, 1, 0), c(1, 1, 4))
  expect_equal(result, c(0.75, 0.5, 0))
})

# ---- compute_gamestate_xg ----

test_that("compute_gamestate_xg classifies gamestates correctly", {
  matches <- tibble::tibble(
    match_date = as.Date(c("2024-01-01", "2024-01-08", "2024-01-15", "2024-01-22")),
    home_team = rep("A", 4),
    away_team = rep("B", 4),
    home_xg = c(1.5, 2.0, 2.5, 3.0),
    away_xg = c(1.0, 1.5, 0.5, 0.5),
    fthg = c(1, 2, 4, 5),  # tied, close, comfortable, lopsided
    ftag = c(1, 1, 2, 0)
  )

  result <- compute_gamestate_xg(matches)
  expect_s3_class(result, "tbl_df")

  # Check gamestate classification
  gamestates <- result$gamestate
  expect_true("tied" %in% gamestates)
  expect_true("close" %in% gamestates)
  expect_true("comfortable" %in% gamestates)
  expect_true("lopsided" %in% gamestates)
})

test_that("compute_gamestate_xg returns rolling features", {
  matches <- tibble::tibble(
    match_date = as.Date("2024-01-01") + 0:9,
    home_team = "A",
    away_team = "B",
    home_xg = rep(1.5, 10),
    away_xg = rep(1.0, 10),
    fthg = rep(1, 10),
    ftag = rep(1, 10)
  )

  result <- compute_gamestate_xg(matches, window = 3L)

  # Should have rolling columns

  expect_true("rolling_xg_for_gs" %in% names(result))
  expect_true("rolling_xg_against_gs" %in% names(result))
  expect_true("rolling_xg_competitive" %in% names(result))

  # First few matches should have NA (not enough history)
  expect_true(is.na(result$rolling_xg_for_gs[1]))
})

test_that("compute_gamestate_xg requires xG and goals", {
  matches <- tibble::tibble(
    match_date = as.Date("2024-01-01"),
    home_team = "A",
    away_team = "B",
    home_xg = 1.5,
    away_xg = 1.0
    # Missing fthg, ftag
  )

  expect_error(compute_gamestate_xg(matches), "Missing required columns")
})

# ---- add_ratio_features ----

test_that("add_ratio_features adds goal ratios when present", {
  matches <- tibble::tibble(
    home_rolling_gf = c(1.5, 2.0),
    away_rolling_gf = c(1.0, 1.0),
    home_rolling_ga = c(1.0, 0.8),
    away_rolling_ga = c(1.2, 1.5)
  )

  result <- add_ratio_features(matches)

  expect_true("home_goals_ratio" %in% names(result))
  expect_true("away_goals_ratio" %in% names(result))

  # Check calculation: home_gf / (home_gf + away_gf)
  expect_equal(result$home_goals_ratio[1], 1.5 / (1.5 + 1.0))
})

test_that("add_ratio_features adds Elo probability when present", {
  matches <- tibble::tibble(
    home_elo = c(1600, 1500),
    away_elo = c(1400, 1500)
  )

  result <- add_ratio_features(matches)

  expect_true("home_elo_prob" %in% names(result))
  # 200 Elo diff should give ~76% expected win prob
  expect_equal(result$home_elo_prob[1], 1 / (1 + 10^(-200/400)), tolerance = 0.01)
  # Equal Elo should give 50%
  expect_equal(result$home_elo_prob[2], 0.5)
})

# ---- reliability_threshold ----

test_that("reliability_threshold computes R-squared by matchday", {
  set.seed(123)
  n_teams <- 20
  n_matches <- 25

  # Create mock data where metric predicts outcome
  matches <- tibble::tibble(
    team = rep(paste0("Team", 1:n_teams), each = n_matches),
    match_num = rep(1:n_matches, n_teams),
    # Metric that improves with more matches
    xg_ratio = 0.5 + rnorm(n_teams * n_matches, sd = 0.1),
    # Outcome correlated with metric
    final_points = 50 + 100 * (0.5 + rnorm(n_teams * n_matches, sd = 0.1) - 0.5)
  )

  result <- reliability_threshold(
    matches,
    metric_col = "xg_ratio",
    outcome_col = "final_points",
    min_matches = 5,
    max_matches = 15
  )

  expect_s3_class(result, "tbl_df")
  expect_true("match_num" %in% names(result))
  expect_true("r_squared" %in% names(result))
  expect_true("is_reliable" %in% names(result))

  # Should have one row per matchday tested
  expect_equal(nrow(result), 11)  # 5 to 15 inclusive
})

test_that("reliability_threshold errors on missing columns", {
  matches <- tibble::tibble(
    team = "A",
    match_num = 1,
    xg_ratio = 0.5
  )

  expect_error(
    reliability_threshold(matches, "xg_ratio", "missing_col"),
    "not found"
  )
})

# ---- first_reliable_matchday ----

test_that("first_reliable_matchday finds threshold crossing", {
  reliability_df <- tibble::tibble(
    match_num = 5:15,
    r_squared = c(0.1, 0.2, 0.3, 0.4, 0.45, 0.52, 0.58, 0.62, 0.65, 0.68, 0.70),
    is_reliable = c(FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE)
  )

  result <- first_reliable_matchday(reliability_df)
  expect_equal(result, 10)  # First TRUE is at index 6, match_num = 10
})

test_that("first_reliable_matchday returns NA when never reliable", {
  reliability_df <- tibble::tibble(
    match_num = 5:10,
    r_squared = c(0.1, 0.2, 0.25, 0.3, 0.35, 0.4),
    is_reliable = rep(FALSE, 6)
  )

  result <- first_reliable_matchday(reliability_df)
  expect_true(is.na(result))
})

# ---- compute_xg_xag_composite ----

test_that("compute_xg_xag_composite combines xG and xAG", {
  matches <- tibble::tibble(
    match_date = as.Date("2024-01-01") + 0:9,
    home_team = "A",
    away_team = "B",
    home_xg = rep(1.5, 10),
    home_xag = rep(0.5, 10),  # xAG
    away_xg = rep(1.0, 10),
    away_xag = rep(0.3, 10)
  )

  result <- compute_xg_xag_composite(matches, window = 3L)

  expect_s3_class(result, "tbl_df")
  expect_true("rolling_xg" %in% names(result))
  expect_true("rolling_xag" %in% names(result))
  expect_true("rolling_xg_xag" %in% names(result))
  expect_true("xg_xag_ratio" %in% names(result))
})

test_that("compute_xg_xag_composite warns without xAG", {
  matches <- tibble::tibble(
    match_date = as.Date("2024-01-01") + 0:4,
    home_team = "A",
    away_team = "B",
    home_xg = rep(1.5, 5),
    away_xg = rep(1.0, 5)
    # No xAG columns
  )

  expect_warning(
    compute_xg_xag_composite(matches),
    "No xAG columns found"
  )
})

test_that("compute_xg_xag_composite errors without xG", {
  matches <- tibble::tibble(
    match_date = as.Date("2024-01-01"),
    home_team = "A",
    away_team = "B"
    # No xG columns
  )

  expect_error(
    compute_xg_xag_composite(matches),
    "Requires"
  )
})
