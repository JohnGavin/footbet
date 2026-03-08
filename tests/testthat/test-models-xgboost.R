# Tests for XGBoost model wrapper (Issue #37)

# ---- Test data ----

make_test_matches <- function(n = 100L) {
  set.seed(42)
  tibble::tibble(
    home_team = sample(c("Arsenal", "Chelsea", "Liverpool", "ManCity"), n, replace = TRUE),
    away_team = sample(c("Spurs", "United", "Villa", "Wolves"), n, replace = TRUE),
    fthg = rpois(n, 1.5),
    ftag = rpois(n, 1.2),
    ftr = dplyr::case_when(
      fthg > ftag ~ "H",
      fthg < ftag ~ "A",
      TRUE ~ "D"
    ),
    home_elo = rnorm(n, 1500, 100),
    away_elo = rnorm(n, 1500, 100),
    elo_diff = home_elo - away_elo,
    home_goals_scored_rolling = runif(n, 1, 3),
    home_goals_conceded_rolling = runif(n, 0.8, 2),
    away_goals_scored_rolling = runif(n, 1, 2.5),
    away_goals_conceded_rolling = runif(n, 1, 2),
    home_rest_days = sample(3:14, n, replace = TRUE),
    away_rest_days = sample(3:14, n, replace = TRUE),
    rest_advantage = home_rest_days - away_rest_days,
    home_position = sample(1:20, n, replace = TRUE),
    away_position = sample(1:20, n, replace = TRUE),
    position_diff = away_position - home_position
  )
}

# ---- prepare_xgb_features ----

test_that("prepare_xgb_features: extracts specified features", {
  matches <- make_test_matches(50)
  features <- c("home_elo", "away_elo", "elo_diff")

  result <- prepare_xgb_features(matches, features)

  expect_type(result, "list")
  expect_true("x" %in% names(result))
  expect_true("feature_names" %in% names(result))
  expect_equal(ncol(result$x), 3L)
  expect_equal(result$feature_names, features)
})

test_that("prepare_xgb_features: handles missing features with warning", {
  matches <- make_test_matches(50)
  features <- c("home_elo", "nonexistent_feature")

  expect_warning(
    result <- prepare_xgb_features(matches, features),
    "Features not found"
  )

  expect_equal(ncol(result$x), 1L)
  expect_equal(result$feature_names, "home_elo")
})

test_that("prepare_xgb_features: errors when no features found", {
  matches <- make_test_matches(50)
  features <- c("nonexistent1", "nonexistent2")

  expect_error(
    prepare_xgb_features(matches, features),
    "No requested features found"
  )
})

test_that("prepare_xgb_features: imputes NA with median", {
  matches <- make_test_matches(50)
  matches$home_elo[1:10] <- NA

  result <- prepare_xgb_features(matches, "home_elo")

  expect_false(any(is.na(result$x)))
})

test_that("prepare_xgb_features: returns numeric matrix", {
  matches <- make_test_matches(50)
  features <- c("home_elo", "away_elo")

  result <- prepare_xgb_features(matches, features)

  expect_true(is.matrix(result$x))
  expect_equal(storage.mode(result$x), "double")
})

# ---- fit_xgboost ----

test_that("fit_xgboost: validates inputs", {
  # NULL matches will fail on target check since NULL has no columns
  expect_error(fit_xgboost(NULL), "not found")
})

test_that("fit_xgboost: errors on missing target column", {
  matches <- make_test_matches(50)
  expect_error(
    fit_xgboost(matches, target = "nonexistent"),
    "not found"
  )
})

test_that("fit_xgboost: trains classification model", {
  skip_if_not_installed("xgboost")

  matches <- make_test_matches(100)
  features <- c("home_elo", "away_elo", "elo_diff")

  fit <- fit_xgboost(
    matches = matches,
    features = features,
    target = "ftr",
    nrounds = 10L,
    early_stopping = NULL
  )

  expect_type(fit, "list")
  expect_s4_class(fit$model, "xgb.Booster")
  expect_equal(fit$target, "ftr")
  expect_equal(fit$feature_names, features)
  expect_s3_class(fit$importance, "data.frame")
})

test_that("fit_xgboost: trains regression model for goals", {
  skip_if_not_installed("xgboost")

  matches <- make_test_matches(100)
  features <- c("home_elo", "away_elo", "elo_diff")

  fit <- fit_xgboost(
    matches = matches,
    features = features,
    target = "fthg",
    nrounds = 10L,
    early_stopping = NULL
  )

  expect_equal(fit$target, "fthg")
  expect_true("reg:squarederror" == fit$params$objective)
})

test_that("fit_xgboost: uses early stopping when specified", {
  skip_if_not_installed("xgboost")

  matches <- make_test_matches(100)
  features <- c("home_elo", "away_elo", "elo_diff")

  fit <- fit_xgboost(
    matches = matches,
    features = features,
    target = "ftr",
    nrounds = 50L,
    early_stopping = 5L
  )

  # Should have stopped before 50 rounds (or at least completed)
  expect_true(fit$model$niter <= 50L)
})

# ---- predict_xgboost ----

test_that("predict_xgboost: returns probabilities for classification", {
  skip_if_not_installed("xgboost")

  matches <- make_test_matches(100)
  features <- c("home_elo", "away_elo", "elo_diff")

  fit <- fit_xgboost(matches, features, "ftr", nrounds = 10L, early_stopping = NULL)
  preds <- predict_xgboost(fit, matches)

  expect_s3_class(preds, "tbl_df")
  expect_true(all(c("prob_h", "prob_d", "prob_a") %in% colnames(preds)))
  expect_equal(nrow(preds), nrow(matches))

  # Probabilities should sum to 1
  row_sums <- preds$prob_h + preds$prob_d + preds$prob_a
  expect_true(all(abs(row_sums - 1) < 1e-6))
})

test_that("predict_xgboost: returns values for regression", {
  skip_if_not_installed("xgboost")

  matches <- make_test_matches(100)
  features <- c("home_elo", "away_elo", "elo_diff")

  fit <- fit_xgboost(matches, features, "fthg", nrounds = 10L, early_stopping = NULL)
  preds <- predict_xgboost(fit, matches)

  expect_type(preds, "double")
  expect_length(preds, nrow(matches))
})

test_that("predict_xgboost: errors on missing features", {
  skip_if_not_installed("xgboost")

  matches <- make_test_matches(100)
  features <- c("home_elo", "away_elo")

  fit <- fit_xgboost(matches, features, "ftr", nrounds = 10L, early_stopping = NULL)

  # Remove a feature from new data
  new_data <- matches[, c("home_elo")]

  expect_error(
    predict_xgboost(fit, new_data),
    "Missing features"
  )
})

# ---- predict_matches_xgb ----

test_that("predict_matches_xgb: adds predictions to matches", {
  skip_if_not_installed("xgboost")

  matches <- make_test_matches(100)
  features <- c("home_elo", "away_elo", "elo_diff")

  fit <- fit_xgboost(matches, features, "ftr", nrounds = 10L, early_stopping = NULL)
  result <- predict_matches_xgb(fit, matches)

  expect_true("prob_h" %in% colnames(result))
  expect_true("prob_d" %in% colnames(result))
  expect_true("prob_a" %in% colnames(result))
  expect_true("pred_outcome" %in% colnames(result))
  expect_true(all(result$pred_outcome %in% c("H", "D", "A")))
})

test_that("predict_matches_xgb: adds goal predictions for regression", {
  skip_if_not_installed("xgboost")

  matches <- make_test_matches(100)
  features <- c("home_elo", "away_elo")

  fit <- fit_xgboost(matches, features, "fthg", nrounds = 10L, early_stopping = NULL)
  result <- predict_matches_xgb(fit, matches)

  expect_true("pred_fthg" %in% colnames(result))
  expect_type(result$pred_fthg, "double")
})

# ---- cv_xgboost ----

test_that("cv_xgboost: returns CV results", {
  skip_if_not_installed("xgboost")

  matches <- make_test_matches(100)
  features <- c("home_elo", "away_elo", "elo_diff")

  result <- cv_xgboost(
    matches = matches,
    features = features,
    target = "ftr",
    nrounds = 20L,
    nfold = 3L
  )

  expect_type(result, "list")
  expect_true("best_nrounds" %in% names(result))
  expect_true("cv_results" %in% names(result))
  expect_true("best_score" %in% names(result))
  expect_true(result$best_nrounds > 0L)
})

# ---- evaluate_xgboost ----

test_that("evaluate_xgboost: computes classification metrics", {
  skip_if_not_installed("xgboost")

  matches <- make_test_matches(100)
  features <- c("home_elo", "away_elo", "elo_diff")

  fit <- fit_xgboost(matches, features, "ftr", nrounds = 10L, early_stopping = NULL)
  metrics <- evaluate_xgboost(fit, matches)

  expect_type(metrics, "list")
  expect_true("accuracy" %in% names(metrics))
  expect_true("log_loss" %in% names(metrics))
  expect_true("confusion" %in% names(metrics))

  expect_true(metrics$accuracy >= 0 && metrics$accuracy <= 1)
  expect_true(metrics$log_loss >= 0)
})

test_that("evaluate_xgboost: computes regression metrics", {
  skip_if_not_installed("xgboost")

  matches <- make_test_matches(100)
  features <- c("home_elo", "away_elo")

  fit <- fit_xgboost(matches, features, "fthg", nrounds = 10L, early_stopping = NULL)
  metrics <- evaluate_xgboost(fit, matches)

  expect_true("rmse" %in% names(metrics))
  expect_true("mae" %in% names(metrics))
  expect_true(metrics$rmse >= 0)
  expect_true(metrics$mae >= 0)
})

# ---- plot_xgb_importance ----

test_that("plot_xgb_importance: returns ggplot", {
  skip_if_not_installed("xgboost")
  skip_if_not_installed("ggplot2")

  matches <- make_test_matches(100)
  features <- c("home_elo", "away_elo", "elo_diff")

  fit <- fit_xgboost(matches, features, "ftr", nrounds = 10L, early_stopping = NULL)
  p <- plot_xgb_importance(fit)

  expect_s3_class(p, "ggplot")
})

test_that("plot_xgb_importance: errors with empty importance", {
  fit <- list(importance = tibble::tibble())

  expect_error(
    plot_xgb_importance(fit),
    "No feature importance"
  )
})

# ---- tune_xgboost ----

test_that("tune_xgboost: searches parameter grid", {
  skip_if_not_installed("xgboost")
  skip_on_cran()  # Can be slow

  matches <- make_test_matches(100)
  features <- c("home_elo", "away_elo")

  # Small grid for testing
  param_grid <- list(
    eta = c(0.1, 0.2),
    max_depth = c(3L, 6L),
    subsample = c(0.8)
  )

  result <- tune_xgboost(
    matches = matches,
    features = features,
    target = "ftr",
    param_grid = param_grid,
    nrounds = 20L,
    nfold = 2L
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 4L)  # 2 x 2 x 1 = 4 combinations
  expect_true(all(c("eta", "max_depth", "subsample", "cv_score") %in% colnames(result)))
})

# ---- Edge cases ----

test_that("fit_xgboost: handles all same outcome", {
  skip_if_not_installed("xgboost")

  matches <- make_test_matches(50)
  matches$ftr <- "H"  # All home wins
  features <- c("home_elo", "away_elo")

  # Should still train without error
  fit <- fit_xgboost(matches, features, "ftr", nrounds = 10L, early_stopping = NULL)
  expect_s4_class(fit$model, "xgb.Booster")
})

test_that("fit_xgboost: handles custom parameters", {
  skip_if_not_installed("xgboost")

  matches <- make_test_matches(100)
  features <- c("home_elo", "away_elo")

  custom_params <- list(
    eta = 0.05,
    max_depth = 3L,
    min_child_weight = 5,
    subsample = 0.7,
    colsample_bytree = 0.7
  )

  fit <- fit_xgboost(
    matches = matches,
    features = features,
    target = "ftr",
    params = custom_params,
    nrounds = 10L,
    early_stopping = NULL
  )

  expect_equal(fit$params$eta, 0.05)
  expect_equal(fit$params$max_depth, 3L)
})
