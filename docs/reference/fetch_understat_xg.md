# Fetch match xG data from Understat

Downloads expected goals (xG) data for a league-season from Understat.
Requires the `understatr` package.

## Usage

``` r
fetch_understat_xg(league, season)
```

## Arguments

- league:

  Character. League name: "EPL", "La_liga", "Bundesliga", "Serie_A",
  "Ligue_1", "RFPL" (Russian Premier League).

- season:

  Integer. Season start year (e.g., 2023 for 2023-24).

## Value

A tibble with match xG data.

## See also

Other data:
[`add_understat_xg()`](https://johngavin.github.io/footbet/reference/add_understat_xg.md),
[`join_understat_xg()`](https://johngavin.github.io/footbet/reference/join_understat_xg.md),
[`understat_team_mapping()`](https://johngavin.github.io/footbet/reference/understat_team_mapping.md)
