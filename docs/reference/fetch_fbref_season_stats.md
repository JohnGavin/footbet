# Fetch FBref team season stats (passing, shooting, possession)

Downloads team-level season stats from FBref using
[`worldfootballR::fb_season_team_stats()`](https://rdrr.io/pkg/worldfootballR/man/fb_season_team_stats.html).
Returns progressive passes, progressive carries, passes into penalty
area, PSxG, etc.

## Usage

``` r
fetch_fbref_season_stats(
  country,
  season_end,
  stat_type = "passing",
  tier = "1st"
)
```

## Arguments

- country:

  Character. Country code ("ENG", "ESP", "GER", "ITA", "FRA").

- season_end:

  Integer. Season end year.

- stat_type:

  Character. One of "passing", "shooting", "possession".

- tier:

  Character. League tier (default "1st").

## Value

A tibble with team-level season stats.

## See also

Other data-acquisition:
[`download_all_fd()`](https://johngavin.github.io/footbet/reference/download_all_fd.md),
[`download_fd_csv()`](https://johngavin.github.io/footbet/reference/download_fd_csv.md),
[`fetch_fbref_advanced_all()`](https://johngavin.github.io/footbet/reference/fetch_fbref_advanced_all.md),
[`fetch_fbref_all()`](https://johngavin.github.io/footbet/reference/fetch_fbref_all.md),
[`fetch_fbref_matches()`](https://johngavin.github.io/footbet/reference/fetch_fbref_matches.md),
[`fetch_fbref_team_match_logs()`](https://johngavin.github.io/footbet/reference/fetch_fbref_team_match_logs.md),
[`fetch_league_injuries()`](https://johngavin.github.io/footbet/reference/fetch_league_injuries.md),
[`fetch_league_suspensions()`](https://johngavin.github.io/footbet/reference/fetch_league_suspensions.md),
[`fetch_league_transfers()`](https://johngavin.github.io/footbet/reference/fetch_league_transfers.md),
[`fetch_squad_values()`](https://johngavin.github.io/footbet/reference/fetch_squad_values.md),
[`join_xg_to_matches()`](https://johngavin.github.io/footbet/reference/join_xg_to_matches.md),
[`parse_fd_csv()`](https://johngavin.github.io/footbet/reference/parse_fd_csv.md),
[`parse_fd_odds()`](https://johngavin.github.io/footbet/reference/parse_fd_odds.md),
[`standardise_fbref_advanced()`](https://johngavin.github.io/footbet/reference/standardise_fbref_advanced.md)
