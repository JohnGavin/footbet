# Simulate betting P&L from a series of value bets

Processes bets in chronological order with configurable staking
strategy. Supports Kelly compounding, flat stakes, or tiered staking by
predicted edge.

## Usage

``` r
simulate_pnl(
  bets,
  initial_bankroll = 1000,
  drawdown_threshold = 0.2,
  max_stake = 0.03,
  transaction_cost = 0,
  max_bankroll = Inf,
  slippage = 0,
  stake_mode = c("kelly", "flat", "tiered"),
  flat_stake = 10,
  edge_tiers = c(0.03, 0.05, 0.08, 0.12),
  tier_stakes = c(5, 10, 15, 20, 25)
)
```

## Arguments

- bets:

  A tibble of value bets with `match_id`, `outcome`, `decimal_odds`,
  `kelly_stake`, `edge`. Must also include `ftr` (actual result) and
  `match_date`.

- initial_bankroll:

  Numeric. Starting bankroll (default 1000).

- drawdown_threshold:

  Numeric. Drawdown to trigger halving (default 0.20).

- max_stake:

  Numeric. Max stake fraction (default 0.03).

- transaction_cost:

  Numeric 0-1. Cost per bet as fraction of stake (default 0).

- max_bankroll:

  Numeric. Cap effective bankroll for stake calc (default Inf).

- slippage:

  Numeric 0-1. Reduce odds by this fraction (default 0).

- stake_mode:

  Character. `"kelly"` (compounding), `"flat"` (fixed amount), or
  `"tiered"` (variable stake by predicted edge).

- flat_stake:

  Numeric. Fixed stake per bet in flat mode (default 10).

- edge_tiers:

  Numeric vector. Edge breakpoints for tiered mode (default
  `c(0.03, 0.05, 0.08, 0.12)`). Bets with edge \< 0.03 get the lowest
  tier, edge 0.03-0.05 the next, etc.

- tier_stakes:

  Numeric vector. Stake per tier (default `c(5, 10, 15, 20, 25)`). Must
  be one element longer than `edge_tiers`.

## Value

A tibble with one row per bet: `match_id`, `match_date`, `outcome`,
`decimal_odds`, `stake_frac`, `stake_amount`, `pnl`, `bankroll`,
`peak_bankroll`, `drawdown`.

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
[`oagd_pnl()`](https://johngavin.github.io/footbet/reference/oagd_pnl.md),
[`oagd_stake()`](https://johngavin.github.io/footbet/reference/oagd_stake.md),
[`summarise_ah_clv()`](https://johngavin.github.io/footbet/reference/summarise_ah_clv.md),
[`summarise_pnl()`](https://johngavin.github.io/footbet/reference/summarise_pnl.md)
