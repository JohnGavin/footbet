# Tests for Kalman filter team strength estimation

test_that("kalman_update produces valid output", {
  state <- c(0, 0)
  P <- diag(1, 2)
  H <- c(1, 0)
  Q <- diag(0.01, 2)
  R <- 0.5

  result <- kalman_update(state, P, observation = 1.5, H, Q, R)

  expect_length(result$state, 2)
  expect_true(is.matrix(result$P))
  expect_equal(nrow(result$P), 2)
  # After seeing 1.5 goals on the first component, state should shift toward 1.5
  expect_true(result$state[1] > 0)
  # Second component unobserved, should stay near 0
  expect_true(abs(result$state[2]) < abs(result$state[1]))
})

test_that("kalman_update with zero innovation doesn't change state", {
  state <- c(1.3, 0.5)
  P <- diag(0.1, 2)
  H <- c(1, 1)
  Q <- diag(0.01, 2)
  R <- 0.5

  # Observation matches prediction exactly
  expected <- sum(H * state)
  result <- kalman_update(state, P, observation = expected, H, Q, R)

  # State should barely change (only process noise widens P)
  expect_equal(result$state, state, tolerance = 0.05)
  expect_equal(result$innovation, 0, tolerance = 1e-10)
})

test_that("kalman_strengths returns pre-match estimates", {
  set.seed(42)
  matches <- tibble::tibble(
    match_date = as.Date("2024-01-01") + 0:9,
    home_team = rep(c("A", "B", "C", "D", "E"), 2),
    away_team = rep(c("B", "C", "D", "E", "A"), 2),
    fthg = rpois(10, 1.5),
    ftag = rpois(10, 1.0)
  )

  strengths <- kalman_strengths(matches, use_xg = FALSE)

  expect_s3_class(strengths, "tbl_df")
  expect_true(all(c("team", "match_date", "attack", "defence") %in% names(strengths)))
  # 10 matches × 2 teams = 20 rows
  expect_equal(nrow(strengths), 20L)
  # First match: all teams should have attack = 0, defence = 0 (prior)
  first <- strengths |> dplyr::filter(match_date == min(match_date))
  expect_true(all(first$attack == 0))
  expect_true(all(first$defence == 0))
})

test_that("kalman_strengths: strong team gets positive attack", {
  # Team A always scores 3, concedes 0. Team B always scores 0, concedes 3.
  matches <- tibble::tibble(
    match_date = as.Date("2024-01-01") + seq(0, by = 7, length.out = 10),
    home_team = rep(c("A", "B"), 5),
    away_team = rep(c("B", "A"), 5),
    fthg = rep(c(3L, 0L), 5),
    ftag = rep(c(0L, 3L), 5)
  )

  strengths <- kalman_strengths(matches, use_xg = FALSE)

  # After several matches, A should have positive attack, B negative
  last <- strengths |>
    dplyr::filter(match_date == max(match_date))
  a_str <- last |> dplyr::filter(team == "A")
  b_str <- last |> dplyr::filter(team == "B")

  expect_true(a_str$attack > b_str$attack)
})

test_that("kalman_strengths works with xG columns", {
  matches <- tibble::tibble(
    match_date = as.Date("2024-01-01") + 0:4,
    home_team = c("A", "B", "C", "A", "B"),
    away_team = c("B", "C", "A", "C", "A"),
    fthg = c(2L, 1L, 0L, 3L, 1L),
    ftag = c(0L, 1L, 2L, 1L, 0L),
    home_xg = c(1.8, 0.9, 0.5, 2.5, 1.2),
    away_xg = c(0.3, 1.1, 1.7, 0.8, 0.4)
  )

  str_goals <- kalman_strengths(matches, use_xg = FALSE)
  str_xg <- kalman_strengths(matches, use_xg = TRUE)

  # Both should produce valid output

  expect_equal(nrow(str_goals), nrow(str_xg))
  # xG-based strengths should differ from goals-based
  expect_false(all(str_goals$attack == str_xg$attack))
})
