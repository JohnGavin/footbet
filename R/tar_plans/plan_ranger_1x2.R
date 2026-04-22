# plan_ranger_1x2.R
# Ranger random forest for 1X2 match outcome prediction (#86)
# Walk-forward CV with enriched features (SoT + shot quality)

plan_ranger_1x2 <- list(

  # ====================================================================
  # ENRICHED FEATURE MATRIX (for Ranger — handles collinearity)
  # ====================================================================

  # Join shot quality features to the main feature matrix
  targets::tar_target(
    feature_matrix_enriched,
    {
      if (!requireNamespace("ranger", quietly = TRUE)) {
        cli::cli_warn("ranger not available. Returning base feature_matrix.")
        return(feature_matrix)
      }

      fm <- feature_matrix

      # Add shot quality features (Understat, per-team rolling)
      # Normalise Understat team names to match football-data.co.uk
      team_map <- build_team_name_map()
      sq <- rolling_shot_quality_5 |>
        dplyr::mutate(team_norm = normalise_team_name(.data$team, team_map))

      # Also normalise feature_matrix team names for matching
      fm <- fm |>
        dplyr::mutate(
          home_norm = normalise_team_name(.data$home_team, team_map),
          away_norm = normalise_team_name(.data$away_team, team_map)
        )

      home_sq <- sq |>
        dplyr::select(
          team_norm = "team_norm", match_date = "match_date",
          home_xg_per_shot = "rolling_xg_per_shot",
          home_big_chances = "rolling_big_chances",
          home_shot_volume = "rolling_shot_volume",
          home_open_play_pct = "rolling_open_play_pct"
        )
      away_sq <- sq |>
        dplyr::select(
          team_norm = "team_norm", match_date = "match_date",
          away_xg_per_shot = "rolling_xg_per_shot",
          away_big_chances = "rolling_big_chances",
          away_shot_volume = "rolling_shot_volume",
          away_open_play_pct = "rolling_open_play_pct"
        )

      fm |>
        dplyr::left_join(home_sq,
          by = c("home_norm" = "team_norm", "match_date")) |>
        dplyr::left_join(away_sq,
          by = c("away_norm" = "team_norm", "match_date")) |>
        dplyr::select(-"home_norm", -"away_norm")
    }
  ),

  # ====================================================================
  # WALK-FORWARD CV: Ranger 1X2 (per-league)
  # ====================================================================

  targets::tar_target(
    cv_ranger_1x2,
    {
      if (!requireNamespace("ranger", quietly = TRUE)) {
        cli::cli_warn("ranger not available. Skipping Ranger 1X2 CV.")
        return(tibble::tibble())
      }

      fm <- feature_matrix_enriched

      # Feature columns for Ranger (all available numeric features)
      feature_cols <- c(
        # Core: Elo + rolling goals
        "home_elo", "away_elo", "elo_diff",
        "home_roll_gf", "home_roll_ga",
        "away_roll_gf", "away_roll_ga",
        # SoT ratio
        "home_sot_for", "home_sot_against", "home_sot_ratio",
        "away_sot_for", "away_sot_against", "away_sot_ratio",
        # Shot quality (Understat)
        "home_xg_per_shot", "home_big_chances",
        "home_shot_volume", "home_open_play_pct",
        "away_xg_per_shot", "away_big_chances",
        "away_shot_volume", "away_open_play_pct"
      )
      available <- intersect(feature_cols, names(fm))

      leagues <- unique(fm$league_code)
      xg_leagues <- c("D1", "E0", "F1", "I1", "SP1")
      # Only run on leagues with shot quality data (Understat coverage)
      leagues_to_run <- intersect(leagues, xg_leagues)

      all_results <- purrr::map(leagues_to_run, function(lg) {
        lg_fm <- fm |>
          dplyr::filter(.data$league_code == lg, !is.na(.data$ftr))

        tryCatch(
          ranger_walkforward_cv(
            fm = lg_fm,
            feature_cols = available,
            train_months = 24L,
            test_months = 1L,
            league_code = lg
          ),
          error = function(e) {
            cli::cli_warn("Ranger CV failed for {lg}: {conditionMessage(e)}")
            NULL
          }
        )
      })

      dplyr::bind_rows(all_results)
    }
  ),

  # Walk-forward CV: Ranger with ONLY core features (baseline for comparison)
  targets::tar_target(
    cv_ranger_1x2_core,
    {
      if (!requireNamespace("ranger", quietly = TRUE)) {
        return(tibble::tibble())
      }

      fm <- feature_matrix
      core_cols <- c(
        "home_elo", "away_elo", "elo_diff",
        "home_roll_gf", "home_roll_ga",
        "away_roll_gf", "away_roll_ga",
        "home_sot_ratio", "away_sot_ratio"
      )
      available <- intersect(core_cols, names(fm))
      xg_leagues <- c("D1", "E0", "F1", "I1", "SP1")

      all_results <- purrr::map(xg_leagues, function(lg) {
        lg_fm <- fm |>
          dplyr::filter(.data$league_code == lg, !is.na(.data$ftr))
        tryCatch(
          ranger_walkforward_cv(lg_fm, available, 24L, 1L, lg),
          error = function(e) NULL
        )
      })

      dplyr::bind_rows(all_results)
    }
  ),

  # ====================================================================
  # COMPARISON TABLE
  # ====================================================================

  targets::tar_target(
    model_comparison_1x2,
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
        summarise_one(cv_ranger_1x2_core, "Ranger core (Elo+goals+SoT)"),
        summarise_one(cv_ranger_1x2, "Ranger enriched (+shot quality)")
      )
    }
  )
)
