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

#' Run walk-forward evaluation for the Poisson GLM baseline
#'
#' For each time split, fits [fit_poisson_glm()] on the training set,
#' predicts on the test set, and computes scoring metrics.
#'
#' @param long_df Long-format match data from [matches_to_long()].
#' @param matches_df Original match data (wide format) with `match_id`, `ftr`.
#' @param train_months Integer. Training window (default 24).
#' @param test_months Integer. Test period (default 1).
#' @return A tibble with one row per fold and columns for log_loss,
#'   brier, rps, fold number, n_train, n_test.
#' @family evaluation
#' @export
evaluate_glm_baseline <- function(long_df,
                                  matches_df,
                                  train_months = 24L,
                                  test_months = 1L) {
  rlang::check_required(long_df)
  rlang::check_required(matches_df)
  if (!is.data.frame(long_df)) {
    cli::cli_abort("{.arg long_df} must be a data frame, not {.cls {class(long_df)}}.")
  }
  if (!is.data.frame(matches_df)) {
    cli::cli_abort("{.arg matches_df} must be a data frame, not {.cls {class(matches_df)}}.")
  }

  # Run per-league to avoid 222-team design matrix (444 cols, OOM)
  leagues <- unique(matches_df$league_code)
  all_results <- purrr::map(leagues, function(lg) {
    lg_long <- long_df[long_df$league_code == lg, ]
    lg_matches <- matches_df[matches_df$league_code == lg, ]

    if (nrow(lg_long) < 100L) return(NULL)

    tryCatch({
      res <- evaluate_glm_baseline_single(
        lg_long, lg_matches,
        train_months = train_months,
        test_months = test_months
      )
      if (nrow(res) > 0L) res$league_code <- lg
      res
    }, error = function(e) NULL)
  })

  dplyr::bind_rows(all_results)
}

#' Walk-forward GLM evaluation for a single league
#'
#' Internal workhorse called by [evaluate_glm_baseline()] per league.
#' Splitting by league keeps the design matrix small (~40 cols vs ~444).
#'
#' @inheritParams evaluate_glm_baseline
#' @return A tibble with one row per fold.
#' @keywords internal
evaluate_glm_baseline_single <- function(long_df,
                                         matches_df,
                                         train_months = 24L,
                                         test_months = 1L) {
  dates <- sort(unique(matches_df$match_date))
  splits <- walk_forward_splits(dates, train_months, test_months)

  if (length(splits) == 0L) {
    return(tibble::tibble(
      fold = integer(), n_train = integer(), n_test = integer(),
      log_loss = numeric(), brier = numeric(), rps = numeric(),
      train_start = as.Date(character()), test_start = as.Date(character()),
      test_end = as.Date(character())
    ))
  }

  n_folds <- length(splits)
  results <- vector("list", n_folds)

  for (k in seq_len(n_folds)) {
    sp <- splits[[k]]

    train_long <- long_df[long_df$match_date >= sp$train_start &
                            long_df$match_date < sp$test_start, ]
    test_matches <- matches_df[matches_df$match_date >= sp$test_start &
                                 matches_df$match_date < sp$test_end, ]

    if (nrow(train_long) < 20L || nrow(test_matches) == 0L) next
    n_train_rows <- nrow(train_long)

    model <- tryCatch(
      fit_poisson_glm(train_long),
      error = function(e) NULL
    )
    if (is.null(model)) next

    preds <- predict_matches_glm(model, test_matches)
    rm(model, train_long)

    eval_df <- dplyr::inner_join(preds, test_matches[, c("match_id", "ftr")],
                                  by = "match_id") |>
      dplyr::filter(!is.na(.data$pred_h))
    rm(preds, test_matches)

    if (nrow(eval_df) == 0L) next

    prob_actual <- dplyr::case_when(
      eval_df$ftr == "H" ~ eval_df$pred_h,
      eval_df$ftr == "D" ~ eval_df$pred_d,
      eval_df$ftr == "A" ~ eval_df$pred_a,
      TRUE ~ NA_real_
    )
    prob_actual <- prob_actual[!is.na(prob_actual)]

    if (length(prob_actual) == 0L) next

    results[[k]] <- tibble::tibble(
      fold = k,
      n_train = n_train_rows,
      n_test = nrow(eval_df),
      log_loss = log_loss(prob_actual),
      brier = brier_1x2(eval_df$pred_h, eval_df$pred_d, eval_df$pred_a,
                          eval_df$ftr),
      rps = rps_1x2(eval_df$pred_h, eval_df$pred_d, eval_df$pred_a,
                      eval_df$ftr),
      train_start = sp$train_start,
      test_start = sp$test_start,
      test_end = sp$test_end
    )
    rm(eval_df, prob_actual)

    if (k %% 20L == 0L) gc(verbose = FALSE)
  }

  dplyr::bind_rows(results)
}

#' Compute implied probabilities from Pinnacle odds (benchmark)
#'
#' Computes naive implied probabilities from raw Pinnacle 1X2 odds
#' by normalising to sum to 1. Used as benchmark — if a model can't
#' beat Pinnacle's log-loss, it has no edge.
#'
#' @param odds_df A tibble with `match_id`, `psh`, `psd`, `psa`.
#' @return A tibble with `match_id`, `implied_h`, `implied_d`, `implied_a`.
#' @family evaluation
#' @export
pinnacle_implied <- function(odds_df) {
  rlang::check_required(odds_df)

  if (nrow(odds_df) == 0L) {
    return(tibble::tibble(
      match_id = character(),
      implied_h = numeric(), implied_d = numeric(), implied_a = numeric()
    ))
  }

  raw_h <- 1 / odds_df$psh
  raw_d <- 1 / odds_df$psd
  raw_a <- 1 / odds_df$psa

  total <- raw_h + raw_d + raw_a

  tibble::tibble(
    match_id = odds_df$match_id,
    implied_h = ifelse(is.na(total), NA_real_, raw_h / total),
    implied_d = ifelse(is.na(total), NA_real_, raw_d / total),
    implied_a = ifelse(is.na(total), NA_real_, raw_a / total)
  )
}

#' Summarise walk-forward evaluation results
#'
#' Computes mean metrics across folds with optional benchmarking
#' against Pinnacle implied probabilities.
#'
#' @param cv_results A tibble from [evaluate_glm_baseline()].
#' @return A tibble with mean/median/sd of scoring metrics across folds.
#' @family evaluation
#' @export
summarise_cv <- function(cv_results) {
  rlang::check_required(cv_results)

  if (nrow(cv_results) == 0L) {
    return(tibble::tibble(
      metric = character(), mean = numeric(),
      median = numeric(), sd = numeric(), n_folds = integer()
    ))
  }

  metrics <- c("log_loss", "brier", "rps")
  dplyr::bind_rows(lapply(metrics, function(m) {
    vals <- cv_results[[m]]
    vals <- vals[!is.na(vals)]
    tibble::tibble(
      metric = m,
      mean = mean(vals),
      median = stats::median(vals),
      sd = stats::sd(vals),
      n_folds = length(vals)
    )
  }))
}

#' Compute closing line value (CLV)
#'
#' Measures the difference between model-implied odds at prediction time
#' and Pinnacle closing odds. Positive CLV indicates the model found value
#' that the market later confirmed.
#'
#' @param pred_prob Numeric vector. Model's predicted probability.
#' @param closing_odds Numeric vector. Pinnacle closing decimal odds.
#' @return Numeric vector. CLV as percentage points (model_prob - closing_prob).
#' @family evaluation
#' @export
closing_line_value <- function(pred_prob, closing_odds) {
  rlang::check_required(pred_prob)
  rlang::check_required(closing_odds)

  if (length(pred_prob) != length(closing_odds)) {
    cli::cli_abort("{.arg pred_prob} and {.arg closing_odds} must have same length.")
  }

  # Convert closing odds to implied probability
  closing_prob <- 1 / closing_odds

  # CLV = model probability - closing implied probability
  # Positive = model found value, negative = model overestimated
  clv <- pred_prob - closing_prob

  clv
}

#' Compute CLV for 1X2 predictions
#'
#' Calculates closing line value for each outcome, returning CLV
#' for the outcome the model had highest edge on.
#'
#' @param pred_h Numeric vector. Model's P(Home win).
#' @param pred_d Numeric vector. Model's P(Draw).
#' @param pred_a Numeric vector. Model's P(Away win).
#' @param closing_h Numeric vector. Pinnacle closing odds (Home).
#' @param closing_d Numeric vector. Pinnacle closing odds (Draw).
#' @param closing_a Numeric vector. Pinnacle closing odds (Away).
#' @return A tibble with CLV for each outcome and summary statistics.
#' @family evaluation
#' @export
clv_1x2 <- function(pred_h, pred_d, pred_a, closing_h, closing_d, closing_a) {
  n <- length(pred_h)

  # Implied closing probabilities (normalised)
  close_prob_h <- 1 / closing_h
  close_prob_d <- 1 / closing_d
  close_prob_a <- 1 / closing_a
  total <- close_prob_h + close_prob_d + close_prob_a
  close_prob_h <- close_prob_h / total
  close_prob_d <- close_prob_d / total
  close_prob_a <- close_prob_a / total

  # CLV per outcome
  clv_h <- pred_h - close_prob_h
  clv_d <- pred_d - close_prob_d
  clv_a <- pred_a - close_prob_a

  # Best CLV (where model had most edge)
  best_clv <- pmax(clv_h, clv_d, clv_a, na.rm = TRUE)
  best_market <- dplyr::case_when(
    clv_h == best_clv ~ "H",
    clv_d == best_clv ~ "D",
    clv_a == best_clv ~ "A",
    TRUE ~ NA_character_
  )

  tibble::tibble(
    clv_h = clv_h,
    clv_d = clv_d,
    clv_a = clv_a,
    best_clv = best_clv,
    best_market = best_market
  )
}

#' Summarise CLV statistics
#'
#' @param clv_df A tibble from [clv_1x2()].
#' @return A tibble with mean, median, and % positive CLV.
#' @family evaluation
#' @export
summarise_clv <- function(clv_df) {
  rlang::check_required(clv_df)

  tibble::tibble(
    mean_clv_h = mean(clv_df$clv_h, na.rm = TRUE),
    mean_clv_d = mean(clv_df$clv_d, na.rm = TRUE),
    mean_clv_a = mean(clv_df$clv_a, na.rm = TRUE),
    mean_best_clv = mean(clv_df$best_clv, na.rm = TRUE),
    median_best_clv = stats::median(clv_df$best_clv, na.rm = TRUE),
    pct_positive_clv = mean(clv_df$best_clv > 0, na.rm = TRUE) * 100,
    n_bets = sum(!is.na(clv_df$best_clv))
  )
}

#' Ensemble model predictions
#'
#' Combines predictions from multiple models using weighted averaging.
#' Weights can be equal, inverse log-loss weighted, or custom.
#'
#' @param predictions A list of tibbles, each with columns `match_id`,
#'   `prob_h`, `prob_d`, `prob_a`. Names are used as model identifiers.
#' @param weights Named numeric vector of model weights, or NULL for equal weights.
#'   Names must match names in `predictions`. Weights are normalised to sum to 1.
#' @return A tibble with ensemble predictions.
#' @family models
#' @export
ensemble_predict <- function(predictions, weights = NULL) {
  rlang::check_required(predictions)

  if (!is.list(predictions) || length(predictions) < 2L) {
    cli::cli_abort("{.arg predictions} must be a list with at least 2 model predictions.")
  }

  model_names <- names(predictions)
  if (is.null(model_names) || any(model_names == "")) {
    cli::cli_abort("{.arg predictions} must be a named list.")
  }

  # Default to equal weights

  if (is.null(weights)) {
    weights <- rep(1 / length(predictions), length(predictions))
    names(weights) <- model_names
  }

  # Validate weights
  if (!all(model_names %in% names(weights))) {
    missing <- setdiff(model_names, names(weights))
    cli::cli_abort("Missing weights for models: {.val {missing}}")
  }

  # Normalise weights
  weights <- weights[model_names]
  weights <- weights / sum(weights)

  # Get common match_ids across all models
  all_ids <- Reduce(intersect, lapply(predictions, function(x) x$match_id))

  if (length(all_ids) == 0L) {
    cli::cli_warn("No common match_ids across models.")
    return(tibble::tibble(
      match_id = character(),
      prob_h = numeric(),
      prob_d = numeric(),
      prob_a = numeric()
    ))
  }

  # Initialize result
  result <- tibble::tibble(
    match_id = all_ids,
    prob_h = 0,
    prob_d = 0,
    prob_a = 0
  )

  # Weighted sum
  for (model_name in model_names) {
    df <- predictions[[model_name]] |>
      dplyr::filter(.data$match_id %in% all_ids) |>
      dplyr::arrange(match(.data$match_id, all_ids))

    w <- weights[[model_name]]
    result$prob_h <- result$prob_h + w * df$prob_h
    result$prob_d <- result$prob_d + w * df$prob_d
    result$prob_a <- result$prob_a + w * df$prob_a
  }

  # Normalise to ensure probabilities sum to 1
  total <- result$prob_h + result$prob_d + result$prob_a
  result$prob_h <- result$prob_h / total
  result$prob_d <- result$prob_d / total
  result$prob_a <- result$prob_a / total

  # Add model disagreement as uncertainty measure
  # Compute variance across models for each match
  var_h <- numeric(length(all_ids))
  var_d <- numeric(length(all_ids))
  var_a <- numeric(length(all_ids))

  for (i in seq_along(all_ids)) {
    match_id <- all_ids[[i]]
    probs_h <- sapply(predictions, function(x) {
      x$prob_h[x$match_id == match_id]
    })
    probs_d <- sapply(predictions, function(x) {
      x$prob_d[x$match_id == match_id]
    })
    probs_a <- sapply(predictions, function(x) {
      x$prob_a[x$match_id == match_id]
    })

    var_h[[i]] <- stats::var(probs_h)
    var_d[[i]] <- stats::var(probs_d)
    var_a[[i]] <- stats::var(probs_a)
  }

  result$uncertainty <- sqrt(var_h + var_d + var_a)

  result
}

#' Compute optimal ensemble weights from historical performance
#'
#' Uses inverse log-loss weighting: models with lower log-loss get higher weights.
#'
#' @param cv_results A named list of CV result tibbles (from [evaluate_glm_baseline()]),
#'   one per model.
#' @return Named numeric vector of weights summing to 1.
#' @family evaluation
#' @export
compute_ensemble_weights <- function(cv_results) {
  rlang::check_required(cv_results)

  if (!is.list(cv_results) || length(cv_results) < 2L) {
    cli::cli_abort("{.arg cv_results} must be a list with at least 2 model results.")
  }

  model_names <- names(cv_results)
  if (is.null(model_names)) {
    cli::cli_abort("{.arg cv_results} must be a named list.")
  }

  # Compute mean log-loss per model
  log_losses <- sapply(cv_results, function(x) mean(x$log_loss, na.rm = TRUE))

  # Inverse log-loss weighting (lower is better)
  # Use softmax-style transformation for stability
  inv_ll <- 1 / log_losses
  weights <- inv_ll / sum(inv_ll)
  names(weights) <- model_names

  weights
}

# ============================================================================
# BETTING PERFORMANCE METRICS
# ============================================================================

#' Compute Sharpe ratio for betting returns
#'
#' Calculates the Sharpe ratio, a risk-adjusted performance metric.
#' Higher values indicate better risk-adjusted returns.
#'
#' @param returns Numeric vector of bet returns (profit/loss as decimal,
#'   e.g., 0.95 for 95% profit, -1 for total loss).
#' @param risk_free_rate Numeric. Annualized risk-free rate (default 0.02 = 2%).
#' @param periods_per_year Integer. Number of betting periods per year
#'   (default 365 for daily betting).
#' @return Numeric. Annualized Sharpe ratio.
#' @family evaluation
#' @export
betting_sharpe_ratio <- function(returns,
                                  risk_free_rate = 0.02,
                                  periods_per_year = 365L) {
  rlang::check_required(returns)

  if (!is.numeric(returns)) {
    cli::cli_abort("{.arg returns} must be numeric.")
  }
  if (length(returns) == 0L) {
    return(NA_real_)
  }
  if (length(returns) < 2L) {
    cli::cli_warn("Need at least 2 returns to compute Sharpe ratio.")
    return(NA_real_)
  }

  # Convert annual risk-free to per-period
  rf_per_period <- (1 + risk_free_rate)^(1 / periods_per_year) - 1

  # Excess returns
  excess <- returns - rf_per_period

  # Mean and SD of excess returns
  mean_excess <- mean(excess, na.rm = TRUE)
  sd_excess <- stats::sd(excess, na.rm = TRUE)


  if (is.na(sd_excess) || sd_excess == 0) {
    return(NA_real_)
  }

  # Annualize
  sharpe <- (mean_excess / sd_excess) * sqrt(periods_per_year)

  sharpe
}

#' Compute returns from bet results
#'
#' Converts win/loss outcomes and odds to decimal returns.
#'
#' @param won Logical vector. TRUE if bet won.
#' @param odds Numeric vector. Decimal odds for each bet.
#' @param stake Numeric vector or scalar. Stake per bet (default 1).
#' @return Numeric vector of returns (profit/loss relative to stake).
#' @family evaluation
#' @export
bet_returns <- function(won, odds, stake = 1) {
  rlang::check_required(won)
  rlang::check_required(odds)

  if (length(won) != length(odds)) {
    cli::cli_abort("{.arg won} and {.arg odds} must have same length.")
  }

  # Expand stake if scalar
  if (length(stake) == 1L) {
    stake <- rep(stake, length(won))
  }

  # Return = (odds - 1) * stake if won, -stake if lost
  dplyr::if_else(won, (odds - 1), -1)
}

#' Summarise betting performance
#'
#' Computes comprehensive betting statistics including ROI, Sharpe,
#' win rate, and drawdown.
#'
#' @param returns Numeric vector of bet returns.
#' @param risk_free_rate Numeric. Risk-free rate for Sharpe (default 0.02).
#' @return A tibble with performance statistics.
#' @family evaluation
#' @export
summarise_betting_performance <- function(returns, risk_free_rate = 0.02) {
  rlang::check_required(returns)

  if (length(returns) == 0L) {
    return(tibble::tibble(
      n_bets = 0L,
      total_return = NA_real_,
      roi_pct = NA_real_,
      win_rate = NA_real_,
      sharpe = NA_real_,
      max_drawdown = NA_real_
    ))
  }

  # Basic stats
  n_bets <- length(returns)
  total_return <- sum(returns, na.rm = TRUE)
  roi_pct <- 100 * total_return / n_bets
  win_rate <- 100 * mean(returns > 0, na.rm = TRUE)

  # Sharpe ratio
  sharpe <- betting_sharpe_ratio(returns, risk_free_rate = risk_free_rate)

  # Max drawdown (cumulative)
  cum_returns <- cumsum(returns)
  running_max <- cummax(cum_returns)
  drawdown <- running_max - cum_returns
  max_drawdown <- max(drawdown, na.rm = TRUE)

  tibble::tibble(
    n_bets = n_bets,
    total_return = total_return,
    roi_pct = roi_pct,
    win_rate = win_rate,
    sharpe = sharpe,
    max_drawdown = max_drawdown
  )
}

# ============================================================================
# ODDS CONVERSION UTILITIES
# ============================================================================

#' Convert decimal odds to fractional
#'
#' @param decimal_odds Numeric vector. Decimal odds (e.g., 2.50).
#' @return Character vector. Fractional odds (e.g., "3/2").
#' @family odds
#' @export
decimal_to_fractional <- function(decimal_odds) {
  rlang::check_required(decimal_odds)

  if (!is.numeric(decimal_odds)) {
    cli::cli_abort("{.arg decimal_odds} must be numeric.")
  }

  sapply(decimal_odds, function(d) {
    if (is.na(d) || d <= 1) return(NA_character_)

    # Convert to fraction
    frac <- d - 1

    # Find best fractional representation
    # Common denominators in UK betting
    denoms <- c(1, 2, 4, 5, 8, 10, 20, 100)

    best_num <- NA_integer_
    best_denom <- NA_integer_
    best_error <- Inf

    for (denom in denoms) {
      num <- round(frac * denom)
      error <- abs(num / denom - frac)
      if (error < best_error && error < 0.001) {
        best_num <- num
        best_denom <- denom
        best_error <- error
      }
    }

    if (is.na(best_num)) {
      # Fallback: use 100ths
      best_num <- round(frac * 100)
      best_denom <- 100L
    }

    # Simplify fraction
    gcd_val <- function(a, b) if (b == 0) a else gcd_val(b, a %% b)
    g <- gcd_val(abs(best_num), abs(best_denom))
    paste0(best_num / g, "/", best_denom / g)
  })
}

#' Convert decimal odds to American
#'
#' @param decimal_odds Numeric vector. Decimal odds.
#' @return Numeric vector. American odds (positive = underdog, negative = favourite).
#' @family odds
#' @export
decimal_to_american <- function(decimal_odds) {
  rlang::check_required(decimal_odds)

  if (!is.numeric(decimal_odds)) {
    cli::cli_abort("{.arg decimal_odds} must be numeric.")
  }

  dplyr::case_when(
    is.na(decimal_odds) ~ NA_real_,
    decimal_odds < 1 ~ NA_real_,
    decimal_odds >= 2 ~ (decimal_odds - 1) * 100,  # Positive (underdog)
    TRUE ~ -100 / (decimal_odds - 1)               # Negative (favourite)
  )
}

#' Convert American odds to decimal
#'
#' @param american_odds Numeric vector. American odds.
#' @return Numeric vector. Decimal odds.
#' @family odds
#' @export
american_to_decimal <- function(american_odds) {
  rlang::check_required(american_odds)

  if (!is.numeric(american_odds)) {
    cli::cli_abort("{.arg american_odds} must be numeric.")
  }

  dplyr::case_when(
    is.na(american_odds) ~ NA_real_,
    american_odds == 0 ~ NA_real_,
    american_odds > 0 ~ (american_odds / 100) + 1,  # Positive (underdog)
    TRUE ~ (100 / abs(american_odds)) + 1           # Negative (favourite)
  )
}

#' Convert fractional odds to decimal
#'
#' @param fractional_odds Character vector. Fractional odds (e.g., "3/2", "evens").
#' @return Numeric vector. Decimal odds.
#' @family odds
#' @export
fractional_to_decimal <- function(fractional_odds) {
  rlang::check_required(fractional_odds)

  if (!is.character(fractional_odds)) {
    cli::cli_abort("{.arg fractional_odds} must be character.")
  }

  sapply(fractional_odds, function(f) {
    if (is.na(f)) return(NA_real_)

    f <- tolower(trimws(f))

    # Handle special cases
    if (f %in% c("evens", "evs", "1/1")) return(2.0)

    # Parse "num/denom" format
    parts <- strsplit(f, "/")[[1]]
    if (length(parts) != 2L) return(NA_real_)

    num <- suppressWarnings(as.numeric(parts[[1]]))
    denom <- suppressWarnings(as.numeric(parts[[2]]))

    if (is.na(num) || is.na(denom) || denom == 0) return(NA_real_)

    (num / denom) + 1
  }, USE.NAMES = FALSE)
}

# ============================================================================
# BRIER SCORE DECOMPOSITION
# ============================================================================

#' Decompose Brier score into reliability, resolution, and uncertainty
#'
#' The Murphy decomposition breaks Brier score into three components:
#' - **Reliability (calibration)**: How well predicted probabilities match
#'   observed frequencies. Lower is better.
#' - **Resolution**: How much predictions vary from the base rate. Higher is
#'   better (more informative forecasts).
#' - **Uncertainty**: Inherent difficulty of the prediction task based on
#'   outcome distribution. Cannot be improved by the model.
#'
#' Formula: BS = Reliability - Resolution + Uncertainty
#'
#' @param predicted Numeric vector. Predicted probabilities for the positive class.
#' @param actual Logical or 0/1 numeric. Actual outcomes.
#' @param n_bins Integer. Number of bins for calibration (default 10).
#' @return A tibble with `brier_score`, `reliability`, `resolution`,
#'   `uncertainty`, and `brier_skill_score` (1 - BS/Uncertainty).
#' @family evaluation
#' @references
#' Murphy, A.H. (1973). A New Vector Partition of the Probability Score.
#' Journal of Applied Meteorology, 12(4), 595-600.
#' @export
brier_decomposition <- function(predicted, actual, n_bins = 10L) {
  rlang::check_required(predicted)
  rlang::check_required(actual)

  if (length(predicted) != length(actual)) {
    cli::cli_abort("{.arg predicted} and {.arg actual} must have same length.")
  }

  # Convert to numeric
  actual <- as.numeric(actual)
  n <- length(actual)

  # Overall Brier score
  brier_score <- mean((predicted - actual)^2)

  # Base rate (climatological probability)
  base_rate <- mean(actual)

  # Uncertainty: variance of outcomes = p_bar * (1 - p_bar)
  uncertainty <- base_rate * (1 - base_rate)

  # Bin predictions for calibration
  bins <- cut(predicted,
              breaks = seq(0, 1, length.out = n_bins + 1),
              include.lowest = TRUE,
              labels = FALSE)

  # Compute reliability and resolution
  reliability <- 0
  resolution <- 0

  for (k in seq_len(n_bins)) {
    in_bin <- which(bins == k)
    n_k <- length(in_bin)

    if (n_k == 0) next

    # Mean predicted probability in bin
    f_k <- mean(predicted[in_bin])
    # Observed frequency in bin
    o_k <- mean(actual[in_bin])

    # Reliability: weighted squared difference between prediction and observation
    reliability <- reliability + (n_k / n) * (f_k - o_k)^2

    # Resolution: weighted squared difference between bin frequency and base rate
    resolution <- resolution + (n_k / n) * (o_k - base_rate)^2
  }

  # Brier Skill Score: improvement over climatology
  brier_skill_score <- 1 - brier_score / uncertainty

  tibble::tibble(
    brier_score = brier_score,
    reliability = reliability,
    resolution = resolution,
    uncertainty = uncertainty,
    brier_skill_score = brier_skill_score,
    n_bins = n_bins,
    n_obs = n

  )
}

#' Decompose Brier score for 1X2 predictions
#'
#' Applies [brier_decomposition()] separately for each outcome class
#' (Home, Draw, Away) and combines results.
#'
#' @param prob_h Numeric vector. Predicted P(Home win).
#' @param prob_d Numeric vector. Predicted P(Draw).
#' @param prob_a Numeric vector. Predicted P(Away win).
#' @param actual Character vector. Actual result ("H", "D", or "A").
#' @param n_bins Integer. Number of bins (default 10).
#' @return A tibble with decomposition for each outcome and overall.
#' @family evaluation
#' @export
brier_decomposition_1x2 <- function(prob_h, prob_d, prob_a, actual, n_bins = 10L) {
  n <- length(actual)

  # Convert outcomes to binary indicators
  actual_h <- as.numeric(actual == "H")
  actual_d <- as.numeric(actual == "D")
  actual_a <- as.numeric(actual == "A")

  # Decompose each outcome
  dec_h <- brier_decomposition(prob_h, actual_h, n_bins) |>
    dplyr::mutate(outcome = "H")
  dec_d <- brier_decomposition(prob_d, actual_d, n_bins) |>
    dplyr::mutate(outcome = "D")
  dec_a <- brier_decomposition(prob_a, actual_a, n_bins) |>
    dplyr::mutate(outcome = "A")

  # Combine
  by_outcome <- dplyr::bind_rows(dec_h, dec_d, dec_a)

  # Overall (mean across outcomes)
  overall <- tibble::tibble(
    outcome = "Overall",
    brier_score = mean(c(dec_h$brier_score, dec_d$brier_score, dec_a$brier_score)),
    reliability = mean(c(dec_h$reliability, dec_d$reliability, dec_a$reliability)),
    resolution = mean(c(dec_h$resolution, dec_d$resolution, dec_a$resolution)),
    uncertainty = mean(c(dec_h$uncertainty, dec_d$uncertainty, dec_a$uncertainty)),
    brier_skill_score = mean(c(dec_h$brier_skill_score, dec_d$brier_skill_score,
                                dec_a$brier_skill_score)),
    n_bins = n_bins,
    n_obs = n
  )

  dplyr::bind_rows(by_outcome, overall)
}

# ============================================================================
# PROBABILITY CALIBRATION
# ============================================================================

#' Calibrate probabilities using Platt scaling
#'
#' Fits a logistic regression on predicted probabilities to improve calibration.
#' Best for sigmoid-shaped calibration curves and small calibration sets.
#'
#' @param predicted Numeric vector. Predicted probabilities (training set).
#' @param actual Logical or 0/1 numeric. Actual outcomes (training set).
#' @return A fitted glm object that can be used with [predict()].
#' @family calibration
#' @references
#' Platt, J. (1999). Probabilistic outputs for support vector machines.
#' @export
fit_platt_scaling <- function(predicted, actual) {
  rlang::check_required(predicted)
  rlang::check_required(actual)

  df <- data.frame(pred = predicted, actual = as.numeric(actual))

  # Fit logistic regression
  model <- stats::glm(actual ~ pred, data = df, family = stats::binomial())

  model
}

#' Calibrate probabilities using isotonic regression
#'
#' Fits isotonic (monotonic) regression on predicted probabilities.
#' Better for non-sigmoid calibration curves and larger datasets.
#'
#' @param predicted Numeric vector. Predicted probabilities (training set).
#' @param actual Logical or 0/1 numeric. Actual outcomes (training set).
#' @return An isoreg object for use with [predict_isotonic()].
#' @family calibration
#' @export
fit_isotonic_regression <- function(predicted, actual) {
  rlang::check_required(predicted)
  rlang::check_required(actual)

  # Isotonic regression requires data sorted by x
  ord <- order(predicted)
  iso <- stats::isoreg(predicted[ord], as.numeric(actual)[ord])

  iso
}

#' Apply Platt scaling calibration to new predictions
#'
#' @param platt_model A model from [fit_platt_scaling()].
#' @param predicted Numeric vector. New predicted probabilities.
#' @return Numeric vector. Calibrated probabilities.
#' @family calibration
#' @export
predict_platt <- function(platt_model, predicted) {
  rlang::check_required(platt_model)
  rlang::check_required(predicted)

  stats::predict(platt_model,
                 newdata = data.frame(pred = predicted),
                 type = "response")
}

#' Apply isotonic calibration to new predictions
#'
#' @param iso_model An isoreg object from [fit_isotonic_regression()].
#' @param predicted Numeric vector. New predicted probabilities.
#' @return Numeric vector. Calibrated probabilities.
#' @family calibration
#' @export
predict_isotonic <- function(iso_model, predicted) {
  rlang::check_required(iso_model)
  rlang::check_required(predicted)

  # Use stepfun for prediction
  sf <- stats::stepfun(iso_model$x, c(iso_model$yf[1], iso_model$yf))
  calibrated <- sf(predicted)

  # Clip to [0, 1]
  pmin(pmax(calibrated, 0), 1)
}

# ============================================================================
# EMPIRICAL BAYES SHRINKAGE
# ============================================================================

#' Apply empirical Bayes shrinkage to rate estimates
#'
#' Shrinks extreme estimates toward the population mean, with more shrinkage
#' for estimates based on fewer observations. Uses the James-Stein estimator
#' approach for Gamma-Poisson (goals) or Beta-Binomial (win rates) data.
#'
#' Based on Tony ElHabr's implementation of Laurie Shaw's methodology.
#'
#' @param observed Numeric vector. Observed counts or rates.
#' @param sample_size Numeric vector. Number of observations (e.g., shots, matches).
#' @param type Character. "rate" for goals/xG per match, "count" for raw goals.
#' @return A tibble with `observed`, `shrunk`, `shrinkage_factor`.
#' @family features
#' @references
#' Shaw, L. (2018). Exceeding Expected Goals.
#' ElHabr, T. (2023). Measuring Shooting Overperformance in Soccer.
#' @export
empirical_bayes_shrink <- function(observed, sample_size, type = c("rate", "count")) {

  rlang::check_required(observed)
  rlang::check_required(sample_size)
  type <- match.arg(type)

  if (length(observed) != length(sample_size)) {
    cli::cli_abort("{.arg observed} and {.arg sample_size} must have same length.")
  }

  n <- length(observed)

  if (type == "rate") {
    # For rates (e.g., goals per 90), use moment matching
    # Estimate prior parameters from population
    mean_rate <- stats::weighted.mean(observed, sample_size, na.rm = TRUE)
    var_rate <- stats::var(observed, na.rm = TRUE)

    # Variance of rate estimates due to sampling
    # Var(rate) = true_var + sampling_var
    # sampling_var ≈ mean_rate / sample_size (for Poisson)
    mean_sampling_var <- mean(mean_rate / sample_size, na.rm = TRUE)

    # Prior variance = observed variance - sampling variance
    prior_var <- max(var_rate - mean_sampling_var, 0.001)

    # Shrinkage factor for each observation
    # B_i = prior_var / (prior_var + sampling_var_i)
    sampling_var <- mean_rate / sample_size
    shrinkage <- prior_var / (prior_var + sampling_var)

    # Shrunk estimate
    shrunk <- shrinkage * observed + (1 - shrinkage) * mean_rate

  } else {
    # For counts, use Gamma-Poisson conjugate
    # Estimate prior from data using method of moments
    mean_count <- mean(observed, na.rm = TRUE)
    var_count <- stats::var(observed, na.rm = TRUE)

    # Gamma prior: alpha, beta where mean = alpha/beta, var = alpha/beta^2
    # From method of moments:
    if (var_count <= mean_count) {
      # No overdispersion, minimal shrinkage
      shrunk <- observed
      shrinkage <- rep(1, n)
    } else {
      beta <- mean_count / (var_count - mean_count)
      alpha <- mean_count * beta

      # Posterior mean = (observed + alpha) / (sample_size + beta)
      shrunk <- (observed + alpha) / (sample_size + beta) * sample_size
      shrinkage <- sample_size / (sample_size + beta)
    }
  }

  tibble::tibble(
    observed = observed,
    sample_size = sample_size,
    shrunk = shrunk,
    shrinkage_factor = shrinkage,
    grand_mean = mean(observed, na.rm = TRUE)
  )
}

#' Shrink team strength estimates
#'
#' Applies empirical Bayes shrinkage to team attack/defense ratings,
#' useful when some teams have few matches.
#'
#' @param team_stats A tibble with `team`, `n_matches`, `attack`, `defense`.
#' @return The input tibble with `attack_shrunk`, `defense_shrunk` columns.
#' @family features
#' @export
shrink_team_strength <- function(team_stats) {
  rlang::check_required(team_stats)

  required <- c("team", "n_matches", "attack", "defense")
  missing <- setdiff(required, names(team_stats))
  if (length(missing) > 0) {
    cli::cli_abort("Missing required columns: {.val {missing}}")
  }

  # Shrink attack ratings
  attack_eb <- empirical_bayes_shrink(
    team_stats$attack,
    team_stats$n_matches,
    type = "rate"
  )

  # Shrink defense ratings
  defense_eb <- empirical_bayes_shrink(
    team_stats$defense,
    team_stats$n_matches,
    type = "rate"
  )

  team_stats |>
    dplyr::mutate(
      attack_shrunk = attack_eb$shrunk,
      defense_shrunk = defense_eb$shrunk,
      attack_shrinkage = attack_eb$shrinkage_factor,
      defense_shrinkage = defense_eb$shrinkage_factor
    )
}

# ============================================================================
# META-ANALYTICS: DISCRIMINATION AND STABILITY
# ============================================================================

#' Compute discrimination meta-metric for a statistic
#'
#' Discrimination measures how well a statistic separates good from bad
#' teams/players within a single season. Higher discrimination means
#' the stat is more useful for ranking.
#'
#' Calculated as: 1 - (within-group variance / total variance)
#' or equivalently, the ICC (intraclass correlation coefficient).
#'
#' @param df A data frame with columns: `team` (or `player`), `season`, `value`.
#' @param entity_col Character. Name of entity column (default "team").
#' @param value_col Character. Name of value column (default "value").
#' @return Numeric. Discrimination coefficient (0-1, higher = better).
#' @family meta-analytics
#' @references
#' Franks, A., D'Amour, A., Cervone, D., & Bornn, L. (2016).
#' Meta-Analytics: Tools for Understanding the Statistical Properties
#' of Sports Metrics.
#' @export
stat_discrimination <- function(df,
                                 entity_col = "team",
                                 value_col = "value") {
  rlang::check_required(df)

  if (!entity_col %in% names(df)) {
    cli::cli_abort("Column {.val {entity_col}} not found.")
  }
  if (!value_col %in% names(df)) {
    cli::cli_abort("Column {.val {value_col}} not found.")
  }

  # Remove NAs
  df <- df[!is.na(df[[value_col]]), ]

  if (nrow(df) < 10) {
    cli::cli_warn("Too few observations for reliable discrimination estimate.")
    return(NA_real_)
  }

  # Total variance
  total_var <- stats::var(df[[value_col]], na.rm = TRUE)

  if (total_var == 0) return(0)

  # Within-entity variance (averaged across entities)
  entity_vars <- df |>
    dplyr::group_by(.data[[entity_col]]) |>
    dplyr::summarise(
      var = stats::var(.data[[value_col]], na.rm = TRUE),
      n = dplyr::n(),
      .groups = "drop"
    ) |>
    dplyr::filter(!is.na(.data$var), .data$n > 1)

  if (nrow(entity_vars) == 0) return(NA_real_)

  # Weighted average within-entity variance
  within_var <- stats::weighted.mean(entity_vars$var, entity_vars$n, na.rm = TRUE)

  # Discrimination = 1 - (within / total) = between / total
  discrimination <- 1 - within_var / total_var

  # Clamp to [0, 1]
  max(0, min(1, discrimination))
}

#' Compute stability meta-metric for a statistic
#'
#' Stability measures how consistently a statistic persists across seasons
#' for the same team/player. Higher stability means the stat is more
#' predictable year-over-year.
#'
#' Calculated as the year-over-year correlation.
#'
#' @param df A data frame with columns: `team` (or `player`), `season`, `value`.
#' @param entity_col Character. Name of entity column (default "team").
#' @param value_col Character. Name of value column (default "value").
#' @param season_col Character. Name of season column (default "season").
#' @return Numeric. Stability coefficient (correlation, 0-1).
#' @family meta-analytics
#' @export
stat_stability <- function(df,
                            entity_col = "team",
                            value_col = "value",
                            season_col = "season") {
  rlang::check_required(df)

  required <- c(entity_col, value_col, season_col)
  missing <- setdiff(required, names(df))
  if (length(missing) > 0) {
    cli::cli_abort("Missing columns: {.val {missing}}")
  }

  # Sort seasons
  seasons <- sort(unique(df[[season_col]]))

  if (length(seasons) < 2) {
    cli::cli_warn("Need at least 2 seasons to compute stability.")
    return(NA_real_)
  }

  # Compute year-over-year correlations
  correlations <- numeric(length(seasons) - 1)

  for (i in seq_len(length(seasons) - 1)) {
    season_1 <- seasons[i]
    season_2 <- seasons[i + 1]

    df_1 <- df[df[[season_col]] == season_1, c(entity_col, value_col)]
    df_2 <- df[df[[season_col]] == season_2, c(entity_col, value_col)]

    names(df_1) <- c("entity", "value_1")
    names(df_2) <- c("entity", "value_2")

    merged <- dplyr::inner_join(df_1, df_2, by = "entity")

    if (nrow(merged) < 5) {
      correlations[i] <- NA_real_
    } else {
      correlations[i] <- stats::cor(merged$value_1, merged$value_2,
                                     use = "pairwise.complete.obs")
    }
  }

  # Average correlation (Fisher z-transform for proper averaging)
  valid_cors <- correlations[!is.na(correlations)]

  if (length(valid_cors) == 0) return(NA_real_)

  # Fisher z-transform, average, back-transform
  z_vals <- atanh(pmin(pmax(valid_cors, -0.999), 0.999))
  mean_z <- mean(z_vals)
  stability <- tanh(mean_z)

  # Return as positive value

  max(0, stability)
}

#' Compute meta-analytics for multiple statistics
#'
#' Calculates discrimination and stability for a set of team/player
#' statistics, identifying which metrics are most useful for prediction.
#'
#' @param df A data frame with entity, season, and multiple stat columns.
#' @param entity_col Character. Name of entity column.
#' @param season_col Character. Name of season column.
#' @param stat_cols Character vector. Names of statistic columns to analyze.
#' @return A tibble with `stat`, `discrimination`, `stability`.
#' @family meta-analytics
#' @export
compute_meta_analytics <- function(df,
                                    entity_col = "team",
                                    season_col = "season",
                                    stat_cols) {
  rlang::check_required(df)
  rlang::check_required(stat_cols)

  results <- vector("list", length(stat_cols))

  for (i in seq_along(stat_cols)) {
    stat <- stat_cols[i]

    if (!stat %in% names(df)) {
      results[[i]] <- tibble::tibble(
        stat = stat,
        discrimination = NA_real_,
        stability = NA_real_
      )
      next
    }

    # Create subset with renamed columns for helpers
    subset_df <- df[, c(entity_col, season_col, stat)]
    names(subset_df) <- c("entity", "season", "value")

    disc <- stat_discrimination(subset_df, "entity", "value")
    stab <- stat_stability(subset_df, "entity", "value", "season")

    results[[i]] <- tibble::tibble(
      stat = stat,
      discrimination = disc,
      stability = stab
    )
  }

  dplyr::bind_rows(results) |>
    dplyr::mutate(
      # Composite score: geometric mean of discrimination and stability
      composite = sqrt(.data$discrimination * .data$stability)
    ) |>
    dplyr::arrange(dplyr::desc(.data$composite))
}

#' Convert odds between any formats
#'
#' Convenience function to convert odds between decimal, fractional,
#' and American formats.
#'
#' @param odds Numeric or character. Input odds.
#' @param from Character. Input format: "decimal", "fractional", or "american".
#' @param to Character. Output format: "decimal", "fractional", or "american".
#' @return Odds in the target format.
#' @family odds
#' @export
convert_odds <- function(odds, from, to) {
  rlang::check_required(odds)
  rlang::check_required(from)
  rlang::check_required(to)

  from <- tolower(from)
  to <- tolower(to)

  valid_formats <- c("decimal", "fractional", "american")
  if (!from %in% valid_formats) {
    cli::cli_abort("{.arg from} must be one of: {.val {valid_formats}}")
  }
  if (!to %in% valid_formats) {
    cli::cli_abort("{.arg to} must be one of: {.val {valid_formats}}")
  }

  # Convert to decimal first
  decimal <- switch(
    from,
    decimal = as.numeric(odds),
    fractional = fractional_to_decimal(odds),
    american = american_to_decimal(odds)
  )

  # Convert from decimal to target
  switch(
    to,
    decimal = decimal,
    fractional = decimal_to_fractional(decimal),
    american = decimal_to_american(decimal)
  )
}
