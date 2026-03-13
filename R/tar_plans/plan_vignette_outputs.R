# plan_vignette_outputs.R
# Pre-compute all tables and plots for vignettes.
# Vignettes perform ZERO computation — they only tar_read() these targets.
# All plots use interactive plotly with dark theme styling.

plan_vignette_outputs <- list(

# ============================================================================
# MERMAID DIAGRAM TARGETS
# Programmatically generated flowcharts that stay in sync with source code.
# ============================================================================

  # Pipeline diagram for vignettes (HTML div for mermaid.js CDN rendering)
  targets::tar_target(
    vig_pipeline_html,
    wrap_mermaid_html(generate_data_pipeline_mermaid(here::here()))
  ),

  # Walk-forward CV diagram for vignettes
  targets::tar_target(
    vig_cv_html,
    wrap_mermaid_html(generate_cv_walkforward_mermaid(here::here()))
  ),

  # Kelly decision tree for vignettes
  targets::tar_target(
    vig_kelly_html,
    wrap_mermaid_html(generate_kelly_decision_mermaid(here::here()))
  ),

  # Pipeline diagram for README.md (fenced mermaid for GitHub)
  targets::tar_target(
    readme_pipeline_mermaid,
    wrap_mermaid_fenced(generate_data_pipeline_mermaid(here::here()))
  ),

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

      plotly::plot_ly(
        plot_data,
        x = ~season,
        y = ~n_matches,
        color = ~league_code,
        type = "bar",
        hovertemplate = paste(
          "<b>%{x}</b><br>",
          "League: %{fullData.name}<br>",
          "Matches: %{y}<extra></extra>"
        )
      ) |>
        theme_dark_plotly(title = "Match Count by League and Season") |>
        plotly::layout(
          barmode = "group",
          xaxis = list(title = "Season", tickangle = 45),
          yaxis = list(title = "Matches"),
          legend = list(title = list(text = "League"))
        )
    }
  ),

# ============================================================================
# Vignette 2: Data Cleaning
# ============================================================================

  targets::tar_target(
    vig_completeness_plot,
    {
      plotly::plot_ly(
        qc_match_completeness,
        x = ~season,
        y = ~league_code,
        z = ~pct_complete,
        type = "heatmap",
        colorscale = "Viridis",
        zmin = 80,
        zmax = 100,
        hovertemplate = paste(
          "Season: %{x}<br>",
          "League: %{y}<br>",
          "Complete: %{z:.1f}%<extra></extra>"
        )
      ) |>
        theme_dark_plotly(title = "Match Result Completeness by League and Season") |>
        plotly::layout(
          xaxis = list(title = "Season", tickangle = 45),
          yaxis = list(title = "League")
        )
    }
  ),

  targets::tar_target(
    vig_pinnacle_coverage_plot,
    {
      plotly::plot_ly(
        qc_pinnacle_coverage,
        x = ~season,
        y = ~league_code,
        z = ~pct_pinnacle,
        type = "heatmap",
        colorscale = list(
          c(0, "#1c1c1c"),
          c(0.5, "#9b59b6"),
          c(1, "#1abc9c")
        ),
        zmin = 0,
        zmax = 100,
        hovertemplate = paste(
          "Season: %{x}<br>",
          "League: %{y}<br>",
          "Pinnacle: %{z:.1f}%<extra></extra>"
        )
      ) |>
        theme_dark_plotly(title = "Pinnacle 1X2 Odds Coverage by League and Season") |>
        plotly::layout(
          xaxis = list(title = "Season", tickangle = 45),
          yaxis = list(title = "League")
        )
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

  targets::tar_target(
    vig_missing_data_heatmap,
    {
      cols_to_check <- c(
        "match_date", "home_team", "away_team", "fthg", "ftag", "ftr",
        "hthg", "htag", "htr", "hs", "as_", "hst", "ast",
        "hf", "af", "hc", "ac", "hy", "ay", "hr", "ar"
      )
      available <- intersect(cols_to_check, names(parsed_matches))

      missing_pct <- tibble::tibble(
        column = available,
        pct_missing = vapply(available, function(col) {
          100 * mean(is.na(parsed_matches[[col]]))
        }, numeric(1))
      ) |>
        dplyr::filter(pct_missing > 0) |>
        dplyr::arrange(dplyr::desc(pct_missing))

      if (nrow(missing_pct) == 0) {
        missing_pct <- tibble::tibble(column = "None", pct_missing = 0)
      }

      plotly::plot_ly(
        missing_pct,
        x = ~column,
        y = ~pct_missing,
        type = "bar",
        marker = list(color = "#e74c3c"),
        text = ~paste0(round(pct_missing, 1), "%"),
        textposition = "outside",
        textfont = list(color = "white", size = 11),
        hovertemplate = paste(
          "<b>%{x}</b><br>",
          "Missing: %{y:.1f}%<extra></extra>"
        )
      ) |>
        theme_dark_plotly(title = "Missing Data by Column") |>
        plotly::layout(
          xaxis = list(title = "", tickangle = 45),
          yaxis = list(title = "% Missing", tickformat = ".1f")
        )
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

      # Calculate observed frequencies
      obs_freq <- goals_data |>
        dplyr::count(side, goals) |>
        dplyr::group_by(side) |>
        dplyr::mutate(density = n / sum(n)) |>
        dplyr::ungroup()

      # Calculate Poisson expected
      poisson_df <- tidyr::expand_grid(
        side = c("Home", "Away"),
        goals = 0:8
      ) |>
        dplyr::mutate(poisson_density = stats::dpois(goals, lambda = mean_goals))

      # Combine for plotting
      plot_data <- dplyr::left_join(obs_freq, poisson_df, by = c("side", "goals"))

      plotly::plot_ly() |>
        plotly::add_bars(
          data = dplyr::filter(plot_data, side == "Home"),
          x = ~goals, y = ~density,
          name = "Home (Observed)",
          marker = list(color = "#3498db"),
          hovertemplate = "Goals: %{x}<br>Density: %{y:.3f}<extra></extra>"
        ) |>
        plotly::add_bars(
          data = dplyr::filter(plot_data, side == "Away"),
          x = ~goals, y = ~density,
          name = "Away (Observed)",
          marker = list(color = "#9b59b6"),
          hovertemplate = "Goals: %{x}<br>Density: %{y:.3f}<extra></extra>"
        ) |>
        plotly::add_lines(
          data = dplyr::filter(plot_data, side == "Home") |> dplyr::distinct(goals, .keep_all = TRUE),
          x = ~goals, y = ~poisson_density,
          name = paste0("Poisson (lambda=", round(mean_goals, 2), ")"),
          line = list(color = "#e67e22", width = 3, dash = "dash"),
          hovertemplate = "Goals: %{x}<br>Poisson: %{y:.3f}<extra></extra>"
        ) |>
        theme_dark_plotly(title = "Goal Distribution: Observed vs Poisson") |>
        plotly::layout(
          barmode = "group",
          xaxis = list(title = "Goals scored", dtick = 1),
          yaxis = list(title = "Density"),
          legend = list(orientation = "h", y = -0.15)
        )
    }
  ),

  targets::tar_target(
    vig_result_proportions,
    {
      # Cleveland dot chart: simpler than stacked bars, easier to compare
      result_data <- parsed_matches |>
        dplyr::filter(!is.na(ftr)) |>
        dplyr::count(league_code, ftr) |>
        dplyr::group_by(league_code) |>
        dplyr::mutate(pct = 100 * n / sum(n)) |>
        dplyr::ungroup() |>
        dplyr::mutate(
          ftr_label = dplyr::case_when(
            ftr == "H" ~ "Home Win",
            ftr == "D" ~ "Draw",
            ftr == "A" ~ "Away Win"
          ),
          ftr_label = factor(ftr_label, levels = c("Home Win", "Draw", "Away Win"))
        )

      colors <- c("Home Win" = "#3498db", "Draw" = "#95a5a6", "Away Win" = "#e67e22")

      # Dot chart (scatter plot with markers)
      plotly::plot_ly(
        result_data,
        x = ~pct,
        y = ~league_code,
        color = ~ftr_label,
        colors = colors,
        type = "scatter",
        mode = "markers",
        marker = list(size = 12),
        hovertemplate = paste(
          "<b>%{y}</b><br>",
          "%{fullData.name}: %{x:.1f}%<extra></extra>"
        )
      ) |>
        theme_dark_plotly(title = "Result Proportions by League (Dot Chart)") |>
        plotly::layout(
          xaxis = list(title = "Percentage (%)", range = c(0, 60)),
          yaxis = list(title = "", categoryorder = "category ascending"),
          shapes = list(
            list(type = "line", x0 = 33.3, x1 = 33.3, y0 = -0.5, y1 = 9.5,
                 line = list(color = "rgba(255,255,255,0.5)", dash = "dash", width = 1))
          ),
          annotations = list(
            list(x = 33.3, y = 1, xref = "x", yref = "paper",
                 text = "33% baseline", showarrow = FALSE, yanchor = "bottom",
                 font = list(color = "rgba(255,255,255,0.7)", size = 10))
          )
        )
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

      plotly::plot_ly(
        ha_data,
        x = ~season,
        y = ~home_win_pct,
        color = ~league_code,
        type = "scatter",
        mode = "lines+markers",
        hovertemplate = paste(
          "Season: %{x}<br>",
          "Home Win: %{y:.1f}%<br>",
          "Matches: %{customdata}<extra></extra>"
        ),
        customdata = ~n_matches
      ) |>
        theme_dark_plotly(title = "Home Win Percentage by League Over Seasons") |>
        add_time_slider() |>
        plotly::layout(
          yaxis = list(title = "Home Win %"),
          shapes = list(
            list(type = "line", x0 = 0, x1 = 1, y0 = overall_mean, y1 = overall_mean,
                 xref = "paper",
                 line = list(color = "#e67e22", dash = "dash", width = 2))
          ),
          annotations = list(
            list(x = 1, y = overall_mean, xref = "paper", yref = "y",
                 text = paste0("Mean: ", round(overall_mean, 1), "%"),
                 showarrow = FALSE, xanchor = "left", font = list(color = "#e67e22"))
          )
        )
    }
  ),

  targets::tar_target(
    vig_scoreline_heatmap,
    {
      scorelines <- parsed_matches |>
        dplyr::filter(!is.na(fthg), !is.na(ftag)) |>
        dplyr::count(fthg, ftag, name = "n") |>
        dplyr::mutate(pct = 100 * n / sum(n)) |>
        dplyr::filter(fthg <= 5, ftag <= 5)

      plotly::plot_ly(
        scorelines,
        x = ~ftag,
        y = ~fthg,
        z = ~pct,
        type = "heatmap",
        colorscale = "Viridis",
        text = ~paste0(round(pct, 1), "%"),
        texttemplate = "%{text}",
        hovertemplate = paste(
          "Home: %{y}, Away: %{x}<br>",
          "Frequency: %{z:.1f}%<extra></extra>"
        )
      ) |>
        theme_dark_plotly(title = "Scoreline Frequency Heatmap (0-5 goals)") |>
        plotly::layout(
          xaxis = list(title = "Away Goals", dtick = 1),
          yaxis = list(title = "Home Goals", dtick = 1)
        )
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

      plotly::plot_ly(
        trend_data,
        x = ~season,
        y = ~mean_goals,
        color = ~league_code,
        type = "scatter",
        mode = "lines+markers",
        hovertemplate = paste(
          "Season: %{x}<br>",
          "Goals/match: %{y:.2f}<br>",
          "Matches: %{customdata}<extra></extra>"
        ),
        customdata = ~n_matches
      ) |>
        theme_dark_plotly(title = "Mean Goals Per Match by League Over Seasons") |>
        add_time_slider() |>
        plotly::layout(
          yaxis = list(title = "Mean Goals Per Match"),
          shapes = list(
            list(type = "line", x0 = 0, x1 = 1, y0 = overall_mean, y1 = overall_mean,
                 xref = "paper",
                 line = list(color = "#e67e22", dash = "dash", width = 2))
          ),
          annotations = list(
            list(x = 1, y = overall_mean, xref = "paper", yref = "y",
                 text = paste0("Mean: ", round(overall_mean, 2)),
                 showarrow = FALSE, xanchor = "left", font = list(color = "#e67e22"))
          )
        )
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

      colors <- c(Home = "#3498db", Draw = "#95a5a6", Away = "#e67e22")

      plotly::plot_ly(
        calibration_data,
        x = ~mean_implied,
        y = ~actual_freq,
        color = ~outcome,
        colors = colors,
        size = ~n,
        type = "scatter",
        mode = "markers",
        hovertemplate = paste(
          "%{fullData.name}<br>",
          "Implied: %{x:.1%}<br>",
          "Actual: %{y:.1%}<br>",
          "N: %{marker.size}<extra></extra>"
        )
      ) |>
        theme_dark_plotly(title = "Pinnacle Odds Calibration: Implied vs Actual") |>
        plotly::layout(
          xaxis = list(title = "Mean Implied Probability", tickformat = ".0%"),
          yaxis = list(title = "Actual Outcome Frequency", tickformat = ".0%"),
          shapes = list(
            list(type = "line", x0 = 0, x1 = 1, y0 = 0, y1 = 1,
                 line = list(color = "white", dash = "dash", width = 1))
          )
        )
    }
  ),

  targets::tar_target(
    vig_elo_spread_plot,
    {
      plotly::plot_ly(
        elo_ratings,
        x = ~elo,
        y = ~league_code,
        type = "box",
        marker = list(color = "#3498db"),
        fillcolor = "rgba(52, 152, 219, 0.5)",
        line = list(color = "white"),
        hovertemplate = paste(
          "League: %{y}<br>",
          "Elo: %{x:.0f}<extra></extra>"
        )
      ) |>
        theme_dark_plotly(title = "Elo Rating Distribution by League") |>
        plotly::layout(
          xaxis = list(title = "Elo Rating"),
          yaxis = list(title = ""),
          shapes = list(
            list(type = "line", x0 = 1500, x1 = 1500, y0 = -0.5, y1 = 9.5,
                 line = list(color = "#e67e22", dash = "dash", width = 2))
          ),
          annotations = list(
            list(x = 1500, y = 1, xref = "x", yref = "paper",
                 text = "Starting Elo (1500)",
                 showarrow = TRUE, arrowhead = 0, ax = 40, ay = 0,
                 font = list(color = "#e67e22"))
          )
        )
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

      plotly::plot_ly(
        overround_data,
        x = ~overround,
        y = ~league_code,
        type = "box",
        marker = list(color = "#3498db"),
        fillcolor = "rgba(52, 152, 219, 0.5)",
        line = list(color = "white"),
        hovertemplate = paste(
          "League: %{y}<br>",
          "Overround: %{x:.2f}%<extra></extra>"
        )
      ) |>
        theme_dark_plotly(title = "Pinnacle 1X2 Overround by League") |>
        plotly::layout(
          xaxis = list(title = "Overround (%)"),
          yaxis = list(title = ""),
          shapes = list(
            list(type = "line", x0 = 0, x1 = 0, y0 = -0.5, y1 = 9.5,
                 line = list(color = "#e67e22", dash = "dash", width = 2))
          )
        )
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

      pinnacle_ref <- pinnacle_eval |>
        dplyr::rename(metric_name = metric, pinnacle_value = value)

      colors <- c("GLM Poisson" = "#3498db", "Dixon-Coles" = "#9b59b6")

      plotly::plot_ly(
        combined,
        x = ~fold,
        y = ~value,
        color = ~model,
        colors = colors,
        type = "scatter",
        mode = "lines+markers",
        hovertemplate = paste(
          "Fold: %{x}<br>",
          "Score: %{y:.4f}<extra></extra>"
        )
      ) |>
        theme_dark_plotly(title = "Walk-Forward CV Metrics: GLM vs Dixon-Coles") |>
        plotly::layout(
          xaxis = list(title = "Fold", dtick = 1),
          yaxis = list(title = "Score (lower is better)"),
          updatemenus = list(
            list(
              type = "dropdown",
              active = 0,
              buttons = list(
                list(method = "restyle",
                     args = list("visible", c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE)),
                     label = "All"),
                list(method = "restyle",
                     args = list("transforms[0].value", "log_loss"),
                     label = "Log Loss"),
                list(method = "restyle",
                     args = list("transforms[0].value", "brier"),
                     label = "Brier"),
                list(method = "restyle",
                     args = list("transforms[0].value", "rps"),
                     label = "RPS")
              )
            )
          )
        )
    }
  ),

  targets::tar_target(
    vig_model_comparison_table,
    model_vs_pinnacle
  ),

  targets::tar_target(
    vig_pnl_curve,
    {
      pnl_data <- pnl_glm |>
        dplyr::mutate(bet_num = dplyr::row_number())

      plotly::plot_ly(
        pnl_data,
        x = ~bet_num,
        y = ~bankroll,
        type = "scatter",
        mode = "lines",
        line = list(color = "#3498db", width = 2),
        hovertemplate = paste(
          "Bet #: %{x}<br>",
          "Bankroll: %{y:.0f}<extra></extra>"
        )
      ) |>
        theme_dark_plotly(title = "Simulated Bankroll Evolution (GLM Value Bets, Quarter Kelly)") |>
        add_time_slider() |>
        plotly::layout(
          xaxis = list(title = "Bet Number"),
          yaxis = list(title = "Bankroll"),
          shapes = list(
            list(type = "line", x0 = 0, x1 = 1, y0 = 1000, y1 = 1000,
                 xref = "paper",
                 line = list(color = "#e67e22", dash = "dash", width = 2))
          ),
          annotations = list(
            list(x = 0.02, y = 1000, xref = "paper", yref = "y",
                 text = "Starting: 1000",
                 showarrow = FALSE, yanchor = "bottom", font = list(color = "#e67e22"))
          )
        )
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

      plotly::plot_ly(
        dd_data,
        x = ~bet_num,
        y = ~drawdown_pct,
        type = "scatter",
        mode = "lines",
        fill = "tozeroy",
        fillcolor = "rgba(231, 76, 60, 0.4)",
        line = list(color = "#e74c3c", width = 2),
        hovertemplate = paste(
          "Bet #: %{x}<br>",
          "Drawdown: %{y:.1f}%<extra></extra>"
        )
      ) |>
        theme_dark_plotly(title = "Drawdown Over Time (GLM Value Bets)") |>
        plotly::layout(
          xaxis = list(title = "Bet Number"),
          yaxis = list(title = "Drawdown (%)"),
          shapes = list(
            list(type = "line", x0 = 0, x1 = 1, y0 = -20, y1 = -20,
                 xref = "paper",
                 line = list(color = "#e67e22", dash = "dash", width = 2))
          ),
          annotations = list(
            list(x = 0.02, y = -20, xref = "paper", yref = "y",
                 text = "-20% Guardrail",
                 showarrow = FALSE, yanchor = "top", font = list(color = "#e67e22"))
          )
        )
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
      colors <- c(H = "#3498db", D = "#95a5a6", A = "#e67e22")

      plotly::plot_ly(
        value_bets_glm,
        x = ~edge,
        color = ~outcome,
        colors = colors,
        type = "histogram",
        opacity = 0.7,
        nbinsx = 30,
        hovertemplate = paste(
          "Edge: %{x:.1%}<br>",
          "Count: %{y}<extra></extra>"
        )
      ) |>
        theme_dark_plotly(title = "Distribution of Edge Values for Identified Value Bets") |>
        plotly::layout(
          barmode = "overlay",
          xaxis = list(title = "Edge (model prob - market prob)", tickformat = ".0%"),
          yaxis = list(title = "Count"),
          shapes = list(
            list(type = "line", x0 = 0.03, x1 = 0.03, y0 = 0, y1 = 1,
                 yref = "paper",
                 line = list(color = "#e74c3c", dash = "dash", width = 2))
          ),
          annotations = list(
            list(x = 0.03, y = 1, xref = "x", yref = "paper",
                 text = "3% min edge",
                 showarrow = TRUE, arrowhead = 0, ax = 40, ay = 20,
                 font = list(color = "#e74c3c"))
          )
        )
    }
  ),

  targets::tar_target(
    vig_kelly_stake_distribution,
    {
      plotly::plot_ly(
        value_bets_glm,
        x = ~kelly_stake,
        type = "histogram",
        marker = list(color = "#3498db"),
        nbinsx = 30,
        hovertemplate = paste(
          "Stake: %{x:.1%}<br>",
          "Count: %{y}<extra></extra>"
        )
      ) |>
        theme_dark_plotly(title = "Distribution of Quarter-Kelly Stake Sizes") |>
        plotly::layout(
          xaxis = list(title = "Stake (fraction of bankroll)", tickformat = ".1%"),
          yaxis = list(title = "Count"),
          shapes = list(
            list(type = "line", x0 = 0.03, x1 = 0.03, y0 = 0, y1 = 1,
                 yref = "paper",
                 line = list(color = "#e67e22", dash = "dash", width = 2))
          ),
          annotations = list(
            list(x = 0.03, y = 1, xref = "x", yref = "paper",
                 text = "3% max stake",
                 showarrow = TRUE, arrowhead = 0, ax = 40, ay = 20,
                 font = list(color = "#e67e22"))
          )
        )
    }
  ),

  targets::tar_target(
    vig_pnl_summary_table,
    pnl_summary
  ),

# ============================================================================
# Statistical Tests (Evidence Enhancement)
# Note: These are optional diagnostic targets. If they fail, the vignette
# still works - it just won't have these statistical test summaries.
# ============================================================================

  targets::tar_target(
    vig_poisson_test,
    {
      # Simple Poisson fit summary without chi-square test
      goals <- c(parsed_matches[["fthg"]], parsed_matches[["ftag"]])
      goals <- goals[!is.na(goals)]
      lambda <- mean(goals)
      variance <- stats::var(goals)

      tibble::tibble(
        test = "Poisson Fit Summary",
        mean_goals = round(lambda, 3),
        variance = round(variance, 3),
        dispersion_ratio = round(variance / lambda, 3),
        n_goals = length(goals),
        conclusion = if (variance / lambda > 1.1) {
          "Overdispersion present (variance > mean)"
        } else {
          "Poisson assumption reasonable"
        }
      )
    }
  ),

  targets::tar_target(
    vig_home_trend_test,
    {
      ha_data <- parsed_matches |>
        dplyr::filter(!is.na(ftr)) |>
        dplyr::group_by(season) |>
        dplyr::summarise(home_win_pct = mean(ftr == "H"), .groups = "drop") |>
        dplyr::mutate(season_num = dplyr::row_number())

      if (nrow(ha_data) < 3) {
        return(tibble::tibble(
          trend_per_season = NA_real_,
          r_squared = NA_real_,
          n_seasons = nrow(ha_data),
          conclusion = "Insufficient data for trend analysis"
        ))
      }

      model <- stats::lm(home_win_pct ~ season_num, data = ha_data)
      slope <- stats::coef(model)[2]
      r_sq <- summary(model)[["r.squared"]]

      tibble::tibble(
        trend_per_season = round(slope * 100, 3),
        r_squared = round(r_sq, 4),
        n_seasons = nrow(ha_data),
        conclusion = dplyr::case_when(
          slope < -0.005 ~ "Declining home advantage trend",
          slope > 0.005 ~ "Increasing home advantage trend",
          TRUE ~ "No clear trend"
        )
      )
    }
  ),

  targets::tar_target(
    vig_model_comparison_test,
    {
      # Simple comparison of mean log-loss (no t-test to avoid edge cases)
      glm_ll <- glm_baseline_cv[["log_loss"]]
      dc_ll <- dc_cv[["log_loss"]]

      if (length(glm_ll) == 0 || length(dc_ll) == 0) {
        return(tibble::tibble(
          mean_glm_logloss = NA_real_,
          mean_dc_logloss = NA_real_,
          mean_diff = NA_real_,
          n_folds = 0L,
          conclusion = "No CV data available"
        ))
      }

      n_folds <- min(length(glm_ll), length(dc_ll))
      glm_ll <- glm_ll[seq_len(n_folds)]
      dc_ll <- dc_ll[seq_len(n_folds)]

      tibble::tibble(
        mean_glm_logloss = round(mean(glm_ll), 4),
        mean_dc_logloss = round(mean(dc_ll), 4),
        mean_diff = round(mean(glm_ll - dc_ll), 4),
        n_folds = as.integer(n_folds),
        conclusion = dplyr::case_when(
          mean(glm_ll) > mean(dc_ll) + 0.01 ~ "Dixon-Coles outperforms GLM",
          mean(dc_ll) > mean(glm_ll) + 0.01 ~ "GLM outperforms Dixon-Coles",
          TRUE ~ "Models perform similarly"
        )
      )
    }
  ),

# ============================================================================
# NOTE: tar_visnetwork() cannot run inside a target - it's an introspection
# function that must be called directly in the vignette. Do NOT add
# vig_targets_dag target here.
# ============================================================================
  NULL
)
