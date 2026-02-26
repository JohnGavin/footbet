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
#' @param con A DBI connection.
#' @param matches_df A tibble from [parse_fd_csv()].
#' @return Number of rows inserted (invisibly).
#' @family storage
#' @export
insert_matches <- function(con, matches_df) {
  if (nrow(matches_df) == 0L) return(invisible(0L))

  # Use INSERT OR IGNORE to handle duplicates
  DBI::dbWriteTable(con, "matches", matches_df, append = TRUE)
  invisible(nrow(matches_df))
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
