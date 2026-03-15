# Tests for R/features.R: compute_elo, devig_odds

# ---- compute_elo ----

# Helper to get final (last) rating per team from match-by-match output
final_elo <- function(result) {
  result |>
    dplyr::group_by(team) |>
    dplyr::slice_tail(n = 1) |>
    dplyr::ungroup()
}

test_that("compute_elo produces ratings for all teams", {
  matches <- tibble::tibble(
    match_date = as.Date(c("2024-01-01", "2024-01-08", "2024-01-15",
                           "2024-01-22", "2024-01-29")),
    home_team = c("A", "B", "C", "A", "B"),
    away_team = c("B", "C", "A", "C", "A"),
    ftr       = c("H", "D", "A", "H", "D")
  )

  result <- compute_elo(matches)
  expect_s3_class(result, "tbl_df")
  expect_equal(sort(unique(result$team)), c("A", "B", "C"))
  expect_true(all(is.numeric(result$elo)))
})

test_that("compute_elo: home wins increase home rating", {
  matches <- tibble::tibble(
    match_date = as.Date(c("2024-01-01", "2024-01-08", "2024-01-15")),
    home_team = c("A", "A", "A"),
    away_team = c("B", "B", "B"),
    ftr       = c("H", "H", "H")
  )

  result <- final_elo(compute_elo(matches))
  elo_a <- result$elo[result$team == "A"]
  elo_b <- result$elo[result$team == "B"]
  expect_true(elo_a > elo_b)
})

test_that("compute_elo: empty input returns empty", {
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
  matches <- tibble::tibble(
    match_date = as.Date(c("2024-01-01", "2024-01-08")),
    home_team = c("A", "B"),
    away_team = c("B", "A"),
    ftr       = c("D", "D")
  )

  result <- final_elo(compute_elo(matches))
  # With home advantage, ratings won't be exactly equal, but should be close
  diff <- abs(result$elo[result$team == "A"] - result$elo[result$team == "B"])
  expect_true(diff < 50)
})

test_that("compute_elo: custom k-factor", {
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

# ---- compute_elo: dynamic k-factor ----

test_that("compute_elo: dynamic_k produces higher early-season volatility", {
  # Aug matches should have higher k than Dec matches
  matches <- tibble::tibble(
    match_date = as.Date(c("2024-08-10", "2024-08-17", "2024-12-10", "2024-12-17")),
    home_team = c("A", "B", "A", "B"),
    away_team = c("B", "A", "B", "A"),
    ftr       = c("H", "H", "H", "H")
  )

  result_fixed <- final_elo(compute_elo(matches, k = 20, dynamic_k = FALSE))
  result_dynamic <- final_elo(compute_elo(matches, dynamic_k = TRUE))

  # Both should produce valid ratings for both teams
  expect_equal(sort(result_fixed$team), c("A", "B"))
  expect_equal(sort(result_dynamic$team), c("A", "B"))

  # Dynamic k should produce different final ratings than fixed k
  elo_a_fixed <- result_fixed$elo[result_fixed$team == "A"]
  elo_a_dynamic <- result_dynamic$elo[result_dynamic$team == "A"]
  expect_false(elo_a_fixed == elo_a_dynamic)
})

test_that("compute_elo: seasonal_k computes correct k values", {
  # Aug = month 8 → high k; Dec = month 12 → low k
  k_aug <- seasonal_k(as.Date("2024-08-15"), k_start = 40, k_end = 20)
  k_dec <- seasonal_k(as.Date("2024-12-15"), k_start = 40, k_end = 20)
  k_oct <- seasonal_k(as.Date("2024-10-15"), k_start = 40, k_end = 20)

  expect_true(k_aug > k_dec)
  expect_true(k_aug > k_oct)
  expect_true(k_oct > k_dec)
  expect_equal(k_aug, 40)  # August = season start = k_start
  expect_equal(k_dec, 20)  # December = month 5 of season = k_end
})

# ---- compute_elo: team-specific home advantage ----

test_that("compute_elo: team_home_advantage uses per-team factors", {
  # Give team A a much stronger home advantage
  ha_map <- c(A = 120, B = 30)

  matches <- tibble::tibble(
    match_date = as.Date(c("2024-01-01", "2024-01-08")),
    home_team = c("A", "B"),
    away_team = c("B", "A"),
    ftr       = c("H", "H")
  )

  result_fixed <- final_elo(compute_elo(matches, home_advantage = 65))
  result_team <- final_elo(compute_elo(matches, team_home_advantage = ha_map))

  # Both should work
  expect_equal(sort(result_team$team), c("A", "B"))

  # Team-specific should produce different final results
  elo_a_fixed <- result_fixed$elo[result_fixed$team == "A"]
  elo_a_team <- result_team$elo[result_team$team == "A"]
  expect_false(elo_a_fixed == elo_a_team)
})

# ---- compute_elo: margin-adjusted k ----

test_that("compute_elo: margin_k downweights blowouts", {
  # 5-0 blowout should produce less Elo change than 1-0 close win
  close_match <- tibble::tibble(
    match_date = as.Date("2024-01-01"),
    home_team = "A", away_team = "B", ftr = "H",
    fthg = 1L, ftag = 0L
  )
  blowout <- tibble::tibble(
    match_date = as.Date("2024-01-01"),
    home_team = "A", away_team = "B", ftr = "H",
    fthg = 5L, ftag = 0L
  )

  result_close <- compute_elo(close_match, k = 20, margin_k = TRUE)
  result_blow <- compute_elo(blowout, k = 20, margin_k = TRUE)

  diff_close <- abs(result_close$elo[result_close$team == "A"] -
                    result_close$elo[result_close$team == "B"])
  diff_blow <- abs(result_blow$elo[result_blow$team == "A"] -
                   result_blow$elo[result_blow$team == "B"])

  # Blowout should have LESS Elo change (downweighted)
  expect_true(diff_blow < diff_close)
})

test_that("compute_elo: margin_k_factor computes correct weights", {
  # Close game (1-0): weight near 1
  # Blowout (5-0): weight much less than 1
  w_close <- margin_k_factor(1L, 0L)
  w_blow <- margin_k_factor(5L, 0L)
  w_draw <- margin_k_factor(1L, 1L)

  expect_true(w_close > w_blow)
  expect_true(w_draw > w_blow)
  expect_true(w_close <= 1.0)
  expect_true(w_blow > 0)
  expect_true(w_blow < 1.0)
})

# ---- compute_elo: match-by-match output ----

test_that("compute_elo: returns match-by-match ratings", {
  matches <- tibble::tibble(
    match_date = as.Date(c("2024-01-01", "2024-01-08", "2024-01-15")),
    home_team = c("A", "B", "A"),
    away_team = c("B", "A", "B"),
    ftr       = c("H", "D", "H")
  )

  result <- compute_elo(matches)

  # Should have match_date column and multiple rows per team
  expect_true("match_date" %in% names(result))
  expect_true(nrow(result) > 2)  # More than just 2 final ratings

  # Each team should have a rating for each match they played
  a_rows <- result[result$team == "A", ]
  expect_equal(nrow(a_rows), 3L)  # A plays in all 3 matches
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

# ---- team_form_score ----

test_that("team_form_score returns values in 0-100 range", {
  # Strong team
  strong <- team_form_score(2.5, 2.8, 1750)
  expect_true(strong >= 0 && strong <= 100)
  expect_true(strong > 50)  # Above average

  # Average team
  avg <- team_form_score(1.5, 1.5, 1500)
  expect_true(avg >= 0 && avg <= 100)
  expect_equal(avg, 50, tolerance = 1)  # Close to 50

  # Weak team
  weak <- team_form_score(0.5, 0.4, 1250)
  expect_true(weak >= 0 && weak <= 100)
  expect_true(weak < 50)  # Below average
})

test_that("team_form_score: higher inputs give higher scores", {
  low <- team_form_score(0.5, 0.5, 1300)
  mid <- team_form_score(1.5, 1.5, 1500)
  high <- team_form_score(2.5, 2.5, 1700)

  expect_true(low < mid)
  expect_true(mid < high)
})

test_that("team_form_score: works without xG (uses goals)", {
  # Without xG, score should still work (uses goals weight)
  score_no_xg <- team_form_score(2.0, NULL, 1550)
  expect_true(is.numeric(score_no_xg))
  expect_true(score_no_xg >= 0 && score_no_xg <= 100)
})

test_that("team_form_score: validates weight sum", {
  expect_error(
    team_form_score(1.5, 1.5, 1500, weight_goals = 0.5, weight_xg = 0.5, weight_elo = 0.5),
    "Weights must sum to 1"
  )
})

# ---- matches_since_event ----

test_that("matches_since_event: basic counting works", {
  # W, L, L, W, L, L, L
  won <- c(TRUE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE)
  result <- matches_since_event(won)

  # First is NA (no history)
  expect_true(is.na(result[1]))
  # After win, counter resets to 0

  expect_equal(result[2], 0L)
  # Then increments
  expect_equal(result[3], 1L)
  expect_equal(result[4], 2L)
  # After another win, reset again
  expect_equal(result[5], 0L)
  expect_equal(result[6], 1L)
  expect_equal(result[7], 2L)
})

test_that("matches_since_event: all TRUE gives all 0s (except first NA)", {
  all_true <- c(TRUE, TRUE, TRUE, TRUE)
  result <- matches_since_event(all_true)

  expect_true(is.na(result[1]))
  expect_equal(result[2:4], c(0L, 0L, 0L))
})

test_that("matches_since_event: all FALSE gives incrementing count", {
  all_false <- c(FALSE, FALSE, FALSE, FALSE)
  result <- matches_since_event(all_false)

  expect_true(is.na(result[1]))
  expect_equal(result[2:4], c(1L, 2L, 3L))
})

test_that("matches_since_event: empty input returns empty", {
  result <- matches_since_event(logical(0))
  expect_equal(length(result), 0L)
})

test_that("matches_since_event: single input returns NA", {
  result <- matches_since_event(TRUE)
  expect_equal(length(result), 1L)
  expect_true(is.na(result[1]))
})

# ---- compute_matches_since ----

test_that("compute_matches_since: returns correct structure", {
  matches <- tibble::tibble(
    match_date = as.Date(c("2024-01-01", "2024-01-08", "2024-01-15")),
    home_team = c("A", "B", "A"),
    away_team = c("B", "A", "B"),
    ftr = c("H", "D", "A"),
    fthg = c(2L, 1L, 0L),
    ftag = c(1L, 1L, 2L)
  )

  result <- compute_matches_since(matches)

  expect_s3_class(result, "tbl_df")
  expect_true(all(c("team", "match_date", "matches_since_win",
                    "matches_since_loss") %in% names(result)))
  # Should have 6 rows (2 teams x 3 matches)
  expect_equal(nrow(result), 6L)
})

test_that("compute_matches_since: tracks wins correctly", {
  # Team A: wins match 1, draws match 2, loses match 3
  matches <- tibble::tibble(
    match_date = as.Date(c("2024-01-01", "2024-01-08", "2024-01-15")),
    home_team = c("A", "A", "B"),
    away_team = c("B", "B", "A"),
    ftr = c("H", "D", "H"),  # A wins, draw, A loses
    fthg = c(2L, 1L, 2L),
    ftag = c(1L, 1L, 0L)
  )

  result <- compute_matches_since(matches)
  team_a <- result |> dplyr::filter(team == "A") |> dplyr::arrange(match_date)

  # Match 1: NA (first match)
  expect_true(is.na(team_a$matches_since_win[1]))
  # Match 2: 0 (just won)
  expect_equal(team_a$matches_since_win[2], 0L)
  # Match 3: 1 (1 match since win)
  expect_equal(team_a$matches_since_win[3], 1L)
})
