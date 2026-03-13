# Compute bankroll growth target

Estimates the number of bets needed to reach a bankroll target given
average edge and stake sizing.

## Usage

``` r
bankroll_growth_target(
  current_bankroll,
  target_bankroll,
  avg_odds = 2,
  avg_edge = 0.05,
  avg_stake_pct = 0.02
)
```

## Arguments

- current_bankroll:

  Numeric. Current bankroll.

- target_bankroll:

  Numeric. Target bankroll.

- avg_odds:

  Numeric. Average decimal odds (default 2.0).

- avg_edge:

  Numeric. Average edge per bet (default 0.05 = 5%).

- avg_stake_pct:

  Numeric. Average stake as % of bankroll (default 0.02).

## Value

A tibble with growth projections.

## See also

Other betting:
[`acca_ev()`](https://johngavin.github.io/footbet/reference/acca_ev.md),
[`acca_odds()`](https://johngavin.github.io/footbet/reference/acca_odds.md),
[`adjust_for_league_strength()`](https://johngavin.github.io/footbet/reference/adjust_for_league_strength.md),
[`analyze_steam_moves()`](https://johngavin.github.io/footbet/reference/analyze_steam_moves.md),
[`detect_flb()`](https://johngavin.github.io/footbet/reference/detect_flb.md),
[`estimate_league_strength()`](https://johngavin.github.io/footbet/reference/estimate_league_strength.md),
[`find_best_accas()`](https://johngavin.github.io/footbet/reference/find_best_accas.md),
[`generate_bias_alerts()`](https://johngavin.github.io/footbet/reference/generate_bias_alerts.md),
[`line_movement()`](https://johngavin.github.io/footbet/reference/line_movement.md),
[`multi_kelly_stakes()`](https://johngavin.github.io/footbet/reference/multi_kelly_stakes.md),
[`simulate_bankroll_growth()`](https://johngavin.github.io/footbet/reference/simulate_bankroll_growth.md),
[`standard_league_strengths()`](https://johngavin.github.io/footbet/reference/standard_league_strengths.md),
[`summarize_flb()`](https://johngavin.github.io/footbet/reference/summarize_flb.md)
