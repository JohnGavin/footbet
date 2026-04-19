# Compute Elo ratings for a league

Updates Elo ratings match-by-match using standard Elo formula. Matches
must be sorted by date. Returns ratings after each match.

## Usage

``` r
compute_elo(
  matches_df,
  k = 20,
  home_advantage = 65,
  init = 1500,
  dynamic_k = FALSE,
  k_start = 40,
  k_end = 20,
  team_home_advantage = NULL,
  margin_k = FALSE,
  reversion = 0,
  asymmetric = FALSE
)
```

## Arguments

- matches_df:

  A tibble with `match_date`, `home_team`, `away_team`, `ftr`. For
  `margin_k = TRUE`, also needs `fthg` and `ftag`.

- k:

  Numeric. Base K-factor (default 20). Ignored when `dynamic_k = TRUE`.

- home_advantage:

  Numeric. Uniform home advantage in Elo points (default 65). Ignored
  when `team_home_advantage` is provided.

- init:

  Numeric. Initial Elo rating (default 1500).

- dynamic_k:

  Logical. Use seasonal K-factor decay (default FALSE).

- k_start:

  Numeric. K-factor at season start (August). Default 40.

- k_end:

  Numeric. K-factor at season end. Default 20.

- team_home_advantage:

  Named numeric vector. Per-team home advantage (e.g.,
  `c(Liverpool = 80, Brentford = 40)`). Default NULL (use uniform).

- margin_k:

  Logical. Downweight blowouts in K-factor (default FALSE).

- reversion:

  Numeric 0-1. Fraction to regress toward league mean at season start
  (default 0 = no reversion). COOPER uses 0.28.

- asymmetric:

  Logical. Allow winners to lose Elo when underperforming expected
  margin (default FALSE). Requires `fthg`/`ftag`.

## Value

A tibble with columns `team`, `match_date`, `elo`.

## Details

Supports enhancements inspired by COOPER/FiveThirtyEight:

- **Dynamic K-factor**: higher K early season, decaying by December

- **Team-specific home advantage**: named vector of per-team adjustments

- **Margin-adjusted K**: downweight blowouts (requires `fthg`/`ftag`
  columns)

- **League reversion**: regress toward league mean at season start

- **Asymmetric wins**: underperforming winners get reduced Elo gain

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
[`compute_gamestate_xg()`](https://johngavin.github.io/footbet/reference/compute_gamestate_xg.md),
[`compute_matches_since()`](https://johngavin.github.io/footbet/reference/compute_matches_since.md),
[`compute_rest_days()`](https://johngavin.github.io/footbet/reference/compute_rest_days.md),
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
[`margin_k_factor()`](https://johngavin.github.io/footbet/reference/margin_k_factor.md),
[`matches_since_event()`](https://johngavin.github.io/footbet/reference/matches_since_event.md),
[`matches_to_long()`](https://johngavin.github.io/footbet/reference/matches_to_long.md),
[`pinnacle_implied_elo()`](https://johngavin.github.io/footbet/reference/pinnacle_implied_elo.md),
[`ratio_normalize()`](https://johngavin.github.io/footbet/reference/ratio_normalize.md),
[`reliability_threshold()`](https://johngavin.github.io/footbet/reference/reliability_threshold.md),
[`rest_days()`](https://johngavin.github.io/footbet/reference/rest_days.md),
[`rolling_goals()`](https://johngavin.github.io/footbet/reference/rolling_goals.md),
[`rolling_xg()`](https://johngavin.github.io/footbet/reference/rolling_xg.md),
[`seasonal_k()`](https://johngavin.github.io/footbet/reference/seasonal_k.md),
[`shrink_team_strength()`](https://johngavin.github.io/footbet/reference/shrink_team_strength.md),
[`team_form_score()`](https://johngavin.github.io/footbet/reference/team_form_score.md),
[`team_position()`](https://johngavin.github.io/footbet/reference/team_position.md),
[`xg_overperformance()`](https://johngavin.github.io/footbet/reference/xg_overperformance.md)
