# Create dark-themed plotly line chart

Convenience function to create a line chart with the dark plotly theme.
Optionally adds markers at data points.

## Usage

``` r
plot_dark_line(
  data,
  x,
  y,
  color = "#3498db",
  title = NULL,
  xlab = NULL,
  ylab = NULL,
  markers = TRUE
)
```

## Arguments

- data:

  A data frame.

- x:

  Column name for x-axis.

- y:

  Column name for y-axis.

- color:

  Line color (default: "#3498db").

- title:

  Plot title.

- xlab:

  X-axis label.

- ylab:

  Y-axis label.

- markers:

  Logical; add markers at data points (default: TRUE).

## Value

A styled plotly line chart.
