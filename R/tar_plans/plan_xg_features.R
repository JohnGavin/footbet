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
  )
)
