# plan_xgk.R
# xG data acquisition (Understat) + Kalman filter team strengths
# Tracks: #82 (xG/Kalman/DC), plans/PLAN_xg_kalman_dc.md

plan_xgk <- list(

  # ====================================================================
  # Phase 1: xG data from Understat (FBref is HTTP 403 blocked)
  # ====================================================================

  # Fetch shot-level xG for Tier 1 leagues via worldfootballR GitHub mirror
  targets::tar_target(
    understat_shots_raw,
    {
      if (!requireNamespace("worldfootballR", quietly = TRUE)) {
        cli::cli_warn("worldfootballR not available. Skipping xG fetch.")
        return(tibble::tibble())
      }

      leagues <- c("EPL", "La liga", "Bundesliga", "Serie A", "Ligue 1")
      cli::cli_alert_info("Fetching Understat shot data for {length(leagues)} leagues...")

      purrr::map_dfr(leagues, function(lg) {
        tryCatch({
          cli::cli_alert("Fetching {lg}...")
          worldfootballR::load_understat_league_shots(league = lg)
        }, error = function(e) {
          cli::cli_warn("Failed to fetch {lg}: {conditionMessage(e)}")
          tibble::tibble()
        })
      })
    },
    cue = targets::tar_cue(mode = "thorough")
  ),

  # Aggregate shots to match-level xG totals
  targets::tar_target(
    understat_match_xg,
    {
      if (nrow(understat_shots_raw) == 0L) return(tibble::tibble())

      understat_shots_raw |>
        dplyr::mutate(
          xG = as.numeric(.data$xG),
          match_date = as.Date(.data$date)
        ) |>
        dplyr::group_by(
          .data$match_id, .data$home_team, .data$away_team,
          .data$match_date, .data$season, .data$league
        ) |>
        dplyr::summarise(
          home_xg = sum(.data$xG[.data$h_a == "h"], na.rm = TRUE),
          away_xg = sum(.data$xG[.data$h_a == "a"], na.rm = TRUE),
          home_shots = sum(.data$h_a == "h"),
          away_shots = sum(.data$h_a == "a"),
          .groups = "drop"
        )
    }
  ),

  # Map Understat league names to our league codes
  targets::tar_target(
    matches_with_xg,
    {
      if (nrow(understat_match_xg) == 0L) {
        cli::cli_warn("No Understat xG data. Returning matches without xG.")
        return(parsed_matches |>
                 dplyr::mutate(home_xg = NA_real_, away_xg = NA_real_))
      }

      league_map <- tibble::tibble(
        league = c("EPL", "La_liga", "Bundesliga", "Serie_A", "Ligue_1"),
        league_code = c("E0", "SP1", "D1", "I1", "F1")
      )

      # Clean team names for fuzzy matching
      xg <- understat_match_xg |>
        dplyr::left_join(league_map, by = "league") |>
        dplyr::filter(!is.na(.data$league_code))

      # Join by date + team names (fuzzy: understat uses full names, fd uses abbreviated)
      joined <- parsed_matches |>
        dplyr::left_join(
          xg |> dplyr::select("match_date", "league_code",
                               home_xg = "home_xg", away_xg = "away_xg",
                               us_home = "home_team", us_away = "away_team"),
          by = c("match_date", "league_code"),
          relationship = "many-to-many"
        ) |>
        # Keep the best match: team name similarity
        dplyr::mutate(
          name_sim = stringdist_sim(.data$home_team, .data$us_home) +
            stringdist_sim(.data$away_team, .data$us_away)
        ) |>
        dplyr::group_by(.data$match_id) |>
        dplyr::slice_max(.data$name_sim, n = 1, with_ties = FALSE) |>
        dplyr::ungroup() |>
        dplyr::select(-"us_home", -"us_away", -"name_sim")

      joined
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
