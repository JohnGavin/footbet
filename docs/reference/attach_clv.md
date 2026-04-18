# Attach closing AH prices and compute per-bet CLV

Joins a bet tibble (from
[`ah_bets_from_preds()`](https://johngavin.github.io/footbet/reference/ah_bets_from_preds.md))
to the closing AH price table and computes per-bet Closing Line Value
and a beat-the-close flag. All AH bets in the codebase are home-side
only, so the home closing average (`avg_cahh`) is the reference.

## Usage

``` r
attach_clv(bets, closing, benchmark = c("pcahh", "avg_cahh"))
```

## Arguments

- bets:

  Tibble from
  [`ah_bets_from_preds()`](https://johngavin.github.io/footbet/reference/ah_bets_from_preds.md).
  Must contain `match_id` and `odds` (the price the bet was placed at).

- closing:

  Tibble from
  [`load_closing_ah_prices()`](https://johngavin.github.io/footbet/reference/load_closing_ah_prices.md).

- benchmark:

  One of `"pcahh"` (Pinnacle closing AH — true sharp close,
  **preferred**) or `"avg_cahh"` (market average closing AH — looser,
  confounded by Pinnacle's tighter margin). Default `"pcahh"`.

## Value

`bets` with extra columns: `close_price`, `clv`, `beat_close`,
`benchmark` (label).

## See also

Other decisions:
[`ah_bets_from_preds()`](https://johngavin.github.io/footbet/reference/ah_bets_from_preds.md),
[`apply_guardrails()`](https://johngavin.github.io/footbet/reference/apply_guardrails.md),
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
[`simulate_pnl()`](https://johngavin.github.io/footbet/reference/simulate_pnl.md),
[`summarise_ah_clv()`](https://johngavin.github.io/footbet/reference/summarise_ah_clv.md),
[`summarise_pnl()`](https://johngavin.github.io/footbet/reference/summarise_pnl.md)
