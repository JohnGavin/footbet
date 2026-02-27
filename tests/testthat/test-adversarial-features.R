# Adversarial QA: compute_elo, devig_odds
# Attack vectors: NULL, NA, boundary, degenerate inputs

# ---- compute_elo ----

test_that("compute_elo: NULL input", {
  expect_error(compute_elo(NULL))
})

test_that("compute_elo: all NA results filtered out", {
  matches <- tibble::tibble(
    match_date = as.Date("2024-01-01"),
    home_team = "A",
    away_team = "B",
    ftr = NA_character_
  )
  result <- compute_elo(matches)
  expect_equal(nrow(result), 0L)
})

test_that("compute_elo: invalid FTR values filtered", {
  matches <- tibble::tibble(
    match_date = as.Date("2024-01-01"),
    home_team = "A",
    away_team = "B",
    ftr = "X"  # invalid
  )
  result <- compute_elo(matches)
  expect_equal(nrow(result), 0L)
})

test_that("compute_elo: single match still works", {
  matches <- tibble::tibble(
    match_date = as.Date("2024-01-01"),
    home_team = "A",
    away_team = "B",
    ftr = "H"
  )
  result <- compute_elo(matches)
  expect_equal(nrow(result), 2L)
})

test_that("compute_elo: k=0 gives no rating changes", {
  matches <- tibble::tibble(
    match_date = as.Date(c("2024-01-01", "2024-01-08")),
    home_team = c("A", "B"),
    away_team = c("B", "A"),
    ftr = c("H", "A")
  )
  result <- compute_elo(matches, k = 0)
  # All ratings should be initial (1500)
  expect_equal(result$elo, c(1500, 1500))
})

# ---- devig_odds ----

test_that("devig_odds: NULL input", {
  expect_error(devig_odds(NULL))
})

test_that("devig_odds: odds = 1 (zero margin edge case)", {
  # Odds of exactly 1 are invalid (can't pay out less than stake)
  odds <- tibble::tibble(
    match_id = "edge",
    psh = 1.0, psd = 1.0, psa = 1.0,
    p_over25 = 1.0, p_under25 = 1.0
  )
  result <- devig_odds(odds)
  # Should return NA (odds <= 1 are invalid)
  expect_true(all(is.na(result$fair_h)))
})

test_that("devig_odds: very tight market (low overround)", {
  odds <- tibble::tibble(
    match_id = "tight",
    psh = 2.00, psd = 3.33, psa = 4.00,
    p_over25 = 2.00, p_under25 = 2.00
  )
  result <- devig_odds(odds)
  expect_true(all(!is.na(result$fair_h)))
  expect_equal(result$fair_h + result$fair_d + result$fair_a, 1, tolerance = 1e-4)
})

test_that("devig_odds: partial odds (only 1X2, no O/U)", {
  odds <- tibble::tibble(
    match_id = "partial",
    psh = 2.10, psd = 3.40, psa = 3.50,
    p_over25 = NA_real_, p_under25 = NA_real_
  )
  result <- devig_odds(odds)
  # 1X2 should be devigged
  expect_false(is.na(result$fair_h))
  # O/U should be NA
  expect_true(is.na(result$fair_over25))
})
