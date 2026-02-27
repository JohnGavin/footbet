# Adversarial QA: models_dc.R
# Attack vectors: NULL, NA, boundary, degenerate inputs

skip_if_not_installed("goalmodel")

# ---- fit_dixon_coles ----

test_that("fit_dixon_coles: NULL input", {
  expect_error(fit_dixon_coles(NULL))
})

test_that("fit_dixon_coles: non-data.frame input", {
  expect_error(fit_dixon_coles("not a df"), "data frame")
})

test_that("fit_dixon_coles: missing required columns", {
  bad <- tibble::tibble(x = 1:5, y = 6:10)
  expect_error(fit_dixon_coles(bad), "Missing columns")
})

test_that("fit_dixon_coles: all zero goals", {
  matches <- tibble::tibble(
    match_date = as.Date("2024-01-01") + 0:9,
    home_team = rep(c("A", "B", "C", "D", "E"), 2),
    away_team = rep(c("B", "C", "D", "E", "A"), 2),
    fthg = rep(0L, 10),
    ftag = rep(0L, 10)
  )
  model <- fit_dixon_coles(matches)
  expect_true(inherits(model, "goalmodel"))
})

test_that("fit_dixon_coles: xi = 0 means no time decay", {
  set.seed(1)
  matches <- tibble::tibble(
    match_date = as.Date("2024-01-01") + 0:49,
    home_team = rep(c("A", "B", "C", "D", "E"), 10),
    away_team = rep(c("B", "C", "D", "E", "A"), 10),
    fthg = as.integer(rpois(50, 1.5)),
    ftag = as.integer(rpois(50, 1.0))
  )
  model <- fit_dixon_coles(matches, xi = 0)
  expect_true(inherits(model, "goalmodel"))
})

# ---- predict_dc ----

test_that("predict_dc: NULL model errors", {
  expect_error(predict_dc(NULL, "A", "B"))
})

# ---- predict_matches_dc ----

test_that("predict_matches_dc: all unknown teams give all NA", {
  set.seed(1)
  matches <- tibble::tibble(
    match_date = as.Date("2024-01-01") + 0:49,
    home_team = rep(c("A", "B", "C", "D", "E"), 10),
    away_team = rep(c("B", "C", "D", "E", "A"), 10),
    fthg = as.integer(rpois(50, 1.5)),
    ftag = as.integer(rpois(50, 1.0))
  )
  model <- fit_dixon_coles(matches)

  test_df <- tibble::tibble(
    match_id = "m1",
    home_team = "UNKNOWN1",
    away_team = "UNKNOWN2"
  )
  preds <- predict_matches_dc(model, test_df)
  expect_true(is.na(preds$pred_h[1]))
})

# ---- evaluate_dc ----

test_that("evaluate_dc: NULL input errors", {
  expect_error(evaluate_dc(NULL))
})

test_that("evaluate_dc: non-data.frame errors", {
  expect_error(evaluate_dc("not a df"), "data frame")
})
