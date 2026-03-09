# plot_theme.R
# Dark theme styling for interactive plotly visualizations
# tonyelhabr-inspired aesthetics: dark background, white text, subtle gridlines

#' Dark theme for plotly plots
#'
#' Apply a consistent dark theme to plotly visualizations with dark background,

#' white text/labels, and subtle grey gridlines. Inspired by tonyelhabr aesthetics.
#'
#' @param p A plotly object.
#' @param title Optional plot title.
#'
#' @return A styled plotly object.
#' @export
#'
#' @examples
#' \dontrun{
#' library(plotly)
#' p <- plot_ly(mtcars, x = ~mpg, y = ~hp, type = "scatter", mode = "markers")
#' theme_dark_plotly(p, title = "MPG vs Horsepower")
#' }
#' @concept plotting
theme_dark_plotly <- function(p, title = NULL) {
  layout_args <- list(
    paper_bgcolor = "#1c1c1c",
    plot_bgcolor = "#1c1c1c",
    font = list(
      color = "white",
      family = "Titillium Web, sans-serif"
    ),
    xaxis = list(
      gridcolor = "#4d4d4d",
      zerolinecolor = "#4d4d4d",
      tickfont = list(color = "white"),
      titlefont = list(color = "white")
    ),
    yaxis = list(
      gridcolor = "#4d4d4d",
      zerolinecolor = "#4d4d4d",
      tickfont = list(color = "white"),
      titlefont = list(color = "white")
    ),
    legend = list(
      bgcolor = "transparent",
      font = list(color = "white")
    ),
    margin = list(t = 60, b = 50, l = 60, r = 40)
  )

  if (!is.null(title)) {
    layout_args$title <- list(
      text = title,
      font = list(color = "white", size = 16)
    )
  }

  do.call(plotly::layout, c(list(p = p), layout_args))
}


#' Add range slider to time series plotly
#'
#' Enhance a time series plotly with an interactive range slider and range
#' selector buttons (1 year, 5 years, all data). Useful for exploring trends
#' across multiple seasons.
#'
#' @param p A plotly object with a time-based x-axis.
#'
#' @return A plotly object with rangeslider enabled.
#' @export
#'
#' @examples
#' \dontrun{
#' library(plotly)
#' library(dplyr)
#' df <- tibble(date = seq.Date(as.Date("2015-01-01"), by = "month", length.out = 100),
#'              value = cumsum(rnorm(100)))
#' plot_ly(df, x = ~date, y = ~value, type = "scatter", mode = "lines") |>
#'   add_time_slider()
#' }
#' @concept plotting
add_time_slider <- function(p) {
  plotly::layout(
    p,
    xaxis = list(
      rangeslider = list(
        visible = TRUE,
        bgcolor = "#2d2d2d",
        bordercolor = "#4d4d4d",
        thickness = 0.1
      ),
      rangeselector = list(
        buttons = list(
          list(count = 1, label = "1y", step = "year", stepmode = "backward"),
          list(count = 5, label = "5y", step = "year", stepmode = "backward"),
          list(step = "all", label = "All")
        ),
        bgcolor = "#3d3d3d",
        font = list(color = "white"),
        activecolor = "#5d5d5d"
      )
    )
  )
}


#' Create dark-themed plotly bar chart
#'
#' Convenience function to create a bar chart with the dark plotly theme.
#'
#' @param data A data frame.
#' @param x Column name for x-axis (unquoted or string).
#' @param y Column name for y-axis (unquoted or string).
#' @param fill Bar color (default: "#3498db").
#' @param title Plot title.
#' @param xlab X-axis label.
#' @param ylab Y-axis label.
#'
#' @return A styled plotly bar chart.
#' @export
#' @concept plotting
plot_dark_bar <- function(data, x, y, fill = "#3498db", title = NULL,
                          xlab = NULL, ylab = NULL) {
  p <- plotly::plot_ly(
    data,
    x = as.formula(paste0("~", rlang::as_name(rlang::enquo(x)))),
    y = as.formula(paste0("~", rlang::as_name(rlang::enquo(y)))),
    type = "bar",
    marker = list(color = fill)
  )

  if (!is.null(xlab) || !is.null(ylab)) {
    p <- plotly::layout(
      p,
      xaxis = list(title = xlab),
      yaxis = list(title = ylab)
    )
  }

  theme_dark_plotly(p, title = title)
}


#' Create dark-themed plotly line chart
#'
#' Convenience function to create a line chart with the dark plotly theme.
#' Optionally adds markers at data points.
#'
#' @param data A data frame.
#' @param x Column name for x-axis.
#' @param y Column name for y-axis.
#' @param color Line color (default: "#3498db").
#' @param title Plot title.
#' @param xlab X-axis label.
#' @param ylab Y-axis label.
#' @param markers Logical; add markers at data points (default: TRUE).
#'
#' @return A styled plotly line chart.
#' @export
#' @concept plotting
plot_dark_line <- function(data, x, y, color = "#3498db", title = NULL,
                           xlab = NULL, ylab = NULL, markers = TRUE) {
  mode <- if (markers) "lines+markers" else "lines"

  p <- plotly::plot_ly(
    data,
    x = as.formula(paste0("~", rlang::as_name(rlang::enquo(x)))),
    y = as.formula(paste0("~", rlang::as_name(rlang::enquo(y)))),
    type = "scatter",
    mode = mode,
    line = list(color = color),
    marker = list(color = color)
  )

  if (!is.null(xlab) || !is.null(ylab)) {
    p <- plotly::layout(
      p,
      xaxis = list(title = xlab),
      yaxis = list(title = ylab)
    )
  }

  theme_dark_plotly(p, title = title)
}


#' Create dark-themed plotly heatmap
#'
#' Convenience function to create a heatmap with the dark plotly theme.
#' Uses a viridis-like color scale.
#'
#' @param data A data frame in wide or long format.
#' @param x Column name for x-axis.
#' @param y Column name for y-axis.
#' @param z Column name for fill values.
#' @param title Plot title.
#' @param showscale Logical; show color scale (default: TRUE).
#' @param colorscale Color scale (default: "Viridis").
#'
#' @return A styled plotly heatmap.
#' @export
#' @concept plotting
plot_dark_heatmap <- function(data, x, y, z, title = NULL,
                              showscale = TRUE, colorscale = "Viridis") {
  p <- plotly::plot_ly(
    data,
    x = as.formula(paste0("~", rlang::as_name(rlang::enquo(x)))),
    y = as.formula(paste0("~", rlang::as_name(rlang::enquo(y)))),
    z = as.formula(paste0("~", rlang::as_name(rlang::enquo(z)))),
    type = "heatmap",
    colorscale = colorscale,
    showscale = showscale
  )

  theme_dark_plotly(p, title = title)
}


#' Create dark-themed plotly box plot
#'
#' Convenience function to create box plots with the dark plotly theme.
#'
#' @param data A data frame.
#' @param x Column name for grouping variable.
#' @param y Column name for values.
#' @param fill Box fill color (default: "#3498db").
#' @param title Plot title.
#'
#' @return A styled plotly box plot.
#' @export
#' @concept plotting
plot_dark_box <- function(data, x, y, fill = "#3498db", title = NULL) {

  p <- plotly::plot_ly(
    data,
    x = as.formula(paste0("~", rlang::as_name(rlang::enquo(x)))),
    y = as.formula(paste0("~", rlang::as_name(rlang::enquo(y)))),
    type = "box",
    marker = list(color = fill),
    fillcolor = fill,
    line = list(color = "white"),
    opacity = 0.7
  )

  theme_dark_plotly(p, title = title)
}
