# Collect match-level predictions for a single league

Collect match-level predictions for a single league

## Usage

``` r
collect_fold_predictions_single(
  long_df,
  matches_df,
  train_months = 24L,
  test_months = 1L,
  model_label = "model",
  league_code = NA_character_
)
```

## Arguments

- long_df:

  Long-format match data for GLM fitting.

- matches_df:

  Wide-format matches with `match_id`, `ftr`, `match_date`,
  `league_code`.

- train_months:

  Integer. Training window (default 24).

- test_months:

  Integer. Test period (default 1).

- model_label:

  Character. Label for the model (e.g., "goals_only").

- league_code:

  Character. League identifier.

## Value

A tibble of per-match predictions.
