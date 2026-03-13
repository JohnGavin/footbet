#!/usr/bin/env Rscript
#' Run targets pipeline with proper nix package paths
#' 
#' This script works around nested nix-shell conflicts by:
#' 1. Adding football project's nix packages to .libPaths()
#' 2. Running tar_make() with all dependencies available
#' 
#' Usage:
#'   Rscript run_targets.R
#'   # OR from R:
#'   source("run_targets.R")

# Setup nix library paths
source("R/setup_nix_libs.R")

# Load targets
library(targets)

# Run the pipeline
tar_make()
