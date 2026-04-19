# Simulate betting P&L from a series of value bets

Processes bets in chronological order, applying Kelly staking with
drawdown guardrails. Returns the full P&L time series.

## Usage

``` r
simulate_pnl(
  bets,
  initial_bankroll = 1000,
  drawdown_threshold = 0.2,
  max_stake = 0.03
)
```

## Arguments

- bets:

  A tibble of value bets with `match_id`, `outcome`, `decimal_odds`,
  `kelly_stake`. Must also include `ftr` (actual result) and
  `match_date`.

- initial_bankroll:

  Numeric. Starting bankroll (default 1000).

- drawdown_threshold:

  Numeric. Drawdown to trigger halving (default 0.20).

- max_stake:

  Numeric. Max stake fraction (default 0.03).

## Value

A tibble with one row per bet: `match_id`, `match_date`, `outcome`,
`decimal_odds`, `stake_frac`, `stake_amount`, `pnl`, `bankroll`,
`peak_bankroll`, `drawdown`.

## See also

Other decisions:
[`apply_guardrails()`](https://johngavin.github.io/footbet/reference/apply_guardrails.md),
[`find_value_bets()`](https://johngavin.github.io/footbet/reference/find_value_bets.md),
[`identify_value_bet()`](https://johngavin.github.io/footbet/reference/identify_value_bet.md),
[`kelly_fraction()`](https://johngavin.github.io/footbet/reference/kelly_fraction.md),
[`summarise_pnl()`](https://johngavin.github.io/footbet/reference/summarise_pnl.md)
