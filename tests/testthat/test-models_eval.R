test_that("log_loss computes correctly for perfect prediction", {
  # Perfect: predicted prob = 1.0 for the event that happened
  ll <- log_loss(rep(1, 10))
  expect_equal(ll, 0, tolerance = 1e-10)
})

test_that("log_loss is higher for worse predictions", {
  good <- log_loss(c(0.9, 0.8, 0.7))
  bad <- log_loss(c(0.1, 0.2, 0.3))
  expect_true(bad > good)
})

test_that("brier_1x2 returns 0 for perfect predictions", {
  bs <- brier_1x2(
    prob_h = c(1, 0, 0),
    prob_d = c(0, 1, 0),
    prob_a = c(0, 0, 1),
    actual = c("H", "D", "A")
  )
  expect_equal(bs, 0)
})

test_that("brier_1x2 returns 2 for worst predictions", {
  # Predict 100% wrong outcome
  bs <- brier_1x2(
    prob_h = c(0, 1, 1),
    prob_d = c(1, 0, 0),
    prob_a = c(0, 0, 0),
    actual = c("H", "D", "A")
  )
  expect_equal(bs, 2)
})

test_that("rps_1x2 returns 0 for perfect predictions", {
  rps <- rps_1x2(
    prob_h = c(1, 0, 0),
    prob_d = c(0, 1, 0),
    prob_a = c(0, 0, 1),
    actual = c("H", "D", "A")
  )
  expect_equal(rps, 0)
})

test_that("walk_forward_splits creates non-empty splits", {
  dates <- seq.Date(as.Date("2020-01-01"), as.Date("2024-12-31"), by = "day")
  splits <- walk_forward_splits(dates, train_months = 24L, test_months = 1L)
  expect_true(length(splits) > 0)

  # Each split should have both train and test indices
  for (s in splits) {
    expect_true(length(s$train_idx) > 0)
    expect_true(length(s$test_idx) > 0)
    # Test dates should be after train dates
    expect_true(max(dates[s$train_idx]) < min(dates[s$test_idx]))
  }
})

test_that("walk_forward_splits: short data returns no splits", {
  dates <- seq.Date(as.Date("2024-01-01"), as.Date("2024-06-30"), by = "week")
  splits <- walk_forward_splits(dates, train_months = 24L, test_months = 1L)
  expect_equal(length(splits), 0L)
})

# ---- pinnacle_implied ----

test_that("pinnacle_implied normalises correctly", {
  odds <- tibble::tibble(
    match_id = "m1",
    psh = 2.10,
    psd = 3.40,
    psa = 3.50
  )
  result <- pinnacle_implied(odds)
  expect_equal(nrow(result), 1L)
  total <- result$implied_h + result$implied_d + result$implied_a
  expect_equal(total, 1, tolerance = 1e-6)
  # Home favourite should have highest implied prob
  expect_true(result$implied_h > result$implied_a)
})

test_that("pinnacle_implied handles NA odds", {
  odds <- tibble::tibble(
    match_id = "m1",
    psh = NA_real_,
    psd = NA_real_,
    psa = NA_real_
  )
  result <- pinnacle_implied(odds)
  expect_true(all(is.na(result$implied_h)))
})

test_that("pinnacle_implied handles empty input", {
  odds <- tibble::tibble(
    match_id = character(),
    psh = numeric(), psd = numeric(), psa = numeric()
  )
  result <- pinnacle_implied(odds)
  expect_equal(nrow(result), 0L)
})

# ---- summarise_cv ----

test_that("summarise_cv computes mean metrics", {
  cv <- tibble::tibble(
    fold = 1:3,
    n_train = c(100L, 100L, 100L),
    n_test = c(10L, 10L, 10L),
    log_loss = c(1.0, 1.1, 1.2),
    brier = c(0.5, 0.6, 0.7),
    rps = c(0.2, 0.25, 0.3)
  )
  result <- summarise_cv(cv)
  expect_equal(nrow(result), 3L)
  expect_equal(result$metric, c("log_loss", "brier", "rps"))
  expect_equal(result$mean[1], mean(cv$log_loss), tolerance = 1e-10)
  expect_equal(result$n_folds[1], 3L)
})

test_that("summarise_cv handles empty input", {
  cv <- tibble::tibble(
    fold = integer(), n_train = integer(), n_test = integer(),
    log_loss = numeric(), brier = numeric(), rps = numeric()
  )
  result <- summarise_cv(cv)
  expect_equal(nrow(result), 0L)
})

# ---- evaluate_glm_baseline ----

test_that("evaluate_glm_baseline runs walk-forward evaluation", {
  # Create 3 years of fake match data
  set.seed(42)
  n_matches <- 400
  teams <- c("A", "B", "C", "D", "E", "F")
  dates <- seq.Date(as.Date("2021-01-01"), as.Date("2024-06-30"),
                     length.out = n_matches)

  matches <- tibble::tibble(
    match_id = paste0("m", seq_len(n_matches)),
    match_date = dates,
    home_team = sample(teams, n_matches, replace = TRUE),
    away_team = sample(teams, n_matches, replace = TRUE),
    fthg = as.integer(rpois(n_matches, 1.4)),
    ftag = as.integer(rpois(n_matches, 1.1)),
    season = "2324",
    league_code = "E0"
  )
  # Ensure home != away
  same <- matches$home_team == matches$away_team
  matches$away_team[same] <- teams[(match(matches$home_team[same], teams) %% 6) + 1]
  matches$ftr <- dplyr::case_when(
    matches$fthg > matches$ftag ~ "H",
    matches$fthg == matches$ftag ~ "D",
    TRUE ~ "A"
  )

  long <- matches_to_long(matches)

  result <- evaluate_glm_baseline(long, matches,
                                   train_months = 24L,
                                   test_months = 1L)
  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0L)
  expect_true(all(c("fold", "log_loss", "brier", "rps") %in% colnames(result)))
  # Log loss should be reasonable (not 0, not huge)
  expect_true(all(result$log_loss > 0))
  expect_true(all(result$log_loss < 5))
})

test_that("evaluate_glm_baseline returns empty for short data", {
  matches <- tibble::tibble(
    match_id = paste0("m", 1:10),
    match_date = as.Date("2024-01-01") + 0:9,
    home_team = rep(c("A", "B"), 5),
    away_team = rep(c("B", "A"), 5),
    fthg = 1L, ftag = 0L, ftr = "H",
    season = "2324", league_code = "E0"
  )
  long <- matches_to_long(matches)

  # Expect warning about insufficient data for walk-forward splits
  expect_warning(
    result <- evaluate_glm_baseline(long, matches,
                                     train_months = 24L, test_months = 1L),
    "No valid walk-forward splits"
  )
  expect_equal(nrow(result), 0L)
})
