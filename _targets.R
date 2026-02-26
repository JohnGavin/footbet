library(targets)

# Set global options
tar_option_set(
  packages = c("footbet", "dplyr", "tibble", "arrow", "DBI", "duckdb")
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
  plan_quality_control,
  plan_features,
  plan_models,
  plan_evaluation,
  plan_decisions,
  plan_doc_examples
)
