library(targets)

# Set global options
# Note: footbet functions are sourced directly below, no need to list in packages
tar_option_set(
  packages = c("dplyr", "tibble", "arrow", "DBI", "duckdb", "ggplot2", "httr2", "lubridate", "glue", "here", "rlang", "cli", "tidyr"),
  controller = if (requireNamespace("crew", quietly = TRUE)) {
    crew::crew_controller_local(
      workers = min(4L, parallel::detectCores() - 1L),
      seconds_idle = 120,
      seconds_wall = 3600
    )
  }
)

# Source package functions (exclude dev/ and tar_plans/)
r_files <- list.files("R", pattern = "\\.R$", full.names = TRUE)
r_files <- r_files[!grepl("R/(dev|tar_plans)/", r_files)]
for (file in r_files) source(file)

# Source and combine plans
plan_files <- list.files(
  "R/tar_plans",
  pattern = "^plan_.*\\.R$",
  full.names = TRUE
)
for (plan_file in plan_files) source(plan_file)

# Combine all plans
c(
  plan_data_acquisition,
  plan_data_validation,
  plan_quality_control,
  plan_features,
  plan_xg_features,
  plan_models,
  plan_models_brms,
  plan_evaluation,
  plan_decisions,
  plan_transfers,
  plan_doc_examples,
  plan_oos,
  plan_clv,
  plan_cutoff,
  plan_oagd,
  plan_xgk,
  plan_ranger_1x2,
  plan_xgboost_1x2,
  plan_brms_1x2,
  plan_qa_gates,
  plan_vignette_outputs,
  plan_pkgdown(),      # pkgdown site build + stage docs/
  plan_pkgctx()        # ctx.yaml cache audit + refresh
)
