# Compute discrimination meta-metric for a statistic

Discrimination measures how well a statistic separates good from bad
teams/players within a single season. Higher discrimination means the
stat is more useful for ranking.

## Usage

``` r
stat_discrimination(df, entity_col = "team", value_col = "value")
```

## Arguments

- df:

  A data frame with columns: `team` (or `player`), `season`, `value`.

- entity_col:

  Character. Name of entity column (default "team").

- value_col:

  Character. Name of value column (default "value").

## Value

Numeric. Discrimination coefficient (0-1, higher = better).

## Details

Calculated as: 1 - (within-group variance / total variance) or
equivalently, the ICC (intraclass correlation coefficient).

## References

Franks, A., D'Amour, A., Cervone, D., & Bornn, L. (2016).
Meta-Analytics: Tools for Understanding the Statistical Properties of
Sports Metrics.

## See also

Other meta-analytics:
[`compute_meta_analytics()`](https://johngavin.github.io/footbet/reference/compute_meta_analytics.md),
[`stat_stability()`](https://johngavin.github.io/footbet/reference/stat_stability.md)
