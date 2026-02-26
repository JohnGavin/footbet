# plan_quality_control.R
# Data completeness and quality checks

plan_quality_control <- list(

  # Match completeness: expected vs actual rows per league/season
  targets::tar_target(
    qc_match_completeness,
    {
      if (nrow(parsed_matches) == 0L) {
        return(tibble::tibble(
          league_code = character(), season = character(),
          n_matches = integer(), has_results = logical()
        ))
      }
      parsed_matches |>
        dplyr::group_by(league_code, season) |>
        dplyr::summarise(
          n_matches    = dplyr::n(),
          n_no_result  = sum(is.na(ftr)),
          pct_complete = 100 * (1 - n_no_result / n_matches),
          min_date     = min(match_date, na.rm = TRUE),
          max_date     = max(match_date, na.rm = TRUE),
          .groups = "drop"
        )
    }
  ),

  # Pinnacle odds coverage
  targets::tar_target(
    qc_pinnacle_coverage,
    {
      if (nrow(parsed_odds) == 0L) {
        return(tibble::tibble(
          league_code = character(), season = character(),
          n_total = integer(), n_pinnacle = integer(), pct_pinnacle = double()
        ))
      }
      # Join season/league from matches
      odds_with_meta <- dplyr::left_join(
        parsed_odds,
        dplyr::select(parsed_matches, match_id, league_code, season),
        by = "match_id"
      )
      odds_with_meta |>
        dplyr::group_by(league_code, season) |>
        dplyr::summarise(
          n_total    = dplyr::n(),
          n_pinnacle = sum(!is.na(psh) & !is.na(psd) & !is.na(psa)),
          pct_pinnacle = 100 * n_pinnacle / n_total,
          .groups = "drop"
        )
    }
  ),

  # Flag anomalies: matches with extreme scores, future dates, etc.
  targets::tar_target(
    qc_anomalies,
    {
      if (nrow(parsed_matches) == 0L) return(tibble::tibble())
      parsed_matches |>
        dplyr::filter(
          fthg > 10L | ftag > 10L |          # extreme scorelines
            is.na(match_date) |               # missing date
            match_date > Sys.Date() + 7L |    # future match (>1 week ahead)
            is.na(home_team) | is.na(away_team)
        ) |>
        dplyr::select(match_id, league_code, season, match_date,
                       home_team, away_team, fthg, ftag)
    }
  ),

  # Summary report combining all QC targets
  targets::tar_target(
    qc_summary,
    {
      list(
        match_completeness = qc_match_completeness,
        pinnacle_coverage  = qc_pinnacle_coverage,
        anomalies          = qc_anomalies,
        total_matches      = nrow(parsed_matches),
        total_odds         = nrow(parsed_odds),
        timestamp          = Sys.time()
      )
    }
  )
)
