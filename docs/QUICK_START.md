# Football Project - Quick Start

## Nested Nix-Shell Issue - Quick Fixes

You’re currently in a nix-shell from a different project. Here are your
options:

### Option 1: Quick workaround (use immediately)

``` r
source("R/setup_nix_libs.R")
library(goalmodel)
library(targets)
tar_make()
```

### Option 2: Use wrapper script

``` r
source("run_targets.R")
```

### Option 3: Exit and restart (proper fix)

``` bash
exit
cd /Users/johngavin/docs_gh/proj/stats/sport/football
nix-shell default.nix
```

## What happened?

- You’re in an impure nix-shell from roxy.shinylive project
- Football project packages exist in /nix/store but aren’t in
  .libPaths()
- Nested nix-shell causes segfaults

## Files

- `R/setup_nix_libs.R` - Adds project packages to library paths
- `run_targets.R` - Wrapper for tar_make() with auto-setup
- `NIX_SHELL_WORKAROUND.md` - Full documentation
- `.Rprofile` - Auto-detects conflicts on startup

## Verification

``` r
# Check if in wrong shell
Sys.getenv("IN_NIX_SHELL")        # "impure"
.libPaths()                        # Should show roxy.shinylive paths
requireNamespace("goalmodel")      # FALSE before fix, TRUE after
```
