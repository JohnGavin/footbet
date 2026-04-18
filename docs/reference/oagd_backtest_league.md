# Run OAGD backtest for one league-season

Fits the rolling model, computes predictions, identifies value bets, and
returns PnL for each bet placed.

## Usage

``` r
oagd_backtest_league(
  data,
  odds_data,
  window = 8L,
  K = 4L,
  half_life = 2,
  beta = 0.3,
  tau_min = 0.05,
  tau_double = 0.1,
  exclude_draws = TRUE,
  transaction_cost = 0.02,
  slippage = 0.01
)
```

## Arguments

- data:

  Tibble from
  [`oagd_match_data()`](https://johngavin.github.io/footbet/reference/oagd_match_data.md),
  one league-season.

- odds_data:

  Tibble from
  [`oagd_add_odds()`](https://johngavin.github.io/footbet/reference/oagd_add_odds.md)
  (same matches).

- window:

  Integer. Rolling window size (default 8).

- K:

  Integer. Form lookback (default 4).

- half_life:

  Numeric. Form half-life (default 2).

- beta:

  Numeric. Form weight (default 0.3).

- tau_min:

  Numeric. Min edge to bet (default 0.05).

- tau_double:

  Numeric. Edge for double stake (default 0.10).

- exclude_draws:

  Logical. If `TRUE`, skip draw bets entirely (default `TRUE` — Skellam
  overestimates draws, see \#78).

- transaction_cost:

  Numeric. Proportional cost on stake (default 0.02).

- slippage:

  Numeric. Proportional odds reduction (default 0.01).

## Value

A tibble of bets placed, with columns: `match_id`, `season`,
`league_code`, `matchday`, `outcome_bet` (H/D/A), `model_prob`,
`implied_prob`, `edge`, `stake`, `odds`, `won`, `pnl`.

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
[`oagd_backtest_summary()`](https://johngavin.github.io/footbet/reference/oagd_backtest_summary.md),
[`oagd_edge()`](https://johngavin.github.io/footbet/reference/oagd_edge.md),
[`oagd_grid()`](https://johngavin.github.io/footbet/reference/oagd_grid.md),
[`oagd_pnl()`](https://johngavin.github.io/footbet/reference/oagd_pnl.md),
[`oagd_stake()`](https://johngavin.github.io/footbet/reference/oagd_stake.md),
[`simulate_pnl()`](https://johngavin.github.io/footbet/reference/simulate_pnl.md),
[`summarise_ah_clv()`](https://johngavin.github.io/footbet/reference/summarise_ah_clv.md),
[`summarise_pnl()`](https://johngavin.github.io/footbet/reference/summarise_pnl.md)
