# Target leagues for data acquisition

Returns a tibble of the 10 target leagues (top 2 divisions for England,
Germany, Italy, Spain, France).

## Usage

``` r
target_leagues()
```

## Value

A tibble with columns `country`, `league_code`, `division`.

## See also

Other utilities:
[`fd_url()`](https://johngavin.github.io/footbet/reference/fd_url.md),
[`make_match_id()`](https://johngavin.github.io/footbet/reference/make_match_id.md),
[`target_seasons()`](https://johngavin.github.io/footbet/reference/target_seasons.md)
