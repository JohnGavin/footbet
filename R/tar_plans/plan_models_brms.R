# plan_models_brms.R
# Hierarchical Bayesian Poisson model with partial pooling using brms.
# NOTE: MCMC is slow but targets invalidate normally (cue = "thorough").
# To skip brms targets: tar_make(names = !starts_with("brms_"))

plan_models_brms <- list(

  # Full brms model fit on all data (for final predictions)
  targets::tar_target(
    brms_full_model,
    {
      if (!requireNamespace("brms", quietly = TRUE)) {
        cli::cli_warn("brms not available. Skipping brms model fit.")
        return(NULL)
      }

      # matches_long already contains match_date
      fit_brms_poisson(
        matches_long,
        iter = 2000L,
        warmup = 1000L,
        chains = 4L,
        cores = 4L
      )
    },
    # Only rebuild if explicitly requested (expensive)
    cue = targets::tar_cue(mode = "thorough")
  ),

  # Walk-forward cross-validation for brms model
  targets::tar_target(
    brms_cv,
    {
      if (!requireNamespace("brms", quietly = TRUE)) {
        cli::cli_warn("brms not available. Skipping brms CV.")
        return(tibble::tibble())
      }

      # matches_long already contains match_date
      evaluate_brms(
        long_df = matches_long,
        matches_df = parsed_matches,
        train_months = 24L,
        test_months = 1L,
        iter = 1000L,   # Reduced for CV speed
        warmup = 500L,
        chains = 2L,
        cores = 2L
      )
    },
    cue = targets::tar_cue(mode = "thorough")
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
      if (!is.null(brms_full_model) &&
          requireNamespace("brms", quietly = TRUE)) {
        # Real brms posterior predictive check
        brms::pp_check(brms_full_model, type = "bars", ndraws = 100) +
          ggplot2::labs(
            title = "Posterior Predictive Check: Goals Distribution",
            subtitle = "Observed (dark) vs replicated (light) from posterior",
            caption = "Model: Poisson with team random effects. 100 posterior draws.",
            x = "Goals per team per match",
            y = "Count"
          ) +
          ggplot2::theme_minimal(base_size = 12)
      } else {
        # Fallback: compare observed goals vs Poisson fit from data
        goals <- c(matches_long$goals)
        lambda <- mean(goals, na.rm = TRUE)
        obs <- table(factor(goals, levels = 0:max(goals, na.rm = TRUE)))
        obs_df <- tibble::tibble(
          goals = as.integer(names(obs)),
          observed = as.integer(obs),
          poisson = stats::dpois(as.integer(names(obs)), lambda) * sum(obs)
        )
        obs_long <- tidyr::pivot_longer(
          obs_df, cols = c("observed", "poisson"),
          names_to = "source", values_to = "count"
        )
        ggplot2::ggplot(obs_long, ggplot2::aes(
          x = goals, y = count, fill = source
        )) +
          ggplot2::geom_col(position = "dodge", alpha = 0.8) +
          ggplot2::scale_fill_manual(
            values = c(observed = "#2c3e50", poisson = "#95a5a6"),
            labels = c(observed = "Observed", poisson = "Poisson fit")
          ) +
          ggplot2::labs(
            title = "Goals Distribution: Observed vs Poisson Model",
            subtitle = paste0(
              "Poisson(\u03bb=", round(lambda, 2),
              ") fitted to ", format(length(goals), big.mark = ","),
              " team-match observations"
            ),
            caption = paste(
              "Poisson GLM baseline shown (brms model not yet fitted).",
              "A hierarchical model would capture team-level variation."
            ),
            x = "Goals per team per match",
            y = "Count",
            fill = NULL
          ) +
          ggplot2::theme_minimal(base_size = 12)
      }
    }
  ),

  # Shrinkage plot: compare fixed vs random effects estimates
  targets::tar_target(
    vig_shrinkage_plot,
    {
      if (!is.null(brms_full_model) &&
          requireNamespace("brms", quietly = TRUE)) {
        # Real brms random effects
        ranef_df <- brms::ranef(brms_full_model)$team[, , "Intercept"]
        ranef_tbl <- tibble::tibble(
          team = rownames(ranef_df),
          re_estimate = ranef_df[, "Estimate"],
          re_lower = ranef_df[, "Q2.5"],
          re_upper = ranef_df[, "Q97.5"]
        )
      } else {
        # Fallback: use GLM team coefficients as proxy
        goals_by_team <- matches_long |>
          dplyr::group_by(team) |>
          dplyr::summarise(
            mean_goals = mean(goals, na.rm = TRUE),
            n_matches = dplyr::n(),
            se = stats::sd(goals, na.rm = TRUE) / sqrt(dplyr::n()),
            .groups = "drop"
          )
        grand_mean <- mean(goals_by_team$mean_goals)
        ranef_tbl <- goals_by_team |>
          dplyr::mutate(
            re_estimate = log(mean_goals / grand_mean),
            re_lower = re_estimate - 1.96 * se / mean_goals,
            re_upper = re_estimate + 1.96 * se / mean_goals
          ) |>
          dplyr::select(team, re_estimate, re_lower, re_upper)
      }

      # Show top and bottom 20 teams to keep plot readable
      ranef_tbl <- ranef_tbl |>
        dplyr::arrange(re_estimate)
      if (nrow(ranef_tbl) > 40L) {
        ranef_tbl <- dplyr::bind_rows(
          utils::head(ranef_tbl, 20L),
          utils::tail(ranef_tbl, 20L)
        )
      }

      is_brms <- !is.null(brms_full_model) &&
        requireNamespace("brms", quietly = TRUE)

      ranef_tbl |>
        dplyr::mutate(team = factor(team, levels = team)) |>
        ggplot2::ggplot(ggplot2::aes(x = re_estimate, y = team)) +
        ggplot2::geom_point() +
        ggplot2::geom_errorbar(
          ggplot2::aes(xmin = re_lower, xmax = re_upper),
          height = 0,
          orientation = "y"
        ) +
        ggplot2::geom_vline(xintercept = 0, linetype = "dashed", alpha = 0.5) +
        ggplot2::labs(
          title = if (is_brms) {
            "Team Attack Strength (Random Effects)"
          } else {
            "Team Attack Strength (GLM Estimates)"
          },
          subtitle = if (is_brms) {
            "Partial pooling shrinks extreme estimates toward zero"
          } else {
            "Top/bottom 20 teams by log(goals ratio). Hierarchical model would shrink extremes."
          },
          caption = if (is_brms) {
            paste(
              "95% credible intervals shown.",
              "Teams with few matches are shrunk more toward the grand mean (0).",
              "Source: brms Poisson model with team random effects."
            )
          } else {
            paste(
              "95% confidence intervals from observed goal rates.",
              "A brms hierarchical model would apply partial pooling,",
              "shrinking teams with few matches toward the grand mean."
            )
          },
          x = "Attack strength (log scale, 0 = average)",
          y = NULL
        ) +
        ggplot2::theme_minimal(base_size = 11) +
        ggplot2::theme(axis.text.y = ggplot2::element_text(size = 6))
    }
  ),

  # ====================================================================
  # MCMC Diagnostics (#60)
  # ====================================================================

  targets::tar_target(
    vig_mcmc_diagnostics,
    {
      if (!requireNamespace("brms", quietly = TRUE) || is.null(brms_full_model)) {
        return(tibble::tibble(
          parameter = "N/A",
          rhat = NA_real_,
          ess_bulk = NA_integer_,
          converged = NA,
          note = "brms model not available. Install brms + rstan to see diagnostics."
        ))
      }

      diag <- brms_diagnostics(brms_full_model)

      # Summary row
      summary_row <- tibble::tibble(
        parameter = paste0("SUMMARY (", nrow(diag), " parameters)"),
        rhat = max(diag$rhat, na.rm = TRUE),
        ess_bulk = min(diag$ess_bulk, na.rm = TRUE),
        converged = all(diag$converged)
      )

      dplyr::bind_rows(diag, summary_row)
    }
  ),

  # ====================================================================
  # Prior Sensitivity Analysis (#61)
  # ====================================================================

  targets::tar_target(
    vig_prior_sensitivity,
    {
      if (!requireNamespace("brms", quietly = TRUE)) {
        return(tibble::tibble(
          prior_width = c("narrow", "default", "wide"),
          fixed_sd = c(0.2, 0.5, 2.0),
          random_sd = c(0.1, 0.3, 1.0),
          note = "brms not available. These are the planned prior widths."
        ))
      }

      # Subset data for speed
      long_sub <- matches_long |>
        dplyr::left_join(
          dplyr::select(parsed_matches, match_id, match_date),
          by = "match_id"
        ) |>
        dplyr::filter(match_date >= max(match_date, na.rm = TRUE) - 365)

      # Three prior widths
      priors <- list(
        narrow = brms::prior(normal(0, 0.2), class = "b") +
                 brms::prior(normal(0, 0.1), class = "sd"),
        default = brms::prior(normal(0, 0.5), class = "b") +
                  brms::prior(normal(0, 0.3), class = "sd"),
        wide = brms::prior(normal(0, 2.0), class = "b") +
               brms::prior(normal(0, 1.0), class = "sd")
      )

      results <- lapply(names(priors), function(pw) {
        fit <- fit_brms_poisson(
          long_sub, prior = priors[[pw]],
          iter = 1000L, warmup = 500L, chains = 2L, cores = 2L
        )
        home_coef <- brms::fixef(fit)["home", ]
        tibble::tibble(
          prior_width = pw,
          fixed_sd = c(0.2, 0.5, 2.0)[match(pw, c("narrow", "default", "wide"))],
          home_estimate = round(home_coef["Estimate"], 3),
          home_lower = round(home_coef["Q2.5"], 3),
          home_upper = round(home_coef["Q97.5"], 3),
          home_se = round(home_coef["Est.Error"], 3)
        )
      })

      dplyr::bind_rows(results)
    },
    cue = targets::tar_cue(mode = "thorough")
  ),

  # ====================================================================
  # LOO-CV and WAIC Model Comparison (#62)
  # ====================================================================

  targets::tar_target(
    vig_loo_comparison,
    {
      if (!requireNamespace("brms", quietly = TRUE) || is.null(brms_full_model)) {
        return(tibble::tibble(
          metric = c("ELPD (LOO)", "p_loo", "LOOIC", "ELPD (WAIC)", "p_waic"),
          estimate = rep(NA_real_, 5),
          se = rep(NA_real_, 5),
          note = "brms model not available."
        ))
      }

      loo_result <- brms_loo(brms_full_model)
      waic_result <- brms_waic(brms_full_model)
      r2_result <- brms_r2(brms_full_model)

      tibble::tibble(
        metric = c("ELPD (LOO)", "p_loo", "LOOIC",
                    "ELPD (WAIC)", "p_waic",
                    "Bayesian R²"),
        estimate = round(c(
          loo_result$estimates["elpd_loo", "Estimate"],
          loo_result$estimates["p_loo", "Estimate"],
          loo_result$estimates["looic", "Estimate"],
          waic_result$estimates["elpd_waic", "Estimate"],
          waic_result$estimates["p_waic", "Estimate"],
          r2_result[1, "Estimate"]
        ), 2),
        se = round(c(
          loo_result$estimates["elpd_loo", "SE"],
          loo_result$estimates["p_loo", "SE"],
          loo_result$estimates["looic", "SE"],
          waic_result$estimates["elpd_waic", "SE"],
          waic_result$estimates["p_waic", "SE"],
          r2_result[1, "Est.Error"]
        ), 2)
      )
    },
    cue = targets::tar_cue(mode = "thorough")
  )
)
