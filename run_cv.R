#!/usr/bin/env Rscript
# Run GLM baseline CV and save results
cat("Starting run_cv.R at:", format(Sys.time()), "\n")

library(targets)
library(dplyr, warn.conflicts = FALSE)
library(tibble)
library(rlang)
library(cli)

source("R/models_baseline.R")
source("R/models_eval.R")
cat("Libraries and functions loaded\n")

matches_long <- tar_read(matches_long)
parsed_matches <- tar_read(parsed_matches)
cat("Data loaded:", nrow(matches_long), "/", nrow(parsed_matches), "rows\n")

# Run CV with progress
dates <- sort(unique(parsed_matches$match_date))
splits <- walk_forward_splits(dates, 24L, 1L)
cat("Processing", length(splits), "folds...\n")

results <- vector("list", length(splits))

for (k in seq_along(splits)) {
  if (k %% 10 == 0) cat("Fold", k, "/", length(splits), "\n")

  sp <- splits[[k]]
  train_long <- matches_long[matches_long$match_date >= sp$train_start &
                              matches_long$match_date < sp$test_start, ]
  test_matches <- parsed_matches[parsed_matches$match_date >= sp$test_start &
                                   parsed_matches$match_date < sp$test_end, ]

  if (nrow(train_long) < 20L || nrow(test_matches) == 0L) next

  model <- tryCatch(fit_poisson_glm(train_long), error = function(e) NULL)
  if (is.null(model)) next

  preds <- predict_matches_glm(model, test_matches)

  eval_df <- dplyr::inner_join(preds, test_matches[, c("match_id", "ftr")],
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
    n_train = nrow(train_long),
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

result <- dplyr::bind_rows(results)
cat("CV completed:", nrow(result), "folds with results\n")

saveRDS(result, "_targets/objects/glm_baseline_cv")
cat("Saved to _targets/objects/glm_baseline_cv\n")
cat("Done at:", format(Sys.time()), "\n")
