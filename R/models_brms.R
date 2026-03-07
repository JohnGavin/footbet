#' Fit a hierarchical Bayesian Poisson model with brms
#'
#' Fits a Poisson regression for goals with random effects for teams,
#' enabling partial pooling (shrinkage) of team attack/defense strengths.
#'
#' @param long_df A long-format tibble with columns `goals`, `home`, `team`, `opponent`.
#' @param iter Integer. Total MCMC iterations per chain (default 2000).
#' @param warmup Integer. Warmup iterations per chain (default 1000).
#' @param chains Integer. Number of MCMC chains (default 4).
#' @param cores Integer. Number of cores for parallel chains (default 4).
#' @param seed Integer. Random seed for reproducibility.
#' @param prior A `brmsprior` object or NULL for default priors.
#' @param ... Additional arguments passed to [brms::brm()].
#' @return A `brmsfit` object.
#' @family models
#' @export
fit_brms_poisson <- function(long_df,
                              iter = 2000L,
                              warmup = 1000L,
                              chains = 4L,
                              cores = 4L,
                              seed = 42L,
                              prior = NULL,
                              ...) {
  rlang::check_installed("brms", reason = "to fit Bayesian hierarchical models")
  rlang::check_required(long_df)

  required_cols <- c("goals", "home", "team", "opponent")
  missing <- setdiff(required_cols, colnames(long_df))
  if (length(missing) > 0L) {
    cli::cli_abort(c(
      "x" = "Missing columns: {.field {missing}}",
      "i" = "Expected: {.field {required_cols}}"
    ))
  }

  if (nrow(long_df) == 0L) {
    cli::cli_abort("Cannot fit model on empty data.")
  }

  # Default weakly informative priors
  if (is.null(prior)) {
    prior <- brms::prior(normal(0, 0.5), class = "b") +
      brms::prior(normal(0, 0.3), class = "sd")
  }

  cli::cli_alert("Fitting brms Poisson model with random effects...")
  cli::cli_alert_info("{nrow(long_df)} observations, {length(unique(long_df$team))} teams")

  # Formula: goals ~ home + (1 | team) + (1 | opponent)
  # - home: fixed effect for home advantage

  # - (1 | team): random intercept for attacking strength
  # - (1 | opponent): random intercept for defensive weakness
  formula <- brms::bf(goals ~ home + (1 | team) + (1 | opponent))

  fit <- brms::brm(
    formula = formula,
    data = long_df,
    family = "poisson",
    prior = prior,
    iter = iter,
    warmup = warmup,
    chains = chains,
    cores = cores,
    seed = seed,
    refresh = 0,  # Suppress progress output
    ...
  )

  fit
}

#' Predict match outcome probabilities from a brms Poisson model
#'
#' Uses posterior predictive distribution to compute 1X2, O/U, and AH probabilities.
#'
#' @param model A `brmsfit` object from [fit_brms_poisson()].
#' @param home_team Character. Home team name.
#' @param away_team Character. Away team name.
#' @param max_goals Integer. Maximum goals to consider in score matrix (default 10).
#' @param ndraws Integer. Number of posterior draws to use (default 1000).
#' @return A list with components:
#'   - `score_matrix`: Matrix of P(home=i, away=j) probabilities
#'   - `prob_1x2`: Named vector c(H, D, A)
#'   - `prob_ou`: Named vector c(over_25, under_25)
#'   - `prob_ah`: Named vector with Asian handicap probabilities (if applicable
#' @family models
#' @export
predict_brms <- function(model,
                          home_team,
                          away_team,
                          max_goals = 10L,
                          ndraws = 1000L) {
  rlang::check_installed("brms")
  rlang::check_required(model)
  rlang::check_required(home_team)
  rlang::check_required(away_team)

  if (!inherits(model, "brmsfit")) {
    cli::cli_abort("{.arg model} must be a brmsfit object, not {.cls {class(model)}}.")
  }

  # Create prediction data for home and away goals
  newdata <- tibble::tibble(
    goals = NA_integer_,
    home = c(1L, 0L),
    team = c(home_team, away_team),
    opponent = c(away_team, home_team)
  )

  # Get posterior predictive samples of lambda (expected goals)
  # We need the linear predictor, not draws of y
  linpred <- brms::posterior_linpred(
    model,
    newdata = newdata,
    ndraws = ndraws,
    transform = TRUE  # Apply exp() to get lambda on original scale
  )

  # linpred is ndraws x 2 matrix: [, 1] = home lambda, [, 2] = away lambda
  lambda_home <- linpred[, 1]
  lambda_away <- linpred[, 2]

  # Compute score matrix by averaging over posterior samples
  # P(home=i, away=j) = mean over draws of dpois(i, lambda_home) * dpois(j, lambda_away)
  score_mat <- matrix(0, nrow = max_goals + 1L, ncol = max_goals + 1L)
  rownames(score_mat) <- 0:max_goals
  colnames(score_mat) <- 0:max_goals

  for (i in 0:max_goals) {
    for (j in 0:max_goals) {
      probs <- stats::dpois(i, lambda_home) * stats::dpois(j, lambda_away)
      score_mat[i + 1, j + 1] <- mean(probs)
    }
  }

  # Normalise to sum to 1

score_mat <- score_mat / sum(score_mat)

  # 1X2 probabilities
  prob_home <- sum(score_mat[lower.tri(score_mat, diag = FALSE)])
  prob_draw <- sum(diag(score_mat))
  prob_away <- sum(score_mat[upper.tri(score_mat, diag = FALSE)])

  # O/U 2.5 probabilities
  total_goals <- outer(0:max_goals, 0:max_goals, `+`)
  prob_over_25 <- sum(score_mat[total_goals > 2.5])
  prob_under_25 <- sum(score_mat[total_goals <= 2.5])

  list(
    score_matrix = score_mat,
    prob_1x2 = c(H = prob_home, D = prob_draw, A = prob_away),
    prob_ou = c(over_25 = prob_over_25, under_25 = prob_under_25),
    lambda = c(home = mean(lambda_home), away = mean(lambda_away)),
    lambda_sd = c(home = stats::sd(lambda_home), away = stats::sd(lambda_away))
  )
}

#' Batch predict matches from a brms model
#'
#' @param model A `brmsfit` object.
#' @param matches_df A tibble with `home_team` and `away_team` columns.
#' @param max_goals Integer. Maximum goals in score matrix.
#' @param ndraws Integer. Number of posterior draws.
#' @return A tibble with match predictions.
#' @family models
#' @export
predict_matches_brms <- function(model, matches_df, max_goals = 10L, ndraws = 500L) {
  rlang::check_required(model)
  rlang::check_required(matches_df)

  if (!all(c("home_team", "away_team") %in% colnames(matches_df))) {
    cli::cli_abort("matches_df must have columns {.field home_team} and {.field away_team}.")
  }

  # Check which teams are in the model
  model_teams <- unique(c(model$data$team, model$data$opponent))
  home_missing <- setdiff(unique(matches_df$home_team), model_teams)
  away_missing <- setdiff(unique(matches_df$away_team), model_teams)

  if (length(home_missing) > 0L || length(away_missing) > 0L) {
    cli::cli_warn(c(
      "!" = "Some teams not in training data (will use population mean):",
      "i" = "Home: {.val {head(home_missing, 5)}}",
      "i" = "Away: {.val {head(away_missing, 5)}}"
    ))
  }

  results <- vector("list", nrow(matches_df))

  for (i in seq_len(nrow(matches_df))) {
    pred <- tryCatch(
      predict_brms(
        model,
        home_team = matches_df$home_team[[i]],
        away_team = matches_df$away_team[[i]],
        max_goals = max_goals,
        ndraws = ndraws
      ),
      error = function(e) {
        cli::cli_warn("Prediction failed for row {i}: {conditionMessage(e)}")
        NULL
      }
    )

    if (!is.null(pred)) {
      results[[i]] <- tibble::tibble(
        home_team = matches_df$home_team[[i]],
        away_team = matches_df$away_team[[i]],
        prob_h = pred$prob_1x2[["H"]],
        prob_d = pred$prob_1x2[["D"]],
        prob_a = pred$prob_1x2[["A"]],
        prob_over_25 = pred$prob_ou[["over_25"]],
        prob_under_25 = pred$prob_ou[["under_25"]],
        lambda_home = pred$lambda[["home"]],
        lambda_away = pred$lambda[["away"]],
        lambda_home_sd = pred$lambda_sd[["home"]],
        lambda_away_sd = pred$lambda_sd[["away"]]
      )
    }
  }

  dplyr::bind_rows(results)
}

#' Evaluate brms model via walk-forward cross-validation
#'
#' @param long_df Long-format match data.
#' @param matches_df Wide-format match data with outcomes.
#' @param train_months Integer. Months of training data per fold.
#' @param test_months Integer. Months of test data per fold.
#' @param iter Integer. MCMC iterations (reduce for faster CV).
#' @param warmup Integer. Warmup iterations.
#' @param chains Integer. Number of chains.
#' @param cores Integer. Cores for parallel.
#' @return A tibble with per-fold evaluation metrics.
#' @family models
#' @export
evaluate_brms <- function(long_df,
                          matches_df,
                          train_months = 24L,
                          test_months = 1L,
                          iter = 1000L,
                          warmup = 500L,
                          chains = 2L,
                          cores = 2L) {
  rlang::check_required(long_df)
  rlang::check_required(matches_df)

  # Get date range
  dates <- sort(unique(matches_df$match_date))
  if (length(dates) < train_months * 30) {
    cli::cli_abort("Not enough data for walk-forward CV with {train_months} month training window.")
  }

  # Generate folds
  splits <- walk_forward_splits(dates, train_months, test_months)

  results <- vector("list", length(splits))

  for (i in seq_along(splits)) {
    split <- splits[[i]]
    cli::cli_alert("Fold {i}/{length(splits)}: Train {split$train_start} to {split$train_end}")

    # Filter training data
    train_long <- long_df |>
      dplyr::filter(
        match_date >= split$train_start,
        match_date <= split$train_end
      )

    # Filter test matches
    test_matches <- matches_df |>
      dplyr::filter(
        match_date >= split$test_start,
        match_date <= split$test_end
      )

    if (nrow(train_long) < 100L || nrow(test_matches) == 0L) {
      cli::cli_warn("Skipping fold {i}: insufficient data")
      next
    }

    # Fit model
    model <- tryCatch(
      fit_brms_poisson(
        train_long,
        iter = iter,
        warmup = warmup,
        chains = chains,
        cores = cores
      ),
      error = function(e) {
        cli::cli_warn("Model fit failed for fold {i}: {conditionMessage(e)}")
        NULL
      }
    )

    if (is.null(model)) next

    # Predict test matches
    preds <- predict_matches_brms(model, test_matches, ndraws = 500L)

    if (nrow(preds) == 0L) next

    # Join with actual results
    eval_df <- preds |>
      dplyr::inner_join(
        dplyr::select(test_matches, home_team, away_team, match_date, ftr),
        by = c("home_team", "away_team")
      )

    if (nrow(eval_df) == 0L) next

    # Extract probability of actual outcome for log loss
    prob_actual <- dplyr::case_when(
      eval_df$ftr == "H" ~ eval_df$prob_h,
      eval_df$ftr == "D" ~ eval_df$prob_d,
      eval_df$ftr == "A" ~ eval_df$prob_a,
      TRUE ~ NA_real_
    )
    prob_actual <- prob_actual[!is.na(prob_actual)]

    if (length(prob_actual) == 0L) next

    # Compute metrics
    ll <- log_loss(prob_actual)
    br <- brier_1x2(eval_df$prob_h, eval_df$prob_d, eval_df$prob_a, eval_df$ftr)
    rp <- rps_1x2(eval_df$prob_h, eval_df$prob_d, eval_df$prob_a, eval_df$ftr)

    results[[i]] <- tibble::tibble(
      fold = i,
      train_start = split$train_start,
      train_end = split$train_end,
      test_start = split$test_start,
      test_end = split$test_end,
      n_train = nrow(train_long),
      n_test = nrow(eval_df),
      log_loss = ll,
      brier = br,
      rps = rp
    )
  }

  dplyr::bind_rows(results)
}
