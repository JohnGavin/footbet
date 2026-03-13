# Dark theme for plotly plots

Apply a consistent dark theme to plotly visualizations with dark
background, white text/labels, and subtle grey gridlines. Inspired by
tonyelhabr aesthetics.

## Usage

``` r
theme_dark_plotly(p, title = NULL)
```

## Arguments

- p:

  A plotly object.

- title:

  Optional plot title.

## Value

A styled plotly object.

## Examples

``` r
if (FALSE) { # \dontrun{
library(plotly)
p <- plot_ly(mtcars, x = ~mpg, y = ~hp, type = "scatter", mode = "markers")
theme_dark_plotly(p, title = "MPG vs Horsepower")
} # }
```
