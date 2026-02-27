# plan_evaluation.R
# Model evaluation: scoring rule summaries and benchmarking

plan_evaluation <- list(

  # Summary metrics across folds
  targets::tar_target(
    glm_eval_summary,
    summarise_cv(glm_baseline_cv)
  ),

  # Benchmark: Pinnacle log-loss on same matches
  targets::tar_target(
    pinnacle_eval,
    {
      # Join Pinnacle implied probs with actual results
      bench <- dplyr::inner_join(
        pinnacle_benchmark,
        dplyr::select(parsed_matches, match_id, ftr),
        by = "match_id"
      ) |>
        dplyr::filter(!is.na(implied_h))

      if (nrow(bench) == 0L) {
        return(tibble::tibble(
          metric = character(), value = numeric()
        ))
      }

      # Compute prob of actual outcome
      prob_actual <- dplyr::case_when(
        bench$ftr == "H" ~ bench$implied_h,
        bench$ftr == "D" ~ bench$implied_d,
        bench$ftr == "A" ~ bench$implied_a,
        TRUE ~ NA_real_
      )
      prob_actual <- prob_actual[!is.na(prob_actual)]

      tibble::tibble(
        metric = c("log_loss", "brier", "rps"),
        value = c(
          log_loss(prob_actual),
          brier_1x2(bench$implied_h, bench$implied_d, bench$implied_a, bench$ftr),
          rps_1x2(bench$implied_h, bench$implied_d, bench$implied_a, bench$ftr)
        )
      )
    }
  ),

  # Dixon-Coles summary metrics
  targets::tar_target(
    dc_eval_summary,
    summarise_cv(dc_cv)
  ),

  # Model vs Pinnacle comparison (all models)
  targets::tar_target(
    model_vs_pinnacle,
    {
      if (nrow(pinnacle_eval) == 0L) {
        return(tibble::tibble(
          model = character(), metric = character(),
          model_mean = numeric(), pinnacle = numeric(), edge = numeric()
        ))
      }

      pinnacle_tbl <- dplyr::select(pinnacle_eval, metric, pinnacle = value)

      # GLM baseline
      glm_comp <- if (nrow(glm_eval_summary) > 0L) {
        dplyr::inner_join(
          dplyr::select(glm_eval_summary, metric, model_mean = mean),
          pinnacle_tbl, by = "metric"
        ) |> dplyr::mutate(model = "glm_poisson")
      }

      # Dixon-Coles
      dc_comp <- if (nrow(dc_eval_summary) > 0L) {
        dplyr::inner_join(
          dplyr::select(dc_eval_summary, metric, model_mean = mean),
          pinnacle_tbl, by = "metric"
        ) |> dplyr::mutate(model = "dixon_coles")
      }

      dplyr::bind_rows(glm_comp, dc_comp) |>
        dplyr::mutate(edge = pinnacle - model_mean) |>
        dplyr::select(model, metric, model_mean, pinnacle, edge)
      # Positive edge = model is better (lower score)
    }
  )
)
