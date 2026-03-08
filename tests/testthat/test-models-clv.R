# Tests for CLV (Closing Line Value) functions

# ---- closing_line_value ----

test_that("closing_line_value computes difference correctly", {
  pred_prob <- c(0.50, 0.30, 0.70)
  closing_odds <- c(2.0, 4.0, 1.50)  # Implied: 0.50, 0.25, 0.67
  
  result <- closing_line_value(pred_prob, closing_odds)
  
  expect_equal(length(result), 3)
  expect_equal(result[1], 0.00, tolerance = 1e-6)  # 0.50 - 0.50 = 0
  expect_equal(result[2], 0.05, tolerance = 1e-6)  # 0.30 - 0.25 = 0.05
  expect_true(result[3] > 0)  # 0.70 - 0.67 > 0
})

test_that("closing_line_value: positive CLV means model found value", {
  pred_prob <- 0.60
  closing_odds <- 2.0  # Implied 0.50
  
  clv <- closing_line_value(pred_prob, closing_odds)
  
  expect_true(clv > 0)  # Model prob > closing prob
})

test_that("closing_line_value: negative CLV means model overestimated", {
  pred_prob <- 0.40
  closing_odds <- 2.0  # Implied 0.50
  
  clv <- closing_line_value(pred_prob, closing_odds)
  
  expect_true(clv < 0)  # Model prob < closing prob
})

test_that("closing_line_value validates matching lengths", {
  expect_error(
    closing_line_value(c(0.5, 0.6), c(2.0, 2.5, 3.0)),
    "same length"
  )
})

test_that("closing_line_value requires arguments", {
  expect_error(closing_line_value())
  expect_error(closing_line_value(c(0.5)))
})

test_that("closing_line_value handles single value", {
  clv <- closing_line_value(0.55, 2.0)
  expect_equal(clv, 0.05)
})

test_that("closing_line_value handles NA values", {
  pred_prob <- c(0.50, NA, 0.70)
  closing_odds <- c(2.0, 4.0, NA)
  
  result <- closing_line_value(pred_prob, closing_odds)
  
  expect_true(is.na(result[2]))
  expect_true(is.na(result[3]))
  expect_false(is.na(result[1]))
})

# ---- clv_1x2 ----

test_that("clv_1x2 computes CLV for all three outcomes", {
  pred_h <- 0.50
  pred_d <- 0.30
  pred_a <- 0.20
  closing_h <- 2.10  # Implied with vig: 1/2.10 = 0.476
  closing_d <- 3.50  # 1/3.50 = 0.286
  closing_a <- 4.00  # 1/4.00 = 0.250
  # Total = 1.012, normalised: 0.470, 0.282, 0.247
  
  result <- clv_1x2(pred_h, pred_d, pred_a, closing_h, closing_d, closing_a)
  
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
  expect_true(all(c("clv_h", "clv_d", "clv_a", "best_clv", "best_market") %in% colnames(result)))
  
  # Check CLV values are computed
  expect_true(!is.na(result$clv_h))
  expect_true(!is.na(result$clv_d))
  expect_true(!is.na(result$clv_a))
})

test_that("clv_1x2 identifies best market", {
  # Model strongly favors home
  pred_h <- 0.60
  pred_d <- 0.25
  pred_a <- 0.15
  # Market is balanced
  closing_h <- 2.10
  closing_d <- 3.50
  closing_a <- 4.00
  
  result <- clv_1x2(pred_h, pred_d, pred_a, closing_h, closing_d, closing_a)
  
  expect_equal(result$best_market, "H")
  expect_equal(result$best_clv, result$clv_h)
})

test_that("clv_1x2 handles multiple matches", {
  pred_h <- c(0.50, 0.30, 0.60)
  pred_d <- c(0.30, 0.40, 0.25)
  pred_a <- c(0.20, 0.30, 0.15)
  closing_h <- c(2.10, 3.50, 1.80)
  closing_d <- c(3.50, 2.50, 3.50)
  closing_a <- c(4.00, 3.00, 5.00)
  
  result <- clv_1x2(pred_h, pred_d, pred_a, closing_h, closing_d, closing_a)
  
  expect_equal(nrow(result), 3)
  expect_equal(length(result$best_market), 3)
})

test_that("clv_1x2 normalises closing odds to sum to 1", {
  pred_h <- 0.50
  pred_d <- 0.30
  pred_a <- 0.20
  # Closing odds with big overround
  closing_h <- 1.90  # 1/1.90 = 0.526
  closing_d <- 3.20  # 1/3.20 = 0.313
  closing_a <- 4.50  # 1/4.50 = 0.222
  # Total = 1.061
  
  result <- clv_1x2(pred_h, pred_d, pred_a, closing_h, closing_d, closing_a)
  
  # CLV should be computed against normalised probs
  # Normalised: 0.496, 0.295, 0.209
  expect_true(!is.na(result$clv_h))
  
  # Reconstruction: normalised closing probs should sum to ~1
  close_h_norm <- (1/closing_h) / ((1/closing_h) + (1/closing_d) + (1/closing_a))
  expect_equal(close_h_norm + (1/closing_d)/((1/closing_h)+(1/closing_d)+(1/closing_a)) + 
               (1/closing_a)/((1/closing_h)+(1/closing_d)+(1/closing_a)), 1, tolerance = 1e-10)
})

test_that("clv_1x2 best_clv equals max of individual CLVs", {
  pred_h <- 0.55
  pred_d <- 0.30
  pred_a <- 0.15
  closing_h <- 2.00
  closing_d <- 3.50
  closing_a <- 5.00
  
  result <- clv_1x2(pred_h, pred_d, pred_a, closing_h, closing_d, closing_a)
  
  max_clv <- max(result$clv_h, result$clv_d, result$clv_a)
  expect_equal(result$best_clv, max_clv)
})

# ---- summarise_clv ----

test_that("summarise_clv computes summary statistics", {
  clv_df <- tibble::tibble(
    clv_h = c(0.02, -0.01, 0.03, 0.01),
    clv_d = c(-0.01, 0.02, -0.02, 0.00),
    clv_a = c(0.00, 0.01, 0.01, -0.01),
    best_clv = c(0.02, 0.02, 0.03, 0.01),
    best_market = c("H", "D", "H", "H")
  )
  
  result <- summarise_clv(clv_df)
  
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
  expect_true(all(c("mean_clv_h", "mean_clv_d", "mean_clv_a", 
                    "mean_best_clv", "median_best_clv",
                    "pct_positive_clv", "n_bets") %in% colnames(result)))
  
  expect_equal(result$mean_clv_h, mean(clv_df$clv_h))
  expect_equal(result$mean_best_clv, mean(clv_df$best_clv))
  expect_equal(result$median_best_clv, median(clv_df$best_clv))
  expect_equal(result$n_bets, 4L)
})

test_that("summarise_clv computes percentage positive correctly", {
  clv_df <- tibble::tibble(
    clv_h = c(0.02, -0.01, 0.03),
    clv_d = c(-0.01, 0.02, -0.02),
    clv_a = c(0.00, 0.01, 0.01),
    best_clv = c(0.02, 0.02, 0.03),  # All positive
    best_market = c("H", "D", "H")
  )
  
  result <- summarise_clv(clv_df)
  
  expect_equal(result$pct_positive_clv, 100)
})

test_that("summarise_clv handles negative CLV", {
  clv_df <- tibble::tibble(
    clv_h = c(-0.02, -0.01, -0.03),
    clv_d = c(-0.01, -0.02, -0.02),
    clv_a = c(-0.01, -0.01, -0.01),
    best_clv = c(-0.01, -0.01, -0.01),  # All negative
    best_market = c("H", "D", "A")
  )
  
  result <- summarise_clv(clv_df)
  
  expect_true(result$mean_best_clv < 0)
  expect_equal(result$pct_positive_clv, 0)
})

test_that("summarise_clv handles NA values", {
  clv_df <- tibble::tibble(
    clv_h = c(0.02, NA, 0.03),
    clv_d = c(-0.01, 0.02, NA),
    clv_a = c(0.00, 0.01, 0.01),
    best_clv = c(0.02, 0.02, 0.03),
    best_market = c("H", "D", "H")
  )
  
  result <- summarise_clv(clv_df)
  
  # Should compute mean ignoring NAs
  expect_false(is.na(result$mean_clv_h))
  expect_equal(result$n_bets, 3L)
})

test_that("summarise_clv requires argument", {
  expect_error(summarise_clv())
})

test_that("summarise_clv handles empty input", {
  clv_df <- tibble::tibble(
    clv_h = numeric(),
    clv_d = numeric(),
    clv_a = numeric(),
    best_clv = numeric(),
    best_market = character()
  )
  
  result <- summarise_clv(clv_df)
  
  expect_true(is.nan(result$mean_best_clv))
  expect_equal(result$n_bets, 0L)
})
