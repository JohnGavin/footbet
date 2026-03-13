# Compute accumulator (parlay) probability with correlation

Compute accumulator (parlay) probability with correlation

## Usage

``` r
accumulator_probability(matches, correlation = 0.1, n_sims = 10000L)
```

## Arguments

- matches:

  A tibble with `match_id`, `lambda_home`, `lambda_away`, and `bet`
  columns. `bet` should be "H", "D", or "A" for each leg.

- correlation:

  Numeric. Inter-match correlation.

- n_sims:

  Integer. Number of simulations.

## Value

A list with:

- `prob_independent`: Probability assuming independence

- `prob_correlated`: Probability accounting for correlation

- `correlation_impact`: Ratio of correlated to independent

## See also

Other simulation:
[`importance_sample_rare()`](https://johngavin.github.io/footbet/reference/importance_sample_rare.md),
[`joint_outcome_probability()`](https://johngavin.github.io/footbet/reference/joint_outcome_probability.md),
[`simulate_correlated_matches()`](https://johngavin.github.io/footbet/reference/simulate_correlated_matches.md),
[`simulate_match_vr()`](https://johngavin.github.io/footbet/reference/simulate_match_vr.md),
[`simulation`](https://johngavin.github.io/footbet/reference/simulation.md)
