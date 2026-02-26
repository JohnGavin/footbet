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

# Add development tools not in DESCRIPTION
dev_extras <- c(
  "usethis", "gert", "gh",
  "pkgdown", "styler", "devtools", "languageserver",
  "pkgload"
)

# Combine all packages
r_pkgs <- unique(c(desc_deps, dev_extras)) |> sort()

# Generate default.nix
rix(
  r_pkgs = r_pkgs,
  system_pkgs = c("qpdf"),
  git_pkgs = NULL,
  ide = "none",
  project_path = ".",
  overwrite = TRUE,
  print = TRUE,
  date = "2026-01-05"
)
