# Convert odds between any formats

Convenience function to convert odds between decimal, fractional, and
American formats.

## Usage

``` r
convert_odds(odds, from, to)
```

## Arguments

- odds:

  Numeric or character. Input odds.

- from:

  Character. Input format: "decimal", "fractional", or "american".

- to:

  Character. Output format: "decimal", "fractional", or "american".

## Value

Odds in the target format.

## See also

Other odds:
[`american_to_decimal()`](https://johngavin.github.io/footbet/reference/american_to_decimal.md),
[`decimal_to_american()`](https://johngavin.github.io/footbet/reference/decimal_to_american.md),
[`decimal_to_fractional()`](https://johngavin.github.io/footbet/reference/decimal_to_fractional.md),
[`fractional_to_decimal()`](https://johngavin.github.io/footbet/reference/fractional_to_decimal.md)
