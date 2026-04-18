# Compute PnL for a single bet

Compute PnL for a single bet

## Usage

``` r
oagd_pnl(stake, odds, won, transaction_cost = 0, slippage = 0)
```

## Arguments

- stake:

  Integer. Units staked (0, 1, or 2).

- odds:

  Numeric. Decimal odds for the outcome bet on.

- won:

  Logical. Whether the outcome occurred.

- transaction_cost:

  Numeric. Proportional cost on stake (default 0, e.g. 0.02 = 2%
  commission).

- slippage:

  Numeric. Proportional reduction in effective odds (default 0, e.g.
  0.01 = 1% worse than quoted).

## Value

Numeric. Profit/loss after costs.

## See also

Other decisions:
[`ah_bets_from_preds()`](https://johngavin.github.io/footbet/reference/ah_bets_from_preds.md),
[`apply_guardrails()`](https://johngavin.github.io/footbet/reference/apply_guardrails.md),
[`attach_clv()`](https://johngavin.github.io/footbet/reference/attach_clv.md),
[`clv`](https://johngavin.github.io/footbet/reference/clv.md),
[`expanding_clv_window()`](https://johngavin.github.io/footbet/reference/expanding_clv_window.md),
[`find_value_bets()`](https://johngavin.github.io/footbet/reference/find_value_bets.md),
[`identify_value_bet()`](https://johngavin.github.io/footbet/reference/identify_value_bet.md),
[`kelly_fraction()`](https://johngavin.github.io/footbet/reference/kelly_fraction.md),
[`load_closing_ah_prices()`](https://johngavin.github.io/footbet/reference/load_closing_ah_prices.md),
[`oagd_backtest`](https://johngavin.github.io/footbet/reference/oagd_backtest.md),
[`oagd_backtest_league()`](https://johngavin.github.io/footbet/reference/oagd_backtest_league.md),
[`oagd_backtest_summary()`](https://johngavin.github.io/footbet/reference/oagd_backtest_summary.md),
[`oagd_edge()`](https://johngavin.github.io/footbet/reference/oagd_edge.md),
[`oagd_grid()`](https://johngavin.github.io/footbet/reference/oagd_grid.md),
[`oagd_stake()`](https://johngavin.github.io/footbet/reference/oagd_stake.md),
[`simulate_pnl()`](https://johngavin.github.io/footbet/reference/simulate_pnl.md),
[`summarise_ah_clv()`](https://johngavin.github.io/footbet/reference/summarise_ah_clv.md),
[`summarise_pnl()`](https://johngavin.github.io/footbet/reference/summarise_pnl.md)
