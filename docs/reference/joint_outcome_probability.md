# Compute joint outcome probabilities from correlated simulations

Compute joint outcome probabilities from correlated simulations

## Usage

``` r
joint_outcome_probability(sims, outcomes)
```

## Arguments

- sims:

  Output from
  [`simulate_correlated_matches()`](https://johngavin.github.io/footbet/reference/simulate_correlated_matches.md).

- outcomes:

  Character vector of outcomes per match (e.g., c("H", "D", "A")).

## Value

Probability that all specified outcomes occur jointly.

## See also

Other simulation:
[`accumulator_probability()`](https://johngavin.github.io/footbet/reference/accumulator_probability.md),
[`importance_sample_rare()`](https://johngavin.github.io/footbet/reference/importance_sample_rare.md),
[`simulate_correlated_matches()`](https://johngavin.github.io/footbet/reference/simulate_correlated_matches.md),
[`simulate_match_vr()`](https://johngavin.github.io/footbet/reference/simulate_match_vr.md),
[`simulation`](https://johngavin.github.io/footbet/reference/simulation.md)
