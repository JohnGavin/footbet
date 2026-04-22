# plan_xgboost_1x2.R
# XGBoost gradient boosting for 1X2 match outcome prediction (#86)
# Walk-forward CV with enriched features (SoT + shot quality)

plan_xgboost_1x2 <- list(

  # ====================================================================
  # WALK-FORWARD CV: XGBoost 1X2
  # ====================================================================

  # XGBoost with enriched features (same as Ranger enriched)
  targets::tar_target(
    cv_xgboost_1x2,
    {
      if (!requireNamespace("xgboost", quietly = TRUE)) {
        cli::cli_warn("xgboost not available. Skipping XGBoost 1X2 CV.")
        return(tibble::tibble())
      }

      fm <- feature_matrix_enriched

      feature_cols <- c(
        "home_elo", "away_elo", "elo_diff",
        "home_roll_gf", "home_roll_ga",
        "away_roll_gf", "away_roll_ga",
        "home_sot_for", "home_sot_against", "home_sot_ratio",
        "away_sot_for", "away_sot_against", "away_sot_ratio",
        "home_xg_per_shot", "home_big_chances",
        "home_shot_volume", "home_open_play_pct",
        "away_xg_per_shot", "away_big_chances",
        "away_shot_volume", "away_open_play_pct"
      )

      xg_leagues <- c("D1", "E0", "F1", "I1", "SP1")

      all_results <- purrr::map(xg_leagues, function(lg) {
        lg_fm <- fm |>
          dplyr::filter(.data$league_code == lg, !is.na(.data$ftr))
        tryCatch(
          xgboost_walkforward_cv(
            fm = lg_fm,
            feature_cols = feature_cols,
            train_months = 24L,
            test_months = 1L,
            league_code = lg,
            nrounds = 200L,
            early_stopping = 15L,
            eta = 0.05,
            max_depth = 4L
          ),
          error = function(e) {
            cli::cli_warn("XGBoost CV failed for {lg}: {conditionMessage(e)}")
            NULL
          }
        )
      })

      dplyr::bind_rows(all_results)
    }
  ),

  # XGBoost with core features only (baseline comparison)
  targets::tar_target(
    cv_xgboost_1x2_core,
    {
      if (!requireNamespace("xgboost", quietly = TRUE)) {
        return(tibble::tibble())
      }

      fm <- feature_matrix
      core_cols <- c(
        "home_elo", "away_elo", "elo_diff",
        "home_roll_gf", "home_roll_ga",
        "away_roll_gf", "away_roll_ga",
        "home_sot_ratio", "away_sot_ratio"
      )

      xg_leagues <- c("D1", "E0", "F1", "I1", "SP1")

      all_results <- purrr::map(xg_leagues, function(lg) {
        lg_fm <- fm |>
          dplyr::filter(.data$league_code == lg, !is.na(.data$ftr))
        tryCatch(
          xgboost_walkforward_cv(lg_fm, core_cols, 24L, 1L, lg),
          error = function(e) NULL
        )
      })

      dplyr::bind_rows(all_results)
    }
  ),

  # ====================================================================
  # FULL MODEL COMPARISON (GLM + xG + Ranger + XGBoost)
  # ====================================================================

  targets::tar_target(
    model_comparison_full,
    {
      summarise_one <- function(df, label) {
        if (!is.data.frame(df) || nrow(df) == 0L ||
            !"log_loss" %in% names(df)) {
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

      xg_leagues <- c("D1", "E0", "F1", "I1", "SP1")

      dplyr::bind_rows(
        summarise_one(
          cv_goals_only |> dplyr::filter(.data$league_code %in% xg_leagues),
          "GLM baseline"
        ),
        summarise_one(cv_xg_features_cut7, "GLM + xG cut7"),
        summarise_one(cv_ranger_1x2_core, "Ranger core"),
        summarise_one(cv_ranger_1x2, "Ranger enriched"),
        summarise_one(cv_xgboost_1x2_core, "XGBoost core"),
        summarise_one(cv_xgboost_1x2, "XGBoost enriched")
      )
    }
  )
)
