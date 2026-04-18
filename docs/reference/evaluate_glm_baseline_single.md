# Walk-forward GLM evaluation for a single league

Internal workhorse called by
[`evaluate_glm_baseline()`](https://johngavin.github.io/footbet/reference/evaluate_glm_baseline.md)
per league. Splitting by league keeps the design matrix small (~40 cols
vs ~444).

## Usage

``` r
evaluate_glm_baseline_single(
  long_df,
  matches_df,
  train_months = 24L,
  test_months = 1L
)
```

## Arguments

- long_df:

  Long-format match data from
  [`matches_to_long()`](https://johngavin.github.io/footbet/reference/matches_to_long.md).

- matches_df:

  Original match data (wide format) with `match_id`, `ftr`.

- train_months:

  Integer. Training window (default 24).

- test_months:

  Integer. Test period (default 1).

## Value

A tibble with one row per fold.
