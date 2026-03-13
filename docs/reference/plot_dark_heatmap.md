# Create dark-themed plotly heatmap

Convenience function to create a heatmap with the dark plotly theme.
Uses a viridis-like color scale.

## Usage

``` r
plot_dark_heatmap(
  data,
  x,
  y,
  z,
  title = NULL,
  showscale = TRUE,
  colorscale = "Viridis"
)
```

## Arguments

- data:

  A data frame in wide or long format.

- x:

  Column name for x-axis.

- y:

  Column name for y-axis.

- z:

  Column name for fill values.

- title:

  Plot title.

- showscale:

  Logical; show color scale (default: TRUE).

- colorscale:

  Color scale (default: "Viridis").

## Value

A styled plotly heatmap.
