test_that("download_fd_csv uses cache when available", {
  tmp <- withr::local_tempdir()
  # Create a fake cached file
  fake_file <- file.path(tmp, "E0_2324.csv")
  writeLines("test", fake_file)

  result <- download_fd_csv("E0", "2324", cache_dir = tmp, overwrite = FALSE)
  expect_equal(result, fake_file)
})
