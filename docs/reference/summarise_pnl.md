# Summarise P&L simulation results

Summarise P&L simulation results

## Usage

``` r
summarise_pnl(pnl_df, initial_bankroll = 1000)
```

## Arguments

- pnl_df:

  A tibble from
  [`simulate_pnl()`](https://johngavin.github.io/footbet/reference/simulate_pnl.md).

- initial_bankroll:

  Numeric. Starting bankroll for ROI calculation.

## Value

A tibble with summary statistics.

## See also

Other decisions:
[`apply_guardrails()`](https://johngavin.github.io/footbet/reference/apply_guardrails.md),
[`find_value_bets()`](https://johngavin.github.io/footbet/reference/find_value_bets.md),
[`identify_value_bet()`](https://johngavin.github.io/footbet/reference/identify_value_bet.md),
[`kelly_fraction()`](https://johngavin.github.io/footbet/reference/kelly_fraction.md),
[`simulate_pnl()`](https://johngavin.github.io/footbet/reference/simulate_pnl.md)
