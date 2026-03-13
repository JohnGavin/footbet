# Fetch match-level xG data from FBref

Downloads match results including expected goals (xG) from FBref via
worldfootballR. Rate limiting is applied to respect FBref ToS.

## Usage

``` r
fetch_fbref_matches(country, season_end, gender = "M", tier = "1st")
```

## Arguments

- country:

  Character. Country code: "ENG", "ESP", "GER", "ITA", "FRA".

- season_end:

  Integer. Season end year (e.g., 2024 for 2023-24).

- gender:

  Character. "M" for men's (default), "F" for women's.

- tier:

  Character. League tier, default "1st".

## Value

A tibble with match results and xG data.

## See also

Other data-acquisition:
[`download_all_fd()`](https://johngavin.github.io/footbet/reference/download_all_fd.md),
[`download_fd_csv()`](https://johngavin.github.io/footbet/reference/download_fd_csv.md),
[`fetch_fbref_all()`](https://johngavin.github.io/footbet/reference/fetch_fbref_all.md),
[`fetch_league_injuries()`](https://johngavin.github.io/footbet/reference/fetch_league_injuries.md),
[`fetch_league_suspensions()`](https://johngavin.github.io/footbet/reference/fetch_league_suspensions.md),
[`fetch_league_transfers()`](https://johngavin.github.io/footbet/reference/fetch_league_transfers.md),
[`fetch_squad_values()`](https://johngavin.github.io/footbet/reference/fetch_squad_values.md),
[`join_xg_to_matches()`](https://johngavin.github.io/footbet/reference/join_xg_to_matches.md),
[`parse_fd_csv()`](https://johngavin.github.io/footbet/reference/parse_fd_csv.md),
[`parse_fd_odds()`](https://johngavin.github.io/footbet/reference/parse_fd_odds.md)
