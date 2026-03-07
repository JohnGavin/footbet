# Global variable declarations to satisfy R CMD check
#
# These are non-standard evaluation (NSE) variables used in:
# - dplyr pipelines (column names)
# - brms formula specifications
# - ggplot2 aesthetics
#
# Declaring them here prevents "no visible binding for global variable" notes.

utils::globalVariables(c(

  # Match data columns
  "away_team",
  "ftr",
  "home_team",
  "match_date",

 # brms prior function
  "normal"
))
