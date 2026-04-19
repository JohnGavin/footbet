# Identify value bets from model vs market probabilities

Compares model-predicted probabilities to devigged market probabilities
and flags bets with sufficient edge.

## Usage

``` r
identify_value_bet(
  model_prob,
  market_prob,
  decimal_odds,
  min_edge = 0.03,
  min_odds = 1.5,
  max_odds = 10
)
```

## Arguments

- model_prob:

  Numeric. Model probability.

- market_prob:

  Numeric. Devigged market probability.

- decimal_odds:

  Numeric. Available decimal odds.

- min_edge:

  Numeric. Minimum edge to consider (default 0.03 = 3%).

- min_odds:

  Numeric. Minimum acceptable odds (default 1.50).

- max_odds:

  Numeric. Maximum acceptable odds (default 10.0).

## Value

A list with `is_value`, `edge`, `kelly_stake`.

## See also

Other decisions:
[`apply_guardrails()`](https://johngavin.github.io/footbet/reference/apply_guardrails.md),
[`find_value_bets()`](https://johngavin.github.io/footbet/reference/find_value_bets.md),
[`kelly_fraction()`](https://johngavin.github.io/footbet/reference/kelly_fraction.md),
[`simulate_pnl()`](https://johngavin.github.io/footbet/reference/simulate_pnl.md),
[`summarise_pnl()`](https://johngavin.github.io/footbet/reference/summarise_pnl.md)
