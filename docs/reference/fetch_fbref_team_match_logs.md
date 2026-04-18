# Fetch FBref team match log stats for all teams in a league-season

Downloads per-match team stats (passing, shooting) using
[`worldfootballR::fb_team_match_log_stats()`](https://rdrr.io/pkg/worldfootballR/man/fb_team_match_log_stats.html).
This provides match-level progressive passes, PSxG, etc. needed for
rolling features.

## Usage

``` r
fetch_fbref_team_match_logs(
  country,
  season_end,
  stat_type = "passing",
  tier = "1st",
  delay = 5
)
```

## Arguments

- country:

  Character. Country code.

- season_end:

  Integer. Season end year.

- stat_type:

  Character. "passing" or "shooting".

- tier:

  Character. League tier (default "1st").

- delay:

  Numeric. Seconds between requests (default 5).

## Value

A tibble with per-match team stats.

## See also

Other data-acquisition:
[`download_all_fd()`](https://johngavin.github.io/footbet/reference/download_all_fd.md),
[`download_fd_csv()`](https://johngavin.github.io/footbet/reference/download_fd_csv.md),
[`fetch_fbref_advanced_all()`](https://johngavin.github.io/footbet/reference/fetch_fbref_advanced_all.md),
[`fetch_fbref_all()`](https://johngavin.github.io/footbet/reference/fetch_fbref_all.md),
[`fetch_fbref_matches()`](https://johngavin.github.io/footbet/reference/fetch_fbref_matches.md),
[`fetch_fbref_season_stats()`](https://johngavin.github.io/footbet/reference/fetch_fbref_season_stats.md),
[`fetch_league_injuries()`](https://johngavin.github.io/footbet/reference/fetch_league_injuries.md),
[`fetch_league_suspensions()`](https://johngavin.github.io/footbet/reference/fetch_league_suspensions.md),
[`fetch_league_transfers()`](https://johngavin.github.io/footbet/reference/fetch_league_transfers.md),
[`fetch_squad_values()`](https://johngavin.github.io/footbet/reference/fetch_squad_values.md),
[`join_xg_to_matches()`](https://johngavin.github.io/footbet/reference/join_xg_to_matches.md),
[`parse_fd_csv()`](https://johngavin.github.io/footbet/reference/parse_fd_csv.md),
[`parse_fd_odds()`](https://johngavin.github.io/footbet/reference/parse_fd_odds.md),
[`standardise_fbref_advanced()`](https://johngavin.github.io/footbet/reference/standardise_fbref_advanced.md)
