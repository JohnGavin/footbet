# Closing Line Value (CLV) diagnostics for Asian Handicap bets

Implements the standard sharp-bettor CLV test: for each bet the model
would place at the Pinnacle pre-match price (`pahh`), compare against
the market closing price (`AvgCAHH`) from football-data.co.uk. Positive
mean CLV implies the model is finding edges that the market eventually
prices in; mean CLV near zero implies market efficiency; negative CLV
implies the model is actively worse than the close.

## Details

Note: football-data.co.uk does NOT publish a Pinnacle-specific closing
AH column. `AvgCAHH`/`AvgCAHA` is the market average closing AH price
and is used as the honest close proxy. Limitation documented in
`plans/MODEL_CATALOGUE.md`.

## See also

Other decisions:
[`ah_bets_from_preds()`](https://johngavin.github.io/footbet/reference/ah_bets_from_preds.md),
[`apply_guardrails()`](https://johngavin.github.io/footbet/reference/apply_guardrails.md),
[`attach_clv()`](https://johngavin.github.io/footbet/reference/attach_clv.md),
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
