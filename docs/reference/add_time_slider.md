# Add range slider to time series plotly

Enhance a time series plotly with an interactive range slider and range
selector buttons (1 year, 5 years, all data). Useful for exploring
trends across multiple seasons.

## Usage

``` r
add_time_slider(p)
```

## Arguments

- p:

  A plotly object with a time-based x-axis.

## Value

A plotly object with rangeslider enabled.

## Examples

``` r
if (FALSE) { # \dontrun{
library(plotly)
library(dplyr)
df <- tibble(date = seq.Date(as.Date("2015-01-01"), by = "month", length.out = 100),
             value = cumsum(rnorm(100)))
plot_ly(df, x = ~date, y = ~value, type = "scatter", mode = "lines") |>
  add_time_slider()
} # }
```
