# Detect favourite-longshot bias in odds

Analyzes historical data for systematic mispricings. The FLB is a
well-documented phenomenon where longshots are overbet (odds too short)
and favourites are underbet (odds too long).

## Usage

``` r
detect_flb(odds_df, actual_results, n_bins = 10L)
```

## Arguments

- odds_df:

  A tibble with devigged probability columns.

- actual_results:

  Character vector. Actual outcomes ("H", "D", "A").

- n_bins:

  Integer. Number of probability bins (default 10).

## Value

A tibble with bias analysis by probability bin.

## See also

Other betting:
[`acca_ev()`](https://johngavin.github.io/footbet/reference/acca_ev.md),
[`acca_odds()`](https://johngavin.github.io/footbet/reference/acca_odds.md),
[`adjust_for_league_strength()`](https://johngavin.github.io/footbet/reference/adjust_for_league_strength.md),
[`analyze_steam_moves()`](https://johngavin.github.io/footbet/reference/analyze_steam_moves.md),
[`bankroll_growth_target()`](https://johngavin.github.io/footbet/reference/bankroll_growth_target.md),
[`estimate_league_strength()`](https://johngavin.github.io/footbet/reference/estimate_league_strength.md),
[`find_best_accas()`](https://johngavin.github.io/footbet/reference/find_best_accas.md),
[`generate_bias_alerts()`](https://johngavin.github.io/footbet/reference/generate_bias_alerts.md),
[`line_movement()`](https://johngavin.github.io/footbet/reference/line_movement.md),
[`multi_kelly_stakes()`](https://johngavin.github.io/footbet/reference/multi_kelly_stakes.md),
[`simulate_bankroll_growth()`](https://johngavin.github.io/footbet/reference/simulate_bankroll_growth.md),
[`standard_league_strengths()`](https://johngavin.github.io/footbet/reference/standard_league_strengths.md),
[`summarize_flb()`](https://johngavin.github.io/footbet/reference/summarize_flb.md)
