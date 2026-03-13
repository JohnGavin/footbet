# Compute meta-analytics for multiple statistics

Calculates discrimination and stability for a set of team/player
statistics, identifying which metrics are most useful for prediction.

## Usage

``` r
compute_meta_analytics(
  df,
  entity_col = "team",
  season_col = "season",
  stat_cols
)
```

## Arguments

- df:

  A data frame with entity, season, and multiple stat columns.

- entity_col:

  Character. Name of entity column.

- season_col:

  Character. Name of season column.

- stat_cols:

  Character vector. Names of statistic columns to analyze.

## Value

A tibble with `stat`, `discrimination`, `stability`.

## See also

Other meta-analytics:
[`stat_discrimination()`](https://johngavin.github.io/footbet/reference/stat_discrimination.md),
[`stat_stability()`](https://johngavin.github.io/footbet/reference/stat_stability.md)
