# plan_features.R
# Feature engineering: rolling averages, Elo, devigged odds

plan_features <- list(

  # TODO (PR #5): Add targets for:
  # - rolling_goals(window = 5)
  # - rolling_goals(window = 10)
  # - rolling_goals(window = 38)
  # - Elo ratings per league
  # - devigged Pinnacle implied probs
  # - transfer net spend features
  # - combined feature matrix

  targets::tar_target(
    features_placeholder,
    "Feature targets will be added in PR #5"
  )
)
