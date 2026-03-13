# Remove margin using power method

Solves for exponent `k` such that `sum(1/odds^k) = 1`. Better for 2-way
markets (Asian handicap, over/under) as it corrects favourite-longshot
bias.

## Usage

``` r
devig_power(odds, tol = 1e-08)
```

## Arguments

- odds:

  Numeric vector of decimal odds.

- tol:

  Numeric. Convergence tolerance (default 1e-8).

## Value

Numeric vector of fair probabilities.

## See also

Other devig:
[`calc_overround()`](https://johngavin.github.io/footbet/reference/calc_overround.md),
[`devig_basic()`](https://johngavin.github.io/footbet/reference/devig_basic.md),
[`devig_shin()`](https://johngavin.github.io/footbet/reference/devig_shin.md)
