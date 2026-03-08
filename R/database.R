#' Connect to the footbet DuckDB database
#'
#' Creates or opens a DuckDB database for storing match and odds data.
#'
#' @param db_path Character. Path to the database file.
#'   Use `":memory:"` for an in-memory database (default for testing).
#' @return A DBI connection object.
#' @family storage
#' @export
connect_db <- function(db_path = ":memory:") {
  if (!nzchar(db_path)) {
    cli::cli_abort("{.arg db_path} must not be empty. Use {.val :memory:} for in-memory.")
  }
  DBI::dbConnect(duckdb::duckdb(), dbdir = db_path)
}

#' Create the footbet database schema
#'
#' Creates the `matches`, `match_odds`, `teams`, and `transfers` tables
#' if they do not already exist.
#'
#' @param con A DBI connection to DuckDB.
#' @return `con` invisibly.
#' @family storage
#' @export
create_schema <- function(con) {
  DBI::dbExecute(con, "
    CREATE TABLE IF NOT EXISTS matches (
      match_id   VARCHAR PRIMARY KEY,
      season     VARCHAR,
      league_code VARCHAR,
      match_date DATE,
      home_team  VARCHAR,
      away_team  VARCHAR,
      fthg       INTEGER,
      ftag       INTEGER,
      ftr        VARCHAR,
      hthg       INTEGER,
      htag       INTEGER,
      htr        VARCHAR,
      hs         INTEGER,
      as_        INTEGER,
      hst        INTEGER,
      ast        INTEGER,
      hc         INTEGER,
      ac         INTEGER,
      hf         INTEGER,
      af         INTEGER,
      hy         INTEGER,
      ay         INTEGER,
      hr         INTEGER,
      ar         INTEGER
    )
  ")

  DBI::dbExecute(con, "
    CREATE TABLE IF NOT EXISTS match_odds (
      match_id    VARCHAR,
      bookmaker   VARCHAR,
      market      VARCHAR,
      snapshot_type VARCHAR,
      odds_h      DOUBLE,
      odds_d      DOUBLE,
      odds_a      DOUBLE,
      odds_over25 DOUBLE,
      odds_under25 DOUBLE,
      ah_line     DOUBLE,
      odds_ahh    DOUBLE,
      odds_aha    DOUBLE,
      prob_h      DOUBLE,
      prob_d      DOUBLE,
      prob_a      DOUBLE,
      overround   DOUBLE,
      PRIMARY KEY (match_id, bookmaker, market, snapshot_type)
    )
  ")

  DBI::dbExecute(con, "
    CREATE TABLE IF NOT EXISTS teams (
      team_id         VARCHAR PRIMARY KEY,
      team_name       VARCHAR,
      league_code     VARCHAR,
      country         VARCHAR,
      squad_value_eur DOUBLE,
      wage_bill_eur   DOUBLE,
      data_season     VARCHAR
    )
  ")

  DBI::dbExecute(con, "
    CREATE TABLE IF NOT EXISTS transfers (
      transfer_id     VARCHAR PRIMARY KEY,
      player_name     VARCHAR,
      transfer_date   DATE,
      season          VARCHAR,
      from_team       VARCHAR,
      to_team         VARCHAR,
      league_from     VARCHAR,
      league_to       VARCHAR,
      fee_eur         DOUBLE,
      fee_type        VARCHAR,
      position        VARCHAR,
      age_at_transfer INTEGER
    )
  ")

  invisible(con)
}

#' Insert parsed match data into DuckDB
#'
#' Inserts match data, skipping rows whose `match_id` already exists.
#'
#' @param con A DBI connection.
#' @param matches_df A tibble from [parse_fd_csv()].
#' @return Number of rows inserted (invisibly).
#' @family storage
#' @export
insert_matches <- function(con, matches_df) {
  if (nrow(matches_df) == 0L) return(invisible(0L))

  # Ensure column order matches the schema
  cols <- c("match_id", "season", "league_code", "match_date",
            "home_team", "away_team", "fthg", "ftag", "ftr",
            "hthg", "htag", "htr", "hs", "as_", "hst", "ast",
            "hc", "ac", "hf", "af", "hy", "ay", "hr", "ar")
  matches_df <- matches_df[, intersect(cols, colnames(matches_df))]

  # Stage in temp table, then INSERT ... ON CONFLICT to skip duplicates
  DBI::dbWriteTable(con, "matches_staging", matches_df, overwrite = TRUE)
  col_list <- paste(colnames(matches_df), collapse = ", ")
  n <- DBI::dbExecute(con, glue::glue("
    INSERT INTO matches ({col_list})
    SELECT {col_list} FROM matches_staging
    ON CONFLICT (match_id) DO NOTHING
  "))
  DBI::dbExecute(con, "DROP TABLE IF EXISTS matches_staging")
  invisible(n)
}

#' Insert parsed odds data into DuckDB
#'
#' Inserts Pinnacle and market aggregate odds for each match. Creates
#' one row per match with bookmaker = 'pinnacle', market = '1x2',
#' snapshot_type = 'closing'.
#'
#' @param con A DBI connection.
#' @param odds_df A tibble from [parse_fd_odds()].
#' @return Number of rows inserted (invisibly).
#' @family storage
#' @export
insert_match_odds <- function(con, odds_df) {
  if (nrow(odds_df) == 0L) return(invisible(0L))

  # Build a single-row-per-match odds record
  ins <- tibble::tibble(
    match_id      = odds_df$match_id,
    bookmaker     = "pinnacle",
    market        = "1x2",
    snapshot_type = "closing",
    odds_h        = odds_df$psh,
    odds_d        = odds_df$psd,
    odds_a        = odds_df$psa,
    odds_over25   = odds_df$p_over25,
    odds_under25  = odds_df$p_under25,
    ah_line       = odds_df$ah_line,
    odds_ahh      = odds_df$pahh,
    odds_aha      = odds_df$paha,
    prob_h        = NA_real_,
    prob_d        = NA_real_,
    prob_a        = NA_real_,
    overround     = NA_real_
  )

  # Compute overround + implied probs where Pinnacle 1X2 all present
  has_1x2 <- !is.na(ins$odds_h) & !is.na(ins$odds_d) & !is.na(ins$odds_a)
  if (any(has_1x2)) {
    inv_h <- 1 / ins$odds_h[has_1x2]
    inv_d <- 1 / ins$odds_d[has_1x2]
    inv_a <- 1 / ins$odds_a[has_1x2]
    total <- inv_h + inv_d + inv_a
    ins$overround[has_1x2] <- total - 1
    ins$prob_h[has_1x2] <- inv_h / total
    ins$prob_d[has_1x2] <- inv_d / total
    ins$prob_a[has_1x2] <- inv_a / total
  }

  DBI::dbWriteTable(con, "match_odds_staging", ins, overwrite = TRUE)
  col_list <- paste(colnames(ins), collapse = ", ")
  n <- DBI::dbExecute(con, glue::glue("
    INSERT INTO match_odds ({col_list})
    SELECT {col_list} FROM match_odds_staging
    ON CONFLICT (match_id, bookmaker, market, snapshot_type) DO NOTHING
  "))
  DBI::dbExecute(con, "DROP TABLE IF EXISTS match_odds_staging")
  invisible(n)
}

#' Write match data as partitioned Parquet
#'
#' Writes parsed match data to Parquet files partitioned by
#' `season` and `league_code`. Existing partitions are overwritten.
#'
#' @param matches_df A tibble from [parse_fd_csv()] (or a combined tibble).
#' @param parquet_dir Character. Output directory for Parquet partitions.
#'   Defaults to `inst/extdata/parquet/matches`.
#' @return `parquet_dir` invisibly.
#' @family storage
#' @export
write_matches_parquet <- function(
    matches_df,
    parquet_dir = here::here("inst", "extdata", "parquet", "matches")) {
  rlang::check_installed("arrow", reason = "to write Parquet files")
  if (nrow(matches_df) == 0L) {
    cli::cli_warn("No rows to write to Parquet.")
    return(invisible(parquet_dir))
  }
  if (!dir.exists(parquet_dir)) dir.create(parquet_dir, recursive = TRUE)
  arrow::write_dataset(
    matches_df,
    parquet_dir,
    format = "parquet",
    partitioning = c("season", "league_code"),
    existing_data_behavior = "overwrite"
  )
  cli::cli_alert_success("Wrote {nrow(matches_df)} rows to {.path {parquet_dir}}")
  invisible(parquet_dir)
}

#' Write odds data as partitioned Parquet
#'
#' @param odds_df A tibble from [parse_fd_odds()] (or a combined tibble).
#'   Must include a `season` column (join from matches).
#' @param parquet_dir Character. Output directory.
#' @return `parquet_dir` invisibly.
#' @family storage
#' @export
write_odds_parquet <- function(
    odds_df,
    parquet_dir = here::here("inst", "extdata", "parquet", "odds")) {
  rlang::check_installed("arrow", reason = "to write Parquet files")
  if (nrow(odds_df) == 0L) {
    cli::cli_warn("No rows to write to Parquet.")
    return(invisible(parquet_dir))
  }

  if (!dir.exists(parquet_dir)) dir.create(parquet_dir, recursive = TRUE)
  arrow::write_dataset(
    odds_df,
    parquet_dir,
    format = "parquet",
    existing_data_behavior = "overwrite"
  )
  cli::cli_alert_success("Wrote {nrow(odds_df)} rows to {.path {parquet_dir}}")
  invisible(parquet_dir)
}

#' Create predictions table schema
#'
#' Creates the `predictions` table for logging model predictions.
#'
#' @param con A DBI connection to DuckDB.
#' @return `con` invisibly.
#' @family storage
#' @export
create_predictions_schema <- function(con) {
  DBI::dbExecute(con, "
    CREATE TABLE IF NOT EXISTS predictions (
      prediction_id   VARCHAR PRIMARY KEY,
      match_id        VARCHAR,
      model_name      VARCHAR,
      predicted_at    TIMESTAMP,
      prob_h          DOUBLE,
      prob_d          DOUBLE,
      prob_a          DOUBLE,
      prob_over25     DOUBLE,
      prob_under25    DOUBLE,
      lambda_home     DOUBLE,
      lambda_away     DOUBLE,
      edge_h          DOUBLE,
      edge_d          DOUBLE,
      edge_a          DOUBLE,
      kelly_h         DOUBLE,
      kelly_d         DOUBLE,
      kelly_a         DOUBLE,
      actual_ftr      VARCHAR,
      actual_fthg     INTEGER,
      actual_ftag     INTEGER,
      clv_h           DOUBLE,
      clv_d           DOUBLE,
      clv_a           DOUBLE,
      profit_loss     DOUBLE
    )
  ")
  invisible(con)
}

#' Log model prediction to database
#'
#' Stores a model prediction with timestamp for tracking and analysis.
#' Uses upsert to avoid duplicates.
#'
#' @param con A DBI connection.
#' @param match_id Character. Match identifier.
#' @param model_name Character. Name of the model (e.g., "glm", "dc", "brms").
#' @param prob_h Numeric. Predicted P(Home win).
#' @param prob_d Numeric. Predicted P(Draw).
#' @param prob_a Numeric. Predicted P(Away win).
#' @param prob_over25 Numeric. Predicted P(Over 2.5 goals). Optional.
#' @param prob_under25 Numeric. Predicted P(Under 2.5 goals). Optional.
#' @param lambda_home Numeric. Expected home goals. Optional.
#' @param lambda_away Numeric. Expected away goals. Optional.
#' @param edge_h Numeric. Edge on home bet. Optional.
#' @param edge_d Numeric. Edge on draw bet. Optional.
#' @param edge_a Numeric. Edge on away bet. Optional.
#' @param kelly_h Numeric. Kelly stake for home bet. Optional.
#' @param kelly_d Numeric. Kelly stake for draw bet. Optional.
#' @param kelly_a Numeric. Kelly stake for away bet. Optional.
#' @return The prediction_id (invisibly).
#' @family storage
#' @export
log_prediction <- function(con,
                           match_id,
                           model_name,
                           prob_h,
                           prob_d,
                           prob_a,
                           prob_over25 = NA_real_,
                           prob_under25 = NA_real_,
                           lambda_home = NA_real_,
                           lambda_away = NA_real_,
                           edge_h = NA_real_,
                           edge_d = NA_real_,
                           edge_a = NA_real_,
                           kelly_h = NA_real_,
                           kelly_d = NA_real_,
                           kelly_a = NA_real_) {
  rlang::check_required(match_id)
  rlang::check_required(model_name)
  rlang::check_required(prob_h)
  rlang::check_required(prob_d)
  rlang::check_required(prob_a)

  # Generate unique prediction ID
  prediction_id <- paste(match_id, model_name, format(Sys.time(), "%Y%m%d%H%M%S"), sep = "_")

  pred_df <- tibble::tibble(
    prediction_id = prediction_id,
    match_id = match_id,
    model_name = model_name,
    predicted_at = Sys.time(),
    prob_h = prob_h,
    prob_d = prob_d,
    prob_a = prob_a,
    prob_over25 = prob_over25,
    prob_under25 = prob_under25,
    lambda_home = lambda_home,
    lambda_away = lambda_away,
    edge_h = edge_h,
    edge_d = edge_d,
    edge_a = edge_a,
    kelly_h = kelly_h,
    kelly_d = kelly_d,
    kelly_a = kelly_a,
    actual_ftr = NA_character_,
    actual_fthg = NA_integer_,
    actual_ftag = NA_integer_,
    clv_h = NA_real_,
    clv_d = NA_real_,
    clv_a = NA_real_,
    profit_loss = NA_real_
  )

  DBI::dbWriteTable(con, "predictions_staging", pred_df, overwrite = TRUE)
  DBI::dbExecute(con, "
    INSERT INTO predictions
    SELECT * FROM predictions_staging
    ON CONFLICT (prediction_id) DO UPDATE SET
      prob_h = EXCLUDED.prob_h,
      prob_d = EXCLUDED.prob_d,
      prob_a = EXCLUDED.prob_a,
      predicted_at = EXCLUDED.predicted_at
  ")
  DBI::dbExecute(con, "DROP TABLE IF EXISTS predictions_staging")

  invisible(prediction_id)
}

#' Batch log predictions from a tibble
#'
#' @param con A DBI connection.
#' @param predictions_df A tibble with columns: `match_id`, `model_name`,
#'   `prob_h`, `prob_d`, `prob_a`, and optional columns for lambda, edge, kelly.
#' @return Number of rows inserted (invisibly).
#' @family storage
#' @export
log_predictions_batch <- function(con, predictions_df) {
  rlang::check_required(predictions_df)

  required <- c("match_id", "model_name", "prob_h", "prob_d", "prob_a")
  missing <- setdiff(required, names(predictions_df))
  if (length(missing) > 0L) {
    cli::cli_abort("Missing required columns: {.val {missing}}")
  }

  # Add missing optional columns
  optional_cols <- c("prob_over25", "prob_under25", "lambda_home", "lambda_away",
                     "edge_h", "edge_d", "edge_a", "kelly_h", "kelly_d", "kelly_a")
  for (col in optional_cols) {
    if (!col %in% names(predictions_df)) {
      predictions_df[[col]] <- NA_real_
    }
  }

  # Generate prediction IDs
  predictions_df$prediction_id <- paste(
    predictions_df$match_id,
    predictions_df$model_name,
    format(Sys.time(), "%Y%m%d%H%M%S"),
    seq_len(nrow(predictions_df)),
    sep = "_"
  )
  predictions_df$predicted_at <- Sys.time()

  # Add outcome columns (to be filled later)
  predictions_df$actual_ftr <- NA_character_
  predictions_df$actual_fthg <- NA_integer_
  predictions_df$actual_ftag <- NA_integer_
  predictions_df$clv_h <- NA_real_
  predictions_df$clv_d <- NA_real_
  predictions_df$clv_a <- NA_real_
  predictions_df$profit_loss <- NA_real_

  # Ensure column order
  col_order <- c("prediction_id", "match_id", "model_name", "predicted_at",
                 "prob_h", "prob_d", "prob_a", "prob_over25", "prob_under25",
                 "lambda_home", "lambda_away", "edge_h", "edge_d", "edge_a",
                 "kelly_h", "kelly_d", "kelly_a", "actual_ftr", "actual_fthg",
                 "actual_ftag", "clv_h", "clv_d", "clv_a", "profit_loss")
  predictions_df <- predictions_df[, col_order]

  DBI::dbWriteTable(con, "predictions_staging", predictions_df, overwrite = TRUE)
  n <- DBI::dbExecute(con, "
    INSERT INTO predictions
    SELECT * FROM predictions_staging
    ON CONFLICT (prediction_id) DO NOTHING
  ")
  DBI::dbExecute(con, "DROP TABLE IF EXISTS predictions_staging")

  cli::cli_alert_success("Logged {nrow(predictions_df)} predictions")
  invisible(n)
}

#' Update prediction outcomes after match completion
#'
#' @param con A DBI connection.
#' @param match_id Character. Match identifier.
#' @param ftr Character. Full-time result ("H", "D", "A").
#' @param fthg Integer. Full-time home goals.
#' @param ftag Integer. Full-time away goals.
#' @param closing_h Numeric. Pinnacle closing odds (Home). Optional for CLV.
#' @param closing_d Numeric. Pinnacle closing odds (Draw). Optional for CLV.
#' @param closing_a Numeric. Pinnacle closing odds (Away). Optional for CLV.
#' @return Number of rows updated (invisibly).
#' @family storage
#' @export
update_prediction_outcome <- function(con,
                                       match_id,
                                       ftr,
                                       fthg,
                                       ftag,
                                       closing_h = NA_real_,
                                       closing_d = NA_real_,
                                       closing_a = NA_real_) {
  rlang::check_required(match_id)
  rlang::check_required(ftr)
  rlang::check_required(fthg)
  rlang::check_required(ftag)

  # First update basic outcome
  n <- DBI::dbExecute(con, glue::glue("
    UPDATE predictions
    SET actual_ftr = '{ftr}',
        actual_fthg = {fthg},
        actual_ftag = {ftag}
    WHERE match_id = '{match_id}'
  "))

  # If closing odds provided, compute CLV
  if (!is.na(closing_h) && !is.na(closing_d) && !is.na(closing_a)) {
    # Get predictions for this match
    preds <- DBI::dbGetQuery(con, glue::glue("
      SELECT prediction_id, prob_h, prob_d, prob_a
      FROM predictions
      WHERE match_id = '{match_id}'
    "))

    if (nrow(preds) > 0L) {
      # Compute closing implied probabilities
      total <- 1/closing_h + 1/closing_d + 1/closing_a
      close_h <- (1/closing_h) / total
      close_d <- (1/closing_d) / total
      close_a <- (1/closing_a) / total

      for (i in seq_len(nrow(preds))) {
        clv_h <- preds$prob_h[[i]] - close_h
        clv_d <- preds$prob_d[[i]] - close_d
        clv_a <- preds$prob_a[[i]] - close_a

        DBI::dbExecute(con, glue::glue("
          UPDATE predictions
          SET clv_h = {clv_h},
              clv_d = {clv_d},
              clv_a = {clv_a}
          WHERE prediction_id = '{preds$prediction_id[[i]]}'
        "))
      }
    }
  }

  invisible(n)
}

#' Query predictions for analysis
#'
#' @param con A DBI connection.
#' @param model_name Character. Filter by model (optional).
#' @param from_date Date. Filter predictions from this date (optional).
#' @param to_date Date. Filter predictions to this date (optional).
#' @param only_settled Logical. Only return predictions with outcomes (default TRUE).
#' @return A tibble of predictions.
#' @family storage
#' @export
query_predictions <- function(con,
                              model_name = NULL,
                              from_date = NULL,
                              to_date = NULL,
                              only_settled = TRUE) {
  sql <- "SELECT * FROM predictions WHERE 1=1"

  if (!is.null(model_name)) {
    sql <- paste0(sql, " AND model_name = '", model_name, "'")
  }
  if (!is.null(from_date)) {
    sql <- paste0(sql, " AND predicted_at >= '", from_date, "'")
  }
  if (!is.null(to_date)) {
    sql <- paste0(sql, " AND predicted_at <= '", to_date, "'")
  }
  if (only_settled) {
    sql <- paste0(sql, " AND actual_ftr IS NOT NULL")
  }

  sql <- paste0(sql, " ORDER BY predicted_at DESC")

  tibble::as_tibble(DBI::dbGetQuery(con, sql))
}

#' Disconnect from the DuckDB database
#'
#' @param con A DBI connection.
#' @return `NULL` invisibly.
#' @family storage
#' @export
disconnect_db <- function(con) {
  DBI::dbDisconnect(con, shutdown = TRUE)
  invisible(NULL)
}
