# Calibrate probabilities using Platt scaling

Fits a logistic regression on predicted probabilities to improve
calibration. Best for sigmoid-shaped calibration curves and small
calibration sets.

## Usage

``` r
fit_platt_scaling(predicted, actual)
```

## Arguments

- predicted:

  Numeric vector. Predicted probabilities (training set).

- actual:

  Logical or 0/1 numeric. Actual outcomes (training set).

## Value

A fitted glm object that can be used with
[`predict()`](https://rdrr.io/r/stats/predict.html).

## References

Platt, J. (1999). Probabilistic outputs for support vector machines.

## See also

Other calibration:
[`fit_isotonic_regression()`](https://johngavin.github.io/footbet/reference/fit_isotonic_regression.md),
[`predict_isotonic()`](https://johngavin.github.io/footbet/reference/predict_isotonic.md),
[`predict_platt()`](https://johngavin.github.io/footbet/reference/predict_platt.md)
