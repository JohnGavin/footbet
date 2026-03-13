# Simulate correlated match outcomes using Gaussian copula

Models dependence between multiple matches using a Gaussian copula. This
captures scenarios where upsets tend to cluster (e.g., bad weather day,
referee inconsistency across matches).

## Usage

``` r
simulate_correlated_matches(
  matches,
  correlation = 0.1,
  n_sims = 5000L,
  seed = NULL
)
```

## Arguments

- matches:

  A tibble with columns:

  - `match_id`: Unique identifier

  - `lambda_home`: Expected home goals

  - `lambda_away`: Expected away goals

- correlation:

  Numeric or matrix. If scalar, uses equicorrelation. If matrix, must be
  valid correlation matrix of size (2 \* n_matches).

- n_sims:

  Integer. Number of joint simulations.

- seed:

  Integer. Random seed.

## Value

A tibble with simulated outcomes for all matches:

- `sim_id`: Simulation index

- `match_id`: Match identifier

- `home_goals`, `away_goals`: Simulated scores

- `result`: "H", "D", or "A"

## See also

Other simulation:
[`accumulator_probability()`](https://johngavin.github.io/footbet/reference/accumulator_probability.md),
[`importance_sample_rare()`](https://johngavin.github.io/footbet/reference/importance_sample_rare.md),
[`joint_outcome_probability()`](https://johngavin.github.io/footbet/reference/joint_outcome_probability.md),
[`simulate_match_vr()`](https://johngavin.github.io/footbet/reference/simulate_match_vr.md),
[`simulation`](https://johngavin.github.io/footbet/reference/simulation.md)
