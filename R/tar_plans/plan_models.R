# plan_models.R
# Model training: GLM baseline + Dixon-Coles with walk-forward evaluation

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

  # Dixon-Coles: walk-forward cross-validation (per-league, then combine)
  # Dixon-Coles requires teams to have played each other, so we must run

  # per-league (teams from EPL never play La Liga teams in domestic data)
  targets::tar_target(
    dc_cv,
    {
      leagues <- unique(parsed_matches$league_code)
      results <- purrr::map(leagues, function(lg) {
        lg_df <- parsed_matches[parsed_matches$league_code == lg, ]
        if (nrow(lg_df) < 200L) return(NULL)
        tryCatch({
          res <- evaluate_dc(
            matches_df = lg_df,
            train_months = 24L,
            test_months = 1L,
            xi = 0.003
          )
          if (nrow(res) > 0L) res$league_code <- lg
          res
        }, error = function(e) NULL)
      })
      dplyr::bind_rows(results)
    }
  ),

  # Pinnacle implied probabilities as benchmark
  targets::tar_target(
    pinnacle_benchmark,
    pinnacle_implied(parsed_odds)
  )
)
