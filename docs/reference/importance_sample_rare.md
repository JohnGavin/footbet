# Importance sampling for rare match outcomes

Estimates probabilities of rare events (e.g., 8+ goals, exact scoreline)
with much lower variance than crude Monte Carlo.

## Usage

``` r
importance_sample_rare(
  lambda_home,
  lambda_away,
  outcome,
  n_sims = 10000L,
  tilt = "auto"
)
```

## Arguments

- lambda_home:

  Numeric. Expected home goals.

- lambda_away:

  Numeric. Expected away goals.

- outcome:

  Character. Outcome to estimate:

  - "over_X" (e.g., "over_5.5", "over_7.5")

  - "exact_HH_AA" (e.g., "exact_5_3")

  - "home_X+" (e.g., "home_4+")

- n_sims:

  Integer. Number of importance samples.

- tilt:

  Numeric or "auto". Exponential tilting parameter. Higher values focus
  samples on rare events. "auto" estimates optimal tilt.

## Value

A list with:

- `probability`: Estimated probability

- `se`: Standard error

- `effective_n`: Effective sample size (lower if weights are uneven)

- `variance_reduction`: Factor vs crude MC

## See also

Other simulation:
[`accumulator_probability()`](https://johngavin.github.io/footbet/reference/accumulator_probability.md),
[`joint_outcome_probability()`](https://johngavin.github.io/footbet/reference/joint_outcome_probability.md),
[`simulate_correlated_matches()`](https://johngavin.github.io/footbet/reference/simulate_correlated_matches.md),
[`simulate_match_vr()`](https://johngavin.github.io/footbet/reference/simulate_match_vr.md),
[`simulation`](https://johngavin.github.io/footbet/reference/simulation.md)
