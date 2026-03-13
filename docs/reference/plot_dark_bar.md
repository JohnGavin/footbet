# Create dark-themed plotly bar chart

Convenience function to create a bar chart with the dark plotly theme.

## Usage

``` r
plot_dark_bar(
  data,
  x,
  y,
  fill = "#3498db",
  title = NULL,
  xlab = NULL,
  ylab = NULL
)
```

## Arguments

- data:

  A data frame.

- x:

  Column name for x-axis (unquoted or string).

- y:

  Column name for y-axis (unquoted or string).

- fill:

  Bar color (default: "#3498db").

- title:

  Plot title.

- xlab:

  X-axis label.

- ylab:

  Y-axis label.

## Value

A styled plotly bar chart.
