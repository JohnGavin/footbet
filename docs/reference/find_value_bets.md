# Find value bets across all matches for 1X2 market

Scans model predictions against devigged odds to find bets where the
model edge exceeds the minimum threshold.

## Usage

``` r
find_value_bets(
  preds,
  devigged,
  odds,
  min_edge = 0.03,
  min_odds = 1.5,
  max_odds = 10
)
```

## Arguments

- preds:

  A tibble with `match_id`, `pred_h`, `pred_d`, `pred_a`.

- devigged:

  A tibble with `match_id`, `fair_h`, `fair_d`, `fair_a`.

- odds:

  A tibble with `match_id`, `psh`, `psd`, `psa` (raw Pinnacle decimal
  odds).

- min_edge:

  Numeric. Minimum edge (default 0.03).

- min_odds:

  Numeric. Minimum odds (default 1.50).

- max_odds:

  Numeric. Maximum odds (default 10.0).

## Value

A tibble of value bets with columns: `match_id`, `outcome`,
`model_prob`, `market_prob`, `decimal_odds`, `edge`, `kelly_stake`.

## See also

Other decisions:
[`apply_guardrails()`](https://johngavin.github.io/footbet/reference/apply_guardrails.md),
[`identify_value_bet()`](https://johngavin.github.io/footbet/reference/identify_value_bet.md),
[`kelly_fraction()`](https://johngavin.github.io/footbet/reference/kelly_fraction.md),
[`simulate_pnl()`](https://johngavin.github.io/footbet/reference/simulate_pnl.md),
[`summarise_pnl()`](https://johngavin.github.io/footbet/reference/summarise_pnl.md)
