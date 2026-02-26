# plan_models.R
# Model training: GLM baseline, Dixon-Coles, Elo

plan_models <- list(

  # TODO (PR #6-7): Add targets for:
  # - walk-forward train/test split
  # - fit_poisson_glm on each training fold
  # - fit_dixon_coles on each training fold
  # - Elo-based predictions
  # - pin models with vetiver

  targets::tar_target(
    models_placeholder,
    "Model targets will be added in PR #6-7"
  )
)
