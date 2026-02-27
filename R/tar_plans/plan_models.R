# plan_models.R
# Model training: GLM baseline with walk-forward evaluation

plan_models <- list(

  # Walk-forward time splits using match dates
  targets::tar_target(
    wf_splits,
    walk_forward_splits(
      dates = sort(unique(parsed_matches$match_date)),
      train_months = 24L,
      test_months = 1L
    )
  ),

  # GLM Poisson baseline: walk-forward cross-validation
  targets::tar_target(
    glm_baseline_cv,
    evaluate_glm_baseline(
      long_df = matches_long,
      matches_df = parsed_matches,
      train_months = 24L,
      test_months = 1L
    )
  ),

  # Pinnacle implied probabilities as benchmark
  targets::tar_target(
    pinnacle_benchmark,
    pinnacle_implied(parsed_odds)
  )
)
