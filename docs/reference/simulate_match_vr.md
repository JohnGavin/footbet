# Monte Carlo simulation with variance reduction

Simulates match outcomes using stacked variance reduction techniques:
antithetic variates, control variates, and stratified sampling.

## Usage

``` r
simulate_match_vr(
  lambda_home,
  lambda_away,
  n_sims = 10000L,
  method = c("stacked", "crude", "antithetic", "control", "stratified"),
  seed = NULL
)
```

## Arguments

- lambda_home:

  Numeric. Expected home goals (Poisson rate).

- lambda_away:

  Numeric. Expected away goals (Poisson rate).

- n_sims:

  Integer. Number of simulations (default 10000).

- method:

  Character. Variance reduction method:

  - "crude": Plain Monte Carlo (baseline)

  - "antithetic": Antithetic variates (~50% variance reduction)

  - "control": Control variates using closed-form Poisson

  - "stratified": Stratified sampling

  - "stacked": All methods combined (best, default)

- seed:

  Integer. Random seed for reproducibility.

## Value

A list with:

- `prob_1x2`: Named vector c(H, D, A)

- `prob_ou`: Named vector c(over_25, under_25)

- `se`: Standard errors for each probability

- `n_sims`: Effective number of simulations

- `method`: Method used

- `variance_reduction`: Estimated variance reduction factor vs crude

## See also

Other simulation:
[`accumulator_probability()`](https://johngavin.github.io/footbet/reference/accumulator_probability.md),
[`importance_sample_rare()`](https://johngavin.github.io/footbet/reference/importance_sample_rare.md),
[`joint_outcome_probability()`](https://johngavin.github.io/footbet/reference/joint_outcome_probability.md),
[`simulate_correlated_matches()`](https://johngavin.github.io/footbet/reference/simulate_correlated_matches.md),
[`simulation`](https://johngavin.github.io/footbet/reference/simulation.md)
