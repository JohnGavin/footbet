# XGBoost model wrapper for football match prediction (Issue #37)

#' Prepare feature matrix for XGBoost
#'
#' Extracts and prepares features from match data for XGBoost training.
#' Handles missing values and converts to numeric matrix.
#'
#' @param matches A tibble with match data and feature columns.
#' @param features Character vector of feature column names to use.
#'   If NULL, uses default feature set.
#' @return A list with `x` (numeric matrix) and `feature_names`.
#' @family models
#' @export
prepare_xgb_features <- function(matches, features = NULL) {
  rlang::check_required(matches)

  if (is.null(features)) {
    # Default feature set
    features <- c(
      "home_elo", "away_elo", "elo_diff",
      "home_goals_scored_rolling", "home_goals_conceded_rolling",
      "away_goals_scored_rolling", "away_goals_conceded_rolling",
      "home_xg_rolling", "away_xg_rolling",
      "home_rest_days", "away_rest_days", "rest_advantage",
      "home_position", "away_position", "position_diff",
      "h2h_home_wins", "h2h_draws", "h2h_away_wins",
      "home_form_pts", "away_form_pts"
    )
  }

  # Keep only features that exist
  available <- intersect(features, colnames(matches))
  if (length(available) == 0L) {
    cli::cli_abort(c(
      "!" = "No requested features found in {.arg matches}.",
      "i" = "Requested: {.val {features}}",
      "i" = "Available: {.val {colnames(matches)}}"
    ))
  }

  if (length(available) < length(features)) {
    missing <- setdiff(features, available)
    cli::cli_warn("Features not found: {.val {missing}}")
  }

  # Extract and convert to matrix
  x <- as.matrix(matches[, available, drop = FALSE])
  storage.mode(x) <- "double"

  # Replace NA with median (simple imputation)
  for (j in seq_len(ncol(x))) {
    na_idx <- is.na(x[, j])
    if (any(na_idx)) {
      med <- stats::median(x[, j], na.rm = TRUE)
      x[na_idx, j] <- if (is.na(med)) 0 else med
    }
  }

  list(x = x, feature_names = available)
}

#' Fit XGBoost model for match outcome prediction
#'
#' Trains an XGBoost classifier for predicting match outcomes (H/D/A)
#' or goals. Supports multi-class classification and regression.
#'
#' @param matches A tibble with match data including features and outcome.
#' @param features Character vector of feature column names.
#'   If NULL, uses default feature set.
#' @param target Character. Target column: "ftr" for outcome (H/D/A),
#'   "fthg" for home goals, "ftag" for away goals.
#' @param params List of XGBoost parameters. Defaults provided for
#'   classification or regression based on target.
#' @param nrounds Integer. Number of boosting rounds (default 100).
#' @param early_stopping Integer. Rounds without improvement to stop
#'   (default 10). Set to NULL to disable.
#' @param verbose Integer. Verbosity level (0 = silent, default).
#' @return A list with `model` (xgb.Booster), `feature_names`,
#'   `target`, `params`, and `importance`.
#' @family models
#' @export
fit_xgboost <- function(matches,
                        features = NULL,
                        target = "ftr",
                        params = NULL,
                        nrounds = 100L,
                        early_stopping = 10L,
                        verbose = 0L) {
  rlang::check_required(matches)

  if (!target %in% colnames(matches)) {
    cli::cli_abort("Target column {.val {target}} not found in {.arg matches}.")
  }

  rlang::check_installed("xgboost",
    reason = "to fit XGBoost models"
  )

  # Prepare features
  feat <- prepare_xgb_features(matches, features)

  # Prepare target
  if (target == "ftr") {
    # Multi-class classification
    y_raw <- matches[[target]]
    if (!all(y_raw %in% c("H", "D", "A"))) {
      cli::cli_abort("Target {.val ftr} must contain only 'H', 'D', 'A' values.")
    }
    # Convert to 0-indexed numeric: H=0, D=1, A=2
    y <- as.integer(factor(y_raw, levels = c("H", "D", "A"))) - 1L
    objective <- "multi:softprob"
    eval_metric <- "mlogloss"
    num_class <- 3L
  } else {
    # Regression for goals
    y <- as.numeric(matches[[target]])
    objective <- "reg:squarederror"
    eval_metric <- "rmse"
    num_class <- NULL
  }

  # Default parameters
  if (is.null(params)) {
    params <- list(
      eta = 0.1,
      max_depth = 6L,
      min_child_weight = 1,
      subsample = 0.8,
      colsample_bytree = 0.8,
      gamma = 0
    )
  }
  params$objective <- objective
  params$eval_metric <- eval_metric
  if (!is.null(num_class)) {
    params$num_class <- num_class
  }

  # Create DMatrix
  dtrain <- xgboost::xgb.DMatrix(
    data = feat$x,
    label = y,
    feature_names = feat$feature_names
  )

  # Train with optional early stopping
  if (!is.null(early_stopping) && early_stopping > 0L) {
    # Split for validation
    n <- nrow(feat$x)
    val_idx <- sample(n, size = ceiling(n * 0.2))
    train_idx <- setdiff(seq_len(n), val_idx)

    dtrain_sub <- xgboost::xgb.DMatrix(
      data = feat$x[train_idx, , drop = FALSE],
      label = y[train_idx],
      feature_names = feat$feature_names
    )
    dval <- xgboost::xgb.DMatrix(
      data = feat$x[val_idx, , drop = FALSE],
      label = y[val_idx],
      feature_names = feat$feature_names
    )

    model <- xgboost::xgb.train(
      params = params,
      data = dtrain_sub,
      nrounds = nrounds,
      watchlist = list(train = dtrain_sub, val = dval),
      early_stopping_rounds = early_stopping,
      verbose = verbose
    )
  } else {
    model <- xgboost::xgb.train(
      params = params,
      data = dtrain,
      nrounds = nrounds,
      verbose = verbose
    )
  }

  # Feature importance
  importance <- xgboost::xgb.importance(
    feature_names = feat$feature_names,
    model = model
  )

  list(
    model = model,
    feature_names = feat$feature_names,
    target = target,
    params = params,
    importance = importance
  )
}

#' Predict with XGBoost model
#'
#' Generates predictions from a fitted XGBoost model.
#' For classification returns probabilities; for regression returns values.
#'
#' @param fit A list from [fit_xgboost()].
#' @param new_data A tibble with the same feature columns as training data.
#' @return For multi-class: a tibble with `prob_h`, `prob_d`, `prob_a`.
#'   For regression: a numeric vector of predicted values.
#' @family models
#' @export
predict_xgboost <- function(fit, new_data) {
  rlang::check_installed("xgboost")
  rlang::check_required(fit)
  rlang::check_required(new_data)

  if (!all(fit$feature_names %in% colnames(new_data))) {
    missing <- setdiff(fit$feature_names, colnames(new_data))
    cli::cli_abort("Missing features in {.arg new_data}: {.val {missing}}")
  }

  # Prepare features
  feat <- prepare_xgb_features(new_data, fit$feature_names)
  dtest <- xgboost::xgb.DMatrix(
    data = feat$x,
    feature_names = fit$feature_names
  )

  # Predict
  preds <- stats::predict(fit$model, dtest)

  if (fit$target == "ftr") {
    # Multi-class: reshape to matrix (n x 3)
    n <- nrow(new_data)
    pred_matrix <- matrix(preds, ncol = 3L, byrow = TRUE)
    tibble::tibble(
      prob_h = pred_matrix[, 1],
      prob_d = pred_matrix[, 2],
      prob_a = pred_matrix[, 3]
    )
  } else {
    # Regression: return as vector
    preds
  }
}

#' Predict matches with XGBoost model
#'
#' Convenience wrapper that adds predictions to match data.
#'
#' @param fit A list from [fit_xgboost()].
#' @param matches A tibble with feature columns.
#' @return The matches tibble with added prediction columns.
#' @family models
#' @export
predict_matches_xgb <- function(fit, matches) {
  rlang::check_required(fit)
  rlang::check_required(matches)

  preds <- predict_xgboost(fit, matches)

  if (fit$target == "ftr") {
    matches |>
      dplyr::bind_cols(preds) |>
      dplyr::mutate(
        pred_outcome = dplyr::case_when(
          .data$prob_h >= .data$prob_d & .data$prob_h >= .data$prob_a ~ "H",
          .data$prob_d >= .data$prob_h & .data$prob_d >= .data$prob_a ~ "D",
          TRUE ~ "A"
        )
      )
  } else {
    col_name <- paste0("pred_", fit$target)
    matches[[col_name]] <- preds
    matches
  }
}

#' Cross-validate XGBoost model
#'
#' Performs k-fold cross-validation for XGBoost hyperparameter tuning.
#'
#' @param matches A tibble with match data.
#' @param features Character vector of feature column names.
#' @param target Character. Target column name.
#' @param params List of XGBoost parameters.
#' @param nrounds Integer. Maximum boosting rounds.
#' @param nfold Integer. Number of CV folds (default 5).
#' @param early_stopping Integer. Early stopping rounds (default 10).
#' @return A list with `best_nrounds`, `cv_results`, and `best_score`.
#' @family models
#' @export
cv_xgboost <- function(matches,
                       features = NULL,
                       target = "ftr",
                       params = NULL,
                       nrounds = 200L,
                       nfold = 5L,
                       early_stopping = 10L) {
  rlang::check_installed("xgboost")

  # Prepare data
  feat <- prepare_xgb_features(matches, features)

  if (target == "ftr") {
    y_raw <- matches[[target]]
    y <- as.integer(factor(y_raw, levels = c("H", "D", "A"))) - 1L
    objective <- "multi:softprob"
    eval_metric <- "mlogloss"
    num_class <- 3L
  } else {
    y <- as.numeric(matches[[target]])
    objective <- "reg:squarederror"
    eval_metric <- "rmse"
    num_class <- NULL
  }

  if (is.null(params)) {
    params <- list(
      eta = 0.1,
      max_depth = 6L,
      min_child_weight = 1,
      subsample = 0.8,
      colsample_bytree = 0.8
    )
  }
  params$objective <- objective
  params$eval_metric <- eval_metric
  if (!is.null(num_class)) {
    params$num_class <- num_class
  }

  dtrain <- xgboost::xgb.DMatrix(
    data = feat$x,
    label = y,
    feature_names = feat$feature_names
  )

  cv_result <- xgboost::xgb.cv(
    params = params,
    data = dtrain,
    nrounds = nrounds,
    nfold = nfold,
    early_stopping_rounds = early_stopping,
    verbose = 0L
  )

  list(
    best_nrounds = cv_result$best_iteration,
    cv_results = cv_result$evaluation_log,
    best_score = cv_result$evaluation_log[[paste0("test_", eval_metric, "_mean")]][cv_result$best_iteration]
  )
}

#' Plot XGBoost feature importance
#'
#' Creates a bar plot of feature importance from a fitted XGBoost model.
#'
#' @param fit A list from [fit_xgboost()] with `importance` component.
#' @param top_n Integer. Number of top features to show (default 15).
#' @return A ggplot2 object.
#' @family models
#' @export
plot_xgb_importance <- function(fit, top_n = 15L) {
  rlang::check_installed("ggplot2")
  rlang::check_required(fit)

  if (is.null(fit$importance) || nrow(fit$importance) == 0L) {
    cli::cli_abort("No feature importance data in {.arg fit}.")
  }

  imp_df <- fit$importance |>
    dplyr::slice_head(n = top_n) |>
    dplyr::mutate(
      Feature = factor(.data$Feature, levels = rev(.data$Feature))
    )

  ggplot2::ggplot(imp_df, ggplot2::aes(x = .data$Gain, y = .data$Feature)) +
    ggplot2::geom_col(fill = "#3B82F6") +
    ggplot2::labs(
      title = "XGBoost Feature Importance",
      x = "Gain",
      y = NULL
    ) +
    ggplot2::theme_minimal()
}

#' Evaluate XGBoost model performance
#'
#' Computes performance metrics for XGBoost predictions.
#'
#' @param fit A list from [fit_xgboost()].
#' @param test_data A tibble with feature columns and actual outcomes.
#' @return A list with accuracy, log loss, and confusion matrix
#'   (for classification) or RMSE and MAE (for regression).
#' @family evaluation
#' @export
evaluate_xgboost <- function(fit, test_data) {
  rlang::check_required(fit)
  rlang::check_required(test_data)

  preds <- predict_xgboost(fit, test_data)
  actual <- test_data[[fit$target]]

  if (fit$target == "ftr") {
    # Classification metrics
    pred_outcome <- dplyr::case_when(
      preds$prob_h >= preds$prob_d & preds$prob_h >= preds$prob_a ~ "H",
      preds$prob_d >= preds$prob_h & preds$prob_d >= preds$prob_a ~ "D",
      TRUE ~ "A"
    )

    accuracy <- mean(pred_outcome == actual)

    # Log loss
    actual_idx <- as.integer(factor(actual, levels = c("H", "D", "A")))
    probs <- as.matrix(preds)
    # Clip to avoid log(0)
    probs <- pmax(pmin(probs, 1 - 1e-15), 1e-15)
    log_loss <- -mean(log(probs[cbind(seq_along(actual_idx), actual_idx)]))

    # Confusion matrix
    confusion <- table(Predicted = pred_outcome, Actual = actual)

    list(
      accuracy = accuracy,
      log_loss = log_loss,
      confusion = confusion
    )
  } else {
    # Regression metrics
    rmse <- sqrt(mean((preds - actual)^2))
    mae <- mean(abs(preds - actual))

    list(
      rmse = rmse,
      mae = mae
    )
  }
}

#' Hyperparameter grid search for XGBoost
#'
#' Searches over a grid of hyperparameters using cross-validation.
#'
#' @param matches A tibble with match data.
#' @param features Character vector of feature column names.
#' @param target Character. Target column name.
#' @param param_grid A list of vectors for each parameter to search.
#'   Default searches over eta, max_depth, and subsample.
#' @param nrounds Integer. Maximum boosting rounds (default 100).
#' @param nfold Integer. CV folds (default 5).
#' @return A tibble with parameter combinations and CV scores.
#' @family models
#' @export
tune_xgboost <- function(matches,
                         features = NULL,
                         target = "ftr",
                         param_grid = NULL,
                         nrounds = 100L,
                         nfold = 5L) {
  rlang::check_installed("xgboost")

  if (is.null(param_grid)) {
    param_grid <- list(
      eta = c(0.05, 0.1, 0.2),
      max_depth = c(3L, 6L, 9L),
      subsample = c(0.7, 0.8, 0.9)
    )
  }

  # Generate all combinations
  grid <- expand.grid(param_grid, stringsAsFactors = FALSE)

  cli::cli_alert("Testing {nrow(grid)} parameter combinations...")

  results <- vector("list", nrow(grid))
  for (i in seq_len(nrow(grid))) {
    params <- as.list(grid[i, ])

    cv_res <- tryCatch(
      cv_xgboost(
        matches = matches,
        features = features,
        target = target,
        params = params,
        nrounds = nrounds,
        nfold = nfold,
        early_stopping = 10L
      ),
      error = function(e) {
        cli::cli_warn("Failed for params {.val {params}}: {conditionMessage(e)}")
        list(best_score = NA_real_, best_nrounds = NA_integer_)
      }
    )

    results[[i]] <- tibble::tibble(
      eta = params$eta,
      max_depth = params$max_depth,
      subsample = params$subsample,
      best_nrounds = cv_res$best_nrounds,
      cv_score = cv_res$best_score
    )
  }

  result_df <- dplyr::bind_rows(results) |>
    dplyr::arrange(.data$cv_score)

  cli::cli_alert_success("Best: eta={result_df$eta[1]}, max_depth={result_df$max_depth[1]}, subsample={result_df$subsample[1]}")

  result_df
}
