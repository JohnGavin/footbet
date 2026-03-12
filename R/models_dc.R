#' Fit a Dixon-Coles model using goalmodel
#'
#' Wraps `goalmodel::goalmodel()` with the Dixon-Coles low-score
#' correction enabled and exponential time-decay weights.
#'
#' @param matches_df A tibble with `home_team`, `away_team`,
#'   `fthg`, `ftag`, `match_date`.
#' @param xi Numeric. Time-decay rate parameter (default 0.003).
#'   Higher values discount older matches more.
#' @return A goalmodel object.
#' @family models
#' @export
fit_dixon_coles <- function(matches_df, xi = 0.003) {
  rlang::check_installed("goalmodel",
    reason = "to fit Dixon-Coles models"
  )
  rlang::check_required(matches_df)
  if (!is.data.frame(matches_df)) {
    cli::cli_abort("{.arg matches_df} must be a data frame, not {.cls {class(matches_df)}}.")
  }

  required_cols <- c("home_team", "away_team", "fthg", "ftag", "match_date")
  missing <- setdiff(required_cols, colnames(matches_df))
  if (length(missing) > 0L) {
    cli::cli_abort("Missing columns: {.val {missing}}")
  }

  if (nrow(matches_df) == 0L) {
    cli::cli_abort("{.arg matches_df} must not be empty.")
  }


  # Filter out rows with NA dates (cannot compute weights)
  matches_df <- matches_df[!is.na(matches_df$match_date), ]
  if (nrow(matches_df) == 0L) {
    cli::cli_abort("All rows have NA match_date.")
  }

  # Compute time-decay weights
  max_date <- max(matches_df$match_date, na.rm = TRUE)
  days_ago <- as.numeric(difftime(max_date, matches_df$match_date, units = "days"))
  weights <- exp(-xi * days_ago)

  goalmodel::goalmodel(
    goals1 = matches_df$fthg,
    goals2 = matches_df$ftag,
    team1  = matches_df$home_team,
    team2  = matches_df$away_team,
    dc     = TRUE,
    weights = weights
  )
}

#' Predict match probabilities from a Dixon-Coles model
#'
#' Uses `goalmodel::predict_result()` for 1X2 probabilities and
#' `goalmodel::predict_goals()` for expected goals, then builds
#' a score matrix for O/U and AH markets.
#'
#' @param model A goalmodel object from [fit_dixon_coles()].
#' @param home_team Character. Home team name.
#' @param away_team Character. Away team name.
#' @param max_goals Integer. Maximum goals for score matrix (default 7).
#' @return A list with `probs_1x2`, `probs_ou25`, `probs_ah05`,
#'   `lambda_home`, `lambda_away`.
#' @family models
#' @export
predict_dc <- function(model, home_team, away_team, max_goals = 7L) {
  rlang::check_installed("goalmodel")
  rlang::check_required(model)

  pred <- goalmodel::predict_result(
    model,
    team1 = home_team,
    team2 = away_team,
    return_df = TRUE
  )

  # Get expected goals for score matrix
  exp_goals <- goalmodel::predict_expg(
    model,
    team1 = home_team,
    team2 = away_team,
    return_df = TRUE
  )

  lambda_home <- exp_goals$expg1
  lambda_away <- exp_goals$expg2

  # Build score matrix from expected goals (independent Poisson approximation)
  # Note: DC correction is already in the 1X2 probs from predict_result
  mat <- score_matrix(lambda_home, lambda_away, max_goals = max_goals)

  list(
    probs_1x2 = c(
      H = pred$p1,
      D = pred$pd,
      A = pred$p2
    ),
    probs_ou25 = score_matrix_to_ou(mat),
    probs_ah05 = score_matrix_to_ah(mat, line = -0.5),
    lambda_home = lambda_home,
    lambda_away = lambda_away
  )
}

#' Predict 1X2 probabilities for all matches using Dixon-Coles
#'
#' Applies [predict_dc()] to each row and returns a tibble of predictions.
#'
#' @param model A goalmodel object from [fit_dixon_coles()].
#' @param matches_df A tibble with `match_id`, `home_team`, `away_team`.
#' @return A tibble with `match_id`, `pred_h`, `pred_d`, `pred_a`,
#'   `pred_over25`, `pred_under25`.
#' @family models
#' @export
predict_matches_dc <- function(model, matches_df) {
  rlang::check_installed("goalmodel")
  rlang::check_required(model)
  rlang::check_required(matches_df)

  if (nrow(matches_df) == 0L) {
    return(tibble::tibble(
      match_id = character(),
      pred_h = numeric(), pred_d = numeric(), pred_a = numeric(),
      pred_over25 = numeric(), pred_under25 = numeric()
    ))
  }

  # Get teams the model knows about
  model_teams <- model$all_teams

  n <- nrow(matches_df)
  pred_h <- rep(NA_real_, n)
  pred_d <- rep(NA_real_, n)
  pred_a <- rep(NA_real_, n)
  pred_over25 <- rep(NA_real_, n)
  pred_under25 <- rep(NA_real_, n)

  for (i in seq_len(n)) {
    ht <- matches_df$home_team[i]
    at <- matches_df$away_team[i]

    if (!(ht %in% model_teams) || !(at %in% model_teams)) next

    p <- tryCatch(
      predict_dc(model, ht, at),
      error = function(e) NULL
    )
    if (is.null(p)) next

    pred_h[i] <- p$probs_1x2[["H"]]
    pred_d[i] <- p$probs_1x2[["D"]]
    pred_a[i] <- p$probs_1x2[["A"]]
    pred_over25[i] <- p$probs_ou25[["over"]]
    pred_under25[i] <- p$probs_ou25[["under"]]
  }

  tibble::tibble(
    match_id = matches_df$match_id,
    pred_h = pred_h,
    pred_d = pred_d,
    pred_a = pred_a,
    pred_over25 = pred_over25,
    pred_under25 = pred_under25
  )
}

#' Walk-forward evaluation for Dixon-Coles model
#'
#' For each time split, fits [fit_dixon_coles()] on the training set,
#' predicts on the test set, and computes scoring metrics.
#'
#' @param matches_df Match data (wide format) with `match_id`, `home_team`,
#'   `away_team`, `fthg`, `ftag`, `ftr`, `match_date`.
#' @param train_months Integer. Training window (default 24).
#' @param test_months Integer. Test period (default 1).
#' @param xi Numeric. Time-decay parameter (default 0.003).
#' @return A tibble with one row per fold and scoring metrics.
#' @family models
#' @export
evaluate_dc <- function(matches_df,
                        train_months = 24L,
                        test_months = 1L,
                        xi = 0.003) {
  rlang::check_installed("goalmodel")
  rlang::check_required(matches_df)
  if (!is.data.frame(matches_df)) {
    cli::cli_abort("{.arg matches_df} must be a data frame, not {.cls {class(matches_df)}}.")
  }

  dates <- sort(unique(matches_df$match_date))
  splits <- walk_forward_splits(dates, train_months, test_months)

  if (length(splits) == 0L) {
    cli::cli_warn("No valid walk-forward splits for Dixon-Coles.")
    return(tibble::tibble(
      fold = integer(), n_train = integer(), n_test = integer(),
      log_loss = numeric(), brier = numeric(), rps = numeric(),
      train_start = as.Date(character()), test_start = as.Date(character()),
      test_end = as.Date(character())
    ))
  }

  results <- vector("list", length(splits))

  for (k in seq_along(splits)) {
    sp <- splits[[k]]

    train_df <- matches_df[matches_df$match_date >= sp$train_start &
                             matches_df$match_date < sp$test_start, ]
    test_df <- matches_df[matches_df$match_date >= sp$test_start &
                            matches_df$match_date < sp$test_end, ]

    if (nrow(train_df) < 50L || nrow(test_df) == 0L) next

    # Fit DC model
    model <- tryCatch(
      fit_dixon_coles(train_df, xi = xi),
      error = function(e) NULL
    )
    if (is.null(model)) next

    # Predict
    preds <- tryCatch(
      predict_matches_dc(model, test_df),
      error = function(e) NULL
    )
    if (is.null(preds)) next

    # Join with actual results
    eval_df <- dplyr::inner_join(preds, test_df[, c("match_id", "ftr")],
                                  by = "match_id") |>
      dplyr::filter(!is.na(.data$pred_h))

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
      n_train = nrow(train_df),
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
  }

  dplyr::bind_rows(results)
}
