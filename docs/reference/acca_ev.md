# Compute expected value of an accumulator

Calculates the expected value of an accumulator bet per unit staked.

## Usage

``` r
acca_ev(probs, odds)
```

## Arguments

- probs:

  Numeric vector. Model probabilities for each selection.

- odds:

  Numeric vector. Decimal odds for each selection.

## Value

Numeric. Expected value (positive = profitable).

## See also

Other betting:
[`acca_odds()`](https://johngavin.github.io/footbet/reference/acca_odds.md),
[`adjust_for_league_strength()`](https://johngavin.github.io/footbet/reference/adjust_for_league_strength.md),
[`analyze_steam_moves()`](https://johngavin.github.io/footbet/reference/analyze_steam_moves.md),
[`bankroll_growth_target()`](https://johngavin.github.io/footbet/reference/bankroll_growth_target.md),
[`detect_flb()`](https://johngavin.github.io/footbet/reference/detect_flb.md),
[`estimate_league_strength()`](https://johngavin.github.io/footbet/reference/estimate_league_strength.md),
[`find_best_accas()`](https://johngavin.github.io/footbet/reference/find_best_accas.md),
[`generate_bias_alerts()`](https://johngavin.github.io/footbet/reference/generate_bias_alerts.md),
[`line_movement()`](https://johngavin.github.io/footbet/reference/line_movement.md),
[`multi_kelly_stakes()`](https://johngavin.github.io/footbet/reference/multi_kelly_stakes.md),
[`simulate_bankroll_growth()`](https://johngavin.github.io/footbet/reference/simulate_bankroll_growth.md),
[`standard_league_strengths()`](https://johngavin.github.io/footbet/reference/standard_league_strengths.md),
[`summarize_flb()`](https://johngavin.github.io/footbet/reference/summarize_flb.md)
