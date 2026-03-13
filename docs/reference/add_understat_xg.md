# Fetch and join Understat xG for multiple seasons

Convenience function to fetch Understat data for multiple seasons and
join to match data.

## Usage

``` r
add_understat_xg(matches_df, understat_league, seasons, fd_league_code = "E0")
```

## Arguments

- matches_df:

  A tibble of match data.

- understat_league:

  Character. Understat league name.

- seasons:

  Integer vector. Season start years.

- fd_league_code:

  Character. Football-data.co.uk league code.

## Value

The matches_df with Understat xG columns.

## See also

Other data:
[`fetch_understat_xg()`](https://johngavin.github.io/footbet/reference/fetch_understat_xg.md),
[`join_understat_xg()`](https://johngavin.github.io/footbet/reference/join_understat_xg.md),
[`understat_team_mapping()`](https://johngavin.github.io/footbet/reference/understat_team_mapping.md)
