# Detect season boundaries

Returns TRUE for the first match of each new season. Season is detected
by a gap of 30+ days (summer break) in the match schedule.

## Usage

``` r
is_season_start(match_dates)
```

## Arguments

- match_dates:

  Date vector, sorted ascending.

## Value

Logical vector.
