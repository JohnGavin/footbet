# Remove margin using Shin's model (1993)

Estimates the insider trading parameter `z` and derives fair
probabilities. Best for 3-way markets (1X2) where draws create
asymmetry.

## Usage

``` r
devig_shin(odds, tol = 1e-08)
```

## Arguments

- odds:

  Numeric vector of decimal odds (length 3 for 1X2).

- tol:

  Numeric. Convergence tolerance.

## Value

Numeric vector of fair probabilities.

## See also

Other devig:
[`calc_overround()`](https://johngavin.github.io/footbet/reference/calc_overround.md),
[`devig_basic()`](https://johngavin.github.io/footbet/reference/devig_basic.md),
[`devig_power()`](https://johngavin.github.io/footbet/reference/devig_power.md)
