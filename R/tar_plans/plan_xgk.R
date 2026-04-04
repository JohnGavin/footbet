# plan_xgk.R
# xG data acquisition + Kalman filter team strengths
# Tracks: #82 (xG/Kalman/DC), plans/PLAN_xg_kalman_dc.md

plan_xgk <- list(

  # ====================================================================
  # Phase 1: xG data from FBref
  # ====================================================================

  # Fetch xG for Tier 1 leagues (FBref has xG from ~2017)
  targets::tar_target(
    fbref_xg_raw,
    {
      if (!requireNamespace("worldfootballR", quietly = TRUE)) {
        cli::cli_warn("worldfootballR not available. Skipping xG fetch.")
        return(tibble::tibble())
      }
      # Tier 1 only (FBref coverage), seasons 2018-2026 (season end year)
      fetch_fbref_all(
        leagues = c("ENG", "ESP", "GER", "ITA", "FRA"),
        seasons = 2018:2026,
        delay = 5
      )
    },
    cue = targets::tar_cue(mode = "thorough")
  ),

  # Join xG to parsed matches
  targets::tar_target(
    matches_with_xg,
    {
      if (nrow(fbref_xg_raw) == 0L) {
        cli::cli_warn("No FBref xG data. Returning matches without xG.")
        return(parsed_matches |>
                 dplyr::mutate(home_xg = NA_real_, away_xg = NA_real_))
      }
      join_xg_to_matches(parsed_matches, fbref_xg_raw)
    }
  ),

  # xG coverage summary
  targets::tar_target(
    xg_coverage,
    {
      matches_with_xg |>
        dplyr::group_by(.data$season, .data$league_code) |>
        dplyr::summarise(
          n_matches = dplyr::n(),
          n_xg = sum(!is.na(.data$home_xg)),
          pct_xg = round(100 * sum(!is.na(.data$home_xg)) / dplyr::n(), 1),
          .groups = "drop"
        )
    }
  )
)
