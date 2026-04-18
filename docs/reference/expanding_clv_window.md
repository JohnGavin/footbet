# Expanding-window devigged CLV with baseline comparison

Produces cumulative devigged CLV through each season in the validation
window, for a model bet tibble and an unselected same-line baseline.
Reveals whether a model's excess CLV is stable as the sample grows (real
signal) or shrinks (noise, regime artefact).

## Usage

``` r
expanding_clv_window(bets, odds, closing, scenario, seasons)
```

## Arguments

- bets:

  Tibble from
  [`ah_bets_from_preds()`](https://johngavin.github.io/footbet/reference/ah_bets_from_preds.md)
  with `match_id`. Can be empty to produce a baseline-only result.

- odds:

  Tibble with `match_id`, `pahh`, `paha`, `ah_line`.

- closing:

  Tibble from
  [`load_closing_ah_prices()`](https://johngavin.github.io/footbet/reference/load_closing_ah_prices.md)
  with `pcahh`, `pcaha`, `ah_line_close`.

- scenario:

  Character label for the bet tibble.

- seasons:

  Character vector of validation seasons to iterate through (e.g.
  `c("2020-21","2021-22","2022-23")`). Each row of the output is
  cumulative through `seasons[1:k]`.

## Value

Tibble with one row per cumulative-through-season per scenario, plus a
matched-seasons baseline row per cumulative window. Columns include
`n_bets`, `devig_clv_pp`, `devig_clv_ci_lo`/`hi`, `devig_excess_pp`
(scenario minus matched baseline), `decimal_clv_pct` for reference.

## Details

Devigging strips Pinnacle's vig from both opening and closing pair
prices via multiplicative normalisation: `fair = (1/p) / (1/pH + 1/pA)`.
The per-match devigged CLV is `fair_close_home - fair_open_home`,
expressed in probability points.

## See also

Other decisions:
[`ah_bets_from_preds()`](https://johngavin.github.io/footbet/reference/ah_bets_from_preds.md),
[`apply_guardrails()`](https://johngavin.github.io/footbet/reference/apply_guardrails.md),
[`attach_clv()`](https://johngavin.github.io/footbet/reference/attach_clv.md),
[`clv`](https://johngavin.github.io/footbet/reference/clv.md),
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
