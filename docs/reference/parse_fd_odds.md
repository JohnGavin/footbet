# Parse Pinnacle odds columns from a football-data.co.uk CSV

Parse Pinnacle odds columns from a football-data.co.uk CSV

## Usage

``` r
parse_fd_odds(file_path, league_code, season)
```

## Arguments

- file_path:

  Character. Path to the CSV file.

- league_code:

  Character. League code.

- season:

  Character. Season code.

## Value

A tibble with match_id and Pinnacle odds columns.

## See also

Other data-acquisition:
[`download_all_fd()`](https://johngavin.github.io/footbet/reference/download_all_fd.md),
[`download_fd_csv()`](https://johngavin.github.io/footbet/reference/download_fd_csv.md),
[`fetch_fbref_all()`](https://johngavin.github.io/footbet/reference/fetch_fbref_all.md),
[`fetch_fbref_matches()`](https://johngavin.github.io/footbet/reference/fetch_fbref_matches.md),
[`fetch_league_injuries()`](https://johngavin.github.io/footbet/reference/fetch_league_injuries.md),
[`fetch_league_suspensions()`](https://johngavin.github.io/footbet/reference/fetch_league_suspensions.md),
[`fetch_league_transfers()`](https://johngavin.github.io/footbet/reference/fetch_league_transfers.md),
[`fetch_squad_values()`](https://johngavin.github.io/footbet/reference/fetch_squad_values.md),
[`join_xg_to_matches()`](https://johngavin.github.io/footbet/reference/join_xg_to_matches.md),
[`parse_fd_csv()`](https://johngavin.github.io/footbet/reference/parse_fd_csv.md)
