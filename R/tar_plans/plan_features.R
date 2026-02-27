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

  # Elo ratings per league
  targets::tar_target(
    elo_ratings,
    {
      leagues <- unique(parsed_matches$league_code)
      dfs <- lapply(leagues, function(lc) {
        league_matches <- dplyr::filter(parsed_matches, league_code == lc)
        ratings <- compute_elo(league_matches)
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

      # Join Elo ratings
      fm <- fm |>
        dplyr::left_join(
          dplyr::rename(elo_ratings, home_elo = elo),
          by = c("home_team" = "team", "league_code" = "league_code")
        ) |>
        dplyr::left_join(
          dplyr::rename(elo_ratings, away_elo = elo),
          by = c("away_team" = "team", "league_code" = "league_code")
        ) |>
        dplyr::mutate(elo_diff = home_elo - away_elo)

      # Join devigged odds
      fm <- fm |>
        dplyr::left_join(devigged_odds, by = "match_id")

      fm
    }
  )
)
