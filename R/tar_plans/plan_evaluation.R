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

  # Model vs Pinnacle comparison
  targets::tar_target(
    model_vs_pinnacle,
    {
      if (nrow(glm_eval_summary) == 0L || nrow(pinnacle_eval) == 0L) {
        return(tibble::tibble(
          metric = character(), model_mean = numeric(),
          pinnacle = numeric(), edge = numeric()
        ))
      }

      dplyr::inner_join(
        dplyr::select(glm_eval_summary, metric, model_mean = mean),
        dplyr::select(pinnacle_eval, metric, pinnacle = value),
        by = "metric"
      ) |>
        dplyr::mutate(edge = pinnacle - model_mean)
      # Positive edge = model is better (lower score)
    }
  )
)
