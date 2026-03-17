#' Setup Nix Library Paths for Football Project
#'
#' Workaround for nested nix-shell conflicts. Reads Imports and Suggests
#' from DESCRIPTION (single source of truth) and adds matching nix store
#' paths to `.libPaths()`.
#'
#' @keywords internal
#' @export
setup_nix_libs <- function() {
  # Read package names from DESCRIPTION (single source of truth)
  desc_path <- here::here("DESCRIPTION")
  if (!file.exists(desc_path)) {
    warning("DESCRIPTION not found at ", desc_path)
    return(invisible(.libPaths()))
  }

  desc <- read.dcf(desc_path)
  parse_field <- function(field) {
    if (!field %in% colnames(desc)) return(character())
    pkgs <- strsplit(desc[, field], ",\\s*|\n\\s*")[[1]]
    gsub("\\s*\\([^)]+\\)", "", trimws(pkgs)) |>
      (\(x) x[nzchar(x) & !is.na(x)])()
  }

  project_pkgs <- unique(c(parse_field("Imports"), parse_field("Suggests")))

  # Search nix store for each package
  nix_paths <- character()
  for (pkg in project_pkgs) {
    search_pattern <- paste0("*-r-", pkg, "-*")
    cmd <- paste0("ls -d /nix/store/", search_pattern, " 2>/dev/null | head -1")
    path <- system(cmd, intern = TRUE, ignore.stderr = TRUE)
    if (length(path) > 0 && nzchar(path)) {
      lib_path <- file.path(path, "library")
      if (dir.exists(lib_path)) {
        nix_paths <- c(nix_paths, lib_path)
      }
    }
  }

  nix_paths <- unique(nix_paths[dir.exists(nix_paths)])

  if (length(nix_paths) > 0) {
    .libPaths(c(nix_paths, .libPaths()))
    message("\nAdded ", length(nix_paths), " nix package paths to .libPaths()")

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

# Auto-run if sourced directly (NOT in R CMD check subprocesses)
if (Sys.getenv("AUTO_SETUP_NIX_LIBS") == "1" ||
    (!interactive() && !nzchar(Sys.getenv("_R_CHECK_PACKAGE_NAME_")))) {
  setup_nix_libs()
}
