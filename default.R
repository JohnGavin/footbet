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

# Generate default.nix WITHOUT git_pkgs to avoid curl segfault
# goalmodel will be added via post-processing with pre-computed hash
rix(
  r_pkgs = r_pkgs,
  system_pkgs = c("qpdf"),
  git_pkgs = NULL,
  ide = "none",

  project_path = ".",
  overwrite = TRUE,
  print = TRUE,
  date = "2026-03-02"
)

# Post-process: add goalmodel with pre-computed hash and fix engsoccerdata
nix_text <- paste(readLines("default.nix"), collapse = "\n")

# Add goalmodel and engsoccerdata override before rpkgs
goalmodel_block <- '
    # engsoccerdata is marked broken in nixpkgs but goalmodel Imports it
    engsoccerdata = pkgs.rPackages.engsoccerdata.overrideAttrs (_: {
      meta = { broken = false; };
    });

    goalmodel = (pkgs.rPackages.buildRPackage {
      name = "goalmodel";
      src = pkgs.fetchgit {
        url = "https://github.com/opisthokonta/goalmodel";
        rev = "84ecd6c2bbad3ccb967abf88ef49e5bcd074e545";
        sha256 = "sha256-InAgUuPsVME4hdyGS2pQsMXFkzlPKlILNP7N6ESnjy8=";
      };
      propagatedBuildInputs = [
        engsoccerdata
      ] ++ builtins.attrValues {
        inherit (pkgs.rPackages)
          MASS
          dplyr
          Rcpp;
      };
    });
'

# Insert goalmodel block after "rpkgs = builtins.attrValues {"
nix_text <- sub(
  "(rpkgs = builtins\\.attrValues \\{)",
  paste0(goalmodel_block, "\n    \\1"),
  nix_text
)

# Add goalmodel to buildInputs
nix_text <- sub(
  "(buildInputs = \\[ rpkgs )",
  "\\1goalmodel ",
  nix_text
)

writeLines(nix_text, "default.nix")
message("Post-processed: goalmodel and engsoccerdata override applied")
