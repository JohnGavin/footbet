# Calculate fractional Kelly stake

Computes the Kelly criterion fraction for a single bet, scaled by a
fractional multiplier (default quarter Kelly).

## Usage

``` r
kelly_fraction(prob_win, decimal_odds, fraction = 0.25, max_stake_pct = 0.05)
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
[`ah_bets_from_preds()`](https://johngavin.github.io/footbet/reference/ah_bets_from_preds.md),
[`apply_guardrails()`](https://johngavin.github.io/footbet/reference/apply_guardrails.md),
[`attach_clv()`](https://johngavin.github.io/footbet/reference/attach_clv.md),
[`clv`](https://johngavin.github.io/footbet/reference/clv.md),
[`expanding_clv_window()`](https://johngavin.github.io/footbet/reference/expanding_clv_window.md),
[`find_value_bets()`](https://johngavin.github.io/footbet/reference/find_value_bets.md),
[`identify_value_bet()`](https://johngavin.github.io/footbet/reference/identify_value_bet.md),
[`load_closing_ah_prices()`](https://johngavin.github.io/footbet/reference/load_closing_ah_prices.md),
[`oagd_backtest`](https://johngavin.github.io/footbet/reference/oagd_backtest.md),
[`oagd_backtest_league()`](https://johngavin.github.io/footbet/reference/oagd_backtest_league.md),
[`oagd_backtest_summary()`](https://johngavin.github.io/footbet/reference/oagd_backtest_summary.md),
[`oagd_edge()`](https://johngavin.github.io/footbet/reference/oagd_edge.md),
[`oagd_grid()`](https://johngavin.github.io/footbet/reference/oagd_grid.md),
[`oagd_pnl()`](https://johngavin.github.io/footbet/reference/oagd_pnl.md),
[`oagd_stake()`](https://johngavin.github.io/footbet/reference/oagd_stake.md),
[`simulate_pnl()`](https://johngavin.github.io/footbet/reference/simulate_pnl.md),
[`summarise_ah_clv()`](https://johngavin.github.io/footbet/reference/summarise_ah_clv.md),
[`summarise_pnl()`](https://johngavin.github.io/footbet/reference/summarise_pnl.md)
