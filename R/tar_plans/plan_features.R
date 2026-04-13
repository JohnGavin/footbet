# plan_features.R
# Feature engineering: rolling averages, Elo, devigged odds

plan_features <- list(

  # Rolling goal averages at multiple windows
  targets::tar_target(
    rolling_5,
    rolling_goals(parsed_matches, window = 5L)
  ),

  targets::tar_target(
    rolling_10,
    rolling_goals(parsed_matches, window = 10L)
  ),

  targets::tar_target(
    rolling_38,
    rolling_goals(parsed_matches, window = 38L)
  ),

  # Long format for Poisson modelling
  targets::tar_target(
    matches_long,
    matches_to_long(parsed_matches)
  ),

  # Elo ratings per league (match-by-match with dynamic K and margin adjustment)
  targets::tar_target(
    elo_ratings,
    {
      leagues <- unique(parsed_matches$league_code)
      dfs <- lapply(leagues, function(lc) {
        league_matches <- dplyr::filter(parsed_matches, league_code == lc)
        ratings <- compute_elo(
          league_matches,
          dynamic_k = TRUE, k_start = 40, k_end = 20,
          margin_k = TRUE, reversion = 0.28, asymmetric = TRUE
        )
        ratings$league_code <- lc
        ratings
      })
      dplyr::bind_rows(dfs)
    }
  ),

  # Devigged Pinnacle probabilities
  targets::tar_target(
    devigged_odds,
    devig_odds(parsed_odds)
  ),

  # Rolling shots-on-target ratio (high discrimination per meta-analytics)
  targets::tar_target(
    rolling_sot_5,
    rolling_sot(parsed_matches, window = 5L)
  ),

  # Combined feature matrix: join rolling stats + Elo + devigged odds
  targets::tar_target(
    feature_matrix,
    {
      # Start with matches
      fm <- parsed_matches |>
        dplyr::select(match_id, league_code, season, match_date,
                       home_team, away_team, fthg, ftag, ftr)

      # Join home team rolling stats (window=5)
      home_roll <- rolling_5 |>
        dplyr::filter(is_home) |>
        dplyr::select(team, match_date, rolling_gf, rolling_ga, rolling_gd) |>
        dplyr::rename(
          home_roll_gf = rolling_gf,
          home_roll_ga = rolling_ga,
          home_roll_gd = rolling_gd
        )

      away_roll <- rolling_5 |>
        dplyr::filter(!is_home) |>
        dplyr::select(team, match_date, rolling_gf, rolling_ga, rolling_gd) |>
        dplyr::rename(
          away_roll_gf = rolling_gf,
          away_roll_ga = rolling_ga,
          away_roll_gd = rolling_gd
        )

      fm <- fm |>
        dplyr::left_join(home_roll,
          by = c("home_team" = "team", "match_date" = "match_date")) |>
        dplyr::left_join(away_roll,
          by = c("away_team" = "team", "match_date" = "match_date"))

      # Join Elo ratings (match-by-match, keyed on team + date + league)
      fm <- fm |>
        dplyr::left_join(
          dplyr::rename(elo_ratings, home_elo = elo),
          by = c("home_team" = "team", "match_date" = "match_date",
                 "league_code" = "league_code")
        ) |>
        dplyr::left_join(
          dplyr::rename(elo_ratings, away_elo = elo),
          by = c("away_team" = "team", "match_date" = "match_date",
                 "league_code" = "league_code")
        ) |>
        dplyr::mutate(elo_diff = home_elo - away_elo)

      # Join devigged odds
      fm <- fm |>
        dplyr::left_join(devigged_odds, by = "match_id")

      # Add rest days
      fm <- compute_rest_days(fm)

      # Join rolling SoT ratio
      home_sot <- rolling_sot_5 |>
        dplyr::select("team", "match_date",
                       home_sot_for = "rolling_sot_for",
                       home_sot_against = "rolling_sot_against",
                       home_sot_ratio = "rolling_sot_ratio")
      away_sot <- rolling_sot_5 |>
        dplyr::select("team", "match_date",
                       away_sot_for = "rolling_sot_for",
                       away_sot_against = "rolling_sot_against",
                       away_sot_ratio = "rolling_sot_ratio")
      fm <- fm |>
        dplyr::left_join(home_sot,
          by = c("home_team" = "team", "match_date")) |>
        dplyr::left_join(away_sot,
          by = c("away_team" = "team", "match_date"))

      # Add Pinnacle implied Elo (ensemble feature)
      if ("fair_h" %in% names(fm)) {
        fm <- fm |>
          dplyr::mutate(
            pinnacle_home_elo = pinnacle_implied_elo(fair_h),
            pinnacle_away_elo = pinnacle_implied_elo(fair_a),
            pinnacle_elo_diff = pinnacle_home_elo - pinnacle_away_elo
          )
      }

      fm
    }
  )
)
