# Map Understat team names to football-data.co.uk names

Returns a named vector mapping Understat names to FD names. This is
necessary because team names differ between sources.

## Usage

``` r
understat_team_mapping(league)
```

## Arguments

- league:

  Character. League code ("E0", "E1", "D1", etc.).

## Value

Named character vector (Understat name -\> FD name).

## See also

Other data:
[`add_understat_xg()`](https://johngavin.github.io/footbet/reference/add_understat_xg.md),
[`fetch_understat_xg()`](https://johngavin.github.io/footbet/reference/fetch_understat_xg.md),
[`join_understat_xg()`](https://johngavin.github.io/footbet/reference/join_understat_xg.md)
