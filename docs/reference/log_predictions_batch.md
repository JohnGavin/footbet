# Batch log predictions from a tibble

Batch log predictions from a tibble

## Usage

``` r
log_predictions_batch(con, predictions_df)
```

## Arguments

- con:

  A DBI connection.

- predictions_df:

  A tibble with columns: `match_id`, `model_name`, `prob_h`, `prob_d`,
  `prob_a`, and optional columns for lambda, edge, kelly.

## Value

Number of rows inserted (invisibly).

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
[`query_predictions()`](https://johngavin.github.io/footbet/reference/query_predictions.md),
[`update_prediction_outcome()`](https://johngavin.github.io/footbet/reference/update_prediction_outcome.md),
[`write_matches_parquet()`](https://johngavin.github.io/footbet/reference/write_matches_parquet.md),
[`write_odds_parquet()`](https://johngavin.github.io/footbet/reference/write_odds_parquet.md)
