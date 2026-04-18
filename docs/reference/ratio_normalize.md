# Normalize features to ratio form

Converts team/opponent features to ratio form: team / (team + opponent).
This captures relative strength in a bounded 0-1 metric that is more
predictive than raw differences.

## Usage

``` r
ratio_normalize(team_value, opponent_value, na_value = 0.5)
```

## Arguments

- team_value:

  Numeric. Team's metric value.

- opponent_value:

  Numeric. Opponent's metric value.

- na_value:

  Numeric. Value to return when denominator is 0 (default 0.5).

## Value

Numeric in range 0-1. Team's share of total.

## Details

Based on Tony ElHabr's analysis showing ratio metrics outperform
difference metrics for xG-based prediction.

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
