# Apply Platt scaling calibration to new predictions

Apply Platt scaling calibration to new predictions

## Usage

``` r
predict_platt(platt_model, predicted)
```

## Arguments

- platt_model:

  A model from
  [`fit_platt_scaling()`](https://johngavin.github.io/footbet/reference/fit_platt_scaling.md).

- predicted:

  Numeric vector. New predicted probabilities.

## Value

Numeric vector. Calibrated probabilities.

## See also

Other calibration:
[`fit_isotonic_regression()`](https://johngavin.github.io/footbet/reference/fit_isotonic_regression.md),
[`fit_platt_scaling()`](https://johngavin.github.io/footbet/reference/fit_platt_scaling.md),
[`predict_isotonic()`](https://johngavin.github.io/footbet/reference/predict_isotonic.md)
