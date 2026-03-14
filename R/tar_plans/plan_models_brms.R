# plan_models_brms.R
# Hierarchical Bayesian Poisson model with partial pooling using brms.
# NOTE: MCMC is slow. These targets are set to cue = "never" by default.

plan_models_brms <- list(

  # Full brms model fit on all data (for final predictions)
  targets::tar_target(
    brms_full_model,
    {
      if (!requireNamespace("brms", quietly = TRUE)) {
        cli::cli_warn("brms not available. Skipping brms model fit.")
        return(NULL)
      }

      # Add match_date to long_df for filtering
      long_with_date <- matches_long |>
        dplyr::left_join(
          dplyr::select(parsed_matches, match_id, match_date),
          by = "match_id"
        )

      fit_brms_poisson(
        long_with_date,
        iter = 2000L,
        warmup = 1000L,
        chains = 4L,
        cores = 4L
      )
    },
    # Only rebuild if explicitly requested (expensive)
    cue = targets::tar_cue(mode = "never")
  ),

  # Walk-forward cross-validation for brms model
  targets::tar_target(
    brms_cv,
    {
      if (!requireNamespace("brms", quietly = TRUE)) {
        cli::cli_warn("brms not available. Skipping brms CV.")
        return(tibble::tibble())
      }

      # Add match_date to long_df
      long_with_date <- matches_long |>
        dplyr::left_join(
          dplyr::select(parsed_matches, match_id, match_date),
          by = "match_id"
        )

      evaluate_brms(
        long_df = long_with_date,
        matches_df = parsed_matches,
        train_months = 24L,
        test_months = 1L,
        iter = 1000L,   # Reduced for CV speed
        warmup = 500L,
        chains = 2L,
        cores = 2L
      )
    },
    cue = targets::tar_cue(mode = "never")
  ),

  # Summary of brms CV results
  targets::tar_target(
    brms_eval_summary,
    {
      # Guard: brms may not be available in Nix
      if (!is.data.frame(brms_cv) || nrow(brms_cv) == 0L) {
        return(tibble::tibble(
          model = "brms_poisson",
          mean_log_loss = NA_real_,
          mean_brier = NA_real_,
          mean_rps = NA_real_,
          n_folds = 0L
        ))
      }
      summarise_cv(brms_cv) |>
        dplyr::mutate(model = "brms_poisson", .before = 1)
    }
  ),

  # Compare all models: GLM vs Dixon-Coles vs brms vs Pinnacle
  targets::tar_target(
    all_models_comparison,
    {
      # All summaries use long format: metric, mean, median, sd, n_folds
      glm_sum <- glm_eval_summary |>
        dplyr::mutate(model = "glm_poisson", .before = 1)

      dc_sum <- dc_eval_summary |>
        dplyr::mutate(model = "dixon_coles", .before = 1)

      # pinnacle_eval is metric/value format (no CV folds)
      pin_sum <- pinnacle_eval |>
        dplyr::transmute(
          model = "pinnacle",
          metric = metric,
          mean = value,
          median = value,
          sd = NA_real_,
          n_folds = 1L
        )

      models <- list(glm_sum, dc_sum, pin_sum)

      # Include brms only if it has real results
      if (is.data.frame(brms_eval_summary) && nrow(brms_eval_summary) > 0L &&
          "mean" %in% names(brms_eval_summary) &&
          !all(is.na(brms_eval_summary$mean))) {
        models <- c(models, list(
          brms_eval_summary |>
            dplyr::mutate(model = "brms_poisson", .before = 1)
        ))
      }

      dplyr::bind_rows(models)
    }
  ),

  # Posterior predictive check plot (for vignette)
  targets::tar_target(
    vig_pp_check_goals,
    {
      if (is.null(brms_full_model) ||
          !requireNamespace("brms", quietly = TRUE)) {
        return(NULL)
      }

      brms::pp_check(brms_full_model, type = "bars", ndraws = 100) +
        ggplot2::labs(
          title = "Posterior Predictive Check: Goals Distribution",
          subtitle = "Observed (dark) vs replicated (light) from posterior",
          caption = "Model: Poisson with team random effects. 100 posterior draws.",
          x = "Goals per team per match",
          y = "Count"
        ) +
        ggplot2::theme_minimal(base_size = 12)
    }
  ),

  # Shrinkage plot: compare fixed vs random effects estimates
  targets::tar_target(
    vig_shrinkage_plot,
    {
      if (is.null(brms_full_model) ||
          !requireNamespace("brms", quietly = TRUE)) {
        return(NULL)
      }

      ranef_df <- brms::ranef(brms_full_model)$team[, , "Intercept"]
      ranef_tbl <- tibble::tibble(
        team = rownames(ranef_df),
        re_estimate = ranef_df[, "Estimate"],
        re_lower = ranef_df[, "Q2.5"],
        re_upper = ranef_df[, "Q97.5"]
      )

      ranef_tbl |>
        dplyr::arrange(re_estimate) |>
        dplyr::mutate(team = factor(team, levels = team)) |>
        ggplot2::ggplot(ggplot2::aes(x = re_estimate, y = team)) +
        ggplot2::geom_point() +
        ggplot2::geom_errorbarh(
          ggplot2::aes(xmin = re_lower, xmax = re_upper),
          height = 0
        ) +
        ggplot2::geom_vline(xintercept = 0, linetype = "dashed", alpha = 0.5) +
        ggplot2::labs(
          title = "Team Attack Strength (Random Effects)",
          subtitle = "Partial pooling shrinks extreme estimates toward zero",
          caption = paste(
            "95% credible intervals shown.",
            "Teams with few matches are shrunk more toward the grand mean (0).",
            "Source: brms Poisson model with team random effects."
          ),
          x = "Attack strength (log scale, 0 = average)",
          y = NULL
        ) +
        ggplot2::theme_minimal(base_size = 11) +
        ggplot2::theme(axis.text.y = ggplot2::element_text(size = 6))
    }
  )
)
