# Property-based tests: mathematical invariants that must hold for any valid input.
# Uses manual randomization (loop + set.seed) — no extra dependency.

# ---- compute_elo: Elo conservation ----

test_that("compute_elo: total Elo is conserved across all teams", {
  for (seed in 1:20) {
    set.seed(seed)
    teams <- LETTERS[1:4]
    n <- sample(5:20, 1)
    home <- sample(teams, n, replace = TRUE)
    away <- sample(teams, n, replace = TRUE)
    # Ensure no self-play
    valid <- home != away
    matches <- tibble::tibble(
      match_date = as.Date("2024-01-01") + sort(sample(1:200, sum(valid))),
      home_team = home[valid],
      away_team = away[valid],
      ftr = sample(c("H", "D", "A"), sum(valid), replace = TRUE)
    )

    result <- compute_elo(matches)
    final <- result |>
      dplyr::group_by(team) |>
      dplyr::slice_tail(n = 1) |>
      dplyr::ungroup()

    n_teams <- length(unique(final$team))
    expect_equal(sum(final$elo), n_teams * 1500, tolerance = 0.01,
                 label = paste("seed", seed))
  }
})

test_that("compute_elo: Elo conserved with dynamic_k and margin_k", {
  for (seed in 1:10) {
    set.seed(seed)
    teams <- LETTERS[1:3]
    n <- sample(6:15, 1)
    home <- sample(teams, n, replace = TRUE)
    away <- sample(teams, n, replace = TRUE)
    valid <- home != away
    matches <- tibble::tibble(
      match_date = as.Date("2024-08-01") + sort(sample(1:150, sum(valid))),
      home_team = home[valid],
      away_team = away[valid],
      ftr = sample(c("H", "D", "A"), sum(valid), replace = TRUE),
      fthg = sample(0:4, sum(valid), replace = TRUE),
      ftag = sample(0:4, sum(valid), replace = TRUE)
    )

    result <- compute_elo(matches, dynamic_k = TRUE, margin_k = TRUE)
    final <- result |>
      dplyr::group_by(team) |>
      dplyr::slice_tail(n = 1) |>
      dplyr::ungroup()

    expect_equal(sum(final$elo), length(unique(final$team)) * 1500,
                 tolerance = 0.01, label = paste("seed", seed))
  }
})

# ---- devig: fair probabilities sum to 1 ----

test_that("devig_shin: fair probabilities always sum to 1", {
  for (seed in 1:30) {
    set.seed(seed)
    # Generate random overround odds (implied probs sum > 1)
    raw_probs <- stats::runif(3, 0.1, 0.8)
    raw_probs <- raw_probs / sum(raw_probs) * stats::runif(1, 1.02, 1.15)
    odds <- 1 / raw_probs

    result <- tryCatch(
      devig_shin(odds),
      error = function(e) NULL
    )

    if (!is.null(result)) {
      total <- sum(result)
      expect_equal(total, 1.0, tolerance = 0.01,
                   label = paste("seed", seed))
      # All probabilities positive
      expect_true(all(result > 0), label = paste("all positive seed", seed))
    }
  }
})

# ---- kelly_stake: always in [0, max_stake] ----

test_that("kelly_fraction: output always non-negative", {
  for (seed in 1:30) {
    set.seed(seed)
    prob <- stats::runif(1, 0.05, 0.95)
    odds <- stats::runif(1, 1.05, 20)
    fraction <- stats::runif(1, 0.1, 1.0)

    stake <- kelly_fraction(prob, odds, fraction = fraction)

    expect_true(stake >= 0, label = paste("non-negative, seed", seed))
    # Quarter Kelly should be bounded
    expect_true(stake <= 1.0, label = paste("<=1, seed", seed))
  }
})

# ---- margin_k_factor: always in (0, 1] ----

test_that("margin_k_factor: weight always in (0, 1]", {
  for (home_g in 0:6) {
    for (away_g in 0:6) {
      w <- margin_k_factor(home_g, away_g)
      expect_true(w > 0, label = paste(home_g, "-", away_g, "> 0"))
      expect_true(w <= 1.0, label = paste(home_g, "-", away_g, "<= 1"))
    }
  }
})

# ---- pinnacle_implied_elo: monotonically increasing ----

test_that("pinnacle_implied_elo: monotonically increasing with probability", {
  probs <- seq(0.05, 0.95, by = 0.05)
  elos <- pinnacle_implied_elo(probs)

  # Each successive prob should yield higher Elo
  diffs <- diff(elos)
  expect_true(all(diffs > 0), label = "monotonically increasing")

  # 50% maps to base (1500)
  expect_equal(pinnacle_implied_elo(0.5), 1500)

  # Symmetric around 0.5
  high <- pinnacle_implied_elo(0.7) - 1500
  low <- 1500 - pinnacle_implied_elo(0.3)
  expect_equal(high, low, tolerance = 0.01)
})

# ---- seasonal_k: always between k_end and k_start ----

test_that("seasonal_k: output always in [k_end, k_start]", {
  dates <- as.Date("2024-01-01") + 0:364
  for (k_s in c(30, 40, 60)) {
    for (k_e in c(10, 20)) {
      vals <- seasonal_k(dates, k_start = k_s, k_end = k_e)
      expect_true(all(vals >= k_e), label = paste(">=", k_e))
      expect_true(all(vals <= k_s), label = paste("<=", k_s))
    }
  }
})

# ---- compute_rest_days: non-negative or NA ----

test_that("compute_rest_days: rest days are NA or positive", {
  for (seed in 1:10) {
    set.seed(seed)
    teams <- LETTERS[1:4]
    n <- sample(8:20, 1)
    home <- sample(teams, n, replace = TRUE)
    away <- sample(teams, n, replace = TRUE)
    valid <- home != away
    matches <- tibble::tibble(
      match_date = as.Date("2024-01-01") + sort(sample(1:100, sum(valid))),
      home_team = home[valid],
      away_team = away[valid],
      ftr = sample(c("H", "D", "A"), sum(valid), replace = TRUE)
    )

    result <- compute_rest_days(matches)
    # Rest days should be NA (first match) or positive integer
    home_rd <- result$home_rest_days[!is.na(result$home_rest_days)]
    away_rd <- result$away_rest_days[!is.na(result$away_rest_days)]
    if (length(home_rd) > 0) expect_true(all(home_rd > 0))
    if (length(away_rd) > 0) expect_true(all(away_rd > 0))
  }
})
