# fix_transfer_data.R — Issue #6: Transfer data via worldfootballR
#
# Changes made:
# 1. Implemented fetch_league_transfers() — wraps tm_league_team_urls +
#    tm_team_transfers with per-team rate limiting
# 2. Implemented fetch_squad_values() — wraps tm_player_market_values,
#    aggregates to team-level squad values
# 3. Added insert_transfers() to R/data_transfers.R — staging table +
#    ON CONFLICT DO NOTHING for idempotent inserts
# 4. Added parse_transfer_fee() and classify_fee() internal helpers
# 5. Added standardise_transfers() to handle varying worldfootballR column names
# 6. Tests: unit + adversarial covering parsing, standardisation, DuckDB insert

# Quick verification (requires network access + worldfootballR):
if (FALSE) {
  devtools::load_all()

  # Fetch transfers for 1 country, 1 season
  transfers <- fetch_league_transfers("England", 2024L, delay = 7)
  cat("Fetched:", nrow(transfers), "transfers\n")
  head(transfers)

  # Fetch squad values
  values <- fetch_squad_values("England", 2024L)
  cat("Squad values:", nrow(values), "teams\n")
  head(values)

  # DuckDB roundtrip

  con <- connect_db(":memory:")
  create_schema(con)
  n <- insert_transfers(con, transfers)
  cat("Inserted:", n, "transfers into DuckDB\n")
  disconnect_db(con)
}
