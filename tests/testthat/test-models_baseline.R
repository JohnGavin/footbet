test_that("score_matrix returns valid probability matrix", {
  mat <- score_matrix(1.5, 1.2)
  expect_true(is.matrix(mat))
  expect_equal(nrow(mat), 8)  # 0:7
  expect_equal(ncol(mat), 8)
  expect_equal(sum(mat), 1, tolerance = 1e-6)
  expect_true(all(mat >= 0))
})

test_that("score_matrix_to_1x2 probabilities sum to 1", {
  mat <- score_matrix(1.5, 1.0)
  probs <- score_matrix_to_1x2(mat)
  expect_named(probs, c("H", "D", "A"))
  expect_equal(sum(probs), 1, tolerance = 1e-6)
  # Home team has higher lambda → should have highest prob
  expect_true(probs["H"] > probs["A"])
})

test_that("score_matrix_to_ou probabilities sum to 1", {
  mat <- score_matrix(1.5, 1.2)
  probs <- score_matrix_to_ou(mat)
  expect_named(probs, c("over", "under"))
  expect_equal(sum(probs), 1, tolerance = 1e-6)
})

test_that("score_matrix_to_ah handles -0.5 line", {
  mat <- score_matrix(1.5, 1.0)
  probs <- score_matrix_to_ah(mat, line = -0.5)
  expect_named(probs, c("win", "push", "lose"))
  expect_equal(sum(probs), 1, tolerance = 1e-6)
  # No push on half-goal line
  expect_equal(unname(probs["push"]), 0, tolerance = 1e-10)
  # AH -0.5 win = home win
  probs_1x2 <- score_matrix_to_1x2(mat)
  expect_equal(unname(probs["win"]), unname(probs_1x2["H"]), tolerance = 1e-10)
})

test_that("score_matrix_to_ah handles -1 line (whole goal)", {
  mat <- score_matrix(2.0, 1.0)
  probs <- score_matrix_to_ah(mat, line = -1)
  expect_named(probs, c("win", "push", "lose"))
  expect_equal(sum(probs), 1, tolerance = 1e-6)
  # Should have push probability (when home wins by exactly 1)
  expect_true(probs["push"] > 0)
})

# ---- fit_poisson_glm ----

test_that("fit_poisson_glm fits a valid model", {
  long <- tibble::tibble(
    match_date = rep(as.Date("2024-01-01") + 0:9, each = 2),
    match_id = rep(paste0("m", 1:10), each = 2),
    team = rep(c("A", "B"), 10),
    opponent = rep(c("B", "A"), 10),
    goals = as.integer(c(2, 1, 0, 1, 1, 0, 3, 2, 1, 1,
                          2, 0, 1, 1, 0, 2, 1, 0, 2, 1)),
    home = rep(c(1L, 0L), 10)
  )

  model <- fit_poisson_glm(long)
  expect_s3_class(model, "glm")
  expect_equal(model$family$family, "poisson")
})

test_that("fit_poisson_glm errors on missing columns", {
  bad_df <- tibble::tibble(x = 1:3)
  expect_error(fit_poisson_glm(bad_df), "Missing columns")
})

# ---- predict_glm ----

test_that("predict_glm returns correct structure", {
  long <- tibble::tibble(
    team = rep(c("A", "B", "C"), each = 6),
    opponent = rep(c("B", "C", "A"), each = 6),
    goals = as.integer(c(2, 1, 0, 1, 3, 2, 1, 0, 1, 2, 0, 1,
                          0, 2, 1, 0, 1, 2)),
    home = rep(c(1L, 0L), 9)
  )
  model <- fit_poisson_glm(long)

  pred <- predict_glm(model, "A", "B")
  expect_type(pred, "list")
  expect_named(pred, c("lambda_home", "lambda_away", "score_mat",
                        "probs_1x2", "probs_ou25", "probs_ah05"))
  expect_true(pred$lambda_home > 0)
  expect_true(pred$lambda_away > 0)
  expect_equal(sum(pred$probs_1x2), 1, tolerance = 1e-6)
  expect_equal(sum(pred$probs_ou25), 1, tolerance = 1e-6)
})

# ---- predict_matches_glm ----

test_that("predict_matches_glm returns predictions for all matches", {
  long <- tibble::tibble(
    team = rep(c("A", "B", "C"), each = 6),
    opponent = rep(c("B", "C", "A"), each = 6),
    goals = as.integer(c(2, 1, 0, 1, 3, 2, 1, 0, 1, 2, 0, 1,
                          0, 2, 1, 0, 1, 2)),
    home = rep(c(1L, 0L), 9)
  )
  model <- fit_poisson_glm(long)

  matches <- tibble::tibble(
    match_id = c("m1", "m2"),
    home_team = c("A", "B"),
    away_team = c("B", "C")
  )

  preds <- predict_matches_glm(model, matches)
  expect_equal(nrow(preds), 2L)
  expect_true(all(!is.na(preds$pred_h)))
  # Each row's 1X2 probs should sum to ~1
  expect_equal(preds$pred_h[1] + preds$pred_d[1] + preds$pred_a[1], 1,
               tolerance = 1e-4)
})

test_that("predict_matches_glm handles unknown teams with NA", {
  long <- tibble::tibble(
    team = rep(c("A", "B"), each = 4),
    opponent = rep(c("B", "A"), each = 4),
    goals = as.integer(c(2, 1, 0, 1, 1, 0, 2, 1)),
    home = rep(c(1L, 0L), 4)
  )
  model <- fit_poisson_glm(long)

  matches <- tibble::tibble(
    match_id = c("m1", "m2"),
    home_team = c("A", "UNKNOWN"),
    away_team = c("B", "A")
  )

  preds <- predict_matches_glm(model, matches)
  expect_false(is.na(preds$pred_h[1]))
  expect_true(is.na(preds$pred_h[2]))
})

test_that("predict_matches_glm handles empty input", {
  long <- tibble::tibble(
    team = rep(c("A", "B"), each = 4),
    opponent = rep(c("B", "A"), each = 4),
    goals = as.integer(c(2, 1, 0, 1, 1, 0, 2, 1)),
    home = rep(c(1L, 0L), 4)
  )
  model <- fit_poisson_glm(long)

  empty <- tibble::tibble(
    match_id = character(), home_team = character(), away_team = character()
  )
  preds <- predict_matches_glm(model, empty)
  expect_equal(nrow(preds), 0L)
})
