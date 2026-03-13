# Write match data as partitioned Parquet

Writes parsed match data to Parquet files partitioned by `season` and
`league_code`. Existing partitions are overwritten.

## Usage

``` r
write_matches_parquet(
  matches_df,
  parquet_dir = here::here("inst", "extdata", "parquet", "matches")
)
```

## Arguments

- matches_df:

  A tibble from
  [`parse_fd_csv()`](https://johngavin.github.io/footbet/reference/parse_fd_csv.md)
  (or a combined tibble).

- parquet_dir:

  Character. Output directory for Parquet partitions. Defaults to
  `inst/extdata/parquet/matches`.

## Value

`parquet_dir` invisibly.

## See also

Other storage:
[`connect_db()`](https://johngavin.github.io/footbet/reference/connect_db.md),
[`create_predictions_schema()`](https://johngavin.github.io/footbet/reference/create_predictions_schema.md),
[`create_schema()`](https://johngavin.github.io/footbet/reference/create_schema.md),
[`disconnect_db()`](https://johngavin.github.io/footbet/reference/disconnect_db.md),
[`insert_match_odds()`](https://johngavin.github.io/footbet/reference/insert_match_odds.md),
[`insert_matches()`](https://johngavin.github.io/footbet/reference/insert_matches.md),
[`insert_transfers()`](https://johngavin.github.io/footbet/reference/insert_transfers.md),
[`log_prediction()`](https://johngavin.github.io/footbet/reference/log_prediction.md),
[`log_predictions_batch()`](https://johngavin.github.io/footbet/reference/log_predictions_batch.md),
[`query_predictions()`](https://johngavin.github.io/footbet/reference/query_predictions.md),
[`update_prediction_outcome()`](https://johngavin.github.io/footbet/reference/update_prediction_outcome.md),
[`write_odds_parquet()`](https://johngavin.github.io/footbet/reference/write_odds_parquet.md)
