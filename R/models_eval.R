#' Compute log loss for probability predictions
#'
#' @param prob Numeric vector of predicted probabilities for the
#'   outcome that actually occurred.
#' @return Numeric. Mean negative log-likelihood (lower is better).
#' @family evaluation
#' @export
log_loss <- function(prob) {
  rlang::check_required(prob)
  if (!is.numeric(prob)) {
    cli::cli_abort("{.arg prob} must be numeric.")
  }
  if (length(prob) == 0L) {
    cli::cli_abort("{.arg prob} must not be empty.")
  }
  # Clip to avoid log(0)
  prob <- pmax(prob, 1e-15)
  prob <- pmin(prob, 1 - 1e-15)
  -mean(log(prob))
}

#' Compute Brier score for 1X2 predictions
#'
#' @param prob_h Numeric vector. Predicted P(Home win).
#' @param prob_d Numeric vector. Predicted P(Draw).
#' @param prob_a Numeric vector. Predicted P(Away win).
#' @param actual Character vector. Actual result ("H", "D", or "A").
#' @return Numeric. Mean Brier score (lower is better).
#' @family evaluation
#' @export
brier_1x2 <- function(prob_h, prob_d, prob_a, actual) {
  n <- length(actual)
  scores <- numeric(n)

  for (i in seq_len(n)) {
    oh <- as.numeric(actual[[i]] == "H")
    od <- as.numeric(actual[[i]] == "D")
    oa <- as.numeric(actual[[i]] == "A")

    scores[[i]] <- (prob_h[[i]] - oh)^2 +
      (prob_d[[i]] - od)^2 +
      (prob_a[[i]] - oa)^2
  }

  mean(scores)
}

#' Compute Ranked Probability Score for ordered outcomes
#'
#' Better than Brier for ordered categories (H > D > A is ordered
#' by goal difference).
#'
#' @param prob_h Numeric vector.
#' @param prob_d Numeric vector.
#' @param prob_a Numeric vector.
#' @param actual Character vector ("H", "D", or "A").
#' @return Numeric. Mean RPS (lower is better).
#' @family evaluation
#' @export
rps_1x2 <- function(prob_h, prob_d, prob_a, actual) {
  n <- length(actual)
  scores <- numeric(n)

  for (i in seq_len(n)) {
    cum_pred <- cumsum(c(prob_h[[i]], prob_d[[i]], prob_a[[i]]))
    oh <- as.numeric(actual[[i]] == "H")
    od <- as.numeric(actual[[i]] == "D")
    cum_actual <- cumsum(c(oh, od, 1 - oh - od))

    # RPS = (1/(K-1)) * sum((cum_pred - cum_actual)^2)
    scores[[i]] <- mean((cum_pred[-3] - cum_actual[-3])^2)
  }

  mean(scores)
}

#' Create walk-forward time splits
#'
#' Generates training/testing indices using a sliding window approach.
#' Training set rolls forward in time; test set is the next period.
#'
#' @param dates Date vector. Match dates (must be sorted).
#' @param train_months Integer. Rolling training window in months (default 24).
#' @param test_months Integer. Test period in months (default 1).
#' @return A list of lists, each with `train_idx` and `test_idx`.
#' @family evaluation
#' @export
walk_forward_splits <- function(dates,
                                train_months = 24L,
                                test_months = 1L) {
  rlang::check_required(dates)

  min_date <- min(dates)
  max_date <- max(dates)

  # Generate split points
  splits <- list()
  current_test_start <- min_date + lubridate::period(train_months, "month")

  while (current_test_start + lubridate::period(test_months, "month") <= max_date) {
    train_start <- current_test_start - lubridate::period(train_months, "month")
    test_end <- current_test_start + lubridate::period(test_months, "month")

    train_idx <- which(dates >= train_start & dates < current_test_start)
    test_idx <- which(dates >= current_test_start & dates < test_end)

    if (length(train_idx) > 0 && length(test_idx) > 0) {
      splits <- c(splits, list(list(
        train_idx = train_idx,
        test_idx = test_idx,
        train_start = train_start,
        test_start = current_test_start,
        test_end = test_end
      )))
    }

    current_test_start <- current_test_start + lubridate::period(test_months, "month")
  }

  splits
}
