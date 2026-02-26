library(rix)

# Read DESCRIPTION to get package dependencies
desc_raw <- read.dcf("DESCRIPTION")
parse_field <- function(field) {
  if (!field %in% colnames(desc_raw)) return(character())
  pkgs <- strsplit(desc_raw[, field], ",\\s*|\n\\s*")[[1]]
  gsub("\\s*\\([^)]+\\)", "", trimws(pkgs)) |>
    (\(x) x[nzchar(x) & !is.na(x)])()
}

# Extract dependencies from Imports and Suggests
desc_deps <- unique(c(parse_field("Imports"), parse_field("Suggests")))

# Packages not available in rstats-on-nix nixpkgs — install from GitHub
git_only <- c("goalmodel")
desc_deps <- setdiff(desc_deps, git_only)

# Add development tools not in DESCRIPTION
dev_extras <- c(
  "usethis", "gert", "gh",
  "pkgdown", "styler", "devtools", "languageserver",
  "pkgload"
)

# Combine all packages
r_pkgs <- unique(c(desc_deps, dev_extras)) |> sort()

# GitHub packages not in rstats-on-nix nixpkgs
git_pkgs <- list(
  list(
    package_name = "goalmodel",
    repo_url = "https://github.com/opisthokonta/goalmodel",
    commit = "84ecd6c2bbad3ccb967abf88ef49e5bcd074e545"
  )
)

# Generate default.nix
rix(
  r_pkgs = r_pkgs,
  system_pkgs = c("qpdf"),
  git_pkgs = git_pkgs,
  ide = "none",
  project_path = ".",
  overwrite = TRUE,
  print = TRUE,
  date = "2026-01-05"
)
