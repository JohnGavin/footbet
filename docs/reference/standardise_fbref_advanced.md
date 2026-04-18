# Standardise FBref team match log columns for progressive stats

Extracts and renames the key columns from FBref passing and shooting
match logs to a consistent format for joining to match data.

## Usage

``` r
standardise_fbref_advanced(passing_df, shooting_df)
```

## Arguments

- passing_df:

  Raw passing match log from
  [`fetch_fbref_team_match_logs()`](https://johngavin.github.io/footbet/reference/fetch_fbref_team_match_logs.md).

- shooting_df:

  Raw shooting match log from
  [`fetch_fbref_team_match_logs()`](https://johngavin.github.io/footbet/reference/fetch_fbref_team_match_logs.md).

## Value

A tibble with `team`, `match_date`, `prgp`, `prgc`, `ppa`, `psxg`, `xg`
per team per match.

## See also

Other data-acquisition:
[`download_all_fd()`](https://johngavin.github.io/footbet/reference/download_all_fd.md),
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
[`parse_fd_odds()`](https://johngavin.github.io/footbet/reference/parse_fd_odds.md)
