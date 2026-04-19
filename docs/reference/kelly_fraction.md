# Calculate fractional Kelly stake

Computes the Kelly criterion fraction for a single bet, scaled by a
fractional multiplier (default quarter Kelly).

## Usage

``` r
kelly_fraction(prob_win, decimal_odds, fraction = 0.25)
```

## Arguments

- prob_win:

  Numeric. Model probability of winning the bet.

- decimal_odds:

  Numeric. Decimal odds offered.

- fraction:

  Numeric. Kelly fraction (default 0.25 = quarter Kelly).

## Value

Numeric. Recommended stake as a fraction of bankroll. Returns 0 if there
is no edge.

## See also

Other decisions:
[`apply_guardrails()`](https://johngavin.github.io/footbet/reference/apply_guardrails.md),
[`find_value_bets()`](https://johngavin.github.io/footbet/reference/find_value_bets.md),
[`identify_value_bet()`](https://johngavin.github.io/footbet/reference/identify_value_bet.md),
[`simulate_pnl()`](https://johngavin.github.io/footbet/reference/simulate_pnl.md),
[`summarise_pnl()`](https://johngavin.github.io/footbet/reference/summarise_pnl.md)
