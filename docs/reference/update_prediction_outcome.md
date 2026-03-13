# Update prediction outcomes after match completion

Update prediction outcomes after match completion

## Usage

``` r
update_prediction_outcome(
  con,
  match_id,
  ftr,
  fthg,
  ftag,
  closing_h = NA_real_,
  closing_d = NA_real_,
  closing_a = NA_real_
)
```

## Arguments

- con:

  A DBI connection.

- match_id:

  Character. Match identifier.

- ftr:

  Character. Full-time result ("H", "D", "A").

- fthg:

  Integer. Full-time home goals.

- ftag:

  Integer. Full-time away goals.

- closing_h:

  Numeric. Pinnacle closing odds (Home). Optional for CLV.

- closing_d:

  Numeric. Pinnacle closing odds (Draw). Optional for CLV.

- closing_a:

  Numeric. Pinnacle closing odds (Away). Optional for CLV.

## Value

Number of rows updated (invisibly).

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
[`write_matches_parquet()`](https://johngavin.github.io/footbet/reference/write_matches_parquet.md),
[`write_odds_parquet()`](https://johngavin.github.io/footbet/reference/write_odds_parquet.md)
