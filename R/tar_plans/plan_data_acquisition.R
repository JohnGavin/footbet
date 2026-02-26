# plan_data_acquisition.R
# Downloads match CSVs from football-data.co.uk, parses, and stores
# in DuckDB + Parquet.

plan_data_acquisition <- list(

  targets::tar_target(
    leagues,
    target_leagues()
  ),

  targets::tar_target(
    seasons,
    target_seasons()
  ),

  targets::tar_target(
    downloaded_files,
    download_all_fd(leagues, seasons),
    cue = targets::tar_cue(mode = "thorough")
  ),

  # Parse match results from each downloaded CSV
  targets::tar_target(
    parsed_matches,
    {
      valid <- downloaded_files[!is.na(downloaded_files$file_path), ]
      if (nrow(valid) == 0L) return(tibble::tibble())
      dfs <- lapply(seq_len(nrow(valid)), function(i) {
        parse_fd_csv(valid$file_path[[i]], valid$league_code[[i]], valid$season[[i]])
      })
      dplyr::bind_rows(dfs)
    }
  ),

  # Parse odds from each downloaded CSV
  targets::tar_target(
    parsed_odds,
    {
      valid <- downloaded_files[!is.na(downloaded_files$file_path), ]
      if (nrow(valid) == 0L) return(tibble::tibble())
      dfs <- lapply(seq_len(nrow(valid)), function(i) {
        parse_fd_odds(valid$file_path[[i]], valid$league_code[[i]], valid$season[[i]])
      })
      dplyr::bind_rows(dfs)
    }
  ),

  # Write matches to Parquet (partitioned by season/league)
  targets::tar_target(
    matches_parquet,
    write_matches_parquet(parsed_matches)
  ),

  # Write odds to Parquet
  targets::tar_target(
    odds_parquet,
    write_odds_parquet(
      dplyr::left_join(
        parsed_odds,
        dplyr::select(parsed_matches, match_id, season, league_code),
        by = "match_id"
      )
    )
  ),

  # Load into DuckDB
  targets::tar_target(
    db_loaded,
    {
      db_path <- here::here("inst", "extdata", "footbet.duckdb")
      con <- connect_db(db_path)
      on.exit(disconnect_db(con))
      create_schema(con)
      n_matches <- insert_matches(con, parsed_matches)
      n_odds <- insert_match_odds(con, parsed_odds)
      list(matches = n_matches, odds = n_odds, db_path = db_path)
    }
  )
)
