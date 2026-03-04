# Tests for R/features.R: compute_elo, devig_odds

# ---- compute_elo ----

test_that("compute_elo produces ratings for all teams", {
  skip_if_not_installed("elo")
  matches <- tibble::tibble(
    match_date = as.Date(c("2024-01-01", "2024-01-08", "2024-01-15",
                           "2024-01-22", "2024-01-29")),
    home_team = c("A", "B", "C", "A", "B"),
    away_team = c("B", "C", "A", "C", "A"),
    ftr       = c("H", "D", "A", "H", "D")
  )

  result <- compute_elo(matches)
  expect_s3_class(result, "tbl_df")
  expect_equal(sort(result$team), c("A", "B", "C"))
  expect_true(all(is.numeric(result$elo)))
})

test_that("compute_elo: home wins increase home rating", {
  skip_if_not_installed("elo")
  matches <- tibble::tibble(
    match_date = as.Date(c("2024-01-01", "2024-01-08", "2024-01-15")),
    home_team = c("A", "A", "A"),
    away_team = c("B", "B", "B"),
    ftr       = c("H", "H", "H")
  )

  result <- compute_elo(matches)
  elo_a <- result$elo[result$team == "A"]
  elo_b <- result$elo[result$team == "B"]
  expect_true(elo_a > elo_b)
})

test_that("compute_elo: empty input returns empty", {
  skip_if_not_installed("elo")
  empty <- tibble::tibble(
    match_date = as.Date(character()),
    home_team = character(),
    away_team = character(),
    ftr = character()
  )
  result <- compute_elo(empty)
  expect_equal(nrow(result), 0L)
})

test_that("compute_elo: all draws give equal ratings", {
  skip_if_not_installed("elo")
  matches <- tibble::tibble(
    match_date = as.Date(c("2024-01-01", "2024-01-08")),
    home_team = c("A", "B"),
    away_team = c("B", "A"),
    ftr       = c("D", "D")
  )

  result <- compute_elo(matches)
  # With home advantage, ratings won't be exactly equal,

  # but should be close
  diff <- abs(result$elo[result$team == "A"] - result$elo[result$team == "B"])
  expect_true(diff < 50)  # Within reasonable range
})

test_that("compute_elo: custom k-factor", {
  skip_if_not_installed("elo")
  matches <- tibble::tibble(
    match_date = as.Date("2024-01-01"),
    home_team = "A",
    away_team = "B",
    ftr = "H"
  )

  result_low_k <- compute_elo(matches, k = 5)
  result_high_k <- compute_elo(matches, k = 40)

  # Higher k should produce larger rating differences
  diff_low <- abs(result_low_k$elo[1] - result_low_k$elo[2])
  diff_high <- abs(result_high_k$elo[1] - result_high_k$elo[2])
  expect_true(diff_high > diff_low)
})

# ---- devig_odds ----

test_that("devig_odds produces fair probabilities summing to 1", {
  odds <- tibble::tibble(
    match_id  = "test_1",
    psh       = 2.10,
    psd       = 3.40,
    psa       = 3.50,
    p_over25  = 1.90,
    p_under25 = 2.00
  )

  result <- devig_odds(odds)
  expect_equal(nrow(result), 1L)

  # 1X2 fair probs should sum to ~1
  total_1x2 <- result$fair_h + result$fair_d + result$fair_a
  expect_equal(total_1x2, 1, tolerance = 1e-6)

  # O/U fair probs should sum to ~1
  total_ou <- result$fair_over25 + result$fair_under25
  expect_equal(total_ou, 1, tolerance = 1e-6)
})

test_that("devig_odds: missing Pinnacle returns NA", {
  odds <- tibble::tibble(
    match_id  = "test_na",
    psh       = NA_real_,
    psd       = NA_real_,
    psa       = NA_real_,
    p_over25  = NA_real_,
    p_under25 = NA_real_
  )

  result <- devig_odds(odds)
  expect_true(all(is.na(result$fair_h)))
  expect_true(all(is.na(result$fair_over25)))
})

test_that("devig_odds: empty input returns empty", {
  odds <- tibble::tibble(
    match_id  = character(),
    psh = numeric(), psd = numeric(), psa = numeric(),
    p_over25 = numeric(), p_under25 = numeric()
  )

  result <- devig_odds(odds)
  expect_equal(nrow(result), 0L)
  expect_true("fair_h" %in% colnames(result))
})

test_that("devig_odds: favourite has higher fair prob", {
  odds <- tibble::tibble(
    match_id  = "test_fav",
    psh       = 1.40,  # strong home favourite
    psd       = 4.50,
    psa       = 8.00,
    p_over25  = 1.60,
    p_under25 = 2.40
  )

  result <- devig_odds(odds)
  expect_true(result$fair_h > result$fair_d)
  expect_true(result$fair_h > result$fair_a)
})

test_that("devig_odds: multiple matches", {
  odds <- tibble::tibble(
    match_id  = c("m1", "m2"),
    psh       = c(2.10, 1.40),
    psd       = c(3.40, 4.50),
    psa       = c(3.50, 8.00),
    p_over25  = c(1.90, 1.60),
    p_under25 = c(2.00, 2.40)
  )

  result <- devig_odds(odds)
  expect_equal(nrow(result), 2L)
  # Each row's 1X2 probs sum to 1
  expect_equal(result$fair_h[1] + result$fair_d[1] + result$fair_a[1], 1, tolerance = 1e-6)
  expect_equal(result$fair_h[2] + result$fair_d[2] + result$fair_a[2], 1, tolerance = 1e-6)
})
