# Add matches-since-event features to team data

Computes several "matches since" features for each team:

- `matches_since_win`: Matches since last win

- `matches_since_loss`: Matches since last loss

- `matches_since_clean_sheet`: Matches since last clean sheet (0 goals
  conceded)

- `matches_since_scored`: Matches since last match with a goal

## Usage

``` r
compute_matches_since(matches_df)
```

## Arguments

- matches_df:

  A tibble with `match_date`, `home_team`, `away_team`, `ftr`, `fthg`,
  `ftag`.

## Value

A tibble in long format with team, match_date, and matches-since
features.

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
[`apply_asof_cutoff()`](https://johngavin.github.io/footbet/reference/apply_asof_cutoff.md),
[`compute_elo()`](https://johngavin.github.io/footbet/reference/compute_elo.md),
[`compute_gamestate_xg()`](https://johngavin.github.io/footbet/reference/compute_gamestate_xg.md),
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
