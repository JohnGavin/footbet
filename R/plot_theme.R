# plot_theme.R
# Dark theme styling for interactive plotly visualizations
# tonyelhabr-inspired aesthetics: dark background, white text, subtle gridlines

# ============================================================================
# TIER AND COUNTRY COLOR CONSTANTS
# ============================================================================

#' Tier color palette
#'
#' Colors for European football league tiers.
#' @export
#' @concept plotting
TIER_COLORS <- c("Top 5" = "#3498db", "2nd Tier" = "#e67e22")

#' Country color palette
#'
#' Colors for the big five European football countries.
#' @export
#' @concept plotting
COUNTRY_COLORS <- c(
England = "#dc3545",
Germany = "#ffc107",
Italy = "#28a745",
Spain = "#fd7e14",
France = "#007bff"
)

#' Add league tier and country metadata
#'
#' Augments a data frame containing `league_code` with tier and country columns.
#' Top 5 leagues (E0, D1, I1, SP1, F1) are marked as "Top 5"; all others as "2nd Tier".
#'
#' @param df A data frame with a `league_code` column.
#'
#' @return The input data frame with `tier` and `country` columns added.
#' @export
#'
#' @examples
#' \dontrun{
#' tibble::tibble(league_code = c("E0", "E1", "D1", "D2")) |>
#'   add_league_metadata()
#' }
#' @concept plotting
add_league_metadata <- function(df) {
df |>
  dplyr::mutate(
    tier = dplyr::case_when(
      league_code %in% c("E0", "D1", "I1", "SP1", "F1") ~ "Top 5",
      TRUE ~ "2nd Tier"
    ),
    country = dplyr::case_when(
      grepl("^E", league_code) ~ "England",
      grepl("^D", league_code) ~ "Germany",
      grepl("^I", league_code) ~ "Italy",
      grepl("^SP", league_code) ~ "Spain",
      grepl("^F", league_code) ~ "France",
      TRUE ~ "Other"
    )
  )
}

# ============================================================================
# THEME FUNCTIONS
# ============================================================================

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
    paper_bgcolor = "#000000",
    plot_bgcolor = "#000000",
    font = list(
      color = "white",
      family = "Titillium Web, sans-serif"
    ),
    xaxis = list(
      gridcolor = "rgba(255, 255, 255, 0.3)",
      zerolinecolor = "rgba(255, 255, 255, 0.5)",
      tickfont = list(color = "white"),
      titlefont = list(color = "white")
    ),
    yaxis = list(
      gridcolor = "rgba(255, 255, 255, 0.3)",
      zerolinecolor = "rgba(255, 255, 255, 0.5)",
      tickfont = list(color = "white"),
      titlefont = list(color = "white")
    ),
    legend = list(
      bgcolor = "#000000",
      font = list(color = "white"),
      orientation = "h",
      yanchor = "top",
      y = -0.15,
      xanchor = "center",
      x = 0.5
    ),
    margin = list(t = 60, b = 80, l = 60, r = 40)
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
        bgcolor = "#000000",
        bordercolor = "rgba(255, 255, 255, 0.3)",
        thickness = 0.1
      ),
      rangeselector = list(
        buttons = list(
          list(count = 1, label = "1y", step = "year", stepmode = "backward"),
          list(count = 5, label = "5y", step = "year", stepmode = "backward"),
          list(step = "all", label = "All")
        ),
        bgcolor = "#000000",
        font = list(color = "white"),
        activecolor = "#333333",
        bordercolor = "rgba(255, 255, 255, 0.3)"
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
#' @importFrom stats as.formula
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
