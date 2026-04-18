# Fetch FBref passing + shooting match logs for multiple league-seasons

Batch fetches match-level team stats for progressive passes, carries,
PSxG, and passes into penalty area. Rate-limited to respect FBref ToS.

## Usage

``` r
fetch_fbref_advanced_all(
  leagues = c("ENG", "ESP", "GER", "ITA", "FRA"),
  seasons = 2018:2025,
  delay = 5
)
```

## Arguments

- leagues:

  Character vector of country codes.

- seasons:

  Integer vector of season end years.

- delay:

  Numeric. Seconds between team requests (default 5).

## Value

A list with `passing` and `shooting` tibbles.

## See also

Other data-acquisition:
[`download_all_fd()`](https://johngavin.github.io/footbet/reference/download_all_fd.md),
[`download_fd_csv()`](https://johngavin.github.io/footbet/reference/download_fd_csv.md),
[`fetch_fbref_all()`](https://johngavin.github.io/footbet/reference/fetch_fbref_all.md),
[`fetch_fbref_matches()`](https://johngavin.github.io/footbet/reference/fetch_fbref_matches.md),
[`fetch_fbref_season_stats()`](https://johngavin.github.io/footbet/reference/fetch_fbref_season_stats.md),
[`fetch_fbref_team_match_logs()`](https://johngavin.github.io/footbet/reference/fetch_fbref_team_match_logs.md),
[`fetch_league_injuries()`](https://johngavin.github.io/footbet/reference/fetch_league_injuries.md),
[`fetch_league_suspensions()`](https://johngavin.github.io/footbet/reference/fetch_league_suspensions.md),
[`fetch_league_transfers()`](https://johngavin.github.io/footbet/reference/fetch_league_transfers.md),
[`fetch_squad_values()`](https://johngavin.github.io/footbet/reference/fetch_squad_values.md),
[`join_xg_to_matches()`](https://johngavin.github.io/footbet/reference/join_xg_to_matches.md),
[`parse_fd_csv()`](https://johngavin.github.io/footbet/reference/parse_fd_csv.md),
[`parse_fd_odds()`](https://johngavin.github.io/footbet/reference/parse_fd_odds.md),
[`standardise_fbref_advanced()`](https://johngavin.github.io/footbet/reference/standardise_fbref_advanced.md)
