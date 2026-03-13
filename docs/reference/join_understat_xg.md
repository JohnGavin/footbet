# Join Understat xG to match data

Matches Understat xG data to football-data.co.uk matches by date and
team names, applying name mappings as needed.

## Usage

``` r
join_understat_xg(matches_df, understat_df, league_code = "E0")
```

## Arguments

- matches_df:

  A tibble of match data with `match_date`, `home_team`, `away_team`.

- understat_df:

  A tibble from
  [`fetch_understat_xg()`](https://johngavin.github.io/footbet/reference/fetch_understat_xg.md).

- league_code:

  Character. League code for team name mapping.

## Value

The matches_df with `understat_home_xg`, `understat_away_xg` columns.

## See also

Other data:
[`add_understat_xg()`](https://johngavin.github.io/footbet/reference/add_understat_xg.md),
[`fetch_understat_xg()`](https://johngavin.github.io/footbet/reference/fetch_understat_xg.md),
[`understat_team_mapping()`](https://johngavin.github.io/footbet/reference/understat_team_mapping.md)
