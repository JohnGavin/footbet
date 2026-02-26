test_that("connect_db creates in-memory connection", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))
  expect_s4_class(con, "duckdb_connection")
})

test_that("create_schema creates all tables", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))

  create_schema(con)

  tables <- DBI::dbListTables(con)
  expect_true("matches" %in% tables)
  expect_true("match_odds" %in% tables)
  expect_true("teams" %in% tables)
  expect_true("transfers" %in% tables)
})

test_that("create_schema is idempotent", {
  con <- connect_db(":memory:")
  on.exit(disconnect_db(con))

  create_schema(con)
  # Running again should not error
  expect_no_error(create_schema(con))
})
