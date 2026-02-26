# plan_data_acquisition.R
# Downloads match CSVs from football-data.co.uk and loads into DuckDB

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
    # Re-run when leagues/seasons change
    cue = targets::tar_cue(mode = "thorough")
  )

  # TODO (PR #2): Add targets for:
  # - parse_fd_csv per file

  # - parse_fd_odds per file
  # - insert_matches into DuckDB
  # - write Parquet partitions
)
