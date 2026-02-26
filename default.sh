#!/usr/bin/env bash
# Project-specific Nix environment for footbet

PROJECT_PATH=$(pwd)
NIX_FILE="default.nix"
GC_ROOT="nix-shell-root"
NEED_REGEN=false

# Check if default.nix exists
if [ ! -f "$NIX_FILE" ]; then
    echo "Generating default.nix from DESCRIPTION..."
    NEED_REGEN=true
elif [ "$PROJECT_PATH/DESCRIPTION" -nt "$NIX_FILE" ]; then
    echo "DESCRIPTION has been modified since default.nix was generated."
    NEED_REGEN=true
fi

if [ "$NEED_REGEN" = true ]; then
    nix-shell \
      --expr "let pkgs = import <nixpkgs> {}; in pkgs.mkShell { buildInputs = [ pkgs.R pkgs.rPackages.rix pkgs.rPackages.cli pkgs.rPackages.curl pkgs.curlMinimal pkgs.cacert ]; }" \
      --command "Rscript --vanilla default.R"
fi

# Create GC root if missing
if [ ! -L "$GC_ROOT" ]; then
    echo "Creating GC root at $GC_ROOT..."
    nix-instantiate . --indirect --add-root $GC_ROOT > /dev/null
fi

# Enter shell if run interactively, otherwise just ensure environment is ready
if [ -t 0 ] && [ -z "$IN_NIX_SHELL" ]; then
    nix-shell
else
    echo "Nix environment ready."
fi
