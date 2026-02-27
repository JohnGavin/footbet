# Tests for R/models_dc.R: fit_dixon_coles, predict_dc, predict_matches_dc, evaluate_dc

# Skip all tests if goalmodel not available
skip_if_not_installed("goalmodel")

# Helper: create mock match data
mock_dc_matches <- function(n = 100, seed = 42) {
  set.seed(seed)
  teams <- c("A", "B", "C", "D", "E", "F")
  dates <- seq.Date(as.Date("2022-01-01"), as.Date("2024-06-30"),
                     length.out = n)
  matches <- tibble::tibble(
    match_id = paste0("m", seq_len(n)),
    match_date = dates,
    home_team = sample(teams, n, replace = TRUE),
    away_team = sample(teams, n, replace = TRUE),
    fthg = as.integer(rpois(n, 1.4)),
    ftag = as.integer(rpois(n, 1.1)),
    season = "2324",
    league_code = "E0"
  )
  same <- matches$home_team == matches$away_team
  matches$away_team[same] <- teams[(match(matches$home_team[same], teams) %% 6) + 1]
  matches$ftr <- dplyr::case_when(
    matches$fthg > matches$ftag ~ "H",
    matches$fthg == matches$ftag ~ "D",
    TRUE ~ "A"
  )
  matches
}

# ---- fit_dixon_coles ----

test_that("fit_dixon_coles fits a valid model", {
  matches <- mock_dc_matches(100)
  model <- fit_dixon_coles(matches)
  expect_true(inherits(model, "goalmodel"))
})

test_that("fit_dixon_coles errors on empty input", {
  empty <- tibble::tibble(
    match_id = character(), match_date = as.Date(character()),
    home_team = character(), away_team = character(),
    fthg = integer(), ftag = integer(), ftr = character()
  )
  expect_error(fit_dixon_coles(empty), "must not be empty")
})

test_that("fit_dixon_coles errors on missing columns", {
  bad <- tibble::tibble(x = 1:5)
  expect_error(fit_dixon_coles(bad), "Missing columns")
})

test_that("fit_dixon_coles: custom xi parameter", {
  matches <- mock_dc_matches(80)
  model_fast <- fit_dixon_coles(matches, xi = 0.01)
  model_slow <- fit_dixon_coles(matches, xi = 0.001)
  # Both should fit
  expect_true(inherits(model_fast, "goalmodel"))
  expect_true(inherits(model_slow, "goalmodel"))
})

# ---- predict_dc ----

test_that("predict_dc returns correct structure", {
  matches <- mock_dc_matches(100)
  model <- fit_dixon_coles(matches)

  pred <- predict_dc(model, "A", "B")
  expect_type(pred, "list")
  expect_named(pred, c("probs_1x2", "probs_ou25", "probs_ah05",
                         "lambda_home", "lambda_away"))
  expect_named(pred$probs_1x2, c("H", "D", "A"))
  expect_equal(sum(pred$probs_1x2), 1, tolerance = 1e-4)
  expect_equal(sum(pred$probs_ou25), 1, tolerance = 1e-4)
  expect_true(pred$lambda_home > 0)
  expect_true(pred$lambda_away > 0)
})

# ---- predict_matches_dc ----

test_that("predict_matches_dc returns predictions for known teams", {
  matches <- mock_dc_matches(100)
  model <- fit_dixon_coles(matches)

  test_matches <- tibble::tibble(
    match_id = c("t1", "t2"),
    home_team = c("A", "B"),
    away_team = c("C", "D")
  )

  preds <- predict_matches_dc(model, test_matches)
  expect_equal(nrow(preds), 2L)
  expect_true(all(!is.na(preds$pred_h)))
  expect_equal(preds$pred_h[1] + preds$pred_d[1] + preds$pred_a[1], 1,
               tolerance = 1e-3)
})

test_that("predict_matches_dc handles unknown teams with NA", {
  matches <- mock_dc_matches(100)
  model <- fit_dixon_coles(matches)

  test_matches <- tibble::tibble(
    match_id = "t1",
    home_team = "UNKNOWN",
    away_team = "A"
  )

  preds <- predict_matches_dc(model, test_matches)
  expect_true(is.na(preds$pred_h[1]))
})

test_that("predict_matches_dc handles empty input", {
  matches <- mock_dc_matches(100)
  model <- fit_dixon_coles(matches)

  empty <- tibble::tibble(
    match_id = character(), home_team = character(), away_team = character()
  )
  preds <- predict_matches_dc(model, empty)
  expect_equal(nrow(preds), 0L)
})

# ---- evaluate_dc ----

test_that("evaluate_dc runs walk-forward evaluation", {
  matches <- mock_dc_matches(400)
  result <- evaluate_dc(matches, train_months = 24L, test_months = 1L)
  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0L)
  expect_true(all(c("fold", "log_loss", "brier", "rps") %in% colnames(result)))
  expect_true(all(result$log_loss > 0))
})

test_that("evaluate_dc returns empty for short data", {
  # Only 3 months of data — too short for 24-month training window
  set.seed(1)
  teams <- c("A", "B", "C", "D")
  matches <- tibble::tibble(
    match_id = paste0("m", 1:20),
    match_date = as.Date("2024-01-01") + 0:19,
    home_team = rep(teams, 5),
    away_team = rep(rev(teams), 5),
    fthg = as.integer(rpois(20, 1.4)),
    ftag = as.integer(rpois(20, 1.1)),
    season = "2324", league_code = "E0"
  )
  matches$ftr <- dplyr::case_when(
    matches$fthg > matches$ftag ~ "H",
    matches$fthg == matches$ftag ~ "D",
    TRUE ~ "A"
  )
  expect_warning(
    result <- evaluate_dc(matches, train_months = 24L),
    "No valid walk-forward splits"
  )
  expect_equal(nrow(result), 0L)
})
