# Nix Shell Nested Environment Workaround

## Problem

The football project has a nested nix-shell conflict:
- Current session is in an **impure nix-shell** from a different project (roxy.shinylive)
- Running `nix-shell default.nix` from within this shell causes segfaults
- Project packages like `goalmodel` are in the nix store but not in `.libPaths()`
- Running a new nix-shell requires building 71 derivations (time-consuming)

## Diagnosis

```r
# Check current environment
Sys.getenv("IN_NIX_SHELL")  # Shows "impure" but from wrong project
.libPaths()                  # Shows roxy.shinylive paths, not football

# Verify goalmodel exists in nix store
file.exists("/nix/store/4w0kf8f1si2ln308lf45jl47cykbw8d7-r-goalmodel")  # TRUE
```

## Solution 1: Use setup_nix_libs.R (Immediate workaround)

Source the helper script to add project packages to your session:

```r
source("R/setup_nix_libs.R")
library(goalmodel)
library(targets)
tar_make()
```

This prepends football project's nix package paths to `.libPaths()` without spawning a nested shell.

## Solution 2: Use run_targets.R wrapper

```bash
Rscript run_targets.R
```

Or from R:
```r
source("run_targets.R")
```

## Solution 3: Exit and re-enter correct nix-shell (Proper fix)

```bash
# Exit current (wrong) nix-shell
exit

# Re-enter football project's nix-shell
cd /Users/johngavin/docs_gh/proj/stats/sport/football
nix-shell default.nix

# OR use the rix setup script
caffeinate -i ~/docs_gh/rix.setup/default.sh
```

Then verify:
```r
Sys.getenv("IN_NIX_SHELL")  # Should be "impure"
.libPaths()                  # Should show football project paths
library(goalmodel)           # Should load without setup
```

## Solution 4: Use nix run (Advanced)

For one-off commands without entering a shell:

```bash
nix-shell /Users/johngavin/docs_gh/proj/stats/sport/football/default.nix \
  --run "R -e 'targets::tar_make()'"
```

Note: This requires building the full environment first time.

## Why This Happened

1. Started session in a different nix-shell (likely via `~/docs_gh/rix.setup/default.sh`)
2. That shell's R package paths took precedence
3. Attempting to spawn nested nix-shell causes segfaults
4. The goalmodel package was built and exists, but isn't in current `.libPaths()`

## Prevention

- Always verify `IN_NIX_SHELL` and `.libPaths()` at session start
- Use project-specific nix-shell for each project
- Exit and re-enter rather than nesting shells
- Consider using `nix develop` (flakes) for better shell management

## Files Created

- `R/setup_nix_libs.R` - Helper to add nix package paths
- `run_targets.R` - Wrapper script for tar_make()
- `NIX_SHELL_WORKAROUND.md` - This documentation
