# Compute stability meta-metric for a statistic

Stability measures how consistently a statistic persists across seasons
for the same team/player. Higher stability means the stat is more
predictable year-over-year.

## Usage

``` r
stat_stability(
  df,
  entity_col = "team",
  value_col = "value",
  season_col = "season"
)
```

## Arguments

- df:

  A data frame with columns: `team` (or `player`), `season`, `value`.

- entity_col:

  Character. Name of entity column (default "team").

- value_col:

  Character. Name of value column (default "value").

- season_col:

  Character. Name of season column (default "season").

## Value

Numeric. Stability coefficient (correlation, 0-1).

## Details

Calculated as the year-over-year correlation.

## See also

Other meta-analytics:
[`compute_meta_analytics()`](https://johngavin.github.io/footbet/reference/compute_meta_analytics.md),
[`stat_discrimination()`](https://johngavin.github.io/footbet/reference/stat_discrimination.md)
