# plan_xg_features.R
# xG-based feature engineering and evaluation.
# Data acquisition (fbref_xg_raw) and matches_with_xg are provided by plan_xgk.R.

plan_xg_features <- list(
  # ============================================================================
  # SHOT QUALITY FEATURES (from Understat shot-level data)
  # ============================================================================

  # Per-match shot quality aggregation
  targets::tar_target(
    shot_quality_per_match,
    compute_shot_quality(understat_shots_raw)
  ),

  # Rolling shot quality features (5-match window)
  targets::tar_target(
    rolling_shot_quality_5,
    rolling_shot_quality(shot_quality_per_match, window = 5L)
  ),

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
  ),

  # ============================================================================
  # PER-LEAGUE BREAKDOWN (#84)
  # ============================================================================

  # Per-league xG vs goals-only comparison (cut7 only)
  targets::tar_target(
    xg_per_league_comparison,
    {
      # xG cut7 leagues
      xg_leagues <- unique(cv_xg_features_cut7$league_code)

      # Filter goals-only to same leagues for fair comparison
      goals_filtered <- cv_goals_only |>
        dplyr::filter(.data$league_code %in% xg_leagues)

      summarise_by_league <- function(df, label) {
        df |>
          dplyr::group_by(.data$league_code) |>
          dplyr::summarise(
            model = label,
            mean_log_loss = mean(.data$log_loss, na.rm = TRUE),
            mean_brier = mean(.data$brier, na.rm = TRUE),
            mean_rps = mean(.data$rps, na.rm = TRUE),
            n_folds = dplyr::n(),
            .groups = "drop"
          )
      }

      goals_by_lg <- summarise_by_league(goals_filtered, "goals_only")
      xg_by_lg <- summarise_by_league(cv_xg_features_cut7, "xg_cut7")

      comparison <- dplyr::bind_rows(goals_by_lg, xg_by_lg) |>
        dplyr::arrange(.data$league_code, .data$model)

      # Add improvement column
      wide <- goals_by_lg |>
        dplyr::select("league_code",
                       goals_ll = "mean_log_loss",
                       goals_brier = "mean_brier",
                       goals_rps = "mean_rps") |>
        dplyr::inner_join(
          xg_by_lg |>
            dplyr::select("league_code",
                           xg_ll = "mean_log_loss",
                           xg_brier = "mean_brier",
                           xg_rps = "mean_rps"),
          by = "league_code"
        ) |>
        dplyr::mutate(
          ll_improvement_pct = 100 * (.data$goals_ll - .data$xg_ll) /
            .data$goals_ll,
          brier_improvement_pct = 100 * (.data$goals_brier - .data$xg_brier) /
            .data$goals_brier,
          rps_improvement_pct = 100 * (.data$goals_rps - .data$xg_rps) /
            .data$goals_rps
        )

      list(long = comparison, wide = wide)
    }
  ),

  # Dixon-Coles vs GLM on xG-era data subset (#84)
  targets::tar_target(
    dc_vs_glm_xg_era,
    {
      # Filter DC results to xG-era leagues
      xg_leagues <- unique(cv_xg_features_cut7$league_code)
      dc_xg_era <- dc_cv |>
        dplyr::filter(.data$league_code %in% xg_leagues)

      # Also filter goals-only GLM to same leagues
      glm_xg_era <- cv_goals_only |>
        dplyr::filter(.data$league_code %in% xg_leagues)

      summarise_one <- function(df, label) {
        if (!is.data.frame(df) || nrow(df) == 0L) {
          return(tibble::tibble(
            model = label, mean_log_loss = NA_real_,
            mean_brier = NA_real_, mean_rps = NA_real_, n_folds = 0L
          ))
        }
        tibble::tibble(
          model = label,
          mean_log_loss = mean(df$log_loss, na.rm = TRUE),
          mean_brier = mean(df$brier, na.rm = TRUE),
          mean_rps = mean(df$rps, na.rm = TRUE),
          n_folds = nrow(df)
        )
      }

      dplyr::bind_rows(
        summarise_one(glm_xg_era, "GLM goals-only"),
        summarise_one(dc_xg_era, "Dixon-Coles goals-only"),
        summarise_one(cv_xg_features_cut7, "GLM + xG cut7")
      )
    }
  ),

  # Calibration data for reliability curves (#84)
  targets::tar_target(
    xg_calibration_data,
    {
      # Collect per-fold match-level predictions for calibration
      # Recompute with match-level data from the same walk-forward
      matches_xg <- matches_with_xg |>
        dplyr::filter(!is.na(.data$home_xg))
      xg_leagues <- unique(cv_xg_features_cut7$league_code)

      # Goals-only model: per-fold match predictions
      goals_preds <- collect_fold_predictions(
        long_df = matches_long,
        matches_df = parsed_matches |>
          dplyr::filter(.data$league_code %in% xg_leagues),
        train_months = 24L,
        test_months = 1L,
        model_label = "goals_only"
      )

      # xG model: per-fold match predictions using cut7 long format
      long_xg <- long_df_xg_cut7 |>
        dplyr::filter(!is.na(.data$rolling_xg_for))
      xg_preds <- collect_fold_predictions(
        long_df = long_xg,
        matches_df = matches_xg,
        train_months = 24L,
        test_months = 1L,
        model_label = "xg_cut7"
      )

      dplyr::bind_rows(goals_preds, xg_preds)
    }
  ),

  # Reliability curve data for calibration plot (#84)
  targets::tar_target(
    xg_reliability_curves,
    {
      if (!is.data.frame(xg_calibration_data) ||
          nrow(xg_calibration_data) == 0L) {
        return(tibble::tibble())
      }

      # Compute reliability curves per model and outcome
      models <- unique(xg_calibration_data$model)
      outcomes <- c("H", "D", "A")

      purrr::map_dfr(models, function(m) {
        df <- xg_calibration_data[xg_calibration_data$model == m, ]
        purrr::map_dfr(outcomes, function(out) {
          pred_col <- switch(out,
            H = df$pred_h,
            D = df$pred_d,
            A = df$pred_a
          )
          actual_binary <- as.numeric(df$actual == out)
          rc <- reliability_curve_data(pred_col, actual_binary,
                                       n_bins = 10L)
          rc$model <- m
          rc$outcome <- out
          rc
        })
      })
    }
  ),

  # Brier decomposition comparison (#84)
  targets::tar_target(
    xg_brier_decomposition,
    {
      if (!is.data.frame(xg_calibration_data) ||
          nrow(xg_calibration_data) == 0L) {
        return(tibble::tibble())
      }

      models <- unique(xg_calibration_data$model)
      purrr::map_dfr(models, function(m) {
        df <- xg_calibration_data[xg_calibration_data$model == m, ]
        dec <- brier_decomposition_1x2(
          df$pred_h, df$pred_d, df$pred_a, df$actual
        )
        dec$model <- m
        dec
      })
    }
  )
)
