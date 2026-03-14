# package.nix - Build footbet as an installable R package derivation
#
# Used by push_to_cachix.sh to build and push to johngavin cachix.
# Uses same nixpkgs pin as default.nix (2026-03-11).
#
# Usage:
#   nix-build package.nix --no-out-link
#   # Push ONLY this package (not deps!) - pipe single path:
#   nix-build package.nix --no-out-link | cachix push johngavin

let
  pkgs = import (fetchTarball "https://github.com/rstats-on-nix/nixpkgs/archive/2026-03-11.tar.gz") {};

  footbet = pkgs.rPackages.buildRPackage {
    name = "footbet";
    src = ./.;

    # Imports from DESCRIPTION
    propagatedBuildInputs = with pkgs.rPackages; [
      cli
      DBI
      dplyr
      duckdb
      glue
      here
      httr2
      lubridate
      Matrix
      plotly
      purrr
      readr
      rlang
      tibble
      tidyr
    ];
  };

in footbet
