# Compute stakes for multiple bets using Kelly criterion

For simultaneous independent bets, computes Kelly fractions and
optionally normalizes if total exceeds a limit. Uses the existing
[`kelly_fraction()`](https://johngavin.github.io/footbet/reference/kelly_fraction.md)
from kelly.R.

## Usage

``` r
multi_kelly_stakes(probs, odds, fraction = 0.25, max_total = 0.2)
```

## Arguments

- probs:

  Numeric vector. Win probabilities for each bet.

- odds:

  Numeric vector. Decimal odds for each bet.

- fraction:

  Numeric. Fraction of full Kelly (default 0.25).

- max_total:

  Numeric. Maximum total stake as fraction of bankroll (default 0.2).

## Value

A tibble with `kelly`, `stake`, `normalized_stake`.

## See also

Other betting:
[`acca_ev()`](https://johngavin.github.io/footbet/reference/acca_ev.md),
[`acca_odds()`](https://johngavin.github.io/footbet/reference/acca_odds.md),
[`adjust_for_league_strength()`](https://johngavin.github.io/footbet/reference/adjust_for_league_strength.md),
[`analyze_steam_moves()`](https://johngavin.github.io/footbet/reference/analyze_steam_moves.md),
[`bankroll_growth_target()`](https://johngavin.github.io/footbet/reference/bankroll_growth_target.md),
[`detect_flb()`](https://johngavin.github.io/footbet/reference/detect_flb.md),
[`estimate_league_strength()`](https://johngavin.github.io/footbet/reference/estimate_league_strength.md),
[`find_best_accas()`](https://johngavin.github.io/footbet/reference/find_best_accas.md),
[`generate_bias_alerts()`](https://johngavin.github.io/footbet/reference/generate_bias_alerts.md),
[`line_movement()`](https://johngavin.github.io/footbet/reference/line_movement.md),
[`simulate_bankroll_growth()`](https://johngavin.github.io/footbet/reference/simulate_bankroll_growth.md),
[`standard_league_strengths()`](https://johngavin.github.io/footbet/reference/standard_league_strengths.md),
[`summarize_flb()`](https://johngavin.github.io/footbet/reference/summarize_flb.md)
