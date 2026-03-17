# Integration tests using real data from targets store.
# These validate that functions work on actual match data shapes,
# catching edge cases that synthetic data misses.
#
# Guarded by skip_if_not — only run locally when targets store exists.

skip_if(nzchar(Sys.getenv("_R_CHECK_PACKAGE_NAME_")), "skipping in R CMD check")

store <- here::here("_targets")

skip_if_not(
 file.exists(file.path(store, "meta", "meta")),
 "targets store not available"
)

# Read targets without callr subprocess (avoids R crash in devtools::test)
safe_read <- function(name) {
  rds <- here::here("inst", "extdata", "vignettes", paste0(name, ".rds"))
  if (file.exists(rds)) return(readRDS(rds))
  tryCatch(
    targets::tar_read_raw(name, store = store),
    error = function(e) NULL
  )
}

# ---- Elo on real match data ----

test_that("compute_elo: runs on full E0 (Premier League) data", {
  matches <- safe_read("parsed_matches") |>
    dplyr::filter(league_code == "E0")

  result <- compute_elo(
    matches,
    dynamic_k = TRUE, k_start = 40, k_end = 20,
    margin_k = TRUE, reversion = 0.28, asymmetric = TRUE
  )

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 2000)
  # Sanity: all ratings between 800 and 2200

  expect_true(all(result$elo > 800 & result$elo < 2200),
              label = "Elo ratings in sane range")
  # All teams present
  teams_in <- unique(c(matches$home_team, matches$away_team))
  teams_out <- unique(result$team)
  expect_true(all(teams_in[!is.na(matches$ftr)] %in% teams_out) ||
              length(setdiff(teams_in, teams_out)) < 3)
})

test_that("compute_elo: Elo conserved on real data per league", {
  matches <- safe_read("parsed_matches")
  leagues <- unique(matches$league_code)

  for (lc in leagues) {
    league_matches <- dplyr::filter(matches, league_code == lc)
    result <- compute_elo(league_matches)
    final <- result |>
      dplyr::group_by(team) |>
      dplyr::slice_tail(n = 1) |>
      dplyr::ungroup()

    n_teams <- nrow(final)
    expect_equal(sum(final$elo), n_teams * 1500, tolerance = 0.1,
                 label = paste("conservation in", lc))
  }
})

# ---- Rest days on real data ----

test_that("compute_rest_days: runs on full dataset", {
  matches <- safe_read("parsed_matches") |>
    dplyr::filter(league_code == "E0")

  result <- compute_rest_days(matches)

  expect_true("home_rest_days" %in% names(result))
  expect_true("away_rest_days" %in% names(result))
  expect_true("rest_diff" %in% names(result))

  # Most rest days should be between 2 and 30
  valid_home <- result$home_rest_days[!is.na(result$home_rest_days)]
  expect_true(mean(valid_home >= 2 & valid_home <= 30) > 0.9,
              label = "90%+ rest days in 2-30 range")
})

# ---- Devig on real odds data ----

test_that("devig_odds: runs on full odds dataset", {
  odds <- safe_read("parsed_odds")

  result <- devig_odds(odds)

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
  expect_true(all(c("fair_h", "fair_d", "fair_a") %in% names(result)))

  # Fair probabilities should sum to ~1 where Pinnacle data exists
  has_pinnacle <- !is.na(result$fair_h) & !is.na(result$fair_d) & !is.na(result$fair_a)
  if (sum(has_pinnacle) > 100) {
    sums <- result$fair_h[has_pinnacle] + result$fair_d[has_pinnacle] +
            result$fair_a[has_pinnacle]
    expect_true(all(abs(sums - 1) < 0.05),
                label = "fair probs sum to ~1")
  }
})

# ---- Feature matrix assembly ----

test_that("feature_matrix: has expected columns and no all-NA features", {
  fm <- safe_read("feature_matrix")

  expected_cols <- c(
    "match_id", "league_code", "season", "match_date",
    "home_team", "away_team", "fthg", "ftag", "ftr",
    "home_elo", "away_elo", "elo_diff"
  )
  for (col in expected_cols) {
    expect_true(col %in% names(fm), label = paste("has column", col))
  }

  # No feature column should be ALL NA
  feature_cols <- c("home_elo", "away_elo", "elo_diff")
  for (col in intersect(feature_cols, names(fm))) {
    expect_true(!all(is.na(fm[[col]])),
                label = paste(col, "not all NA"))
  }
})

test_that("feature_matrix: rest days present and reasonable", {
  fm <- safe_read("feature_matrix")

  if ("home_rest_days" %in% names(fm)) {
    valid <- fm$home_rest_days[!is.na(fm$home_rest_days)]
    expect_true(length(valid) > 1000, label = "enough non-NA rest days")
    # Median rest should be around 7 (weekly schedule)
    expect_true(stats::median(valid) >= 4 & stats::median(valid) <= 14,
                label = "median rest days plausible")
  }
})

test_that("feature_matrix: Pinnacle implied Elo present where odds exist", {
  fm <- safe_read("feature_matrix")

  if ("pinnacle_home_elo" %in% names(fm)) {
    has_odds <- !is.na(fm$fair_h)
    has_elo <- !is.na(fm$pinnacle_home_elo)
    # Where we have fair odds, we should have implied Elo
    expect_true(all(has_elo[has_odds]),
                label = "pinnacle Elo present where odds exist")
    # Implied Elo should be in sane range
    valid_elo <- fm$pinnacle_home_elo[has_elo]
    expect_true(all(valid_elo > 800 & valid_elo < 2200),
                label = "pinnacle Elo in sane range")
  }
})

# ---- Elo ratings target shape ----

test_that("elo_ratings target: has expected columns and sane range", {
  elo <- safe_read("elo_ratings")

  expect_s3_class(elo, "tbl_df")
  expect_true(all(c("team", "elo", "league_code") %in% names(elo)))
  expect_true(nrow(elo) > 100, label = "enough rows")
  expect_true(all(elo$elo > 800 & elo$elo < 2200),
              label = "Elo ratings in sane range")
})

# ---- Vignette targets: none NULL ----

test_that("all vig_* RDS files are non-NULL", {
  rds_dir <- here::here("inst", "extdata", "vignettes")
  skip_if_not(dir.exists(rds_dir), "RDS directory not found")

  rds_files <- list.files(rds_dir, pattern = "^vig_.*\\.rds$")
  expect_true(length(rds_files) > 0, label = "found vig_* RDS files")

  null_targets <- c()
  for (f in rds_files) {
    obj <- readRDS(file.path(rds_dir, f))
    if (is.null(obj)) null_targets <- c(null_targets, f)
  }

  expect_equal(length(null_targets), 0L,
               label = paste("NULL RDS:", paste(null_targets, collapse = ", ")))
})
