# Insert parsed odds data into DuckDB

Inserts Pinnacle and market aggregate odds for each match. Creates one
row per match with bookmaker = 'pinnacle', market = '1x2', snapshot_type
= 'closing'.

## Usage

``` r
insert_match_odds(con, odds_df)
```

## Arguments

- con:

  A DBI connection.

- odds_df:

  A tibble from
  [`parse_fd_odds()`](https://johngavin.github.io/footbet/reference/parse_fd_odds.md).

## Value

Number of rows inserted (invisibly).

## See also

Other storage:
[`connect_db()`](https://johngavin.github.io/footbet/reference/connect_db.md),
[`create_predictions_schema()`](https://johngavin.github.io/footbet/reference/create_predictions_schema.md),
[`create_schema()`](https://johngavin.github.io/footbet/reference/create_schema.md),
[`disconnect_db()`](https://johngavin.github.io/footbet/reference/disconnect_db.md),
[`insert_matches()`](https://johngavin.github.io/footbet/reference/insert_matches.md),
[`insert_transfers()`](https://johngavin.github.io/footbet/reference/insert_transfers.md),
[`log_prediction()`](https://johngavin.github.io/footbet/reference/log_prediction.md),
[`log_predictions_batch()`](https://johngavin.github.io/footbet/reference/log_predictions_batch.md),
[`query_predictions()`](https://johngavin.github.io/footbet/reference/query_predictions.md),
[`update_prediction_outcome()`](https://johngavin.github.io/footbet/reference/update_prediction_outcome.md),
[`write_matches_parquet()`](https://johngavin.github.io/footbet/reference/write_matches_parquet.md),
[`write_odds_parquet()`](https://johngavin.github.io/footbet/reference/write_odds_parquet.md)
