# Add league tier and country metadata

Augments a data frame containing `league_code` with tier and country
columns. Top 5 leagues (E0, D1, I1, SP1, F1) are marked as "Top 5"; all
others as "2nd Tier".

## Usage

``` r
add_league_metadata(df)
```

## Arguments

- df:

  A data frame with a `league_code` column.

## Value

The input data frame with `tier` and `country` columns added.

## Examples

``` r
if (FALSE) { # \dontrun{
tibble::tibble(league_code = c("E0", "E1", "D1", "D2")) |>
  add_league_metadata()
} # }
```
