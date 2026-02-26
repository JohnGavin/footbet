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
