# Fetch league suspensions from Transfermarkt

Downloads the list of currently suspended players in a league (yellow
card accumulations, red cards, etc.).

## Usage

``` r
fetch_league_suspensions(country, start_year = 2024L)
```

## Arguments

- country:

  Character. Country name (e.g. "England").

- start_year:

  Integer. Season start year.

## Value

A tibble of suspended players with columns: `player_name`, `team`,
`position`, `suspension_type`, `games_remaining`, `market_value_eur`.

## See also

Other data-acquisition:
[`download_all_fd()`](https://johngavin.github.io/footbet/reference/download_all_fd.md),
[`download_fd_csv()`](https://johngavin.github.io/footbet/reference/download_fd_csv.md),
[`fetch_fbref_all()`](https://johngavin.github.io/footbet/reference/fetch_fbref_all.md),
[`fetch_fbref_matches()`](https://johngavin.github.io/footbet/reference/fetch_fbref_matches.md),
[`fetch_league_injuries()`](https://johngavin.github.io/footbet/reference/fetch_league_injuries.md),
[`fetch_league_transfers()`](https://johngavin.github.io/footbet/reference/fetch_league_transfers.md),
[`fetch_squad_values()`](https://johngavin.github.io/footbet/reference/fetch_squad_values.md),
[`join_xg_to_matches()`](https://johngavin.github.io/footbet/reference/join_xg_to_matches.md),
[`parse_fd_csv()`](https://johngavin.github.io/footbet/reference/parse_fd_csv.md),
[`parse_fd_odds()`](https://johngavin.github.io/footbet/reference/parse_fd_odds.md)
