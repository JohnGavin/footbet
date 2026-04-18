# Setup Nix Library Paths for Football Project

Workaround for nested nix-shell conflicts. Reads Imports and Suggests
from DESCRIPTION (single source of truth) and adds matching nix store
paths to [`.libPaths()`](https://rdrr.io/r/base/libPaths.html).

## Usage

``` r
setup_nix_libs()
```
