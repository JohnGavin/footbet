# plan_xg_features.R
# xG-based feature engineering and evaluation.
# Data acquisition (fbref_xg_raw) and matches_with_xg are provided by plan_xgk.R.

plan_xg_features <- list(
  # ============================================================================
  # FEATURE ENGINEERING
  # ============================================================================

  # Compute all xG features
  targets::tar_target(
    xg_features,
    compute_xg_features(
      matches_with_xg,
      rolling_window = 5L,
      overperf_window = 10L
    )
  ),

  # Rolling xG (5-match window)
  targets::tar_target(
    rolling_xg_features,
    rolling_xg(matches_with_xg, window = 5L)
  ),

  # Cumulative xG ratio (key metric from article)
  targets::tar_target(
    xg_ratio_features,
    cumulative_xg_ratio(matches_with_xg)
  ),

  # Augmented feature matrix with xG
  targets::tar_target(
    feature_matrix_xg,
    {
      # Start with existing feature matrix
      fm <- feature_matrix

      # Add xG features for home team
      home_xg <- xg_features |>
        dplyr::filter(.data$is_home) |>
        dplyr::select(
          match_id = "match_id",
          home_rolling_xg_for = "rolling_xg_for",
          home_rolling_xg_against = "rolling_xg_against",
          home_xg_ratio = "xg_ratio",
          home_overperf_attack = "rolling_overperf_attack",
          home_overperf_defense = "rolling_overperf_defense"
        )

      # Add xG features for away team
      away_xg <- xg_features |>
        dplyr::filter(!.data$is_home) |>
        dplyr::select(
          match_id = "match_id",
          away_rolling_xg_for = "rolling_xg_for",
          away_rolling_xg_against = "rolling_xg_against",
          away_xg_ratio = "xg_ratio",
          away_overperf_attack = "rolling_overperf_attack",
          away_overperf_defense = "rolling_overperf_defense"
        )

      # Join to feature matrix
      fm |>
        dplyr::left_join(home_xg, by = "match_id") |>
        dplyr::left_join(away_xg, by = "match_id")
    }
  ),

  # ============================================================================
  # EVALUATION: xG vs GOALS COMPARISON
  # ============================================================================

  # Convert matches with xG to long format for modelling
  targets::tar_target(
    long_df_xg,
    {
      # Add xG to long format
      long <- matches_to_long(matches_with_xg)

      # Join rolling xG features
      xg <- xg_features |>
        dplyr::select(
          team = "team",
          match_date = "match_date",
          rolling_xg_for = "rolling_xg_for",
          rolling_xg_against = "rolling_xg_against",
          xg_ratio = "xg_ratio"
        )

      long |>
        dplyr::left_join(xg, by = c("team", "match_date"))
    }
  ),

  # Walk-forward CV: Goals-only baseline
  targets::tar_target(
    cv_goals_only,
    evaluate_glm_baseline(
      long_df = matches_long,
      matches_df = parsed_matches,
      train_months = 24L,
      test_months = 1L
    )
  ),

  # Walk-forward CV: xG features (using augmented feature matrix)
  targets::tar_target(
    cv_xg_features,
    {
      # Filter to matches with xG data
      matches_xg <- matches_with_xg |>
        dplyr::filter(!is.na(.data$home_xg))

      if (nrow(matches_xg) < 100) {
        cli::cli_warn("Insufficient xG data for CV evaluation.")
        return(tibble::tibble())
      }

      # Create long format with xG
      long_xg <- long_df_xg |>
        dplyr::filter(!is.na(.data$rolling_xg_for))

      evaluate_glm_baseline(
        long_df = long_xg,
        matches_df = matches_xg,
        train_months = 24L,
        test_months = 1L
      )
    }
  ),

  # Compare xG vs goals predictive power
  targets::tar_target(
    xg_vs_goals_comparison,
    {
      goals <- cv_goals_only |>
        dplyr::summarise(
          model = "goals_only",
          mean_log_loss = mean(.data$log_loss, na.rm = TRUE),
          mean_brier = mean(.data$brier, na.rm = TRUE),
          mean_rps = mean(.data$rps, na.rm = TRUE),
          n_folds = dplyr::n()
        )

      # Guard: cv_xg_features may be empty if no xG data
      if (!is.data.frame(cv_xg_features) || nrow(cv_xg_features) == 0L ||
          !"log_loss" %in% names(cv_xg_features)) {
        return(goals |> dplyr::mutate(log_loss_improvement = NA_real_))
      }

      xg <- cv_xg_features |>
        dplyr::summarise(
          model = "xg_features",
          mean_log_loss = mean(.data$log_loss, na.rm = TRUE),
          mean_brier = mean(.data$brier, na.rm = TRUE),
          mean_rps = mean(.data$rps, na.rm = TRUE),
          n_folds = dplyr::n()
        )

      comparison <- dplyr::bind_rows(goals, xg)

      comparison$log_loss_improvement <- c(
        NA,
        (goals$mean_log_loss - xg$mean_log_loss) / goals$mean_log_loss * 100
      )

      comparison
    }
  ),

  # ============================================================================
  # DIAGNOSTICS
  # ============================================================================

  # xG data coverage summary
  targets::tar_target(
    xg_coverage_summary,
    {
      matches_with_xg |>
        dplyr::group_by(.data$league_code, .data$season) |>
        dplyr::summarise(
          n_matches = dplyr::n(),
          n_with_xg = sum(!is.na(.data$home_xg)),
          pct_xg = round(100 * .data$n_with_xg / .data$n_matches, 1),
          .groups = "drop"
        ) |>
        dplyr::arrange(.data$league_code, .data$season)
    }
  ),

  # xG stability by matchday (when does xG ratio become reliable?)
  targets::tar_target(
    xg_stability_by_matchday,
    {
      # For each matchday, compute correlation between cumulative xG ratio

      # and rest-of-season points
      # This replicates the article's R² analysis

      xg_ratio_features |>
        dplyr::filter(.data$match_num >= 3, .data$match_num <= 20) |>
        dplyr::group_by(.data$match_num) |>
        dplyr::summarise(
          n_obs = dplyr::n(),
          mean_xg_ratio = mean(.data$xg_ratio, na.rm = TRUE),
          sd_xg_ratio = stats::sd(.data$xg_ratio, na.rm = TRUE),
          .groups = "drop"
        )
    }
  ),

  # ============================================================================
  # BET-TIME CUTOFF VARIANTS (leak-free)
  # ============================================================================
  #
  # The xG rolling helpers (rolling_xg, cumulative_xg_ratio,
  # xg_overperformance, compute_gamestate_xg) all use
  # dplyr::lag(slider_mean(...)) which at row i includes rows
  # i-window..i-1 — i.e. the team's prior matches up to and
  # including the match immediately before the target. If the
  # team played a midweek cup match between Pinnacle's opening
  # price and kickoff, that match contributes to the feature
  # even though the bettor would not have had its result.
  #
  # Fix: use apply_asof_cutoff() from R/leakage_fix.R to look
  # up xg_features as of (match_date - 7 days), strictly
  # excluding any team match played within the last 7 days.
  # These targets are NOT currently consumed by any AH bet
  # pipeline — kept as leak-free counterparts for future use.

  targets::tar_target(
    feature_matrix_xg_cut7,
    {
      fm <- parsed_matches |>
        dplyr::select(
          match_id, league_code, season, match_date,
          home_team, away_team, fthg, ftag, ftr
        )

      # xg_features is the long (team, match_date) table from
      # compute_xg_features(); carry the five rolling metric cols.
      xg_cols <- c(
        "rolling_xg_for", "rolling_xg_against",
        "xg_ratio",
        "rolling_overperf_attack", "rolling_overperf_defense"
      )
      available <- intersect(xg_cols, names(xg_features))
      if (length(available) == 0L) return(fm)

      apply_asof_cutoff(
        feature_df = xg_features |>
          dplyr::select("team", "match_date", dplyr::all_of(available)),
        target_df = fm,
        feature_cols = available,
        cutoff_days = cutoff_days_default
      )
    }
  ),

  # Long-format variant matching long_df_xg, but with leak-free
  # xG features joined via apply_asof_cutoff. Used by
  # cv_xg_features_cut7 as a like-for-like comparison to the
  # current (leaky) cv_xg_features.
  targets::tar_target(
    long_df_xg_cut7,
    {
      matches_xg <- matches_with_xg |>
        dplyr::filter(!is.na(.data$home_xg))
      if (nrow(matches_xg) == 0L) return(tibble::tibble())

      # Build as-of-cutoff feature table keyed by (team, match_date)
      cut_feat <- matches_xg |>
        dplyr::select(match_id, home_team, away_team, match_date) |>
        apply_asof_cutoff(
          feature_df = xg_features |>
            dplyr::select("team", "match_date",
                          "rolling_xg_for", "rolling_xg_against", "xg_ratio"),
          target_df = _,
          feature_cols = c("rolling_xg_for", "rolling_xg_against", "xg_ratio"),
          cutoff_days = cutoff_days_default
        )

      # Pivot back to long (one row per team per match) for
      # join to matches_to_long().
      home_side <- cut_feat |>
        dplyr::transmute(
          match_id = .data$match_id, team = .data$home_team,
          match_date = .data$match_date,
          rolling_xg_for     = .data$home_rolling_xg_for,
          rolling_xg_against = .data$home_rolling_xg_against,
          xg_ratio           = .data$home_xg_ratio
        )
      away_side <- cut_feat |>
        dplyr::transmute(
          match_id = .data$match_id, team = .data$away_team,
          match_date = .data$match_date,
          rolling_xg_for     = .data$away_rolling_xg_for,
          rolling_xg_against = .data$away_rolling_xg_against,
          xg_ratio           = .data$away_xg_ratio
        )
      cut_long <- dplyr::bind_rows(home_side, away_side)

      matches_to_long(matches_xg) |>
        dplyr::left_join(cut_long, by = c("match_id", "team", "match_date"))
    }
  ),

  # Walk-forward CV on cut7 xG features. Numbers here should
  # be compared with `cv_xg_features` — a shrinking xG advantage
  # is the signature that the original evaluation was leakage.
  targets::tar_target(
    cv_xg_features_cut7,
    {
      matches_xg <- matches_with_xg |> dplyr::filter(!is.na(.data$home_xg))
      if (nrow(matches_xg) < 100) {
        cli::cli_warn("Insufficient xG data for cut7 CV.")
        return(tibble::tibble())
      }
      long_xg <- long_df_xg_cut7 |> dplyr::filter(!is.na(.data$rolling_xg_for))
      if (nrow(long_xg) < 100) return(tibble::tibble())

      evaluate_glm_baseline(
        long_df = long_xg,
        matches_df = matches_xg,
        train_months = 24L,
        test_months = 1L
      )
    }
  ),

  # Side-by-side comparison of cv_xg_features (leaky) vs
  # cv_xg_features_cut7 (leak-free) vs cv_goals_only.
  targets::tar_target(
    xg_vs_goals_cut7_comparison,
    {
      summarise_one <- function(df, label) {
        if (!is.data.frame(df) || nrow(df) == 0L ||
            !"log_loss" %in% names(df)) {
          return(tibble::tibble(
            model = label,
            mean_log_loss = NA_real_,
            mean_brier = NA_real_,
            mean_rps = NA_real_,
            n_folds = 0L
          ))
        }
        tibble::tibble(
          model = label,
          mean_log_loss = mean(df$log_loss, na.rm = TRUE),
          mean_brier    = mean(df$brier,    na.rm = TRUE),
          mean_rps      = mean(df$rps,      na.rm = TRUE),
          n_folds       = nrow(df)
        )
      }

      dplyr::bind_rows(
        summarise_one(cv_goals_only,       "goals_only"),
        summarise_one(cv_xg_features,      "xg_cut0 (leaky)"),
        summarise_one(cv_xg_features_cut7, "xg_cut7 (clean)")
      )
    }
  )
)
