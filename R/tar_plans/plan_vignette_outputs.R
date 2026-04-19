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
    wrap_mermaid_html(
      generate_data_pipeline_mermaid(here::here()),
      caption = "Data pipeline: CSV download \u2192 parsing \u2192 validation \u2192 modelling \u2192 evaluation. Nodes link to package functions."
    )
  ),

  # Walk-forward CV diagram for vignettes
  targets::tar_target(
    vig_cv_html,
    wrap_mermaid_html(
      generate_cv_walkforward_mermaid(here::here()),
      caption = "Walk-forward cross-validation: 24-month rolling training window, 1-month test. Each fold fits GLM and Dixon-Coles per league."
    )
  ),

  # Kelly decision tree for vignettes
  targets::tar_target(
    vig_kelly_html,
    wrap_mermaid_html(
      generate_kelly_decision_mermaid(here::here()),
      caption = "Kelly staking decision tree: edge \u2265 3% and odds 1.50\u201310.00 triggers quarter-Kelly stake with 3% max and 20% drawdown halt."
    )
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
      wide <- parsed_matches |>
        dplyr::count(league_code, season, name = "n_matches") |>
        tidyr::pivot_wider(
          names_from = season, values_from = n_matches, values_fill = 0L
        )
      # Order rows by average matches (highest first)
      season_cols <- setdiff(names(wide), "league_code")
      wide$avg <- rowMeans(wide[, season_cols], na.rm = TRUE)
      wide <- wide |> dplyr::arrange(dplyr::desc(avg)) |> dplyr::select(-avg)
      # Reverse column order (most recent season first)
      wide |> dplyr::select(league_code, dplyr::all_of(rev(sort(season_cols))))
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
        dplyr::arrange(dplyr::desc(n_matches))
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
          pct_1x2         = round(100 * mean(!is.na(psh) & !is.na(psd) & !is.na(psa)), 1),
          pct_over_under  = round(100 * mean(!is.na(p_over25) | !is.na(p_under25)), 1),
          .groups = "drop"
        ) |>
        dplyr::arrange(dplyr::desc(season), league_code)
    }
  ),

  targets::tar_target(
    vig_matches_per_season_plot,
    {
      plot_data <- parsed_matches |>
        dplyr::count(league_code, season, name = "n_matches") |>
        add_league_metadata()

      # Add small random jitter to avoid overlapping text labels
      set.seed(42)
      plot_data <- plot_data |>
        dplyr::mutate(
          tier_color = dplyr::if_else(tier == "Top 5",
                                       TIER_COLORS[["Top 5"]],
                                       TIER_COLORS[["2nd Tier"]])
        )

      # Text-label dotplot: league codes as labels in tier colors
      p <- plotly::plot_ly()
      for (t in c("Top 5", "2nd Tier")) {
        td <- plot_data |> dplyr::filter(tier == t)
        p <- p |> plotly::add_trace(
          data = td,
          x = ~n_matches,
          y = ~season,
          text = ~league_code,
          name = t,
          type = "scatter",
          mode = "text",
          textfont = list(color = TIER_COLORS[[t]], size = 13),
          hovertemplate = paste(
            "<b>%{text}</b><br>",
            "Season: %{y}<br>",
            "Matches: %{x:.0f}<extra></extra>"
          ),
          showlegend = FALSE
        )
      }

      p |>
        theme_dark_plotly(title = "Match Count by League and Season") |>

        plotly::layout(
          showlegend = FALSE,
          yaxis = list(
            title = "Season",
            autorange = "reversed",  # Recent at top
            categoryorder = "category descending"
          ),
          xaxis = list(title = "Matches"),
          annotations = list(list(
            x = 0.5, y = 1.05, xref = "paper", yref = "paper",
            text = "Blue = Top 5 | Orange = 2nd Tier | Current season incomplete",
            showarrow = FALSE, font = list(size = 10, color = "white")
          ))
        )
    }
  ),

# ============================================================================
# Vignette 2: Data Cleaning
# ============================================================================

  targets::tar_target(
    vig_completeness_plot,
    {
      comp_data <- qc_match_completeness |>
        add_league_metadata()

      n_perfect <- comp_data |>
        dplyr::filter(pct_complete >= 100) |>
        nrow()

      imperfect <- comp_data |>
        dplyr::filter(pct_complete < 100) |>
        dplyr::select(league_code, season, tier, pct_complete) |>
        dplyr::arrange(pct_complete)

      # Build summary row for perfect completeness
      summary_row <- tibble::tibble(
        league_code = paste0("(", n_perfect, " league-seasons at 100%)"),
        season = "",
        tier = "",
        pct_complete = 100
      )

      # Return plain data.frame — DT wrapping happens in vignette QMD
      # (DT::datatable objects contain hardcoded nix store paths that
      # break when loaded from RDS on a different machine)
      dplyr::bind_rows(imperfect, summary_row)
    }
  ),

  targets::tar_target(
    vig_pinnacle_coverage_plot,
    {
      plot_data <- qc_pinnacle_coverage |>
        add_league_metadata()

      # Create horizontal white guide shapes for each season
      seasons <- unique(plot_data$season)
      guide_shapes <- lapply(seq_along(seasons), function(i) {
        list(
          type = "line", x0 = 0, x1 = 100, xref = "x",
          y0 = i - 0.5, y1 = i - 0.5, yref = "y",
          line = list(color = "rgba(255,255,255,0.2)", width = 1)
        )
      })

      # Text-label dotplot: league codes as labels in tier colors
      p <- plotly::plot_ly()
      for (t in c("Top 5", "2nd Tier")) {
        td <- plot_data |> dplyr::filter(tier == t)
        p <- p |> plotly::add_trace(
          data = td,
          x = ~pct_pinnacle,
          y = ~season,
          text = ~league_code,
          name = t,
          type = "scatter",
          mode = "text",
          textfont = list(color = TIER_COLORS[[t]], size = 13),
          hovertemplate = paste(
            "<b>%{text}</b><br>",
            "Season: %{y}<br>",
            "Pinnacle: %{x:.1f}%<extra></extra>"
          ),
          showlegend = FALSE
        )
      }

      p |>
        theme_dark_plotly(title = "Pinnacle 1X2 Odds Coverage by League and Season") |>
        plotly::layout(
          showlegend = FALSE,
          xaxis = list(title = "% Coverage", range = c(-5, 105)),
          yaxis = list(
            title = "Season",
            autorange = "reversed",
            categoryorder = "category descending"
          ),
          shapes = guide_shapes,
          annotations = list(list(
            x = 0.5, y = 1.05, xref = "paper", yref = "paper",
            text = "Blue = Top 5 | Orange = 2nd Tier | 0% = no Pinnacle data",
            showarrow = FALSE, font = list(size = 10, color = "white")
          ))
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

      # Variable descriptions for user context
      descriptions <- tibble::tribble(
        ~column,      ~description,
        "match_date", "Match date",
        "home_team",  "Home team name",
        "away_team",  "Away team name",
        "fthg",       "Full-time home goals",
        "ftag",       "Full-time away goals",
        "ftr",        "Full-time result (H/D/A)",
        "hthg",       "Half-time home goals",
        "htag",       "Half-time away goals",
        "htr",        "Half-time result",
        "hs",         "Home shots",
        "as_",        "Away shots",
        "hst",        "Home shots on target",
        "ast",        "Away shots on target",
        "hf",         "Home fouls",
        "af",         "Away fouls",
        "hc",         "Home corners",
        "ac",         "Away corners",
        "hy",         "Home yellow cards",
        "ay",         "Away yellow cards",
        "hr",         "Home red cards",
        "ar",         "Away red cards"
      )

      tibble::tibble(
        column = available,
        n_missing = vapply(available, function(col) {
          sum(is.na(parsed_matches[[col]]))
        }, integer(1)),
        pct_missing = round(100 * n_missing / nrow(parsed_matches), 1),
        n_total = nrow(parsed_matches)
      ) |>
        dplyr::left_join(descriptions, by = "column") |>
        dplyr::select(column, description, n_missing, pct_missing, n_total) |>
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

      # Variable descriptions for context
      descriptions <- tibble::tribble(
        ~column,      ~description,
        "match_date", "Match date",
        "home_team",  "Home team name",
        "away_team",  "Away team name",
        "fthg",       "Full-time home goals",
        "ftag",       "Full-time away goals",
        "ftr",        "Full-time result",
        "hthg",       "Half-time home goals",
        "htag",       "Half-time away goals",
        "htr",        "Half-time result",
        "hs",         "Home shots",
        "as_",        "Away shots",
        "hst",        "Home shots on target",
        "ast",        "Away shots on target",
        "hf",         "Home fouls",
        "af",         "Away fouls",
        "hc",         "Home corners",
        "ac",         "Away corners",
        "hy",         "Home yellow cards",
        "ay",         "Away yellow cards",
        "hr",         "Home red cards",
        "ar",         "Away red cards"
      )

      missing_pct <- tibble::tibble(
        column = available,
        pct_missing = vapply(available, function(col) {
          100 * mean(is.na(parsed_matches[[col]]))
        }, numeric(1))
      ) |>
        dplyr::left_join(descriptions, by = "column") |>
        dplyr::filter(pct_missing > 0) |>
        dplyr::arrange(dplyr::desc(pct_missing)) |>
        dplyr::mutate(column = factor(column, levels = rev(column)))

      if (nrow(missing_pct) == 0) {
        missing_pct <- tibble::tibble(
          column = "None", pct_missing = 0, description = "No missing data"
        )
      }

      # Classify columns: match stats are expected missing in older seasons
      stats_cols <- c("hs", "as_", "hst", "ast", "hf", "af",
                       "hc", "ac", "hy", "ay", "hr", "ar",
                       "hthg", "htag", "htr")
      missing_pct <- missing_pct |>
        dplyr::mutate(
          expected = dplyr::if_else(column %in% stats_cols, "expected", "unexpected"),
          bar_color = dplyr::if_else(expected == "expected", "#e67e22", "#e74c3c")
        )

      # Horizontal dotchart with percentage labels, colored by expected/unexpected
      plotly::plot_ly(
        missing_pct,
        x = ~pct_missing,
        y = ~column,
        text = ~paste0(round(pct_missing, 1), "%"),
        textposition = "right",
        type = "scatter",
        mode = "markers+text",
        marker = list(color = ~bar_color, size = 12),
        textfont = list(color = "white", size = 10),
        hovertemplate = paste(
          "<b>%{y}</b><br>",
          "%{customdata}<br>",
          "Missing: %{x:.1f}%<extra></extra>"
        ),
        customdata = ~description
      ) |>
        theme_dark_plotly(title = "Missing Data by Column (ordered by % missing)") |>
        plotly::layout(
          xaxis = list(title = "% Missing", range = c(0, max(missing_pct$pct_missing) * 1.2)),
          yaxis = list(title = ""),
          annotations = list(
            list(
              x = 0.5, y = 1.05, xref = "paper", yref = "paper",
              text = "Orange = expected missing (match stats not recorded in older seasons) | Red = unexpected",
              showarrow = FALSE, font = list(size = 10, color = "white")
            ),
            list(
              x = 0.5, y = -0.1, xref = "paper", yref = "paper",
              text = "Shots, corners, cards, half-time stats: only available from ~2000s onward",
              showarrow = FALSE, font = list(size = 10, color = "#95a5a6")
            )
          )
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
          hovertemplate = "Goals: %{x:.0f}<br>Density: %{y:.3f}<extra></extra>"
        ) |>
        plotly::add_bars(
          data = dplyr::filter(plot_data, side == "Away"),
          x = ~goals, y = ~density,
          name = "Away (Observed)",
          marker = list(color = "#9b59b6"),
          hovertemplate = "Goals: %{x:.0f}<br>Density: %{y:.3f}<extra></extra>"
        ) |>
        plotly::add_lines(
          data = dplyr::filter(plot_data, side == "Home") |> dplyr::distinct(goals, .keep_all = TRUE),
          x = ~goals, y = ~poisson_density,
          name = paste0("Poisson (lambda=", round(mean_goals, 2), ")"),
          line = list(color = "#e67e22", width = 3, dash = "dash"),
          hovertemplate = "Goals: %{x:.0f}<br>Poisson: %{y:.3f}<extra></extra>"
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
      result_data <- parsed_matches |>
        dplyr::filter(!is.na(ftr)) |>
        dplyr::count(league_code, ftr) |>
        dplyr::group_by(league_code) |>
        dplyr::mutate(pct = 100 * n / sum(n)) |>
        dplyr::ungroup() |>
        dplyr::mutate(
          ftr_label = dplyr::case_when(
            ftr == "H" ~ "Home Win",
            ftr == "D" ~ "Draw (tied score)",  # Clarified terminology
            ftr == "A" ~ "Away Win"
          ),
          ftr_label = factor(ftr_label, levels = c("Home Win", "Draw (tied score)", "Away Win"))
        )

      # Order leagues by home win % (highest at top)
      home_order <- result_data |>
        dplyr::filter(ftr == "H") |>
        dplyr::arrange(dplyr::desc(pct)) |>
        dplyr::pull(league_code)

      result_data <- result_data |>
        dplyr::mutate(league_code = factor(league_code, levels = rev(home_order)))

      colors <- c("Home Win" = "#3498db", "Draw (tied score)" = "#95a5a6", "Away Win" = "#e67e22")

      # Text-label dotchart: league codes as labels in result colors
      # Add small jitter to y to avoid overlap
      set.seed(42)
      result_data <- result_data |>
        dplyr::mutate(y_jitter = as.numeric(league_code) + stats::runif(dplyr::n(), -0.15, 0.15))

      p <- plotly::plot_ly()
      for (lbl in c("Home Win", "Draw (tied score)", "Away Win")) {
        td <- result_data |> dplyr::filter(ftr_label == lbl)
        p <- p |> plotly::add_trace(
          data = td,
          x = ~pct,
          y = ~league_code,
          text = ~as.character(league_code),
          name = lbl,
          type = "scatter",
          mode = "text",
          textfont = list(color = colors[[lbl]], size = 14),
          hovertemplate = paste(
            "<b>%{y}</b><br>",
            lbl, ": %{x:.1f}%<extra></extra>"
          ),
          showlegend = FALSE
        )
      }

      p |>
        theme_dark_plotly(title = "Result Proportions by League (ordered by home win %)") |>
        plotly::layout(
          showlegend = FALSE,
          xaxis = list(title = "Percentage (%)", range = c(0, 60)),
          yaxis = list(title = ""),
          shapes = list(
            list(type = "line", x0 = 33.3, x1 = 33.3, y0 = -0.5, y1 = 9.5,
                 line = list(color = "rgba(255,255,255,0.5)", dash = "dash", width = 1))
          ),
          annotations = list(
            list(x = 33.3, y = 1, xref = "x", yref = "paper",
                 text = "33% baseline", showarrow = FALSE, yanchor = "bottom",
                 font = list(color = "rgba(255,255,255,0.7)", size = 10)),
            list(x = 0.5, y = 1.05, xref = "paper", yref = "paper",
                 text = "Blue = Home | Grey = Draw | Orange = Away",
                 showarrow = FALSE, font = list(size = 10, color = "white"))
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
        ) |>
        add_league_metadata()

      overall_mean <- mean(ha_data$home_win_pct)

      # Order countries by average home win % (highest first)
      country_order <- ha_data |>
        dplyr::group_by(country) |>
        dplyr::summarise(mean_hw = mean(home_win_pct), .groups = "drop") |>
        dplyr::arrange(dplyr::desc(mean_hw)) |>
        dplyr::pull(country)

      # 5x1 subplot: one panel per country, each showing both leagues
      panels <- lapply(seq_along(country_order), function(i) {
        cty <- country_order[i]
        cty_data <- ha_data |> dplyr::filter(country == cty)
        cty_color <- COUNTRY_COLORS[[cty]]

        # Build panel with raw data lines per league
        p <- plotly::plot_ly()
        for (lc in unique(cty_data$league_code)) {
          lc_data <- cty_data |> dplyr::filter(league_code == lc)
          p <- p |> plotly::add_trace(
            data = lc_data,
            x = ~season, y = ~home_win_pct,
            name = lc, legendgroup = lc,
            type = "scatter", mode = "lines+markers",
            line = list(color = cty_color, width = 1),
            marker = list(color = cty_color, size = 5),
            hovertemplate = paste0(
              lc, "<br>Season: %{x}<br>Home Win: %{y:.1f}%<extra></extra>"
            ),
            showlegend = (i == 1)
          )

          # Add loess trend line
          if (nrow(lc_data) >= 4) {
            season_nums <- seq_len(nrow(lc_data))
            loess_fit <- stats::loess(home_win_pct ~ season_nums,
                                       data = lc_data, span = 0.75)
            lc_data$loess_y <- stats::predict(loess_fit)
            p <- p |> plotly::add_lines(
              data = lc_data,
              x = ~season, y = ~loess_y,
              name = paste0(lc, " trend"), legendgroup = paste0(lc, "_trend"),
              line = list(color = cty_color, width = 3, dash = "dash"),
              hovertemplate = paste0(
                lc, " trend<br>Season: %{x}<br>Trend: %{y:.1f}%<extra></extra>"
              ),
              showlegend = FALSE
            )
          }
        }

        # Add mean annotation for each league in this country
        means <- cty_data |>
          dplyr::group_by(league_code) |>
          dplyr::summarise(mean_hw = round(mean(home_win_pct), 1), .groups = "drop")

        mean_annotations <- lapply(seq_len(nrow(means)), function(j) {
          list(x = 1, y = means$mean_hw[j], xref = "paper", yref = "y",
               text = paste0(means$league_code[j], " ", means$mean_hw[j], "%"),
               showarrow = FALSE, xanchor = "left",
               font = list(color = cty_color, size = 13))
        })

        p |> plotly::layout(
          annotations = c(
            list(list(
              x = 0.5, y = 1.15, xref = "paper", yref = "paper",
              text = cty, showarrow = FALSE,
              font = list(color = cty_color, size = 16, family = "bold")
            )),
            mean_annotations
          )
        )
      })

      plotly::subplot(panels, nrows = 5, shareX = TRUE, shareY = TRUE, titleY = TRUE) |>
        theme_dark_plotly(title = "Home Win % by Country (ordered by avg home win %)") |>
        plotly::layout(
          yaxis  = list(title = "Home Win %"),
          yaxis2 = list(title = "Home Win %"),
          yaxis3 = list(title = "Home Win %"),
          yaxis4 = list(title = "Home Win %"),
          yaxis5 = list(title = "Home Win %"),
          shapes = lapply(seq_len(5), function(i) {
            yref <- if (i == 1) "y" else paste0("y", i)
            list(type = "line", x0 = 0, x1 = 1,
                 y0 = overall_mean, y1 = overall_mean,
                 xref = "paper", yref = yref,
                 line = list(color = "#e67e22", dash = "dot", width = 1))
          }),
          annotations = list(
            list(x = 0.02, y = overall_mean, xref = "paper", yref = "y",
                 text = paste0("Mean: ", round(overall_mean, 1), "%"),
                 showarrow = FALSE, xanchor = "left",
                 font = list(color = "#e67e22", size = 10))
          ),
          height = 900
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
          "Home: %{y:.0f}, Away: %{x:.0f}<br>",
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
        ) |>
        add_league_metadata()

      overall_mean <- mean(trend_data$mean_goals)

      # Order countries by average goals (highest first)
      country_order <- trend_data |>
        dplyr::group_by(country) |>
        dplyr::summarise(mean_g = mean(mean_goals), .groups = "drop") |>
        dplyr::arrange(dplyr::desc(mean_g)) |>
        dplyr::pull(country)

      # 5x1 subplot: one panel per country, each showing both leagues
      panels <- lapply(seq_along(country_order), function(i) {
        cty <- country_order[i]
        cty_data <- trend_data |> dplyr::filter(country == cty)
        cty_color <- COUNTRY_COLORS[[cty]]

        p <- plotly::plot_ly()
        for (lc in unique(cty_data$league_code)) {
          lc_data <- cty_data |> dplyr::filter(league_code == lc)
          p <- p |> plotly::add_trace(
            data = lc_data,
            x = ~season, y = ~mean_goals,
            name = lc, legendgroup = lc,
            type = "scatter", mode = "lines+markers",
            line = list(color = cty_color, width = 1),
            marker = list(color = cty_color, size = 5),
            hovertemplate = paste0(
              lc, "<br>Season: %{x}<br>Goals/match: %{y:.2f}<extra></extra>"
            ),
            showlegend = (i == 1)
          )

          # Add loess trend line
          if (nrow(lc_data) >= 4) {
            season_nums <- seq_len(nrow(lc_data))
            loess_fit <- stats::loess(mean_goals ~ season_nums,
                                       data = lc_data, span = 0.75)
            lc_data$loess_y <- stats::predict(loess_fit)
            p <- p |> plotly::add_lines(
              data = lc_data,
              x = ~season, y = ~loess_y,
              name = paste0(lc, " trend"), legendgroup = paste0(lc, "_trend"),
              line = list(color = cty_color, width = 3, dash = "dash"),
              hovertemplate = paste0(
                lc, " trend<br>Season: %{x}<br>Trend: %{y:.2f}<extra></extra>"
              ),
              showlegend = FALSE
            )
          }
        }

        # Mean annotation per league
        means <- cty_data |>
          dplyr::group_by(league_code) |>
          dplyr::summarise(mean_g = round(mean(mean_goals), 2), .groups = "drop")

        mean_annotations <- lapply(seq_len(nrow(means)), function(j) {
          list(x = 1, y = means$mean_g[j], xref = "paper", yref = "y",
               text = paste0(means$league_code[j], " ", means$mean_g[j]),
               showarrow = FALSE, xanchor = "left",
               font = list(color = cty_color, size = 13))
        })

        p |> plotly::layout(
          annotations = c(
            list(list(
              x = 0.5, y = 1.15, xref = "paper", yref = "paper",
              text = cty, showarrow = FALSE,
              font = list(color = cty_color, size = 16, family = "bold")
            )),
            mean_annotations
          )
        )
      })

      plotly::subplot(panels, nrows = 5, shareX = TRUE, shareY = TRUE, titleY = TRUE) |>
        theme_dark_plotly(title = "Mean Goals Per Match by Country (ordered by avg goals)") |>
        plotly::layout(
          yaxis  = list(title = "Goals/Match"),
          yaxis2 = list(title = "Goals/Match"),
          yaxis3 = list(title = "Goals/Match"),
          yaxis4 = list(title = "Goals/Match"),
          yaxis5 = list(title = "Goals/Match"),
          shapes = lapply(seq_len(5), function(i) {
            yref <- if (i == 1) "y" else paste0("y", i)
            list(type = "line", x0 = 0, x1 = 1,
                 y0 = overall_mean, y1 = overall_mean,
                 xref = "paper", yref = yref,
                 line = list(color = "#e67e22", dash = "dot", width = 1))
          }),
          annotations = list(
            list(x = 0.02, y = overall_mean, xref = "paper", yref = "y",
                 text = paste0("Mean: ", round(overall_mean, 2)),
                 showarrow = FALSE, xanchor = "left",
                 font = list(color = "#e67e22", size = 10))
          ),
          height = 900
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

      # Find extreme points (max and min n) for annotations
      extremes <- calibration_data |>
        dplyr::group_by(outcome) |>
        dplyr::slice_max(n, n = 1) |>
        dplyr::bind_rows(
          calibration_data |>
            dplyr::group_by(outcome) |>
            dplyr::slice_min(n, n = 1)
        ) |>
        dplyr::distinct()

      # Create annotations for extreme points (larger font, offset from diagonal)
      extreme_annotations <- lapply(seq_len(nrow(extremes)), function(i) {
        # Offset away from x=y diagonal: above-left if below diagonal, below-right if above
        above_diag <- extremes$actual_freq[i] > extremes$mean_implied[i]
        list(
          x = extremes$mean_implied[i],
          y = extremes$actual_freq[i],
          text = paste0("n=", extremes$n[i]),
          showarrow = TRUE,
          arrowhead = 0,
          arrowcolor = "white",
          ax = if (above_diag) -45 else 45,
          ay = if (above_diag) -35 else 35,
          font = list(color = "white", size = 12)
        )
      })

      colors <- c(Home = "#3498db", Draw = "#95a5a6", Away = "#e67e22")

      plotly::plot_ly(
        calibration_data,
        x = ~mean_implied,
        y = ~actual_freq,
        color = ~outcome,
        colors = colors,
        size = ~n,
        customdata = ~as.integer(n),
        type = "scatter",
        mode = "markers",
        hovertemplate = paste(
          "%{fullData.name}<br>",
          "Implied: %{x:.1%}<br>",
          "Actual: %{y:.1%}<br>",
          "N: %{customdata}<extra></extra>"
        )
      ) |>
        theme_dark_plotly(title = "Pinnacle Calibration: Implied vs Actual (size = sample count)") |>
        plotly::layout(
          showlegend = FALSE,
          xaxis = list(title = "Mean Implied Probability", tickformat = ".0%"),
          yaxis = list(title = "Actual Outcome Frequency", tickformat = ".0%"),
          shapes = list(
            list(type = "line", x0 = 0, x1 = 1, y0 = 0, y1 = 1,
                 line = list(color = "white", dash = "dash", width = 1))
          ),
          annotations = c(
            extreme_annotations,
            list(list(
              x = 0.5, y = 1.05, xref = "paper", yref = "paper",
              text = "Blue = Home | Grey = Draw | Orange = Away | Diagonal = perfect calibration",
              showarrow = FALSE, font = list(size = 10, color = "white")
            ))
          )
        )
    }
  ),

  targets::tar_target(
    vig_elo_spread_plot,
    {
      elo_data <- elo_ratings |> add_league_metadata()

      # Compute IQR per league for ordering
      elo_iqr <- elo_data |>
        dplyr::group_by(league_code, tier) |>
        dplyr::summarise(
          iqr = stats::IQR(elo, na.rm = TRUE),
          .groups = "drop"
        )

      # Mean IQR per tier for annotation
      tier_iqr <- elo_iqr |>
        dplyr::group_by(tier) |>
        dplyr::summarise(mean_iqr = round(mean(iqr), 0), .groups = "drop")

      # Build top-5 panel: order leagues by IQR (widest first)
      top5_order <- elo_iqr |>
        dplyr::filter(tier == "Top 5") |>
        dplyr::arrange(dplyr::desc(iqr)) |>
        dplyr::pull(league_code)
      top5_data <- elo_data |>
        dplyr::filter(tier == "Top 5") |>
        dplyr::mutate(league_code = factor(league_code, levels = rev(top5_order)))

      top5_mean_iqr <- tier_iqr |>
        dplyr::filter(tier == "Top 5") |>
        dplyr::pull(mean_iqr)

      p1 <- plotly::plot_ly(
        top5_data,
        x = ~elo, y = ~league_code,
        type = "box",
        marker = list(color = TIER_COLORS[["Top 5"]]),
        fillcolor = "rgba(52, 152, 219, 0.5)",
        line = list(color = "white"),
        hovertemplate = "League: %{y}<br>Elo: %{x:.0f}<extra></extra>"
      ) |>
        plotly::layout(
          annotations = list(list(
            x = 0.5, y = 1.12, xref = "paper", yref = "paper",
            text = paste0("Top 5 (mean IQR: ", top5_mean_iqr, ")"),
            showarrow = FALSE,
            font = list(color = TIER_COLORS[["Top 5"]], size = 12)
          ))
        )

      # Build 2nd-tier panel
      t2_order <- elo_iqr |>
        dplyr::filter(tier == "2nd Tier") |>
        dplyr::arrange(dplyr::desc(iqr)) |>
        dplyr::pull(league_code)
      t2_data <- elo_data |>
        dplyr::filter(tier == "2nd Tier") |>
        dplyr::mutate(league_code = factor(league_code, levels = rev(t2_order)))

      t2_mean_iqr <- tier_iqr |>
        dplyr::filter(tier == "2nd Tier") |>
        dplyr::pull(mean_iqr)

      p2 <- plotly::plot_ly(
        t2_data,
        x = ~elo, y = ~league_code,
        type = "box",
        marker = list(color = TIER_COLORS[["2nd Tier"]]),
        fillcolor = "rgba(230, 126, 34, 0.5)",
        line = list(color = "white"),
        hovertemplate = "League: %{y}<br>Elo: %{x:.0f}<extra></extra>"
      ) |>
        plotly::layout(
          annotations = list(list(
            x = 0.5, y = 1.12, xref = "paper", yref = "paper",
            text = paste0("2nd Tier (mean IQR: ", t2_mean_iqr, ")"),
            showarrow = FALSE,
            font = list(color = TIER_COLORS[["2nd Tier"]], size = 12)
          ))
        )

      plotly::subplot(p1, p2, nrows = 2, shareX = TRUE, titleY = TRUE) |>
        theme_dark_plotly(
          title = "Elo Spread by League (ordered by IQR within tier)"
        ) |>
        plotly::layout(
          xaxis = list(title = "Elo Rating"),
          yaxis = list(title = ""),
          yaxis2 = list(title = ""),
          shapes = list(
            list(type = "line", x0 = 1500, x1 = 1500, y0 = 0, y1 = 1,
                 xref = "x", yref = "paper",
                 line = list(color = "#e67e22", dash = "dash", width = 2))
          ),
          annotations = list(
            list(x = 1500, y = 1.02, xref = "x", yref = "paper",
                 text = "Starting Elo (1500)",
                 showarrow = FALSE,
                 font = list(color = "#e67e22", size = 10)),
            list(x = 0.5, y = -0.08, xref = "paper", yref = "paper",
                 text = "Wider IQR = more competitive imbalance. Top divisions typically show wider Elo spreads.",
                 showarrow = FALSE,
                 font = list(color = "white", size = 10))
          ),
          height = 700
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
        dplyr::filter(!is.na(league_code)) |>
        add_league_metadata()

      # Order by median overround (lowest margin at top = best for bettors)
      league_order <- overround_data |>
        dplyr::group_by(league_code) |>
        dplyr::summarise(median_or = stats::median(overround, na.rm = TRUE)) |>
        dplyr::arrange(median_or) |>
        dplyr::pull(league_code)

      overround_data <- overround_data |>
        dplyr::mutate(league_code = factor(league_code, levels = rev(league_order)))

      # Get tier for coloring
      tier_map <- overround_data |>
        dplyr::distinct(league_code, tier)

      plotly::plot_ly(
        overround_data,
        x = ~overround,
        y = ~league_code,
        color = ~tier,
        colors = TIER_COLORS,
        type = "box",
        line = list(color = "white"),
        hovertemplate = paste(
          "League: %{y}<br>",
          "Overround: %{x:.2f}%<extra></extra>"
        )
      ) |>
        theme_dark_plotly(title = "Pinnacle 1X2 Overround by League (ordered by median)") |>
        plotly::layout(
          showlegend = FALSE,
          xaxis = list(title = "Overround (%)"),
          yaxis = list(title = ""),
          shapes = list(
            list(type = "line", x0 = 0, x1 = 0, y0 = -0.5, y1 = 9.5,
                 line = list(color = "#e67e22", dash = "dash", width = 2))
          ),
          annotations = list(
            list(
              x = 0.5, y = 1.05, xref = "paper", yref = "paper",
              text = "Blue = Top 5 | Orange = 2nd Tier | Lower = better for bettors",
              showarrow = FALSE, font = list(size = 10, color = "white")
            ),
            list(
              x = 0.5, y = -0.1, xref = "paper", yref = "paper",
              text = "Median overround 2-4% confirms Pinnacle as sharp benchmark",
              showarrow = FALSE, font = list(size = 11, color = "#95a5a6")
            )
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
          "Fold: %{x:.0f}<br>",
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
    {
      model_vs_pinnacle |>
        dplyr::mutate(
          dplyr::across(
            dplyr::any_of(c("log_loss", "brier", "rps", "edge")),
            \(x) round(x, 3)
          )
        )
    }
  ),

  targets::tar_target(
    vig_pnl_curve,
    {
      pnl_data <- pnl_glm

      plotly::plot_ly(
        pnl_data,
        x = ~match_date,
        y = ~bankroll,
        type = "scatter",
        mode = "lines",
        line = list(color = "#3498db", width = 2),
        hovertemplate = paste(
          "Date: %{x}<br>",
          "Bankroll: %{y:,.0f}<extra></extra>"
        )
      ) |>
        theme_dark_plotly(title = "Simulated Bankroll (log scale, GLM Quarter Kelly)") |>
        add_time_slider() |>
        plotly::layout(
          xaxis = list(title = "Date"),
          yaxis = list(title = "Bankroll (log scale)", type = "log"),
          shapes = list(
            list(type = "line", x0 = 0, x1 = 1, y0 = 1000, y1 = 1000,
                 xref = "paper",
                 line = list(color = "#e67e22", dash = "dash", width = 2))
          ),
          annotations = list(
            list(x = 0.02, y = log10(1000), xref = "paper", yref = "y",
                 text = "Starting: 1,000",
                 showarrow = FALSE, yanchor = "bottom", font = list(color = "#e67e22"))
          )
        )
    }
  ),

  targets::tar_target(
    vig_drawdown_plot,
    {
      dd_data <- pnl_glm |>
        dplyr::mutate(drawdown_pct = 100 * drawdown)

      plotly::plot_ly(
        dd_data,
        x = ~match_date,
        y = ~drawdown_pct,
        type = "scatter",
        mode = "lines",
        fill = "tozeroy",
        fillcolor = "rgba(231, 76, 60, 0.4)",
        line = list(color = "#e74c3c", width = 2),
        hovertemplate = paste(
          "Date: %{x}<br>",
          "Drawdown: %{y:.1f}%<extra></extra>"
        )
      ) |>
        theme_dark_plotly(title = "Drawdown Over Time (GLM Value Bets)") |>
        plotly::layout(
          xaxis = list(title = "Date"),
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
      # Cap stakes at 3% (pmin) — plots the actual applied stake after guardrail
      plot_data <- value_bets_glm |>
        dplyr::mutate(capped_stake = pmin(kelly_stake, 0.03))

      n_capped <- sum(value_bets_glm$kelly_stake > 0.03, na.rm = TRUE)
      n_total  <- nrow(value_bets_glm)
      pct_capped <- round(100 * n_capped / n_total, 1)

      plotly::plot_ly(
        plot_data,
        x = ~capped_stake,
        type = "histogram",
        marker = list(color = "#3498db"),
        nbinsx = 30,
        hovertemplate = paste(
          "Stake: %{x:.1%}<br>",
          "Count: %{y}<extra></extra>"
        )
      ) |>
        theme_dark_plotly(
          title = "Distribution of Applied Stake Sizes (post-cap, quarter-Kelly)"
        ) |>
        plotly::layout(
          xaxis = list(title = "Stake (fraction of bankroll)", tickformat = ".1%"),
          yaxis = list(title = "Count"),
          shapes = list(
            list(type = "line", x0 = 0.03, x1 = 0.03, y0 = 0, y1 = 1,
                 yref = "paper",
                 line = list(color = "#e67e22", dash = "dash", width = 2))
          ),
          annotations = list(
            list(
              x = 0.03, y = 1, xref = "x", yref = "paper",
              text = paste0("3% cap (", n_capped, " bets, ", pct_capped, "% capped)"),
              showarrow = TRUE, arrowhead = 0, ax = 50, ay = 20,
              font = list(color = "#e67e22")
            )
          )
        )
    }
  ),

  targets::tar_target(
    vig_pnl_summary_table,
    {
      optimistic <- pnl_summary |>
        dplyr::mutate(scenario = "Optimistic (no costs)", .before = 1)
      realistic <- pnl_summary_realistic |>
        dplyr::mutate(scenario = "Realistic (2% cost, 1% slip, flat £10)", .before = 1)

      comparison <- dplyr::bind_rows(optimistic, realistic) |>
        dplyr::mutate(
          dplyr::across(dplyr::where(is.numeric), ~ signif(.x, 4)),
          roi_pct = round(roi_pct, 1),
          max_drawdown = round(max_drawdown * 100, 1),
          win_rate = round(win_rate * 100, 1),
          avg_odds = round(avg_odds, 2)
        )
      comparison
    }
  ),

  # Realistic PnL curve for vignette
  targets::tar_target(
    vig_pnl_curve_realistic,
    {
      plotly::plot_ly() |>
        plotly::add_lines(
          data = pnl_glm, x = ~match_date, y = ~bankroll,
          name = "Optimistic (no costs)",
          line = list(color = "#3498db", width = 1, dash = "dot"),
          hovertemplate = "Optimistic<br>%{x}<br>%{y:,.0f}<extra></extra>"
        ) |>
        plotly::add_lines(
          data = pnl_glm_realistic, x = ~match_date, y = ~bankroll,
          name = "Realistic (2% cost, flat £10)",
          line = list(color = "#e67e22", width = 2),
          hovertemplate = "Realistic<br>%{x}<br>%{y:,.0f}<extra></extra>"
        ) |>
        theme_dark_plotly(title = "Bankroll: Optimistic vs Realistic (log scale)") |>
        plotly::layout(
          xaxis = list(title = "Date"),
          yaxis = list(title = "Bankroll (log scale)", type = "log"),
          legend = list(x = 0.02, y = 0.98, bgcolor = "rgba(0,0,0,0.5)"),
          shapes = list(
            list(type = "line", x0 = 0, x1 = 1, y0 = 1000, y1 = 1000,
                 xref = "paper",
                 line = list(color = "white", dash = "dash", width = 1))
          )
        )
    }
  ),

# ============================================================================
# Statistical Tests (Evidence Enhancement)
# Note: These are optional diagnostic targets. If they fail, the vignette
# still works - it just won't have these statistical test summaries.
# ============================================================================

  targets::tar_target(
    vig_poisson_test,
    {
      home_goals <- parsed_matches[["fthg"]][!is.na(parsed_matches[["fthg"]])]
      away_goals <- parsed_matches[["ftag"]][!is.na(parsed_matches[["ftag"]])]
      all_goals <- c(home_goals, away_goals)

      lambda_all <- mean(all_goals)
      lambda_home <- mean(home_goals)
      lambda_away <- mean(away_goals)

      # LR test: single lambda vs separate home/away lambdas
      ll_single <- sum(stats::dpois(all_goals, lambda_all, log = TRUE))
      ll_separate <- sum(stats::dpois(home_goals, lambda_home, log = TRUE)) +
                     sum(stats::dpois(away_goals, lambda_away, log = TRUE))
      lr_stat <- 2 * (ll_separate - ll_single)
      lr_pvalue <- stats::pchisq(lr_stat, df = 1, lower.tail = FALSE)

      variance <- stats::var(all_goals)

      tibble::tibble(
        test = "Poisson Fit Summary",
        mean_home = round(lambda_home, 3),
        mean_away = round(lambda_away, 3),
        mean_all = round(lambda_all, 3),
        variance = round(variance, 3),
        dispersion_ratio = round(variance / lambda_all, 3),
        lr_statistic = round(lr_stat, 1),
        lr_pvalue = format.pval(lr_pvalue, digits = 3),
        n_goals = length(all_goals),
        conclusion = paste0(
          if (variance / lambda_all > 1.1) "Overdispersion present. " else "Near-Poisson. ",
          "Home (", round(lambda_home, 2), ") vs Away (", round(lambda_away, 2),
          "): LR test p", if (lr_pvalue < 0.001) "<0.001" else paste0("=", round(lr_pvalue, 4)),
          " — separate home/away models ",
          if (lr_pvalue < 0.05) "justified." else "not justified."
        )
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
# AH BACKTEST VIGNETTE TARGETS (#88)
# ============================================================================

  # Equity curve data (cumulative P&L per model × staking)
  targets::tar_target(
    vig_ah_equity_curves,
    {
      ah_walkforward_all |>
        dplyr::arrange(.data$model, .data$staking, .data$match_id) |>
        dplyr::group_by(.data$model, .data$staking) |>
        dplyr::mutate(
          cum_pnl = cumsum(.data$net),
          bet_num = dplyr::row_number()
        ) |>
        dplyr::ungroup()
    }
  ),

  # Drawdown data (underwater from peak)
  targets::tar_target(
    vig_ah_drawdown,
    {
      vig_ah_equity_curves |>
        dplyr::group_by(.data$model, .data$staking) |>
        dplyr::mutate(
          peak = cummax(.data$cum_pnl),
          drawdown = .data$cum_pnl - .data$peak
        ) |>
        dplyr::ungroup()
    }
  ),

  # Summary comparison table for AH models
  targets::tar_target(
    vig_ah_summary_table,
    ah_walkforward_summary |>
      dplyr::mutate(
        roi_pct = round(.data$roi_pct, 1),
        win_rate = round(.data$win_rate, 1),
        sharpe = round(.data$sharpe, 3),
        max_dd = round(.data$max_dd, 0)
      ) |>
      dplyr::select("model", "staking", "n_bets", "roi_pct",
                      "win_rate", "sharpe", "max_dd")
  ),

  # Per-season heatmap data
  targets::tar_target(
    vig_ah_season_heatmap,
    ah_walkforward_by_season |>
      dplyr::filter(.data$staking == "flat") |>
      dplyr::mutate(
        roi_pct = round(.data$roi_pct, 1),
        label = paste0(.data$model, " (", .data$test_season, ")")
      )
  ),

  # CLV per league (combined Ranger + Ensemble)
  targets::tar_target(
    vig_ah_clv_table,
    {
      ranger_clv <- oos_ah_ranger_clv_summary |>
        dplyr::filter(.data$league_code != "ALL") |>
        dplyr::select("league_code", "n_bets",
                       ranger_clv = "mean_clv",
                       ranger_btc = "beat_close_rate",
                       ranger_roi = "roi_pct")

      ensemble_clv <- oos_ah_ensemble_clv_summary |>
        dplyr::filter(.data$league_code != "ALL") |>
        dplyr::select("league_code",
                       ensemble_clv = "mean_clv",
                       ensemble_btc = "beat_close_rate",
                       ensemble_roi = "roi_pct")

      dplyr::full_join(ranger_clv, ensemble_clv, by = "league_code") |>
        dplyr::mutate(
          dplyr::across(dplyr::where(is.numeric), \(x) round(x, 3))
        )
    }
  ),

# ============================================================================
# NOTE: tar_visnetwork() cannot run inside a target - it's an introspection
# function that must be called directly in the vignette. Do NOT add
# vig_targets_dag target here.
# ============================================================================

# ============================================================================
# BUILD-INFO FOOTER (#87)
# Same format as historical/drif.html: pkg version | Git SHA | R ver | Built
# ============================================================================

  targets::tar_target(
    vig_build_info,
    {
      # GitHub remote URL
      gh_url <- tryCatch({
        remote <- system("git remote get-url origin 2>/dev/null", intern = TRUE)
        sub("\\.git$", "", sub("^git@github\\.com:", "https://github.com/", remote))
      }, error = function(e) NULL)

      # Git SHA
      git_sha_short <- tryCatch(
        system("git rev-parse --short HEAD 2>/dev/null", intern = TRUE),
        error = function(e) "N/A"
      )
      git_sha_full <- tryCatch(
        system("git rev-parse HEAD 2>/dev/null", intern = TRUE),
        error = function(e) git_sha_short
      )

      # Package version
      pkg_ver <- tryCatch(
        as.character(utils::packageVersion("footbet")),
        error = function(e) {
          desc <- tryCatch(read.dcf("DESCRIPTION", "Version"), error = function(e2) "dev")
          as.character(desc)
        }
      )

      r_ver <- as.character(getRversion())
      build_time <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")

      # Build linked markdown
      ver_link <- if (!is.null(gh_url)) {
        sprintf("[%s](%s/releases/tag/v%s)", pkg_ver, gh_url, pkg_ver)
      } else pkg_ver

      sha_link <- if (!is.null(gh_url) && git_sha_short != "N/A") {
        sprintf("[`%s`](%s/commit/%s)", git_sha_short, gh_url, git_sha_full)
      } else sprintf("`%s`", git_sha_short)

      r_link <- sprintf(
        "[%s](https://cran.r-project.org/doc/manuals/r-release/NEWS.html)",
        r_ver
      )

      knitr::asis_output(sprintf(
        "\n---\n\n**footbet** %s | **Git** %s | **R** %s | **Built** %s\n",
        ver_link, sha_link, r_link, build_time
      ))
    }
  ),

# ============================================================================
# xG CALIBRATION (#84)
# ============================================================================

  targets::tar_target(
    vig_xg_per_league,
    {
      tryCatch(xg_per_league_comparison, error = function(e) NULL)
    }
  ),

  targets::tar_target(
    vig_dc_vs_glm_xg,
    {
      tryCatch(dc_vs_glm_xg_era, error = function(e) NULL)
    }
  ),

  targets::tar_target(
    vig_market_baselines,
    {
      tryCatch(
        market_baselines |>
          dplyr::filter(.data$league_code %in% c("D1", "E0", "F1", "I1", "SP1")),
        error = function(e) NULL
      )
    }
  ),

# ============================================================================
# MODEL LEADERBOARD — unified cross-model comparison for GH Pages
# Combines 1X2 calibration (model_comparison_with_brms) with AH P&L
# (vig_ah_summary_table) into a single table matching MODEL_CATALOGUE.md
# ============================================================================

  targets::tar_target(
    vig_model_leaderboard,
    {
      # 1X2 calibration metrics (log-loss, Brier, RPS)
      cal <- tryCatch(
        model_comparison_with_brms |>
          dplyr::select(
            "model",
            log_loss = "mean_log_loss",
            brier = "mean_brier",
            rps = "mean_rps",
            "n_folds"
          ) |>
          dplyr::mutate(market = "1X2"),
        error = function(e) NULL
      )

      # AH walk-forward P&L (flat staking only for the leaderboard)
      ah <- tryCatch(
        vig_ah_summary_table |>
          dplyr::filter(.data$staking == "flat") |>
          dplyr::select(
            "model", "n_bets", "roi_pct", "sharpe", "max_dd"
          ) |>
          dplyr::mutate(market = "AH"),
        error = function(e) NULL
      )

      # Pinnacle baseline row
      pinn <- tryCatch({
        pe <- pinnacle_eval
        if (is.data.frame(pe) && nrow(pe) > 0L) {
          tibble::tibble(
            model = "Pinnacle closing",
            market = "1X2",
            log_loss = pe$value[pe$metric == "log_loss"],
            brier = pe$value[pe$metric == "brier"],
            rps = pe$value[pe$metric == "rps"],
            n_folds = NA_integer_
          )
        } else NULL
      }, error = function(e) NULL)

      # Combine calibration rows
      cal_all <- dplyr::bind_rows(cal, pinn) |>
        dplyr::mutate(
          log_loss = round(.data$log_loss, 3),
          brier = round(.data$brier, 3),
          rps = round(.data$rps, 3)
        )

      # Combine AH rows (already rounded in vig_ah_summary_table)
      if (!is.null(ah) && nrow(ah) > 0L) {
        leaderboard <- dplyr::bind_rows(
          cal_all |>
            dplyr::mutate(
              n_bets = NA_integer_, roi_pct = NA_real_,
              sharpe = NA_real_, max_dd = NA_real_
            ),
          ah |>
            dplyr::mutate(
              log_loss = NA_real_, brier = NA_real_,
              rps = NA_real_, n_folds = NA_integer_
            )
        )
      } else {
        leaderboard <- cal_all |>
          dplyr::mutate(
            n_bets = NA_integer_, roi_pct = NA_real_,
            sharpe = NA_real_, max_dd = NA_real_
          )
      }

      leaderboard |>
        dplyr::select(
          "model", "market", "roi_pct", "n_bets", "sharpe",
          "max_dd", "log_loss", "brier", "rps", "n_folds"
        ) |>
        dplyr::arrange(
          dplyr::desc(.data$market),
          dplyr::desc(dplyr::coalesce(.data$roi_pct, 0))
        )
    }
  ),

  NULL
)
