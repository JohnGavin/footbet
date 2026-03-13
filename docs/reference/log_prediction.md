# Log model prediction to database

Stores a model prediction with timestamp for tracking and analysis. Uses
upsert to avoid duplicates.

## Usage

``` r
log_prediction(
  con,
  match_id,
  model_name,
  prob_h,
  prob_d,
  prob_a,
  prob_over25 = NA_real_,
  prob_under25 = NA_real_,
  lambda_home = NA_real_,
  lambda_away = NA_real_,
  edge_h = NA_real_,
  edge_d = NA_real_,
  edge_a = NA_real_,
  kelly_h = NA_real_,
  kelly_d = NA_real_,
  kelly_a = NA_real_
)
```

## Arguments

- con:

  A DBI connection.

- match_id:

  Character. Match identifier.

- model_name:

  Character. Name of the model (e.g., "glm", "dc", "brms").

- prob_h:

  Numeric. Predicted P(Home win).

- prob_d:

  Numeric. Predicted P(Draw).

- prob_a:

  Numeric. Predicted P(Away win).

- prob_over25:

  Numeric. Predicted P(Over 2.5 goals). Optional.

- prob_under25:

  Numeric. Predicted P(Under 2.5 goals). Optional.

- lambda_home:

  Numeric. Expected home goals. Optional.

- lambda_away:

  Numeric. Expected away goals. Optional.

- edge_h:

  Numeric. Edge on home bet. Optional.

- edge_d:

  Numeric. Edge on draw bet. Optional.

- edge_a:

  Numeric. Edge on away bet. Optional.

- kelly_h:

  Numeric. Kelly stake for home bet. Optional.

- kelly_d:

  Numeric. Kelly stake for draw bet. Optional.

- kelly_a:

  Numeric. Kelly stake for away bet. Optional.

## Value

The prediction_id (invisibly).

## See also

Other storage:
[`connect_db()`](https://johngavin.github.io/footbet/reference/connect_db.md),
[`create_predictions_schema()`](https://johngavin.github.io/footbet/reference/create_predictions_schema.md),
[`create_schema()`](https://johngavin.github.io/footbet/reference/create_schema.md),
[`disconnect_db()`](https://johngavin.github.io/footbet/reference/disconnect_db.md),
[`insert_match_odds()`](https://johngavin.github.io/footbet/reference/insert_match_odds.md),
[`insert_matches()`](https://johngavin.github.io/footbet/reference/insert_matches.md),
[`insert_transfers()`](https://johngavin.github.io/footbet/reference/insert_transfers.md),
[`log_predictions_batch()`](https://johngavin.github.io/footbet/reference/log_predictions_batch.md),
[`query_predictions()`](https://johngavin.github.io/footbet/reference/query_predictions.md),
[`update_prediction_outcome()`](https://johngavin.github.io/footbet/reference/update_prediction_outcome.md),
[`write_matches_parquet()`](https://johngavin.github.io/footbet/reference/write_matches_parquet.md),
[`write_odds_parquet()`](https://johngavin.github.io/footbet/reference/write_odds_parquet.md)
