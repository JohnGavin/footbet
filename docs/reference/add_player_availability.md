# Add player availability features to match data

For each match, computes the percentage of key player value missing due
to injuries/suspensions for both home and away teams.

## Usage

``` r
add_player_availability(
  matches,
  injuries_df,
  suspensions_df,
  squad_values_df,
  top_n = 5L
)
```

## Arguments

- matches:

  A tibble with `home_team`, `away_team` columns.

- injuries_df:

  A tibble from
  [`fetch_league_injuries()`](https://johngavin.github.io/footbet/reference/fetch_league_injuries.md).

- suspensions_df:

  A tibble from
  [`fetch_league_suspensions()`](https://johngavin.github.io/footbet/reference/fetch_league_suspensions.md).

- squad_values_df:

  Player-level values from Transfermarkt.

- top_n:

  Integer. Number of top players to consider (default 5).

## Value

The matches tibble with added columns: `home_key_out`, `away_key_out`,
`home_value_missing_pct`, `away_value_missing_pct`,
`availability_advantage`.

## See also

Other features:
[`add_form_scores()`](https://johngavin.github.io/footbet/reference/add_form_scores.md),
[`add_form_streaks()`](https://johngavin.github.io/footbet/reference/add_form_streaks.md),
[`add_h2h_features()`](https://johngavin.github.io/footbet/reference/add_h2h_features.md),
[`add_league_positions()`](https://johngavin.github.io/footbet/reference/add_league_positions.md),
[`add_matches_since()`](https://johngavin.github.io/footbet/reference/add_matches_since.md),
[`add_ratio_features()`](https://johngavin.github.io/footbet/reference/add_ratio_features.md),
[`add_rest_days()`](https://johngavin.github.io/footbet/reference/add_rest_days.md),
[`apply_asof_cutoff()`](https://johngavin.github.io/footbet/reference/apply_asof_cutoff.md),
[`compute_elo()`](https://johngavin.github.io/footbet/reference/compute_elo.md),
[`compute_gamestate_xg()`](https://johngavin.github.io/footbet/reference/compute_gamestate_xg.md),
[`compute_matches_since()`](https://johngavin.github.io/footbet/reference/compute_matches_since.md),
[`compute_rest_days()`](https://johngavin.github.io/footbet/reference/compute_rest_days.md),
[`compute_shot_quality()`](https://johngavin.github.io/footbet/reference/compute_shot_quality.md),
[`compute_xg_features()`](https://johngavin.github.io/footbet/reference/compute_xg_features.md),
[`compute_xg_xag_composite()`](https://johngavin.github.io/footbet/reference/compute_xg_xag_composite.md),
[`cumulative_xg_ratio()`](https://johngavin.github.io/footbet/reference/cumulative_xg_ratio.md),
[`devig_odds()`](https://johngavin.github.io/footbet/reference/devig_odds.md),
[`empirical_bayes_shrink()`](https://johngavin.github.io/footbet/reference/empirical_bayes_shrink.md),
[`first_reliable_matchday()`](https://johngavin.github.io/footbet/reference/first_reliable_matchday.md),
[`form_streak()`](https://johngavin.github.io/footbet/reference/form_streak.md),
[`h2h_record()`](https://johngavin.github.io/footbet/reference/h2h_record.md),
[`key_players_unavailable()`](https://johngavin.github.io/footbet/reference/key_players_unavailable.md),
[`league_table()`](https://johngavin.github.io/footbet/reference/league_table.md),
[`leakage_fix`](https://johngavin.github.io/footbet/reference/leakage_fix.md),
[`margin_k_factor()`](https://johngavin.github.io/footbet/reference/margin_k_factor.md),
[`matches_since_event()`](https://johngavin.github.io/footbet/reference/matches_since_event.md),
[`matches_to_long()`](https://johngavin.github.io/footbet/reference/matches_to_long.md),
[`pinnacle_implied_elo()`](https://johngavin.github.io/footbet/reference/pinnacle_implied_elo.md),
[`ratio_normalize()`](https://johngavin.github.io/footbet/reference/ratio_normalize.md),
[`reliability_threshold()`](https://johngavin.github.io/footbet/reference/reliability_threshold.md),
[`rest_days()`](https://johngavin.github.io/footbet/reference/rest_days.md),
[`rolling_goals()`](https://johngavin.github.io/footbet/reference/rolling_goals.md),
[`rolling_progressive()`](https://johngavin.github.io/footbet/reference/rolling_progressive.md),
[`rolling_psxg()`](https://johngavin.github.io/footbet/reference/rolling_psxg.md),
[`rolling_shot_quality()`](https://johngavin.github.io/footbet/reference/rolling_shot_quality.md),
[`rolling_sot()`](https://johngavin.github.io/footbet/reference/rolling_sot.md),
[`rolling_xg()`](https://johngavin.github.io/footbet/reference/rolling_xg.md),
[`seasonal_k()`](https://johngavin.github.io/footbet/reference/seasonal_k.md),
[`shrink_team_strength()`](https://johngavin.github.io/footbet/reference/shrink_team_strength.md),
[`team_form_score()`](https://johngavin.github.io/footbet/reference/team_form_score.md),
[`team_position()`](https://johngavin.github.io/footbet/reference/team_position.md),
[`xg_overperformance()`](https://johngavin.github.io/footbet/reference/xg_overperformance.md)
