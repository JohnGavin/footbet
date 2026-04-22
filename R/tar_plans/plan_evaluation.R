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

  # Market baselines: Pinnacle + consensus (avg bookie) per league
  targets::tar_target(
    market_baselines,
    evaluate_market_baselines(parsed_odds, parsed_matches)
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
  ),

  # ====================================================================
  # Per-team and per-league AH ROI heatmap (#75)
  # ====================================================================

  # Per-team ROI: which teams are systematically mispredicted?
  targets::tar_target(
    ah_roi_per_team,
    {
      bets <- ah_walkforward_all |>
        dplyr::filter(.data$staking == "flat")  # flat stake for clean comparison

      if (nrow(bets) == 0L) return(tibble::tibble())

      # Join to get team names and league
      bets_teams <- bets |>
        dplyr::inner_join(
          parsed_matches |>
            dplyr::select("match_id", "home_team", "away_team", "league_code"),
          by = "match_id"
        )

      # Home team perspective
      home_roi <- bets_teams |>
        dplyr::group_by(model = .data$model, team = .data$home_team,
                        league_code = .data$league_code) |>
        dplyr::summarise(
          n_bets = dplyr::n(),
          roi_pct = round(100 * sum(.data$net) / sum(.data$stake), 1),
          win_rate = round(100 * mean(.data$won), 1),
          .groups = "drop"
        ) |>
        dplyr::mutate(venue = "home")

      # Away team perspective
      away_roi <- bets_teams |>
        dplyr::group_by(model = .data$model, team = .data$away_team,
                        league_code = .data$league_code) |>
        dplyr::summarise(
          n_bets = dplyr::n(),
          roi_pct = round(100 * sum(.data$net) / sum(.data$stake), 1),
          win_rate = round(100 * mean(.data$won), 1),
          .groups = "drop"
        ) |>
        dplyr::mutate(venue = "away")

      dplyr::bind_rows(home_roi, away_roi) |>
        dplyr::arrange(.data$model, .data$league_code, .data$team)
    }
  ),

  # Per-league AH ROI by model
  targets::tar_target(
    ah_roi_per_league,
    {
      bets <- ah_walkforward_all |>
        dplyr::filter(.data$staking == "flat")

      if (nrow(bets) == 0L) return(tibble::tibble())

      bets |>
        dplyr::inner_join(
          parsed_matches |>
            dplyr::select("match_id", "league_code"),
          by = "match_id"
        ) |>
        dplyr::group_by(.data$model, .data$league_code) |>
        dplyr::summarise(
          n_bets = dplyr::n(),
          roi_pct = round(100 * sum(.data$net) / sum(.data$stake), 1),
          win_rate = round(100 * mean(.data$won), 1),
          sharpe = {
            n <- dplyr::n()
            s <- if (n >= 2L) stats::sd(.data$net) else NA_real_
            dplyr::if_else(!is.na(s) & s > 0,
              round(mean(.data$net) / s, 3), NA_real_)
          },
          .groups = "drop"
        ) |>
        dplyr::arrange(.data$model, .data$league_code)
    }
  )
)
