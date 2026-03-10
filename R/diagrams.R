# diagrams.R
# Programmatically generated mermaid flowcharts for documentation.
# Extracts function names from roxygen @family tags and config values from code.
# Diagrams auto-update when source files change (via tar_cue).

# ============================================================================
# HELPER FUNCTIONS - EXTRACT FROM CODE
# ============================================================================

#' Extract function names by roxygen family tag
#'
#' Scans R files for functions with a specific @family tag.
#' Used to keep diagrams in sync with actual function names.
#'
#' @param family Character. The @family tag to search for (e.g., "data-acquisition").
#' @param pkg_path Character. Path to package root (default ".").
#' @return Character vector of function names.
#' @noRd
extract_functions_by_family <- function(family, pkg_path = ".") {
  r_dir <- file.path(pkg_path, "R")
  if (!dir.exists(r_dir)) return(character(0))

  r_files <- list.files(r_dir, pattern = "\\.R$", full.names = TRUE)

  functions <- purrr::map(r_files, function(file) {
    lines <- readLines(file, warn = FALSE)

    # Find lines with the @family tag
    family_pattern <- paste0("@family\\s+", family, "\\b")
    family_lines <- grep(family_pattern, lines, perl = TRUE)

    if (length(family_lines) == 0L) return(character(0))

    # For each @family line, find the function definition that follows
    purrr::map_chr(family_lines, function(line_num) {
      # Scan forward up to 30 lines to find function definition
      for (i in line_num:min(line_num + 30L, length(lines))) {
        fn_match <- regmatches(
          lines[i],
          regexpr("^([a-zA-Z_][a-zA-Z0-9_.]*?)\\s*<-\\s*function", lines[i], perl = TRUE)
        )
        if (length(fn_match) > 0 && nchar(fn_match) > 0) {
          return(sub("\\s*<-.*", "", fn_match))
        }
      }
      NA_character_
    }) |>
      stats::na.omit() |>
      as.character()
  }) |>
    unlist() |>
    unique()

  functions
}

#' Extract pipeline phase labels from _pkgdown.yml
#'
#' Reads reference section titles from _pkgdown.yml to use as
#' diagram subgraph labels. Falls back to defaults if not found.
#'
#' @param pkg_path Character. Path to package root (default ".").
#' @return Named list with phase labels.
#' @noRd
extract_phase_labels <- function(pkg_path = ".") {
  pkgdown_file <- file.path(pkg_path, "_pkgdown.yml")


  defaults <- list(
    data = "Data Acquisition",
    features = "Feature Engineering",
    models = "Prediction Models",
    betting = "Betting Strategy"
  )


  if (!file.exists(pkgdown_file)) return(defaults)

  yml <- tryCatch(
    yaml::read_yaml(pkgdown_file),
    error = function(e) NULL
  )

  if (is.null(yml) || is.null(yml$reference)) return(defaults)

  labels <- defaults

  for (section in yml$reference) {
    title <- section$title
    contents <- section$contents
    if (is.null(contents)) next
    content_str <- paste(unlist(contents), collapse = " ")

    if (grepl("data-acquisition", content_str, ignore.case = TRUE)) {
      labels$data <- title
    }
    if (grepl("\\bfeatures\\b", content_str, ignore.case = TRUE)) {
      labels$features <- title
    }
    if (grepl("\\bmodels\\b", content_str, ignore.case = TRUE)) {
      labels$models <- title
    }
    if (grepl("decisions|betting", content_str, ignore.case = TRUE)) {
      labels$betting <- title
    }
  }

  labels
}

#' Extract CV configuration from walk_forward_splits function
#'
#' Parses models_eval.R to extract the default train_months value.
#'
#' @param pkg_path Character. Path to package root.
#' @return Named list with CV config values.
#' @noRd
extract_cv_config <- function(pkg_path = ".") {
  eval_file <- file.path(pkg_path, "R", "models_eval.R")

  defaults <- list(train_months = 24L, test_months = 1L)

  if (!file.exists(eval_file)) return(defaults)


  lines <- readLines(eval_file, warn = FALSE)

  # Find walk_forward_splits function
  fn_start <- grep("walk_forward_splits\\s*<-\\s*function", lines)
  if (length(fn_start) == 0L) return(defaults)

  # Scan for train_months default

  for (i in fn_start[1]:min(fn_start[1] + 10L, length(lines))) {
    if (grepl("train_months\\s*=\\s*\\d+", lines[i])) {
      train_match <- regmatches(
        lines[i],
        regexpr("train_months\\s*=\\s*(\\d+)", lines[i], perl = TRUE)
      )
      if (length(train_match) > 0) {
        train_val <- as.integer(sub(".*=\\s*(\\d+).*", "\\1", train_match))
        defaults$train_months <- train_val
      }
    }
    if (grepl("test_months\\s*=\\s*\\d+", lines[i])) {
      test_match <- regmatches(
        lines[i],
        regexpr("test_months\\s*=\\s*(\\d+)", lines[i], perl = TRUE)
      )
      if (length(test_match) > 0) {
        test_val <- as.integer(sub(".*=\\s*(\\d+).*", "\\1", test_match))
        defaults$test_months <- test_val
      }
    }
  }

  defaults
}

#' Extract Kelly staking configuration from kelly.R
#'
#' Parses kelly.R to extract default values for min_edge, max_stake,
#' kelly_fraction, and drawdown_threshold.
#'
#' @param pkg_path Character. Path to package root.
#' @return Named list with Kelly config values.
#' @noRd
extract_kelly_config <- function(pkg_path = ".") {
  kelly_file <- file.path(pkg_path, "R", "kelly.R")

  defaults <- list(
    min_edge = 0.03,
    max_stake = 0.03,
    kelly_fraction = 0.25,
    drawdown_threshold = 0.20
  )

  if (!file.exists(kelly_file)) return(defaults)

  lines <- readLines(kelly_file, warn = FALSE)

  # Extract defaults from function signatures
  patterns <- list(
    min_edge = "min_edge\\s*=\\s*([0-9.]+)",
    max_stake = "max_stake\\s*=\\s*([0-9.]+)",
    kelly_fraction = "fraction\\s*=\\s*([0-9.]+)",
    drawdown_threshold = "drawdown_threshold\\s*=\\s*([0-9.]+)"
  )

  all_text <- paste(lines, collapse = "\n")

  for (name in names(patterns)) {
    match <- regmatches(
      all_text,
      regexpr(patterns[[name]], all_text, perl = TRUE)
    )
    if (length(match) > 0 && nchar(match) > 0) {
      val <- as.numeric(sub(".*=\\s*([0-9.]+).*", "\\1", match))
      if (!is.na(val)) defaults[[name]] <- val
    }
  }

  defaults
}

# ============================================================================
# MERMAID GENERATORS
# ============================================================================

#' Generate data pipeline mermaid flowchart
#'
#' Creates a mermaid flowchart showing the data acquisition and
#' processing pipeline. Function names are extracted from @family tags.
#'
#' @param pkg_path Character. Path to package root.
#' @return Character. Mermaid flowchart code.
#' @family diagrams
#' @export
generate_data_pipeline_mermaid <- function(pkg_path = ".") {
  # Extract actual function names
  data_fns <- extract_functions_by_family("data-acquisition", pkg_path)
  feature_fns <- extract_functions_by_family("features", pkg_path)

  # Find specific functions (with fallbacks)
  parse_fn <- data_fns[grepl("parse_fd_csv", data_fns)][1]
  if (is.na(parse_fn)) parse_fn <- "parse_fd_csv"

  odds_fn <- data_fns[grepl("parse_fd_odds", data_fns)][1]
  if (is.na(odds_fn)) odds_fn <- "parse_fd_odds"

  xg_fn <- data_fns[grepl("fetch_fbref|fbref", data_fns)][1]
  if (is.na(xg_fn)) xg_fn <- "fetch_fbref_matches"

  rolling_fn <- feature_fns[grepl("rolling_goals", feature_fns)][1]
  if (is.na(rolling_fn)) rolling_fn <- "rolling_goals"

  elo_fn <- feature_fns[grepl("compute_elo", feature_fns)][1]
  if (is.na(elo_fn)) elo_fn <- "compute_elo"

  # Extract labels from _pkgdown.yml
  labels <- extract_phase_labels(pkg_path)

  glue::glue('
flowchart LR
    subgraph Data["{labels$data}"]
        FD[football-data.co.uk] --> Parse[{parse_fn}]
        FD --> Odds[{odds_fn}]
        FB[FBref/Understat] --> XG[{xg_fn}]
    end
    subgraph Features["{labels$features}"]
        Parse --> Roll[{rolling_fn}]
        XG --> Roll
        Roll --> Elo[{elo_fn}]
    end
    subgraph Models["{labels$models}"]
        Elo --> GLM[Poisson GLM]
        Elo --> DC[Dixon-Coles]
        GLM --> Eval[Walk-Forward CV]
        DC --> Eval
    end
    subgraph Betting["{labels$betting}"]
        Eval --> Value[find_value_bets]
        Odds --> Devig[devig_odds]
        Devig --> Value
        Value --> Kelly[kelly_fraction]
    end
')
}

#' Generate walk-forward CV mermaid flowchart
#'
#' Creates a mermaid flowchart showing the walk-forward cross-validation
#' strategy. Train window months are extracted from code.
#'
#' @param pkg_path Character. Path to package root.
#' @return Character. Mermaid flowchart code.
#' @family diagrams
#' @export
generate_cv_walkforward_mermaid <- function(pkg_path = ".") {
  config <- extract_cv_config(pkg_path)
  train_months <- config$train_months

  glue::glue('
flowchart TB
    subgraph Fold1[Fold 1]
        T1[Train: Months 1-{train_months}] --> V1[Test: Month {train_months + 1}]
    end
    subgraph Fold2[Fold 2]
        T2[Train: Months 1-{train_months + 1}] --> V2[Test: Month {train_months + 2}]
    end
    subgraph FoldN[Fold N]
        TN[Train: Months 1 to N-1] --> VN[Test: Month N]
    end
    V1 -.-> T2
    V2 -.-> |...| TN
    V1 --> Agg((Aggregate Metrics))
    V2 --> Agg
    VN --> Agg
')
}

#' Generate Kelly decision tree mermaid flowchart
#'
#' Creates a mermaid flowchart showing the Kelly staking decision tree.
#' Threshold values are extracted from kelly.R defaults.
#'
#' @param pkg_path Character. Path to package root.
#' @return Character. Mermaid flowchart code.
#' @family diagrams
#' @export
generate_kelly_decision_mermaid <- function(pkg_path = ".") {
  config <- extract_kelly_config(pkg_path)
  edge_pct <- round(config$min_edge * 100)
  stake_pct <- round(config$max_stake * 100)
  dd_pct <- round(config$drawdown_threshold * 100)
  kelly_frac <- config$kelly_fraction

  glue::glue('
flowchart TD
    Input[Model Prob + Odds] --> Edge[Calculate Edge]
    Edge --> Check{{{{Edge > {edge_pct}%?}}}}
    Check -->|No| NoBet[No Bet]
    Check -->|Yes| Kelly[Calculate Kelly f*]
    Kelly --> Frac[Apply {kelly_frac} Kelly]
    Frac --> Max{{{{Stake > {stake_pct}%?}}}}
    Max -->|Yes| Cap[Cap at {stake_pct}%]
    Max -->|No| DD
    Cap --> DD{{{{Drawdown > {dd_pct}%?}}}}
    DD -->|Yes| Halve[Halve Stake]
    DD -->|No| Final[Final Stake]
    Halve --> Final
')
}

# ============================================================================
# OUTPUT WRAPPERS
# ============================================================================

#' Wrap mermaid code in HTML div for vignettes
#'
#' Creates an HTML structure that renders with mermaid.js CDN.
#' Used for vignettes where click/href works with securityLevel: loose.
#'
#' @param mermaid_code Character. Mermaid diagram code.
#' @return Character with class "html" for auto-printing with output: asis.
#' @family diagrams
#' @export
wrap_mermaid_html <- function(mermaid_code) {
  html <- paste0('<div class="mermaid">\n', mermaid_code, '\n</div>')
  structure(html, class = c("html", "character"))
}

#' Wrap mermaid code in fenced block for README.md
#'
#' Creates a GitHub-flavored markdown fenced code block that
#' GitHub renders natively as a diagram.
#'
#' @param mermaid_code Character. Mermaid diagram code.
#' @return Character. Fenced mermaid code block.
#' @family diagrams
#' @export
wrap_mermaid_fenced <- function(mermaid_code) {
  paste0("```mermaid\n", mermaid_code, "\n```")
}
