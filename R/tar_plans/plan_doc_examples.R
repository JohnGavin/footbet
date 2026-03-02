# plan_doc_examples.R
# Code examples for README and vignettes, stored as targets.
# Each example is a character vector validated by parse().

parse_code_example <- function(code) {
  result <- tryCatch(
    {
      parse(text = paste(code, collapse = "\n"))
      list(valid = TRUE, error = NULL, code = code)
    },
    error = function(e) {
      list(valid = FALSE, error = conditionMessage(e), code = code)
    }
  )
  result
}

plan_doc_examples <- list(

  # Example 1: Download and parse data
  targets::tar_target(
    code_example_download,
    c(
      "library(footbet)",
      "",
      "# Define leagues and seasons",
      "leagues <- target_leagues()",
      "seasons <- target_seasons()",
      "",
      "# Download CSVs from football-data.co.uk",
      "files <- download_all_fd(leagues, seasons)",
      "",
      "# Parse match results and odds",
      "matches <- dplyr::bind_rows(lapply(seq_len(nrow(files)), function(i) {",
      "  parse_fd_csv(files$file_path[[i]], files$league_code[[i]], files$season[[i]])",
      "}))",
      "odds <- dplyr::bind_rows(lapply(seq_len(nrow(files)), function(i) {",
      "  parse_fd_odds(files$file_path[[i]], files$league_code[[i]], files$season[[i]])",
      "}))"
    )
  ),

  targets::tar_target(
    code_parsed_download,
    parse_code_example(code_example_download)
  ),

  # Example 2: Devig and model
  targets::tar_target(
    code_example_model,
    c(
      "library(footbet)",
      "",
      "# Devig Pinnacle odds (Shin method for 1X2)",
      "fair_odds <- devig_odds(odds)",
      "",
      "# Fit Poisson GLM baseline",
      "long_df <- matches_to_long(matches)",
      "glm_model <- fit_poisson_glm(long_df)",
      "",
      "# Predict match probabilities",
      "preds <- predict_matches_glm(glm_model, matches)"
    )
  ),

  targets::tar_target(
    code_parsed_model,
    parse_code_example(code_example_model)
  ),

  # Example 3: Value betting
  targets::tar_target(
    code_example_betting,
    c(
      "library(footbet)",
      "",
      "# Find value bets (model prob > market prob + 3%)",
      "value_bets <- find_value_bets(",
      "  preds     = preds,",
      "  devigged  = fair_odds,",
      "  odds      = odds,",
      "  min_edge  = 0.03,",
      "  min_odds  = 1.50,",
      "  max_odds  = 10.0",
      ")",
      "",
      "# Simulate P&L with quarter Kelly staking",
      "pnl <- simulate_pnl(",
      "  bets = dplyr::inner_join(value_bets,",
      "    dplyr::select(matches, match_id, ftr, match_date),",
      "    by = \"match_id\"",
      "  ),",
      "  initial_bankroll     = 1000,",
      "  drawdown_threshold   = 0.20,",
      "  max_stake            = 0.03",
      ")",
      "",
      "# Summary statistics",
      "summarise_pnl(pnl, initial_bankroll = 1000)"
    )
  ),

  targets::tar_target(
    code_parsed_betting,
    parse_code_example(code_example_betting)
  ),

  # Validation gate: all examples must parse
  targets::tar_target(
    doc_examples_validation,
    {
      parse_results <- list(
        code_parsed_download,
        code_parsed_model,
        code_parsed_betting
      )
      all_valid <- all(vapply(parse_results, function(x) x$valid, logical(1)))
      if (!all_valid) {
        failures <- parse_results[!vapply(parse_results, function(x) x$valid, logical(1))]
        cli::cli_abort(c(
          "x" = "Code examples failed syntax validation",
          "i" = paste("Errors:", vapply(failures, function(x) x$error, character(1)))
        ))
      }
      list(all_valid = TRUE, n_examples = length(parse_results))
    }
  )
)
