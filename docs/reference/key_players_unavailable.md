# Check key player availability for a team

Determines if a team's most valuable players are available by
cross-referencing squad values with injuries and suspensions. Useful as
a predictive feature.

## Usage

``` r
key_players_unavailable(
  team,
  injuries_df,
  suspensions_df,
  squad_values_df,
  top_n = 5L
)
```

## Arguments

- team:

  Character. Team name (must match Transfermarkt spelling).

- injuries_df:

  A tibble from
  [`fetch_league_injuries()`](https://johngavin.github.io/footbet/reference/fetch_league_injuries.md).

- suspensions_df:

  A tibble from
  [`fetch_league_suspensions()`](https://johngavin.github.io/footbet/reference/fetch_league_suspensions.md).

- squad_values_df:

  A tibble from
  [`fetch_squad_values()`](https://johngavin.github.io/footbet/reference/fetch_squad_values.md)
  with player-level data (requires `player_name` and
  `market_value_eur`).

- top_n:

  Integer. Number of top players to check (default 5).

## Value

A list with `n_unavailable`, `unavailable_value_eur`,
`pct_value_missing`, `key_players_out` (character vector).

## See also

Other features:
[`add_form_scores()`](https://johngavin.github.io/footbet/reference/add_form_scores.md),
[`add_form_streaks()`](https://johngavin.github.io/footbet/reference/add_form_streaks.md),
[`add_h2h_features()`](https://johngavin.github.io/footbet/reference/add_h2h_features.md),
[`add_league_positions()`](https://johngavin.github.io/footbet/reference/add_league_positions.md),
[`add_matches_since()`](https://johngavin.github.io/footbet/reference/add_matches_since.md),
[`add_player_availability()`](https://johngavin.github.io/footbet/reference/add_player_availability.md),
[`add_ratio_features()`](https://johngavin.github.io/footbet/reference/add_ratio_features.md),
[`add_rest_days()`](https://johngavin.github.io/footbet/reference/add_rest_days.md),
[`compute_elo()`](https://johngavin.github.io/footbet/reference/compute_elo.md),
[`compute_gamestate_xg()`](https://johngavin.github.io/footbet/reference/compute_gamestate_xg.md),
[`compute_matches_since()`](https://johngavin.github.io/footbet/reference/compute_matches_since.md),
[`compute_xg_features()`](https://johngavin.github.io/footbet/reference/compute_xg_features.md),
[`compute_xg_xag_composite()`](https://johngavin.github.io/footbet/reference/compute_xg_xag_composite.md),
[`cumulative_xg_ratio()`](https://johngavin.github.io/footbet/reference/cumulative_xg_ratio.md),
[`devig_odds()`](https://johngavin.github.io/footbet/reference/devig_odds.md),
[`empirical_bayes_shrink()`](https://johngavin.github.io/footbet/reference/empirical_bayes_shrink.md),
[`first_reliable_matchday()`](https://johngavin.github.io/footbet/reference/first_reliable_matchday.md),
[`form_streak()`](https://johngavin.github.io/footbet/reference/form_streak.md),
[`h2h_record()`](https://johngavin.github.io/footbet/reference/h2h_record.md),
[`league_table()`](https://johngavin.github.io/footbet/reference/league_table.md),
[`matches_since_event()`](https://johngavin.github.io/footbet/reference/matches_since_event.md),
[`matches_to_long()`](https://johngavin.github.io/footbet/reference/matches_to_long.md),
[`ratio_normalize()`](https://johngavin.github.io/footbet/reference/ratio_normalize.md),
[`reliability_threshold()`](https://johngavin.github.io/footbet/reference/reliability_threshold.md),
[`rest_days()`](https://johngavin.github.io/footbet/reference/rest_days.md),
[`rolling_goals()`](https://johngavin.github.io/footbet/reference/rolling_goals.md),
[`rolling_xg()`](https://johngavin.github.io/footbet/reference/rolling_xg.md),
[`shrink_team_strength()`](https://johngavin.github.io/footbet/reference/shrink_team_strength.md),
[`team_form_score()`](https://johngavin.github.io/footbet/reference/team_form_score.md),
[`team_position()`](https://johngavin.github.io/footbet/reference/team_position.md),
[`xg_overperformance()`](https://johngavin.github.io/footbet/reference/xg_overperformance.md)
