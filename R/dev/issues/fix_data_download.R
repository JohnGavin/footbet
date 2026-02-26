# fix_data_download.R — Issue #3: Data download pipeline
# Run after PR merge to verify pipeline works end-to-end
#
# Changes made:
# 1. Added insert_match_odds() to R/database.R
# 2. Added write_matches_parquet() and write_odds_parquet() to R/database.R
# 3. Completed plan_data_acquisition.R with parse/insert/parquet targets
# 4. Completed plan_quality_control.R with completeness/coverage/anomaly targets
# 5. Moved `here` from Suggests to Imports (used in exported function defaults)
# 6. Updated insert_matches() to use staging table + ON CONFLICT DO NOTHING
# 7. Expanded tests: parse integration, database roundtrip, adversarial QA

# Quick verification (1 league, 1 season):
if (FALSE) {
  devtools::load_all()

  # Download
  csv_path <- download_fd_csv("E0", "2324")

  # Parse
  matches <- parse_fd_csv(csv_path, "E0", "2324")
  odds <- parse_fd_odds(csv_path, "E0", "2324")
  cat("Parsed:", nrow(matches), "matches,", nrow(odds), "odds rows\n")

  # DuckDB roundtrip
  con <- connect_db(":memory:")
  create_schema(con)
  insert_matches(con, matches)
  insert_match_odds(con, odds)

  db_matches <- DBI::dbGetQuery(con, "SELECT COUNT(*) AS n FROM matches")
  db_odds <- DBI::dbGetQuery(con, "SELECT COUNT(*) AS n FROM match_odds")
  cat("DB:", db_matches$n, "matches,", db_odds$n, "odds\n")

  # Pinnacle coverage
  pin <- DBI::dbGetQuery(con, "SELECT COUNT(*) AS n FROM match_odds WHERE odds_h IS NOT NULL")
  cat("Pinnacle odds:", pin$n, "/", db_odds$n, "\n")

  disconnect_db(con)
}
