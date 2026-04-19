# Apply drawdown guardrails to stake

Halves the stake when cumulative drawdown exceeds threshold.

## Usage

``` r
apply_guardrails(
  stake,
  current_bankroll,
  peak_bankroll,
  drawdown_threshold = 0.2,
  max_stake = 0.03
)
```

## Arguments

- stake:

  Numeric. Proposed stake fraction.

- current_bankroll:

  Numeric. Current bankroll.

- peak_bankroll:

  Numeric. Peak bankroll reached.

- drawdown_threshold:

  Numeric. Drawdown level to trigger halving (default 0.20 = 20%).

- max_stake:

  Numeric. Maximum stake as fraction of bankroll (default 0.03 = 3%).

## Value

Numeric. Adjusted stake fraction.

## See also

Other decisions:
[`find_value_bets()`](https://johngavin.github.io/footbet/reference/find_value_bets.md),
[`identify_value_bet()`](https://johngavin.github.io/footbet/reference/identify_value_bet.md),
[`kelly_fraction()`](https://johngavin.github.io/footbet/reference/kelly_fraction.md),
[`simulate_pnl()`](https://johngavin.github.io/footbet/reference/simulate_pnl.md),
[`summarise_pnl()`](https://johngavin.github.io/footbet/reference/summarise_pnl.md)
