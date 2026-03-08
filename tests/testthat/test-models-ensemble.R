# Tests for ensemble prediction functions

# ---- ensemble_predict ----

test_that("ensemble_predict combines multiple model predictions", {
  predictions <- list(
    model_a = tibble::tibble(
      match_id = c("m1", "m2", "m3"),
      prob_h = c(0.50, 0.40, 0.60),
      prob_d = c(0.30, 0.35, 0.25),
      prob_a = c(0.20, 0.25, 0.15)
    ),
    model_b = tibble::tibble(
      match_id = c("m1", "m2", "m3"),
      prob_h = c(0.55, 0.45, 0.65),
      prob_d = c(0.25, 0.30, 0.20),
      prob_a = c(0.20, 0.25, 0.15)
    )
  )
  
  result <- ensemble_predict(predictions)
  
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 3)
  expect_true(all(c("match_id", "prob_h", "prob_d", "prob_a", "uncertainty") %in% colnames(result)))
  
  # With equal weights, should be average
  expect_equal(result$prob_h[1], 0.525, tolerance = 1e-6)
})

test_that("ensemble_predict uses equal weights by default", {
  predictions <- list(
    model_a = tibble::tibble(
      match_id = "m1",
      prob_h = 0.50,
      prob_d = 0.30,
      prob_a = 0.20
    ),
    model_b = tibble::tibble(
      match_id = "m1",
      prob_h = 0.60,
      prob_d = 0.25,
      prob_a = 0.15
    )
  )
  
  result <- ensemble_predict(predictions, weights = NULL)
  
  # Equal weight average
  expect_equal(result$prob_h, 0.55, tolerance = 1e-6)
  expect_equal(result$prob_d, 0.275, tolerance = 1e-6)
  expect_equal(result$prob_a, 0.175, tolerance = 1e-6)
})

test_that("ensemble_predict respects custom weights", {
  predictions <- list(
    model_a = tibble::tibble(
      match_id = "m1",
      prob_h = 0.50,
      prob_d = 0.30,
      prob_a = 0.20
    ),
    model_b = tibble::tibble(
      match_id = "m1",
      prob_h = 0.60,
      prob_d = 0.25,
      prob_a = 0.15
    )
  )
  
  # Weight model_a 75%, model_b 25%
  weights <- c(model_a = 0.75, model_b = 0.25)
  result <- ensemble_predict(predictions, weights = weights)
  
  expected_h <- 0.50 * 0.75 + 0.60 * 0.25
  expect_equal(result$prob_h, expected_h, tolerance = 1e-6)
})

test_that("ensemble_predict normalises weights to sum to 1", {
  predictions <- list(
    model_a = tibble::tibble(
      match_id = "m1",
      prob_h = 0.50,
      prob_d = 0.30,
      prob_a = 0.20
    ),
    model_b = tibble::tibble(
      match_id = "m1",
      prob_h = 0.60,
      prob_d = 0.25,
      prob_a = 0.15
    )
  )
  
  # Unnormalised weights
  weights <- c(model_a = 3, model_b = 1)
  result <- ensemble_predict(predictions, weights = weights)
  
  # Should normalise to 0.75, 0.25
  expected_h <- 0.50 * 0.75 + 0.60 * 0.25
  expect_equal(result$prob_h, expected_h, tolerance = 1e-6)
})

test_that("ensemble_predict normalises final probabilities to sum to 1", {
  predictions <- list(
    model_a = tibble::tibble(
      match_id = "m1",
      prob_h = 0.50,
      prob_d = 0.30,
      prob_a = 0.20
    ),
    model_b = tibble::tibble(
      match_id = "m1",
      prob_h = 0.60,
      prob_d = 0.25,
      prob_a = 0.15
    )
  )
  
  result <- ensemble_predict(predictions)
  
  total <- result$prob_h + result$prob_d + result$prob_a
  expect_equal(total, 1, tolerance = 1e-10)
})

test_that("ensemble_predict computes uncertainty from model disagreement", {
  # High agreement
  preds_agree <- list(
    model_a = tibble::tibble(
      match_id = "m1",
      prob_h = 0.50,
      prob_d = 0.30,
      prob_a = 0.20
    ),
    model_b = tibble::tibble(
      match_id = "m1",
      prob_h = 0.51,
      prob_d = 0.29,
      prob_a = 0.20
    )
  )
  
  # Low agreement
  preds_disagree <- list(
    model_a = tibble::tibble(
      match_id = "m1",
      prob_h = 0.70,
      prob_d = 0.20,
      prob_a = 0.10
    ),
    model_b = tibble::tibble(
      match_id = "m1",
      prob_h = 0.30,
      prob_d = 0.40,
      prob_a = 0.30
    )
  )
  
  result_agree <- ensemble_predict(preds_agree)
  result_disagree <- ensemble_predict(preds_disagree)
  
  expect_true(result_disagree$uncertainty > result_agree$uncertainty)
})

test_that("ensemble_predict uses only common match_ids", {
  predictions <- list(
    model_a = tibble::tibble(
      match_id = c("m1", "m2", "m3"),
      prob_h = c(0.50, 0.40, 0.60),
      prob_d = c(0.30, 0.35, 0.25),
      prob_a = c(0.20, 0.25, 0.15)
    ),
    model_b = tibble::tibble(
      match_id = c("m1", "m3"),  # Missing m2
      prob_h = c(0.55, 0.65),
      prob_d = c(0.25, 0.20),
      prob_a = c(0.20, 0.15)
    )
  )
  
  result <- ensemble_predict(predictions)
  
  # Should only include m1 and m3
  expect_equal(nrow(result), 2)
  expect_true(all(result$match_id %in% c("m1", "m3")))
})

test_that("ensemble_predict warns when no common matches", {
  predictions <- list(
    model_a = tibble::tibble(
      match_id = "m1",
      prob_h = 0.50,
      prob_d = 0.30,
      prob_a = 0.20
    ),
    model_b = tibble::tibble(
      match_id = "m2",
      prob_h = 0.60,
      prob_d = 0.25,
      prob_a = 0.15
    )
  )
  
  expect_warning(
    result <- ensemble_predict(predictions),
    "No common match_ids"
  )
  expect_equal(nrow(result), 0)
})

test_that("ensemble_predict requires at least 2 models", {
  predictions <- list(
    model_a = tibble::tibble(
      match_id = "m1",
      prob_h = 0.50,
      prob_d = 0.30,
      prob_a = 0.20
    )
  )
  
  expect_error(
    ensemble_predict(predictions),
    "at least 2 model predictions"
  )
})

test_that("ensemble_predict requires named list", {
  predictions <- list(
    tibble::tibble(match_id = "m1", prob_h = 0.5, prob_d = 0.3, prob_a = 0.2),
    tibble::tibble(match_id = "m1", prob_h = 0.6, prob_d = 0.25, prob_a = 0.15)
  )
  
  expect_error(
    ensemble_predict(predictions),
    "named list"
  )
})

test_that("ensemble_predict validates weights match model names", {
  predictions <- list(
    model_a = tibble::tibble(match_id = "m1", prob_h = 0.5, prob_d = 0.3, prob_a = 0.2),
    model_b = tibble::tibble(match_id = "m1", prob_h = 0.6, prob_d = 0.25, prob_a = 0.15)
  )
  
  weights <- c(model_x = 0.5, model_y = 0.5)
  
  expect_error(
    ensemble_predict(predictions, weights = weights),
    "Missing weights for models"
  )
})

test_that("ensemble_predict requires argument", {
  expect_error(ensemble_predict())
})

# ---- compute_ensemble_weights ----

test_that("compute_ensemble_weights computes inverse log-loss weights", {
  cv_results <- list(
    model_a = tibble::tibble(
      fold = 1:3,
      log_loss = c(1.0, 1.1, 1.2),
      brier = c(0.5, 0.5, 0.5),
      rps = c(0.2, 0.2, 0.2)
    ),
    model_b = tibble::tibble(
      fold = 1:3,
      log_loss = c(1.5, 1.6, 1.7),  # Worse model
      brier = c(0.6, 0.6, 0.6),
      rps = c(0.3, 0.3, 0.3)
    )
  )
  
  weights <- compute_ensemble_weights(cv_results)
  
  expect_true(is.numeric(weights))
  expect_equal(length(weights), 2)
  expect_equal(names(weights), c("model_a", "model_b"))
  
  # Better model (lower log-loss) should have higher weight
  expect_true(weights["model_a"] > weights["model_b"])
  
  # Weights should sum to 1
  expect_equal(sum(weights), 1, tolerance = 1e-10)
})

test_that("compute_ensemble_weights handles equal performance", {
  cv_results <- list(
    model_a = tibble::tibble(fold = 1:2, log_loss = c(1.0, 1.0), brier = c(0.5, 0.5), rps = c(0.2, 0.2)),
    model_b = tibble::tibble(fold = 1:2, log_loss = c(1.0, 1.0), brier = c(0.5, 0.5), rps = c(0.2, 0.2))
  )
  
  weights <- compute_ensemble_weights(cv_results)
  
  # Equal performance = equal weights
  expect_equal(unname(weights["model_a"]), unname(weights["model_b"]), tolerance = 1e-10)
  expect_equal(unname(weights["model_a"]), 0.5, tolerance = 1e-10)
})

test_that("compute_ensemble_weights requires at least 2 models", {
  cv_results <- list(
    model_a = tibble::tibble(fold = 1, log_loss = 1.0, brier = 0.5, rps = 0.2)
  )
  
  expect_error(
    compute_ensemble_weights(cv_results),
    "at least 2 model results"
  )
})

test_that("compute_ensemble_weights requires named list", {
  cv_results <- list(
    tibble::tibble(fold = 1, log_loss = 1.0, brier = 0.5, rps = 0.2),
    tibble::tibble(fold = 1, log_loss = 1.2, brier = 0.6, rps = 0.3)
  )
  
  expect_error(
    compute_ensemble_weights(cv_results),
    "named list"
  )
})

test_that("compute_ensemble_weights handles NA in log_loss", {
  cv_results <- list(
    model_a = tibble::tibble(fold = 1:3, log_loss = c(1.0, 1.1, NA), brier = c(0.5, 0.5, 0.5), rps = c(0.2, 0.2, 0.2)),
    model_b = tibble::tibble(fold = 1:3, log_loss = c(1.5, 1.6, 1.7), brier = c(0.6, 0.6, 0.6), rps = c(0.3, 0.3, 0.3))
  )
  
  weights <- compute_ensemble_weights(cv_results)
  
  # Should compute mean ignoring NA
  expect_false(is.na(weights["model_a"]))
  expect_equal(sum(weights), 1, tolerance = 1e-10)
})

test_that("compute_ensemble_weights requires argument", {
  expect_error(compute_ensemble_weights())
})
