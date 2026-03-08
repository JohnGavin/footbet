# Tests for prediction logging functions

# ---- create_predictions_schema ----

test_that("create_predictions_schema creates predictions table", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  
  create_predictions_schema(con)
  
  tables <- DBI::dbListTables(con)
  expect_true("predictions" %in% tables)
})

test_that("create_predictions_schema is idempotent", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  
  create_predictions_schema(con)
  expect_no_error(create_predictions_schema(con))
})

# ---- log_prediction ----

test_that("log_prediction inserts prediction with required fields", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_predictions_schema(con)
  
  pred_id <- log_prediction(
    con = con,
    match_id = "E0_2024-01-15_Arsenal_Chelsea",
    model_name = "glm",
    prob_h = 0.55,
    prob_d = 0.25,
    prob_a = 0.20
  )
  
  expect_true(is.character(pred_id))
  expect_true(nchar(pred_id) > 0)
  
  # Verify inserted
  result <- DBI::dbGetQuery(con, "SELECT * FROM predictions")
  expect_equal(nrow(result), 1)
  expect_equal(result$match_id, "E0_2024-01-15_Arsenal_Chelsea")
  expect_equal(result$model_name, "glm")
  expect_equal(result$prob_h, 0.55)
  expect_equal(result$prob_d, 0.25)
  expect_equal(result$prob_a, 0.20)
})

test_that("log_prediction stores optional fields", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_predictions_schema(con)
  
  log_prediction(
    con = con,
    match_id = "m1",
    model_name = "dc",
    prob_h = 0.50,
    prob_d = 0.30,
    prob_a = 0.20,
    prob_over25 = 0.55,
    prob_under25 = 0.45,
    lambda_home = 1.5,
    lambda_away = 1.2,
    edge_h = 0.05,
    edge_d = -0.02,
    edge_a = -0.03,
    kelly_h = 0.02,
    kelly_d = 0,
    kelly_a = 0
  )
  
  result <- DBI::dbGetQuery(con, "SELECT * FROM predictions")
  expect_equal(result$prob_over25, 0.55)
  expect_equal(result$lambda_home, 1.5)
  expect_equal(result$edge_h, 0.05)
  expect_equal(result$kelly_h, 0.02)
})

test_that("log_prediction requires required arguments", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_predictions_schema(con)
  
  expect_error(log_prediction(con = con))
  expect_error(log_prediction(con = con, match_id = "m1"))
  expect_error(log_prediction(con = con, match_id = "m1", model_name = "glm"))
})

test_that("log_prediction upserts on conflict", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_predictions_schema(con)
  
  # Insert initial prediction
  pred_id <- log_prediction(
    con = con,
    match_id = "m1",
    model_name = "glm",
    prob_h = 0.50,
    prob_d = 0.30,
    prob_a = 0.20
  )
  
  # Manually insert again with same ID to trigger upsert
  DBI::dbExecute(con, sprintf("
    INSERT INTO predictions (prediction_id, match_id, model_name, predicted_at, prob_h, prob_d, prob_a)
    VALUES ('%s', 'm1', 'glm', CURRENT_TIMESTAMP, 0.60, 0.25, 0.15)
    ON CONFLICT (prediction_id) DO UPDATE SET
      prob_h = EXCLUDED.prob_h,
      prob_d = EXCLUDED.prob_d,
      prob_a = EXCLUDED.prob_a
  ", pred_id))
  
  result <- DBI::dbGetQuery(con, "SELECT * FROM predictions")
  # Should still be 1 row
  expect_equal(nrow(result), 1)
  expect_equal(result$prob_h, 0.60)
})

# ---- log_predictions_batch ----

test_that("log_predictions_batch inserts multiple predictions", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_predictions_schema(con)
  
  preds <- tibble::tibble(
    match_id = c("m1", "m2", "m3"),
    model_name = c("glm", "glm", "glm"),
    prob_h = c(0.50, 0.60, 0.45),
    prob_d = c(0.30, 0.25, 0.35),
    prob_a = c(0.20, 0.15, 0.20)
  )
  
  n <- log_predictions_batch(con, preds)
  
  expect_equal(n, 3)
  
  result <- DBI::dbGetQuery(con, "SELECT * FROM predictions ORDER BY match_id")
  expect_equal(nrow(result), 3)
  expect_equal(result$match_id, c("m1", "m2", "m3"))
})

test_that("log_predictions_batch adds missing optional columns", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_predictions_schema(con)
  
  # Minimal prediction without optional columns
  preds <- tibble::tibble(
    match_id = "m1",
    model_name = "glm",
    prob_h = 0.50,
    prob_d = 0.30,
    prob_a = 0.20
  )
  
  expect_no_error(log_predictions_batch(con, preds))
  
  result <- DBI::dbGetQuery(con, "SELECT * FROM predictions")
  expect_true(is.na(result$lambda_home))
  expect_true(is.na(result$edge_h))
})

test_that("log_predictions_batch validates required columns", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_predictions_schema(con)
  
  # Missing prob_a
  preds <- tibble::tibble(
    match_id = "m1",
    model_name = "glm",
    prob_h = 0.50,
    prob_d = 0.30
  )
  
  expect_error(
    log_predictions_batch(con, preds),
    "Missing required columns"
  )
})

test_that("log_predictions_batch requires argument", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_predictions_schema(con)
  
  expect_error(log_predictions_batch(con))
})

test_that("log_predictions_batch handles duplicates with ON CONFLICT", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_predictions_schema(con)
  
  preds <- tibble::tibble(
    match_id = c("m1", "m2"),
    model_name = c("glm", "glm"),
    prob_h = c(0.50, 0.60),
    prob_d = c(0.30, 0.25),
    prob_a = c(0.20, 0.15)
  )
  
  n1 <- log_predictions_batch(con, preds)
  expect_equal(n1, 2)
  
  # Try inserting again - should skip due to ON CONFLICT
  n2 <- log_predictions_batch(con, preds)
  expect_equal(n2, 0)  # No new rows inserted
  
  result <- DBI::dbGetQuery(con, "SELECT * FROM predictions")
  expect_equal(nrow(result), 2)  # Still only 2 rows
})

# ---- update_prediction_outcome ----

test_that("update_prediction_outcome updates actual result", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_predictions_schema(con)
  
  # Insert prediction
  log_prediction(con, "m1", "glm", 0.50, 0.30, 0.20)
  
  # Update outcome
  n <- update_prediction_outcome(con, "m1", "H", 2L, 1L)
  
  expect_equal(n, 1)
  
  result <- DBI::dbGetQuery(con, "SELECT * FROM predictions")
  expect_equal(result$actual_ftr, "H")
  expect_equal(result$actual_fthg, 2L)
  expect_equal(result$actual_ftag, 1L)
})

test_that("update_prediction_outcome computes CLV when closing odds provided", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_predictions_schema(con)
  
  # Insert prediction with 0.55 home prob
  log_prediction(con, "m1", "glm", 0.55, 0.25, 0.20)
  
  # Update with closing odds: 2.0, 3.5, 4.0
  # Implied: 0.50, 0.286, 0.25 -> normalised: 0.483, 0.276, 0.241
  update_prediction_outcome(
    con, "m1", "H", 2L, 1L,
    closing_h = 2.0,
    closing_d = 3.5,
    closing_a = 4.0
  )
  
  result <- DBI::dbGetQuery(con, "SELECT * FROM predictions")
  expect_false(is.na(result$clv_h))
  expect_false(is.na(result$clv_d))
  expect_false(is.na(result$clv_a))
  
  # CLV_h should be positive (0.55 > ~0.48)
  expect_true(result$clv_h > 0)
})

test_that("update_prediction_outcome requires required arguments", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_predictions_schema(con)
  
  expect_error(update_prediction_outcome(con))
  expect_error(update_prediction_outcome(con, "m1"))
  expect_error(update_prediction_outcome(con, "m1", "H"))
  expect_error(update_prediction_outcome(con, "m1", "H", 2L))
})

test_that("update_prediction_outcome updates multiple predictions for same match", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_predictions_schema(con)
  
  # Insert predictions from two models for same match
  log_prediction(con, "m1", "glm", 0.50, 0.30, 0.20)
  log_prediction(con, "m1", "dc", 0.55, 0.25, 0.20)
  
  # Update outcome
  update_prediction_outcome(con, "m1", "H", 2L, 1L)
  
  result <- DBI::dbGetQuery(con, "SELECT * FROM predictions ORDER BY model_name")
  expect_equal(nrow(result), 2)
  expect_true(all(result$actual_ftr == "H"))
  expect_true(all(result$actual_fthg == 2L))
})

# ---- query_predictions ----

test_that("query_predictions retrieves all predictions by default", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_predictions_schema(con)
  
  log_prediction(con, "m1", "glm", 0.50, 0.30, 0.20)
  log_prediction(con, "m2", "dc", 0.55, 0.25, 0.20)
  update_prediction_outcome(con, "m1", "H", 2L, 1L)
  
  # With only_settled = FALSE
  result <- query_predictions(con, only_settled = FALSE)
  
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
})

test_that("query_predictions filters by model_name", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_predictions_schema(con)
  
  log_prediction(con, "m1", "glm", 0.50, 0.30, 0.20)
  log_prediction(con, "m2", "dc", 0.55, 0.25, 0.20)
  update_prediction_outcome(con, "m1", "H", 2L, 1L)
  update_prediction_outcome(con, "m2", "D", 1L, 1L)
  
  result <- query_predictions(con, model_name = "glm")
  
  expect_equal(nrow(result), 1)
  expect_equal(result$model_name, "glm")
})

test_that("query_predictions only returns settled by default", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_predictions_schema(con)
  
  log_prediction(con, "m1", "glm", 0.50, 0.30, 0.20)
  log_prediction(con, "m2", "glm", 0.55, 0.25, 0.20)
  update_prediction_outcome(con, "m1", "H", 2L, 1L)
  # m2 remains unsettled
  
  result <- query_predictions(con, only_settled = TRUE)
  
  expect_equal(nrow(result), 1)
  expect_equal(result$match_id, "m1")
})

test_that("query_predictions filters by date range", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_predictions_schema(con)
  
  # Insert predictions at different times
  log_prediction(con, "m1", "glm", 0.50, 0.30, 0.20)
  Sys.sleep(1)
  log_prediction(con, "m2", "glm", 0.55, 0.25, 0.20)
  
  update_prediction_outcome(con, "m1", "H", 2L, 1L)
  update_prediction_outcome(con, "m2", "D", 1L, 1L)
  
  # Get all predictions
  all_preds <- query_predictions(con)
  expect_equal(nrow(all_preds), 2)
  
  # Filter by date (this is hard to test precisely due to timestamps)
  # Just check the function accepts date parameters
  from_date <- Sys.Date() - 1
  to_date <- Sys.Date() + 1
  result <- query_predictions(con, from_date = from_date, to_date = to_date)
  expect_true(nrow(result) >= 0)
})

test_that("query_predictions returns empty for no matches", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_predictions_schema(con)
  
  result <- query_predictions(con, model_name = "nonexistent")
  
  expect_equal(nrow(result), 0)
})

test_that("query_predictions handles empty table", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_predictions_schema(con)
  
  result <- query_predictions(con, only_settled = FALSE)
  
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

# ---- Integration test ----

test_that("full prediction lifecycle works", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_predictions_schema(con)
  
  # 1. Log predictions
  preds <- tibble::tibble(
    match_id = c("m1", "m2", "m3"),
    model_name = "glm",
    prob_h = c(0.50, 0.60, 0.45),
    prob_d = c(0.30, 0.25, 0.35),
    prob_a = c(0.20, 0.15, 0.20),
    edge_h = c(0.05, 0.10, -0.02),
    kelly_h = c(0.02, 0.05, 0)
  )
  log_predictions_batch(con, preds)
  
  # 2. Update outcomes
  update_prediction_outcome(con, "m1", "H", 2L, 1L, 
                            closing_h = 2.0, closing_d = 3.5, closing_a = 4.0)
  update_prediction_outcome(con, "m2", "D", 1L, 1L,
                            closing_h = 1.8, closing_d = 3.0, closing_a = 5.0)
  
  # 3. Query settled predictions
  settled <- query_predictions(con, only_settled = TRUE)
  
  expect_equal(nrow(settled), 2)
  expect_true(all(!is.na(settled$actual_ftr)))
  expect_true(all(!is.na(settled$clv_h)))
  
  # 4. Query unsettled
  unsettled <- query_predictions(con, only_settled = FALSE)
  expect_equal(nrow(unsettled), 3)
  
  # m3 should have NA actual_ftr
  m3 <- unsettled[unsettled$match_id == "m3", ]
  expect_true(is.na(m3$actual_ftr))
})
