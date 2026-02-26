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
