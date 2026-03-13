# Apply isotonic calibration to new predictions

Apply isotonic calibration to new predictions

## Usage

``` r
predict_isotonic(iso_model, predicted)
```

## Arguments

- iso_model:

  An isoreg object from
  [`fit_isotonic_regression()`](https://johngavin.github.io/footbet/reference/fit_isotonic_regression.md).

- predicted:

  Numeric vector. New predicted probabilities.

## Value

Numeric vector. Calibrated probabilities.

## See also

Other calibration:
[`fit_isotonic_regression()`](https://johngavin.github.io/footbet/reference/fit_isotonic_regression.md),
[`fit_platt_scaling()`](https://johngavin.github.io/footbet/reference/fit_platt_scaling.md),
[`predict_platt()`](https://johngavin.github.io/footbet/reference/predict_platt.md)
