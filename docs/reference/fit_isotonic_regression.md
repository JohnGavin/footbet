# Calibrate probabilities using isotonic regression

Fits isotonic (monotonic) regression on predicted probabilities. Better
for non-sigmoid calibration curves and larger datasets.

## Usage

``` r
fit_isotonic_regression(predicted, actual)
```

## Arguments

- predicted:

  Numeric vector. Predicted probabilities (training set).

- actual:

  Logical or 0/1 numeric. Actual outcomes (training set).

## Value

An isoreg object for use with
[`predict_isotonic()`](https://johngavin.github.io/footbet/reference/predict_isotonic.md).

## See also

Other calibration:
[`fit_platt_scaling()`](https://johngavin.github.io/footbet/reference/fit_platt_scaling.md),
[`predict_isotonic()`](https://johngavin.github.io/footbet/reference/predict_isotonic.md),
[`predict_platt()`](https://johngavin.github.io/footbet/reference/predict_platt.md)
