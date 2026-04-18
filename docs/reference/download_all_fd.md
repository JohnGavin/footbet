# Download all target league/season combinations

Download all target league/season combinations

## Usage

``` r
download_all_fd(
  leagues = target_leagues(),
  seasons = target_seasons(),
  cache_dir = here::here("inst", "extdata", "raw"),
  delay = 1
)
```

## Arguments

- leagues:

  A tibble with column `league_code`, as from
  [`target_leagues()`](https://johngavin.github.io/footbet/reference/target_leagues.md).

- seasons:

  Character vector of season codes, as from
  [`target_seasons()`](https://johngavin.github.io/footbet/reference/target_seasons.md).

- cache_dir:

  Character. Cache directory.

- delay:

  Numeric. Seconds to pause between requests (rate limiting).

## Value

A tibble with columns `league_code`, `season`, `file_path`.

## See also

Other data-acquisition:
[`download_fd_csv()`](https://johngavin.github.io/footbet/reference/download_fd_csv.md),
[`fetch_fbref_advanced_all()`](https://johngavin.github.io/footbet/reference/fetch_fbref_advanced_all.md),
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
