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
  # Create sufficient data to avoid rank deficiency
  set.seed(42)
  teams <- c("A", "B", "C", "D")
  matches_list <- list()
  idx <- 1
  for (i in seq_along(teams)) {
    for (j in seq_along(teams)) {
      if (i != j) {
        for (k in 1:3) {  # 3 matches per pair
          matches_list[[idx]] <- list(
            team = teams[i],
            opponent = teams[j],
            goals = rpois(1, 1.5),
            home = sample(0:1, 1)
          )
          idx <- idx + 1
        }
      }
    }
  }
  long <- dplyr::bind_rows(lapply(matches_list, tibble::as_tibble))
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
  # Create sufficient data to avoid rank deficiency
  # 4 teams, 6 rounds = 24 matches = 48 observations
  set.seed(42)
  teams <- c("A", "B", "C", "D")
  rounds <- 6
  matches_list <- list()
  idx <- 1
  for (r in seq_len(rounds)) {
    for (i in seq_along(teams)) {
      for (j in seq_along(teams)) {
        if (i != j && idx <= 48) {
          matches_list[[idx]] <- list(
            team = teams[i],
            opponent = teams[j],
            goals = rpois(1, 1.5),
            home = sample(0:1, 1)
          )
          idx <- idx + 1
        }
      }
    }
  }
  long <- dplyr::bind_rows(lapply(matches_list, tibble::as_tibble))
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

# ---- temporal_split ----

test_that("temporal_split creates three non-overlapping periods", {
  matches <- tibble::tibble(
    season = c("1516", "1617", "1718", "1819", "1920",
               "2021", "2122", "2223",
               "2324", "2425", "2526"),
    n = 1:11
  )

  split <- temporal_split(matches)
  expect_equal(nrow(split$train), 5)
  expect_equal(nrow(split$validate), 3)
  expect_equal(nrow(split$test), 3)

  # No overlap
  expect_equal(nrow(dplyr::intersect(split$train, split$validate)), 0)
  expect_equal(nrow(dplyr::intersect(split$validate, split$test)), 0)
  expect_equal(nrow(dplyr::intersect(split$train, split$test)), 0)

  # Union = original
  expect_equal(
    nrow(dplyr::bind_rows(split$train, split$validate, split$test)),
    nrow(matches)
  )
})

test_that("temporal_split requires season column", {
  expect_error(temporal_split(tibble::tibble(x = 1)), "season")
})

test_that("temporal_split custom boundaries work", {
  matches <- tibble::tibble(
    season = c("1516", "1617", "1718", "1819", "1920",
               "2021", "2122", "2223", "2324", "2425")
  )

  split <- temporal_split(matches, train_end = "1718", validate_end = "2122")
  expect_equal(nrow(split$train), 3)   # 1516, 1617, 1718
  expect_equal(nrow(split$validate), 4) # 1819, 1920, 2021, 2122
  expect_equal(nrow(split$test), 3)    # 2223, 2324, 2425
})
