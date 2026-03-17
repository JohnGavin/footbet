#' Setup Nix Library Paths for Football Project
#'
#' Workaround for nested nix-shell conflicts. Adds football project's
#' nix packages to .libPaths() without spawning nested shell.
#'
#' @keywords internal
#' @export
setup_nix_libs <- function() {
  # Direct paths for known project-specific packages
  # These were built by default.nix but aren't in current shell
  known_paths <- c(
    "/nix/store/4w0kf8f1si2ln308lf45jl47cykbw8d7-r-goalmodel/library"
  )
  
  # Additional packages to search for dynamically
  project_pkgs <- c(
    "brms",
    "crew",
    "engsoccerdata",
    "mockery",
    "targets",
    "tarchetypes",
    "understatr",
    "worldfootballR",
    "xgboost"
  )
  
  nix_paths <- known_paths
  
  # Find additional package paths in nix store
  for (pkg in project_pkgs) {
    search_pattern <- paste0("*-r-", pkg, "-*")
    cmd <- paste0("ls -d /nix/store/", search_pattern, " 2>/dev/null | head -1")
    path <- system(cmd, intern = TRUE, ignore.stderr = TRUE)
    if (length(path) > 0 && nzchar(path)) {
      lib_path <- file.path(path, "library")
      if (dir.exists(lib_path)) {
        nix_paths <- c(nix_paths, lib_path)
        message("Found ", pkg, ": ", basename(path))
      }
    }
  }
  
  # Filter to existing paths
  nix_paths <- nix_paths[dir.exists(nix_paths)]
  
  if (length(nix_paths) > 0) {
    # Prepend to .libPaths()
    .libPaths(c(nix_paths, .libPaths()))
    message("\nAdded ", length(nix_paths), " nix package paths to .libPaths()")
    
    # Verify goalmodel
    has_goalmodel <- requireNamespace("goalmodel", quietly = TRUE)
    message("goalmodel available: ", has_goalmodel)
    
    if (has_goalmodel) {
      message("Success! You can now use library(goalmodel) and run tar_make()")
    }
  } else {
    warning("No project packages found in /nix/store")
  }
  
  invisible(.libPaths())
}

# Auto-run if sourced directly
if (!interactive() || Sys.getenv("AUTO_SETUP_NIX_LIBS") == "1") {
  setup_nix_libs()
}
