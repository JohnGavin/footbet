# Adversarial QA: R/database.R exported functions
# Attack vectors: NULL, invalid paths, empty data, double operations

# ---- connect_db ----

test_that("connect_db: invalid path errors", {
  # DuckDB errors when parent directory doesn't exist
  expect_error(connect_db("/nonexistent/dir/db.duckdb"))
})

test_that("connect_db: empty string path", {
  # Empty string is not valid
  expect_error(connect_db(""))
})

# ---- create_schema ----

test_that("create_schema: NULL connection", {
  expect_error(create_schema(NULL))
})

# ---- insert_matches ----

test_that("insert_matches: empty dataframe returns 0", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  create_schema(con)

  result <- insert_matches(con, tibble::tibble())
  expect_equal(result, 0L)
})

test_that("insert_matches: NULL connection", {
  expect_error(insert_matches(NULL, tibble::tibble(x = 1)))
})

# ---- disconnect_db ----

test_that("disconnect_db: NULL connection", {
  expect_error(disconnect_db(NULL))
})

test_that("disconnect_db: double disconnect warns", {
  con <- connect_db(":memory:")
  disconnect_db(con)
  # DuckDB issues a warning (not error) on double disconnect
  expect_warning(disconnect_db(con))
})
