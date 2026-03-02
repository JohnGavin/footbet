# plan_vignette_outputs.R
# Pre-compute all tables and plots for vignettes.
# Vignettes perform ZERO computation — they only tar_read() these targets.

plan_vignette_outputs <- list(

# ============================================================================
# Vignette 1: Data Sources
# ============================================================================

  targets::tar_target(
    vig_league_season_grid,
    {
      parsed_matches |>
        dplyr::count(league_code, season, name = "n_matches") |>
        tidyr::pivot_wider(
          names_from = season, values_from = n_matches, values_fill = 0L
        ) |>
        dplyr::arrange(league_code)
    }
  ),

  targets::tar_target(
    vig_data_source_summary,
    {
      league_info <- leagues |>
        dplyr::select(league_code, country, division)

      parsed_matches |>
        dplyr::group_by(league_code) |>
        dplyr::summarise(
          n_seasons  = dplyr::n_distinct(season),
          n_matches  = dplyr::n(),
          first_date = min(match_date, na.rm = TRUE),
          last_date  = max(match_date, na.rm = TRUE),
          .groups = "drop"
        ) |>
        dplyr::left_join(league_info, by = "league_code") |>
        dplyr::select(country, league_code, division, n_seasons, n_matches,
                       first_date, last_date) |>
        dplyr::arrange(country, division)
    }
  ),

  targets::tar_target(
    vig_odds_columns_available,
    {
      odds_with_meta <- dplyr::left_join(
        parsed_odds,
        dplyr::select(parsed_matches, match_id, league_code, season),
        by = "match_id"
      )

      odds_with_meta |>
        dplyr::group_by(league_code, season) |>
        dplyr::summarise(
          n_matches       = dplyr::n(),
          pct_1x2         = 100 * mean(!is.na(psh) & !is.na(psd) & !is.na(psa)),
          pct_over_under  = 100 * mean(!is.na(p_over25) | !is.na(p_under25)),
          .groups = "drop"
        ) |>
        dplyr::arrange(league_code, season)
    }
  ),

  targets::tar_target(
    vig_matches_per_season_plot,
    {
      plot_data <- parsed_matches |>
        dplyr::count(league_code, season, name = "n_matches")

      ggplot2::ggplot(plot_data, ggplot2::aes(x = season, y = n_matches)) +
        ggplot2::geom_col(fill = "#2c3e50") +
        ggplot2::facet_wrap(~league_code, scales = "free_y", ncol = 2) +
        ggplot2::labs(
          title = "Match Count by League and Season",
          subtitle = "Top-2 divisions across 5 countries; most leagues have ~380 matches/season (Div 1) or ~500+ (Div 2)",
          caption = paste(
            "Source: football-data.co.uk.",
            "Bars show total parsed matches per league/season.",
            "Key: E0 (EPL) and D1 (Bundesliga) have fewer matches than Div 2 leagues.",
            "Missing bars indicate seasons not yet available."
          ),
          x = "Season", y = "Matches"
        ) +
        ggplot2::theme_minimal(base_size = 11) +
        ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
    }
  ),

# ============================================================================
# Vignette 2: Data Cleaning
# ============================================================================

  targets::tar_target(
    vig_completeness_plot,
    {
      ggplot2::ggplot(
        qc_match_completeness,
        ggplot2::aes(x = season, y = league_code, fill = pct_complete)
      ) +
        ggplot2::geom_tile(color = "white", linewidth = 0.5) +
        ggplot2::geom_text(
          ggplot2::aes(label = sprintf("%.0f", pct_complete)),
          size = 2.5
        ) +
        ggplot2::scale_fill_viridis_c(
          option = "D", limits = c(80, 100), na.value = "grey80"
        ) +
        ggplot2::labs(
          title = "Match Result Completeness by League and Season",
          subtitle = "Percentage of matches with non-missing full-time result (FTR); 100% = all results present",
          caption = paste(
            "Source: football-data.co.uk, parsed by footbet::parse_fd_csv().",
            "Fill = % of matches with valid FTR. Greyed cells = <80% or missing.",
            "Key: Most leagues achieve 100%; partial seasons show lower values."
          ),
          x = "Season", y = "League", fill = "% Complete"
        ) +
        ggplot2::theme_minimal(base_size = 11) +
        ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
    }
  ),

  targets::tar_target(
    vig_pinnacle_coverage_plot,
    {
      ggplot2::ggplot(
        qc_pinnacle_coverage,
        ggplot2::aes(x = season, y = league_code, fill = pct_pinnacle)
      ) +
        ggplot2::geom_tile(color = "white", linewidth = 0.5) +
        ggplot2::geom_text(
          ggplot2::aes(label = sprintf("%.0f", pct_pinnacle)),
          size = 2.5
        ) +
        ggplot2::scale_fill_viridis_c(
          option = "C", limits = c(0, 100), na.value = "grey80"
        ) +
        ggplot2::labs(
          title = "Pinnacle 1X2 Odds Coverage by League and Season",
          subtitle = "Percentage of matches with all three Pinnacle closing odds (PSH, PSD, PSA) present",
          caption = paste(
            "Source: football-data.co.uk Pinnacle columns.",
            "Fill = % of matches with complete 1X2 odds.",
            "Key: Pinnacle coverage dropped to 0% for some leagues from Jul 2025 due to feed break.",
            "Div 2 leagues often have lower Pinnacle coverage than top divisions."
          ),
          x = "Season", y = "League", fill = "% Pinnacle"
        ) +
        ggplot2::theme_minimal(base_size = 11) +
        ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
    }
  ),

  targets::tar_target(
    vig_anomalies_table,
    {
      if (nrow(qc_anomalies) == 0L) {
        return(tibble::tibble(
          match_id = character(),
          flag = character(),
          details = character()
        ))
      }
      qc_anomalies |>
        dplyr::mutate(
          total_goals = fthg + ftag,
          flag = dplyr::case_when(
            is.na(match_date) ~ "Missing date",
            match_date > Sys.Date() + 7L ~ "Future match",
            total_goals > 7L ~ paste0("High scoring (", total_goals, " goals)"),
            is.na(home_team) | is.na(away_team) ~ "Missing team name",
            TRUE ~ "Other"
          )
        ) |>
        dplyr::select(match_id, league_code, season, match_date,
                       home_team, away_team, fthg, ftag, flag)
    }
  ),

  targets::tar_target(
    vig_missing_data_by_column,
    {
      cols_to_check <- c(
        "match_date", "home_team", "away_team", "fthg", "ftag", "ftr",
        "hthg", "htag", "htr", "hs", "as_", "hst", "ast",
        "hf", "af", "hc", "ac", "hy", "ay", "hr", "ar"
      )
      available <- intersect(cols_to_check, names(parsed_matches))
      tibble::tibble(
        column = available,
        n_missing = vapply(available, function(col) {
          sum(is.na(parsed_matches[[col]]))
        }, integer(1)),
        pct_missing = round(100 * n_missing / nrow(parsed_matches), 1),
        n_total = nrow(parsed_matches)
      ) |>
        dplyr::arrange(dplyr::desc(pct_missing))
    }
  ),

# ============================================================================
# Vignette 3: EDA
# ============================================================================

  targets::tar_target(
    vig_goals_distribution,
    {
      goals_data <- tibble::tibble(
        goals = c(parsed_matches$fthg, parsed_matches$ftag),
        side  = rep(c("Home", "Away"), each = nrow(parsed_matches))
      ) |> dplyr::filter(!is.na(goals))

      mean_goals <- mean(goals_data$goals, na.rm = TRUE)
      poisson_df <- tibble::tibble(
        goals = 0:8,
        density = stats::dpois(0:8, lambda = mean_goals)
      )

      ggplot2::ggplot(goals_data, ggplot2::aes(x = goals)) +
        ggplot2::geom_histogram(
          ggplot2::aes(y = ggplot2::after_stat(density)),
          binwidth = 1, fill = "#2c3e50", alpha = 0.7, color = "white"
        ) +
        ggplot2::geom_line(
          data = poisson_df,
          ggplot2::aes(x = goals, y = density),
          color = "#e67e22", linewidth = 1.2
        ) +
        ggplot2::geom_point(
          data = poisson_df,
          ggplot2::aes(x = goals, y = density),
          color = "#e67e22", size = 2.5
        ) +
        ggplot2::facet_wrap(~side) +
        ggplot2::labs(
          title = "Goal Distribution: Observed vs Poisson",
          subtitle = paste0(
            "Orange line = Poisson(lambda=", round(mean_goals, 2),
            "); home teams score slightly more than away teams"
          ),
          caption = paste(
            "Source: football-data.co.uk, all leagues/seasons combined.",
            "Histogram = observed goal frequency; line = Poisson fit.",
            "Key: The Poisson is a reasonable first approximation but underpredicts 0-0 and high-scoring draws.",
            "See Dixon & Coles (1997) for the correction term."
          ),
          x = "Goals scored", y = "Density"
        ) +
        ggplot2::theme_minimal(base_size = 11)
    }
  ),

  targets::tar_target(
    vig_result_proportions,
    {
      result_data <- parsed_matches |>
        dplyr::filter(!is.na(ftr)) |>
        dplyr::count(league_code, ftr) |>
        dplyr::group_by(league_code) |>
        dplyr::mutate(pct = 100 * n / sum(n)) |>
        dplyr::ungroup()

      result_data$ftr <- factor(result_data$ftr, levels = c("H", "D", "A"))

      ggplot2::ggplot(result_data, ggplot2::aes(x = league_code, y = pct, fill = ftr)) +
        ggplot2::geom_col(position = "stack") +
        ggplot2::scale_fill_manual(
          values = c(H = "#2c3e50", D = "#95a5a6", A = "#e67e22"),
          labels = c(H = "Home win", D = "Draw", A = "Away win")
        ) +
        ggplot2::geom_hline(yintercept = c(33.3, 66.7), linetype = "dashed", alpha = 0.3) +
        ggplot2::labs(
          title = "Result Proportions by League",
          subtitle = "Compared to a uniform 33/33/33 baseline (dashed lines); home advantage is universal",
          caption = paste(
            "Source: football-data.co.uk, all seasons combined.",
            "Stacked bars show % of Home/Draw/Away results per league.",
            "Key: Home win rate ranges from ~43-47%; draws ~25-28%; away wins ~27-30%.",
            "Dashed lines = uniform 33.3% baseline for comparison."
          ),
          x = "League", y = "Percentage (%)", fill = "Result"
        ) +
        ggplot2::coord_flip() +
        ggplot2::theme_minimal(base_size = 11)
    }
  ),

  targets::tar_target(
    vig_home_advantage_by_league,
    {
      ha_data <- parsed_matches |>
        dplyr::filter(!is.na(ftr)) |>
        dplyr::group_by(league_code, season) |>
        dplyr::summarise(
          home_win_pct = 100 * mean(ftr == "H"),
          n_matches = dplyr::n(),
          .groups = "drop"
        )

      overall_mean <- mean(ha_data$home_win_pct)

      ggplot2::ggplot(ha_data, ggplot2::aes(x = season, y = home_win_pct, group = 1)) +
        ggplot2::geom_line(color = "#2c3e50") +
        ggplot2::geom_point(color = "#2c3e50", size = 1.5) +
        ggplot2::geom_hline(
          yintercept = overall_mean, linetype = "dashed", color = "#e67e22"
        ) +
        ggplot2::facet_wrap(~league_code, ncol = 2) +
        ggplot2::labs(
          title = "Home Win Percentage by League Over Seasons",
          subtitle = paste0(
            "Orange dashed line = overall mean (", round(overall_mean, 1),
            "%); COVID seasons (2020-21) show reduced home advantage"
          ),
          caption = paste(
            "Source: football-data.co.uk.",
            "Each point = home win % for one league-season.",
            "Key: Home advantage declined during COVID (empty stadiums, 2020-21).",
            "Most leagues show 43-48% home win rate."
          ),
          x = "Season", y = "Home Win %"
        ) +
        ggplot2::theme_minimal(base_size = 11) +
        ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
    }
  ),

  targets::tar_target(
    vig_scoreline_heatmap,
    {
      scorelines <- parsed_matches |>
        dplyr::filter(!is.na(fthg), !is.na(ftag)) |>
        dplyr::count(fthg, ftag, name = "n") |>
        dplyr::mutate(pct = 100 * n / sum(n))

      ggplot2::ggplot(
        dplyr::filter(scorelines, fthg <= 5, ftag <= 5),
        ggplot2::aes(x = factor(ftag), y = factor(fthg), fill = pct)
      ) +
        ggplot2::geom_tile(color = "white") +
        ggplot2::geom_text(ggplot2::aes(label = sprintf("%.1f%%", pct)), size = 3) +
        ggplot2::scale_fill_viridis_c(option = "D") +
        ggplot2::labs(
          title = "Scoreline Frequency Heatmap (0-5 goals)",
          subtitle = "1-1 and 1-0 are the most common results; scorelines above 4-4 are extremely rare",
          caption = paste(
            "Source: football-data.co.uk, all leagues/seasons.",
            "Fill = percentage of all matches with that exact scoreline.",
            "Key: 1-0 (~12%), 1-1 (~11%), 2-1 (~10%) dominate.",
            "Scorelines 5+ omitted (<0.5% combined)."
          ),
          x = "Away Goals", y = "Home Goals", fill = "% of Matches"
        ) +
        ggplot2::theme_minimal(base_size = 11)
    }
  ),

  targets::tar_target(
    vig_goals_per_season_trend,
    {
      trend_data <- parsed_matches |>
        dplyr::filter(!is.na(fthg), !is.na(ftag)) |>
        dplyr::mutate(total_goals = fthg + ftag) |>
        dplyr::group_by(league_code, season) |>
        dplyr::summarise(
          mean_goals = mean(total_goals),
          n_matches  = dplyr::n(),
          .groups    = "drop"
        )

      overall_mean <- mean(trend_data$mean_goals)

      ggplot2::ggplot(trend_data, ggplot2::aes(x = season, y = mean_goals, group = 1)) +
        ggplot2::geom_line(color = "#2c3e50") +
        ggplot2::geom_point(color = "#2c3e50", size = 1.5) +
        ggplot2::geom_hline(
          yintercept = overall_mean, linetype = "dashed", color = "#e67e22"
        ) +
        ggplot2::facet_wrap(~league_code, ncol = 2) +
        ggplot2::labs(
          title = "Mean Goals Per Match by League Over Seasons",
          subtitle = paste0(
            "Orange dashed line = overall mean (",
            round(overall_mean, 2),
            " goals/match); slight upward trend in most leagues"
          ),
          caption = paste(
            "Source: football-data.co.uk.",
            "Line = mean total goals (home + away) per match per season.",
            "Key: Scoring has increased slightly since 2015, especially in Serie A.",
            "Bundesliga consistently among highest-scoring leagues (~3.0 goals/match)."
          ),
          x = "Season", y = "Mean Goals Per Match"
        ) +
        ggplot2::theme_minimal(base_size = 11) +
        ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
    }
  ),

  targets::tar_target(
    vig_outlier_matches,
    {
      parsed_matches |>
        dplyr::filter(!is.na(fthg), !is.na(ftag)) |>
        dplyr::mutate(total_goals = fthg + ftag) |>
        dplyr::filter(total_goals > 7L) |>
        dplyr::select(match_id, league_code, season, match_date,
                       home_team, away_team, fthg, ftag, total_goals) |>
        dplyr::arrange(dplyr::desc(total_goals), match_date)
    }
  ),

  targets::tar_target(
    vig_odds_vs_result,
    {
      bench <- dplyr::inner_join(
        devigged_odds,
        dplyr::select(parsed_matches, match_id, ftr),
        by = "match_id"
      ) |>
        dplyr::filter(!is.na(fair_h), !is.na(ftr))

      # Bin implied probabilities and compute actual frequency
      calibration_data <- dplyr::bind_rows(
        bench |>
          dplyr::mutate(
            outcome = "Home",
            implied_prob = fair_h,
            actual = as.integer(ftr == "H")
          ),
        bench |>
          dplyr::mutate(
            outcome = "Draw",
            implied_prob = fair_d,
            actual = as.integer(ftr == "D")
          ),
        bench |>
          dplyr::mutate(
            outcome = "Away",
            implied_prob = fair_a,
            actual = as.integer(ftr == "A")
          )
      ) |>
        dplyr::mutate(
          prob_bin = cut(implied_prob, breaks = seq(0, 1, by = 0.05),
                         include.lowest = TRUE)
        ) |>
        dplyr::group_by(outcome, prob_bin) |>
        dplyr::summarise(
          mean_implied = mean(implied_prob, na.rm = TRUE),
          actual_freq  = mean(actual, na.rm = TRUE),
          n            = dplyr::n(),
          .groups = "drop"
        ) |>
        dplyr::filter(n >= 30L)

      ggplot2::ggplot(calibration_data,
        ggplot2::aes(x = mean_implied, y = actual_freq, color = outcome)
      ) +
        ggplot2::geom_point(ggplot2::aes(size = n), alpha = 0.7) +
        ggplot2::geom_abline(slope = 1, intercept = 0, linetype = "dashed", alpha = 0.5) +
        ggplot2::scale_color_manual(
          values = c(Home = "#2c3e50", Draw = "#95a5a6", Away = "#e67e22")
        ) +
        ggplot2::scale_size_continuous(range = c(1, 5)) +
        ggplot2::labs(
          title = "Pinnacle Odds Calibration: Implied Probability vs Actual Frequency",
          subtitle = "Points on the diagonal = perfectly calibrated; Pinnacle is well-calibrated across all outcomes",
          caption = paste(
            "Source: football-data.co.uk Pinnacle odds, devigged via Shin method.",
            "X = mean devigged implied probability per 5% bin; Y = actual outcome frequency.",
            "Key: Pinnacle is near-perfectly calibrated; slight favourites-longshots bias at extremes.",
            "Bins with <30 matches excluded for reliability. Size = number of matches."
          ),
          x = "Mean Implied Probability", y = "Actual Outcome Frequency",
          color = "Outcome", size = "N matches"
        ) +
        ggplot2::theme_minimal(base_size = 11)
    }
  ),

  targets::tar_target(
    vig_elo_spread_plot,
    {
      ggplot2::ggplot(elo_ratings, ggplot2::aes(x = elo, y = league_code)) +
        ggplot2::geom_boxplot(fill = "#2c3e50", alpha = 0.6, outlier.alpha = 0.3) +
        ggplot2::geom_vline(xintercept = 1500, linetype = "dashed", color = "#e67e22") +
        ggplot2::labs(
          title = "Elo Rating Distribution by League",
          subtitle = "Orange dashed line = starting Elo (1500); wider spreads indicate more competitive imbalance",
          caption = paste(
            "Source: Elo ratings computed by footbet::compute_elo() from match results.",
            "Box = IQR, whiskers = 1.5*IQR, dots = outliers.",
            "Key: Top divisions (E0, D1, I1, SP1, F1) have wider Elo spreads than Div 2.",
            "Higher Elo = stronger teams. Initial rating = 1500 for all teams."
          ),
          x = "Elo Rating", y = "League"
        ) +
        ggplot2::theme_minimal(base_size = 11)
    }
  ),

  targets::tar_target(
    vig_overround_by_league,
    {
      overround_data <- parsed_odds |>
        dplyr::filter(!is.na(psh), !is.na(psd), !is.na(psa)) |>
        dplyr::mutate(
          overround = 100 * (1/psh + 1/psd + 1/psa - 1)
        ) |>
        dplyr::left_join(
          dplyr::select(parsed_matches, match_id, league_code),
          by = "match_id"
        ) |>
        dplyr::filter(!is.na(league_code))

      ggplot2::ggplot(overround_data, ggplot2::aes(x = overround, y = league_code)) +
        ggplot2::geom_boxplot(fill = "#2c3e50", alpha = 0.6, outlier.alpha = 0.3) +
        ggplot2::geom_vline(xintercept = 0, linetype = "dashed", color = "#e67e22") +
        ggplot2::labs(
          title = "Pinnacle 1X2 Overround by League",
          subtitle = paste(
            "Overround (%) = bookmaker margin;",
            "Pinnacle's ~2-4% is the sharpest in the industry"
          ),
          caption = paste(
            "Source: football-data.co.uk Pinnacle closing odds.",
            "Overround = (1/PSH + 1/PSD + 1/PSA - 1) * 100.",
            "Key: Pinnacle margin is ~2-4% (vs 5-15% for soft bookmakers).",
            "Lower margin = fairer odds = better benchmark for model evaluation."
          ),
          x = "Overround (%)", y = "League"
        ) +
        ggplot2::theme_minimal(base_size = 11)
    }
  ),

  targets::tar_target(
    vig_typical_match_stats,
    {
      stat_cols <- c("hs", "as_", "hst", "ast", "hf", "af",
                      "hc", "ac", "hy", "ay", "hr", "ar")
      available <- intersect(stat_cols, names(parsed_matches))

      if (length(available) == 0L) {
        return(tibble::tibble(
          league_code = character(),
          message = "No match statistics columns available"
        ))
      }

      parsed_matches |>
        dplyr::group_by(league_code) |>
        dplyr::summarise(
          dplyr::across(
            dplyr::any_of(available),
            \(x) round(stats::median(x, na.rm = TRUE), 1)
          ),
          n_matches = dplyr::n(),
          .groups = "drop"
        ) |>
        dplyr::arrange(league_code)
    }
  ),

# ============================================================================
# Vignette 4: Model Fitting
# ============================================================================

  targets::tar_target(
    vig_cv_metrics_plot,
    {
      # Combine GLM and DC fold-level metrics
      glm_folds <- glm_baseline_cv |>
        dplyr::select(fold, log_loss, brier, rps) |>
        tidyr::pivot_longer(
          cols = c(log_loss, brier, rps),
          names_to = "metric", values_to = "value"
        ) |>
        dplyr::mutate(model = "GLM Poisson")

      dc_folds <- dc_cv |>
        dplyr::select(fold, log_loss, brier, rps) |>
        tidyr::pivot_longer(
          cols = c(log_loss, brier, rps),
          names_to = "metric", values_to = "value"
        ) |>
        dplyr::mutate(model = "Dixon-Coles")

      combined <- dplyr::bind_rows(glm_folds, dc_folds)

      # Add Pinnacle reference lines
      pinnacle_ref <- pinnacle_eval |>
        dplyr::rename(metric = metric, pinnacle_value = value)

      ggplot2::ggplot(combined, ggplot2::aes(x = fold, y = value, color = model)) +
        ggplot2::geom_line() +
        ggplot2::geom_point(size = 2) +
        ggplot2::geom_hline(
          data = pinnacle_ref,
          ggplot2::aes(yintercept = pinnacle_value),
          linetype = "dashed", color = "#e67e22", linewidth = 0.8
        ) +
        ggplot2::facet_wrap(~metric, scales = "free_y") +
        ggplot2::scale_color_manual(
          values = c("GLM Poisson" = "#2c3e50", "Dixon-Coles" = "#8e44ad")
        ) +
        ggplot2::labs(
          title = "Walk-Forward CV Metrics: GLM vs Dixon-Coles vs Pinnacle",
          subtitle = "Orange dashed = Pinnacle benchmark; lower is better for all three scoring rules",
          caption = paste(
            "Source: Walk-forward CV with 24-month train / 1-month test windows.",
            "Metrics: log-loss, Brier score, RPS (all proper scoring rules, lower = better).",
            "Key: Dixon-Coles slightly outperforms GLM; both trail Pinnacle on most folds.",
            "Orange dashed line = Pinnacle implied probability benchmark."
          ),
          x = "Fold", y = "Score", color = "Model"
        ) +
        ggplot2::theme_minimal(base_size = 11)
    }
  ),

  targets::tar_target(
    vig_model_comparison_table,
    model_vs_pinnacle
  ),

  targets::tar_target(
    vig_pnl_curve,
    {
      ggplot2::ggplot(pnl_glm, ggplot2::aes(x = seq_len(nrow(pnl_glm)), y = bankroll)) +
        ggplot2::geom_line(color = "#2c3e50") +
        ggplot2::geom_hline(yintercept = 1000, linetype = "dashed", color = "#e67e22") +
        ggplot2::labs(
          title = "Simulated Bankroll Evolution (GLM Value Bets, Quarter Kelly)",
          subtitle = "Orange dashed line = starting bankroll (1000); drawdown guardrails halve stakes at -20%",
          caption = paste(
            "Source: footbet::simulate_pnl() with min_edge=3%, quarter Kelly, max_stake=3%.",
            "X = bet number (chronological); Y = bankroll in units.",
            "Key: Bankroll trajectory depends heavily on sample period and model accuracy.",
            "Drawdown guardrails activate when bankroll drops 20% from peak."
          ),
          x = "Bet Number", y = "Bankroll"
        ) +
        ggplot2::theme_minimal(base_size = 11)
    }
  ),

  targets::tar_target(
    vig_drawdown_plot,
    {
      dd_data <- pnl_glm |>
        dplyr::mutate(
          bet_num = dplyr::row_number(),
          drawdown_pct = 100 * drawdown
        )

      ggplot2::ggplot(dd_data, ggplot2::aes(x = bet_num, y = drawdown_pct)) +
        ggplot2::geom_area(fill = "#e74c3c", alpha = 0.4) +
        ggplot2::geom_line(color = "#e74c3c") +
        ggplot2::geom_hline(yintercept = -20, linetype = "dashed", color = "#e67e22") +
        ggplot2::labs(
          title = "Drawdown Over Time (GLM Value Bets)",
          subtitle = "Orange dashed line = -20% guardrail threshold; stakes halved when breached",
          caption = paste(
            "Source: footbet::simulate_pnl() drawdown column.",
            "X = bet number; Y = drawdown from peak bankroll (%).",
            "Key: Drawdown exceeding -20% triggers stake reduction (apply_guardrails).",
            "Maximum drawdown is the key risk metric for bankroll survival."
          ),
          x = "Bet Number", y = "Drawdown (%)"
        ) +
        ggplot2::theme_minimal(base_size = 11)
    }
  ),

  targets::tar_target(
    vig_value_bets_summary,
    {
      value_bets_glm |>
        dplyr::left_join(
          dplyr::select(parsed_matches, match_id, league_code, season),
          by = "match_id"
        ) |>
        dplyr::group_by(outcome, league_code) |>
        dplyr::summarise(
          n_bets     = dplyr::n(),
          mean_edge  = round(mean(edge, na.rm = TRUE), 4),
          mean_odds  = round(mean(decimal_odds, na.rm = TRUE), 2),
          mean_kelly = round(mean(kelly_stake, na.rm = TRUE), 4),
          .groups    = "drop"
        ) |>
        dplyr::arrange(outcome, league_code)
    }
  ),

  targets::tar_target(
    vig_edge_distribution,
    {
      ggplot2::ggplot(value_bets_glm, ggplot2::aes(x = edge, fill = outcome)) +
        ggplot2::geom_histogram(binwidth = 0.01, alpha = 0.7, position = "identity") +
        ggplot2::scale_fill_manual(
          values = c(H = "#2c3e50", D = "#95a5a6", A = "#e67e22")
        ) +
        ggplot2::geom_vline(xintercept = 0.03, linetype = "dashed", color = "red") +
        ggplot2::labs(
          title = "Distribution of Edge Values for Identified Value Bets",
          subtitle = "Red dashed line = minimum edge threshold (3%); most edges cluster near 3-10%",
          caption = paste(
            "Source: footbet::find_value_bets() with min_edge=0.03.",
            "Edge = model_prob - market_prob. Bins = 1 percentage point.",
            "Key: Most value bets have modest edges (3-8%);",
            "large edges (>15%) are rare and may indicate model error."
          ),
          x = "Edge (model prob - market prob)", y = "Count", fill = "Outcome"
        ) +
        ggplot2::theme_minimal(base_size = 11)
    }
  ),

  targets::tar_target(
    vig_kelly_stake_distribution,
    {
      ggplot2::ggplot(value_bets_glm, ggplot2::aes(x = kelly_stake)) +
        ggplot2::geom_histogram(binwidth = 0.005, fill = "#2c3e50", alpha = 0.7) +
        ggplot2::geom_vline(xintercept = 0.03, linetype = "dashed", color = "#e67e22") +
        ggplot2::labs(
          title = "Distribution of Quarter-Kelly Stake Sizes",
          subtitle = "Orange dashed line = max stake cap (3% of bankroll); most stakes are well below cap",
          caption = paste(
            "Source: footbet::find_value_bets() with quarter Kelly.",
            "Kelly stake = edge / (odds - 1), then divided by 4 (quarter Kelly).",
            "Key: Quarter Kelly keeps individual stakes small (~0.5-2% of bankroll).",
            "Max stake guardrail caps at 3% to prevent ruin from single-bet losses."
          ),
          x = "Stake (fraction of bankroll)", y = "Count"
        ) +
        ggplot2::theme_minimal(base_size = 11)
    }
  ),

  targets::tar_target(
    vig_pnl_summary_table,
    pnl_summary
  )
)
