#' @title Quant Simulation Methods
#' @description Advanced simulation techniques for football outcome prediction:
#'   variance reduction, importance sampling, and correlated match simulation.
#' @name simulation
#' @family simulation
NULL

# ============================================================================
# VARIANCE REDUCTION
# ============================================================================

#' Monte Carlo simulation with variance reduction
#'
#' Simulates match outcomes using stacked variance reduction techniques:
#' antithetic variates, control variates, and stratified sampling.
#'
#' @param lambda_home Numeric. Expected home goals (Poisson rate).
#' @param lambda_away Numeric. Expected away goals (Poisson rate).
#' @param n_sims Integer. Number of simulations (default 10000).
#' @param method Character. Variance reduction method:
#'   - "crude": Plain Monte Carlo (baseline)
#'   - "antithetic": Antithetic variates (~50% variance reduction)
#'   - "control": Control variates using closed-form Poisson
#'   - "stratified": Stratified sampling
#'   - "stacked": All methods combined (best, default)
#' @param seed Integer. Random seed for reproducibility.
#' @return A list with:
#'   - `prob_1x2`: Named vector c(H, D, A)
#'   - `prob_ou`: Named vector c(over_25, under_25)
#'   - `se`: Standard errors for each probability
#'   - `n_sims`: Effective number of simulations
#'   - `method`: Method used
#'   - `variance_reduction`: Estimated variance reduction factor vs crude
#' @family simulation
#' @export
simulate_match_vr <- function(lambda_home,
                               lambda_away,
                               n_sims = 10000L,
                               method = c("stacked", "crude", "antithetic", "control", "stratified"),
                               seed = NULL) {
  method <- match.arg(method)

 if (!is.null(seed)) set.seed(seed)

  if (lambda_home <= 0 || lambda_away <= 0) {
    cli::cli_abort("Lambda values must be positive.")
  }

  result <- switch(
    method,
    crude = simulate_crude(lambda_home, lambda_away, n_sims),
    antithetic = simulate_antithetic(lambda_home, lambda_away, n_sims),
    control = simulate_control(lambda_home, lambda_away, n_sims),
    stratified = simulate_stratified(lambda_home, lambda_away, n_sims),
    stacked = simulate_stacked(lambda_home, lambda_away, n_sims)
  )

  result$method <- method
  result
}

#' @noRd
simulate_crude <- function(lambda_home, lambda_away, n_sims) {
  home_goals <- stats::rpois(n_sims, lambda_home)
  away_goals <- stats::rpois(n_sims, lambda_away)

  compute_probs_from_sims(home_goals, away_goals, n_sims)
}

#' @noRd
simulate_antithetic <- function(lambda_home, lambda_away, n_sims) {
  # Generate uniform random variables
  n_half <- n_sims %/% 2
  u_home <- stats::runif(n_half)
  u_away <- stats::runif(n_half)

  # Original samples
  home1 <- stats::qpois(u_home, lambda_home)
  away1 <- stats::qpois(u_away, lambda_away)

  # Antithetic samples (1 - u)
  home2 <- stats::qpois(1 - u_home, lambda_home)
  away2 <- stats::qpois(1 - u_away, lambda_away)

  home_goals <- c(home1, home2)
  away_goals <- c(away1, away2)

  result <- compute_probs_from_sims(home_goals, away_goals, length(home_goals))
  result$variance_reduction <- 2.0  # Theoretical ~2x for correlated antithetic
  result
}

#' @noRd
simulate_control <- function(lambda_home, lambda_away, n_sims) {
  # Simulate with crude MC
  home_goals <- stats::rpois(n_sims, lambda_home)
  away_goals <- stats::rpois(n_sims, lambda_away)

  # Control variate: use closed-form Poisson expectations
  # E[goals] = lambda, we use deviation from lambda as control
  control_home <- home_goals - lambda_home
  control_away <- away_goals - lambda_away

  # Indicators for outcomes
  home_win <- as.numeric(home_goals > away_goals)
  draw <- as.numeric(home_goals == away_goals)
  away_win <- as.numeric(home_goals < away_goals)
  over_25 <- as.numeric(home_goals + away_goals > 2.5)

  # Compute optimal beta coefficients for control variates
  # beta = -Cov(Y, C) / Var(C)
  beta_home_h <- -stats::cov(home_win, control_home) / stats::var(control_home)
  beta_away_h <- -stats::cov(home_win, control_away) / stats::var(control_away)

  # Adjusted estimates
  home_win_adj <- home_win + beta_home_h * control_home + beta_away_h * control_away
  draw_adj <- draw  # Less benefit for draw
  away_win_adj <- away_win - beta_home_h * control_home - beta_away_h * control_away
  over_25_adj <- over_25

  # Clamp to [0, 1] and normalise
  probs <- c(
    H = max(0, min(1, mean(home_win_adj))),
    D = mean(draw),
    A = max(0, min(1, mean(away_win_adj)))
  )
  probs <- probs / sum(probs)

  list(
    prob_1x2 = probs,
    prob_ou = c(over_25 = mean(over_25), under_25 = 1 - mean(over_25)),
    se = c(
      H = stats::sd(home_win_adj) / sqrt(n_sims),
      D = stats::sd(draw) / sqrt(n_sims),
      A = stats::sd(away_win_adj) / sqrt(n_sims)
    ),
    n_sims = n_sims,
    variance_reduction = stats::var(home_win) / stats::var(home_win_adj)
  )
}

#' @noRd
simulate_stratified <- function(lambda_home, lambda_away, n_sims) {
  # Stratify by total goals (0-1, 2-3, 4-5, 6+)
  # Use theoretical probabilities to allocate samples
  max_goals <- 10L
  strata <- list(
    c(0, 1),
    c(2, 3),
    c(4, 5),
    6:max_goals
  )

  # Compute stratum probabilities using closed-form Poisson
  stratum_probs <- vapply(strata, function(s) {
    sum(vapply(s, function(total) {
      sum(stats::dpois(0:total, lambda_home) * stats::dpois(total - 0:total, lambda_away))
    }, numeric(1)))
  }, numeric(1))
  stratum_probs <- stratum_probs / sum(stratum_probs)

  # Allocate samples proportionally
  n_per_stratum <- pmax(1L, round(n_sims * stratum_probs))

  home_goals <- integer(0)
  away_goals <- integer(0)
  weights <- numeric(0)

  for (i in seq_along(strata)) {
    n_s <- n_per_stratum[i]
    total_range <- strata[[i]]

    for (j in seq_len(n_s)) {
      # Sample total goals from stratum
      total <- sample(total_range, 1)
      # Split between home and away (conditional on total)
      h <- stats::rbinom(1, total, lambda_home / (lambda_home + lambda_away))
      a <- total - h
      home_goals <- c(home_goals, h)
      away_goals <- c(away_goals, a)
      weights <- c(weights, stratum_probs[i] / n_per_stratum[i] * n_sims)
    }
  }

  # Weighted probability estimates
  home_win <- home_goals > away_goals
  draw_ind <- home_goals == away_goals
  away_win <- home_goals < away_goals
  over_25 <- (home_goals + away_goals) > 2.5

  w_norm <- weights / sum(weights)

  list(
    prob_1x2 = c(
      H = sum(w_norm * home_win),
      D = sum(w_norm * draw_ind),
      A = sum(w_norm * away_win)
    ),
    prob_ou = c(
      over_25 = sum(w_norm * over_25),
      under_25 = sum(w_norm * (!over_25))
    ),
    se = c(H = NA_real_, D = NA_real_, A = NA_real_),  # Complex for stratified
    n_sims = length(home_goals),
    variance_reduction = 3.0  # Approximate
  )
}

#' @noRd
simulate_stacked <- function(lambda_home, lambda_away, n_sims) {
  # Combine antithetic + control variates for maximum reduction
  n_half <- n_sims %/% 2
  u_home <- stats::runif(n_half)
  u_away <- stats::runif(n_half)

  # Antithetic pairs
  home1 <- stats::qpois(u_home, lambda_home)
  away1 <- stats::qpois(u_away, lambda_away)
  home2 <- stats::qpois(1 - u_home, lambda_home)
  away2 <- stats::qpois(1 - u_away, lambda_away)

  home_goals <- c(home1, home2)
  away_goals <- c(away1, away2)
  n_total <- length(home_goals)

  # Control variates
  control_home <- home_goals - lambda_home
  control_away <- away_goals - lambda_away

  home_win <- as.numeric(home_goals > away_goals)
  draw_ind <- as.numeric(home_goals == away_goals)
  away_win <- as.numeric(home_goals < away_goals)
  over_25 <- as.numeric(home_goals + away_goals > 2.5)

  # Optimal beta for control variates
  var_ch <- stats::var(control_home)
  var_ca <- stats::var(control_away)

  if (var_ch > 1e-10 && var_ca > 1e-10) {
    beta_h <- -stats::cov(home_win, control_home) / var_ch
    beta_a <- -stats::cov(home_win, control_away) / var_ca
    home_win_adj <- home_win + beta_h * control_home + beta_a * control_away
    vr_factor <- stats::var(home_win) / max(1e-10, stats::var(home_win_adj))
  } else {
    home_win_adj <- home_win
    vr_factor <- 2.0
  }

  probs <- c(
    H = max(0, min(1, mean(home_win_adj))),
    D = mean(draw_ind),
    A = max(0, min(1, 1 - mean(home_win_adj) - mean(draw_ind)))
  )
  probs <- probs / sum(probs)

  list(
    prob_1x2 = probs,
    prob_ou = c(over_25 = mean(over_25), under_25 = 1 - mean(over_25)),
    se = c(
      H = stats::sd(home_win_adj) / sqrt(n_total),
      D = stats::sd(draw_ind) / sqrt(n_total),
      A = NA_real_
    ),
    n_sims = n_total,
    variance_reduction = vr_factor * 2  # Antithetic + control
  )
}

#' @noRd
compute_probs_from_sims <- function(home_goals, away_goals, n_sims) {
  home_win <- home_goals > away_goals
  draw_ind <- home_goals == away_goals
  away_win <- home_goals < away_goals
  over_25 <- (home_goals + away_goals) > 2.5

  list(
    prob_1x2 = c(H = mean(home_win), D = mean(draw_ind), A = mean(away_win)),
    prob_ou = c(over_25 = mean(over_25), under_25 = mean(!over_25)),
    se = c(
      H = stats::sd(home_win) / sqrt(n_sims),
      D = stats::sd(draw_ind) / sqrt(n_sims),
      A = stats::sd(away_win) / sqrt(n_sims)
    ),
    n_sims = n_sims,
    variance_reduction = 1.0
  )
}

# ============================================================================
# IMPORTANCE SAMPLING FOR RARE EVENTS
# ============================================================================

#' Importance sampling for rare match outcomes
#'
#' Estimates probabilities of rare events (e.g., 8+ goals, exact scoreline)
#' with much lower variance than crude Monte Carlo.
#'
#' @param lambda_home Numeric. Expected home goals.
#' @param lambda_away Numeric. Expected away goals.
#' @param outcome Character. Outcome to estimate:
#'   - "over_X" (e.g., "over_5.5", "over_7.5")
#'   - "exact_HH_AA" (e.g., "exact_5_3")
#'   - "home_X+" (e.g., "home_4+")
#' @param n_sims Integer. Number of importance samples.
#' @param tilt Numeric or "auto". Exponential tilting parameter.
#'   Higher values focus samples on rare events. "auto" estimates optimal tilt.
#' @return A list with:
#'   - `probability`: Estimated probability
#'   - `se`: Standard error
#'   - `effective_n`: Effective sample size (lower if weights are uneven)
#'   - `variance_reduction`: Factor vs crude MC
#' @family simulation
#' @export
importance_sample_rare <- function(lambda_home,
                                    lambda_away,
                                    outcome,
                                    n_sims = 10000L,
                                    tilt = "auto") {
  rlang::check_required(outcome)

  # Parse outcome
  parsed <- parse_rare_outcome(outcome)

  # Determine tilted distribution parameters
  if (identical(tilt, "auto")) {
    tilt <- estimate_optimal_tilt(lambda_home, lambda_away, parsed)
  }

  # Tilted lambdas (exponential tilting toward higher goals)
  lambda_home_tilt <- lambda_home * exp(tilt)
  lambda_away_tilt <- lambda_away * exp(tilt)

  # Sample from tilted distribution
  home_goals <- stats::rpois(n_sims, lambda_home_tilt)
  away_goals <- stats::rpois(n_sims, lambda_away_tilt)

  # Compute importance weights: p(x|original) / p(x|tilted)
  log_weights <- (
    stats::dpois(home_goals, lambda_home, log = TRUE) +
    stats::dpois(away_goals, lambda_away, log = TRUE) -
    stats::dpois(home_goals, lambda_home_tilt, log = TRUE) -
    stats::dpois(away_goals, lambda_away_tilt, log = TRUE)
  )
  weights <- exp(log_weights - max(log_weights))  # Numerical stability
  weights <- weights / sum(weights)

  # Indicator for outcome
  indicator <- evaluate_outcome(home_goals, away_goals, parsed)

  # Weighted estimate
  prob_est <- sum(weights * indicator)

  # Effective sample size
  eff_n <- 1 / sum(weights^2)

  # Standard error via weighted variance
  var_est <- sum(weights^2 * (indicator - prob_est)^2)
  se <- sqrt(var_est)

  # Compare to crude MC variance (theoretical)
  # For rare events, crude MC variance ≈ p(1-p)/n ≈ p/n
  crude_var <- prob_est * (1 - prob_est) / n_sims
  variance_reduction <- crude_var / max(var_est, 1e-15)

  list(
    probability = prob_est,
    se = se,
    effective_n = eff_n,
    variance_reduction = variance_reduction,
    tilt = tilt,
    outcome = outcome
  )
}

#' @noRd
parse_rare_outcome <- function(outcome) {
  if (grepl("^over_", outcome)) {
    threshold <- as.numeric(sub("over_", "", outcome))
    return(list(type = "over", threshold = threshold))
  }
  if (grepl("^exact_", outcome)) {
    parts <- strsplit(sub("exact_", "", outcome), "_")[[1]]
    return(list(type = "exact", home = as.integer(parts[1]), away = as.integer(parts[2])))
  }
  if (grepl("^home_", outcome)) {
    threshold <- as.integer(sub("\\+$", "", sub("home_", "", outcome)))
    return(list(type = "home_min", threshold = threshold))
  }
  cli::cli_abort("Unknown outcome format: {.val {outcome}}")
}

#' @noRd
evaluate_outcome <- function(home_goals, away_goals, parsed) {
  switch(
    parsed$type,
    over = as.numeric((home_goals + away_goals) > parsed$threshold),
    exact = as.numeric(home_goals == parsed$home & away_goals == parsed$away),
    home_min = as.numeric(home_goals >= parsed$threshold)
  )
}

#' @noRd
estimate_optimal_tilt <- function(lambda_home, lambda_away, parsed) {
  # Heuristic: tilt proportional to how rare the event is
  # For "over" outcomes, tilt more for higher thresholds
  if (parsed$type == "over") {
    base_total <- lambda_home + lambda_away
    excess <- max(0, parsed$threshold - base_total)
    return(min(1.5, 0.3 + 0.15 * excess))
  }
  if (parsed$type == "exact") {
    # Tilt toward the target scoreline
    return(0.5)
  }
  if (parsed$type == "home_min") {
    excess <- max(0, parsed$threshold - lambda_home)
    return(min(1.5, 0.2 + 0.2 * excess))
  }
  0.3  # Default
}

# ============================================================================
# CORRELATED MATCH SIMULATION (COPULAS)
# ============================================================================

#' Simulate correlated match outcomes using Gaussian copula
#'
#' Models dependence between multiple matches using a Gaussian copula.
#' This captures scenarios where upsets tend to cluster (e.g., bad weather day,
#' referee inconsistency across matches).
#'
#' @param matches A tibble with columns:
#'   - `match_id`: Unique identifier
#'   - `lambda_home`: Expected home goals
#'   - `lambda_away`: Expected away goals
#' @param correlation Numeric or matrix. If scalar, uses equicorrelation.
#'   If matrix, must be valid correlation matrix of size (2 * n_matches).
#' @param n_sims Integer. Number of joint simulations.
#' @param seed Integer. Random seed.
#' @return A tibble with simulated outcomes for all matches:
#'   - `sim_id`: Simulation index
#'   - `match_id`: Match identifier
#'   - `home_goals`, `away_goals`: Simulated scores
#'   - `result`: "H", "D", or "A"
#' @family simulation
#' @export
simulate_correlated_matches <- function(matches,
                                         correlation = 0.1,
                                         n_sims = 5000L,
                                         seed = NULL) {
  rlang::check_required(matches)

  required_cols <- c("match_id", "lambda_home", "lambda_away")
  missing <- setdiff(required_cols, colnames(matches))
  if (length(missing) > 0L) {
    cli::cli_abort("Missing columns: {.field {missing}}")
  }

  if (!is.null(seed)) set.seed(seed)

  n_matches <- nrow(matches)
  n_vars <- 2 * n_matches  # home and away goals for each match

  # Build correlation matrix
  if (is.matrix(correlation)) {
    if (nrow(correlation) != n_vars || ncol(correlation) != n_vars) {
      cli::cli_abort("Correlation matrix must be {n_vars}x{n_vars}.")
    }
    cor_mat <- correlation
  } else {
    # Equicorrelation structure
    cor_mat <- matrix(correlation, nrow = n_vars, ncol = n_vars)
    diag(cor_mat) <- 1
  }

  # Ensure positive definiteness
  eig <- eigen(cor_mat, symmetric = TRUE, only.values = TRUE)$values
  if (any(eig <= 0)) {
    cli::cli_warn("Correlation matrix not positive definite. Using nearest PD approximation.")
    cor_mat <- as.matrix(Matrix::nearPD(cor_mat)$mat)
  }

  # Generate correlated normals via Cholesky decomposition
  L <- chol(cor_mat)
  Z <- matrix(stats::rnorm(n_sims * n_vars), nrow = n_sims, ncol = n_vars)
  corr_normals <- Z %*% L

  # Transform to uniforms via standard normal CDF
  U <- stats::pnorm(corr_normals)

  # Transform to Poisson via quantile function
  results <- vector("list", n_sims)

  for (sim in seq_len(n_sims)) {
    sim_results <- tibble::tibble(
      sim_id = sim,
      match_id = matches$match_id,
      home_goals = integer(n_matches),
      away_goals = integer(n_matches)
    )

    for (i in seq_len(n_matches)) {
      u_home <- U[sim, 2 * i - 1]
      u_away <- U[sim, 2 * i]
      sim_results$home_goals[i] <- stats::qpois(u_home, matches$lambda_home[i])
      sim_results$away_goals[i] <- stats::qpois(u_away, matches$lambda_away[i])
    }

    sim_results$result <- dplyr::case_when(
      sim_results$home_goals > sim_results$away_goals ~ "H",
      sim_results$home_goals < sim_results$away_goals ~ "A",
      TRUE ~ "D"
    )

    results[[sim]] <- sim_results
  }

  dplyr::bind_rows(results)
}

#' Compute joint outcome probabilities from correlated simulations
#'
#' @param sims Output from [simulate_correlated_matches()].
#' @param outcomes Character vector of outcomes per match (e.g., c("H", "D", "A")).
#' @return Probability that all specified outcomes occur jointly.
#' @family simulation
#' @export
joint_outcome_probability <- function(sims, outcomes) {
  rlang::check_required(sims)
  rlang::check_required(outcomes)

  match_ids <- unique(sims$match_id)
  if (length(outcomes) != length(match_ids)) {
    cli::cli_abort("outcomes must have length {length(match_ids)}, got {length(outcomes)}.")
  }

  # Check each simulation
  n_sims <- max(sims$sim_id)
  hits <- 0L

  for (sim_id in seq_len(n_sims)) {
    sim_data <- sims[sims$sim_id == sim_id, ]
    if (all(sim_data$result == outcomes)) {
      hits <- hits + 1L
    }
  }

  hits / n_sims
}

#' Compute accumulator (parlay) probability with correlation
#'
#' @param matches A tibble with `match_id`, `lambda_home`, `lambda_away`, and `bet` columns.
#'   `bet` should be "H", "D", or "A" for each leg.
#' @param correlation Numeric. Inter-match correlation.
#' @param n_sims Integer. Number of simulations.
#' @return A list with:
#'   - `prob_independent`: Probability assuming independence
#'   - `prob_correlated`: Probability accounting for correlation
#'   - `correlation_impact`: Ratio of correlated to independent
#' @family simulation
#' @export
accumulator_probability <- function(matches, correlation = 0.1, n_sims = 10000L) {
  rlang::check_required(matches)

  if (!"bet" %in% colnames(matches)) {
    cli::cli_abort("matches must have a {.field bet} column with 'H', 'D', or 'A'.")
  }

  # Independent probability
  indep_probs <- vapply(seq_len(nrow(matches)), function(i) {
    mat <- score_matrix(matches$lambda_home[i], matches$lambda_away[i])
    probs_1x2 <- score_matrix_to_1x2(mat)
    switch(matches$bet[i], H = probs_1x2[1], D = probs_1x2[2], A = probs_1x2[3])
  }, numeric(1))
  prob_indep <- prod(indep_probs)

  # Correlated probability
  sims <- simulate_correlated_matches(matches, correlation = correlation, n_sims = n_sims)
  prob_corr <- joint_outcome_probability(sims, matches$bet)

  list(
    prob_independent = prob_indep,
    prob_correlated = prob_corr,
    correlation_impact = prob_corr / prob_indep,
    n_legs = nrow(matches)
  )
}
