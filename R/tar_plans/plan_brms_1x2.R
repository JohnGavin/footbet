# plan_brms_1x2.R
# brms hierarchical Poisson for 1X2 match outcome prediction (#86)
# Walk-forward CV per league — uses rstan backend

plan_brms_1x2 <- list(

  # ====================================================================
  # WALK-FORWARD CV: brms hierarchical Poisson (per-league)
  # ====================================================================

  targets::tar_target(
    cv_brms_1x2,
    {
      if (!requireNamespace("brms", quietly = TRUE)) {
        cli::cli_warn("brms not available. Skipping brms 1X2 CV.")
        return(tibble::tibble())
      }

      xg_leagues <- c("D1", "E0", "F1", "I1", "SP1")

      all_results <- purrr::map(xg_leagues, function(lg) {
        lg_long <- matches_long |>
          dplyr::filter(.data$league_code == lg)

        lg_matches <- parsed_matches |>
          dplyr::filter(.data$league_code == lg, !is.na(.data$ftr))

        tryCatch({
          cli::cli_alert("brms CV for league {lg}")
          evaluate_brms(
            long_df = lg_long,
            matches_df = lg_matches,
            train_months = 24L,
            test_months = 1L,
            # Reduced iterations for CV speed (2 chains x 500+500)
            iter = 1000L,
            warmup = 500L,
            chains = 2L,
            cores = 2L
          ) |>
            dplyr::mutate(league_code = lg)
        },
        error = function(e) {
          cli::cli_warn("brms CV failed for {lg}: {conditionMessage(e)}")
          NULL
        })
      })

      dplyr::bind_rows(all_results)
    }
  ),

  # ====================================================================
  # UPDATED FULL COMPARISON (adds brms to existing 6-model table)
  # ====================================================================

  targets::tar_target(
    model_comparison_with_brms,
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
        summarise_one(cv_xgboost_1x2, "XGBoost enriched"),
        summarise_one(cv_brms_1x2, "brms hierarchical")
      )
    }
  )
)
