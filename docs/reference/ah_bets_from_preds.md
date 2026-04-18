# Generate AH bets from any prediction dataframe

Generic function that takes model predictions (with or without lambdas),
builds DC score matrices, computes AH cover probabilities, and
identifies value bets against Pinnacle AH odds.

## Usage

``` r
ah_bets_from_preds(
  preds,
  odds,
  matches,
  rho = -0.13,
  min_edge = 0.03,
  use_kelly = FALSE,
  kelly_frac = 0.25,
  base_stake = 10
)
```

## Arguments

- preds:

  Tibble with `match_id`, `pred_h`, `pred_a`. Optionally `lambda_home`,
  `lambda_away` (if absent, reverse-engineered from probs).

- odds:

  Tibble with `match_id`, `ah_line`, `pahh`, `paha`.

- matches:

  Tibble with `match_id`, `fthg`, `ftag`, `ftr`.

- rho:

  Numeric. Dixon-Coles rho (default -0.13).

- min_edge:

  Numeric. Minimum edge to bet (default 0.03).

## Value

Tibble of AH bets with `match_id`, `market`, `edge`, `odds`, `won`,
`stake`, `net`.

## See also

Other decisions:
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
[`simulate_pnl()`](https://johngavin.github.io/footbet/reference/simulate_pnl.md),
[`summarise_ah_clv()`](https://johngavin.github.io/footbet/reference/summarise_ah_clv.md),
[`summarise_pnl()`](https://johngavin.github.io/footbet/reference/summarise_pnl.md)
