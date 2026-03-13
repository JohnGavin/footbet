# Remove bookmaker margin from odds (basic proportional method)

Divides each implied probability by the overround to get fair
probabilities that sum to 1.

## Usage

``` r
devig_basic(odds)
```

## Arguments

- odds:

  Numeric vector of decimal odds (e.g. `c(2.10, 3.40, 3.50)`).

## Value

Numeric vector of fair probabilities.

## See also

Other devig:
[`calc_overround()`](https://johngavin.github.io/footbet/reference/calc_overround.md),
[`devig_power()`](https://johngavin.github.io/footbet/reference/devig_power.md),
[`devig_shin()`](https://johngavin.github.io/footbet/reference/devig_shin.md)
