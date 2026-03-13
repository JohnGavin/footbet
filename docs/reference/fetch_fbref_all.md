# Fetch FBref data for multiple leagues and seasons

Batch fetches xG data with rate limiting to respect FBref ToS.

## Usage

``` r
fetch_fbref_all(
  leagues = c("ENG", "ESP", "GER", "ITA", "FRA"),
  seasons = 2018:2024,
  delay = 5
)
```

## Arguments

- leagues:

  Character vector of country/league codes.

- seasons:

  Integer vector of season end years.

- delay:

  Numeric. Seconds to pause between requests (default 5).

## Value

A tibble with all matches combined.

## See also

Other data-acquisition:
[`download_all_fd()`](https://johngavin.github.io/footbet/reference/download_all_fd.md),
[`download_fd_csv()`](https://johngavin.github.io/footbet/reference/download_fd_csv.md),
[`fetch_fbref_matches()`](https://johngavin.github.io/footbet/reference/fetch_fbref_matches.md),
[`fetch_league_injuries()`](https://johngavin.github.io/footbet/reference/fetch_league_injuries.md),
[`fetch_league_suspensions()`](https://johngavin.github.io/footbet/reference/fetch_league_suspensions.md),
[`fetch_league_transfers()`](https://johngavin.github.io/footbet/reference/fetch_league_transfers.md),
[`fetch_squad_values()`](https://johngavin.github.io/footbet/reference/fetch_squad_values.md),
[`join_xg_to_matches()`](https://johngavin.github.io/footbet/reference/join_xg_to_matches.md),
[`parse_fd_csv()`](https://johngavin.github.io/footbet/reference/parse_fd_csv.md),
[`parse_fd_odds()`](https://johngavin.github.io/footbet/reference/parse_fd_odds.md)
