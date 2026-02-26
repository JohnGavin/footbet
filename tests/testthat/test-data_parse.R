test_that("parse_fd_csv rejects missing file", {
  expect_error(parse_fd_csv("/nonexistent.csv", "E0", "2324"), "not found")
})

test_that("parse_fd_odds rejects missing file", {
  expect_error(parse_fd_odds("/nonexistent.csv", "E0", "2324"), "not found")
})

test_that("safe_int handles missing columns", {
  df <- data.frame(a = 1:3)
  result <- footbet:::safe_int(df, "b")
  expect_length(result, 3)
  expect_true(all(is.na(result)))
})

test_that("safe_num handles missing columns", {
  df <- data.frame(a = 1:3)
  result <- footbet:::safe_num(df, "b")
  expect_length(result, 3)
  expect_true(all(is.na(result)))
})
