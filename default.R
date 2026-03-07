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
  date = "2025-12-15"
)

# Post-process: engsoccerdata is marked broken in nixpkgs but is in
# goalmodel's Imports. Override the broken mark and use list concatenation
# for goalmodel's propagatedBuildInputs.
nix_text <- paste(readLines("default.nix"), collapse = "\n")
nix_text <- sub(
  "    goalmodel = \\(pkgs\\.rPackages\\.buildRPackage \\{\n      name = \"goalmodel\";\n      src = pkgs\\.fetchgit \\{\n        url = \"https://github\\.com/opisthokonta/goalmodel\";\n        rev = \"[^\"]+\";\n        sha256 = \"[^\"]+\";\n      \\};\n      propagatedBuildInputs = builtins\\.attrValues \\{\n        inherit \\(pkgs\\.rPackages\\) \n          MASS\n          engsoccerdata\n          dplyr\n          Rcpp;\n      \\};",
  "    # engsoccerdata is marked broken in nixpkgs but goalmodel Imports it
    engsoccerdata = pkgs.rPackages.engsoccerdata.overrideAttrs (_: {
      meta = { broken = false; };
    });

    goalmodel = (pkgs.rPackages.buildRPackage {
      name = \"goalmodel\";
      src = pkgs.fetchgit {
        url = \"https://github.com/opisthokonta/goalmodel\";
        rev = \"84ecd6c2bbad3ccb967abf88ef49e5bcd074e545\";
        sha256 = \"sha256-InAgUuPsVME4hdyGS2pQsMXFkzlPKlILNP7N6ESnjy8=\";
      };
      propagatedBuildInputs = [
        engsoccerdata
      ] ++ builtins.attrValues {
        inherit (pkgs.rPackages)
          MASS
          dplyr
          Rcpp;
      };",
  nix_text
)
writeLines(nix_text, "default.nix")
message("Post-processed: engsoccerdata broken override applied")
