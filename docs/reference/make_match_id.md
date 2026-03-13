# Generate a unique match ID

Creates a deterministic match identifier from league, date, and teams.

## Usage

``` r
make_match_id(league_code, match_date, home_team, away_team)
```

## Arguments

- league_code:

  Character.

- match_date:

  Date or character in ISO format.

- home_team:

  Character.

- away_team:

  Character.

## Value

Character match ID.

## See also

Other utilities:
[`fd_url()`](https://johngavin.github.io/footbet/reference/fd_url.md),
[`target_leagues()`](https://johngavin.github.io/footbet/reference/target_leagues.md),
[`target_seasons()`](https://johngavin.github.io/footbet/reference/target_seasons.md)
