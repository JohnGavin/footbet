#!/usr/bin/env bash
#
# push_to_cachix.sh - Push ONLY this project's R package to johngavin cachix
#
# CRITICAL: Only the single project derivation is pushed. Standard R packages
# (dplyr, arrow, duckdb, etc.) are ALREADY on rstats-on-nix and must NEVER
# be pushed to johngavin.
#
# Step 5 of 9-step workflow. Builds from package.nix, pushes ONE derivation.
#
# Usage:
#   ./push_to_cachix.sh
#
# Exit codes:
#   0 - Success
#   1 - General error
#   2 - Validation failed (missing files, not authenticated)
#   3 - Build failed (nix-build error)
#   4 - Push failed (cachix push error)
#   5 - Pin failed (cachix pin error)

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

trap 'handle_error $? $LINENO' ERR

handle_error() {
  local exit_code=$1
  local line_number=$2
  echo -e "${RED}ERROR: Script failed at line ${line_number} with exit code ${exit_code}${NC}"
  exit $exit_code
}

log_step() { echo -e "${BLUE}$1${NC}"; }
log_success() { echo -e "${GREEN}$1${NC}"; }
log_error() { echo -e "${RED}ERROR: $1${NC}"; }
log_warning() { echo -e "${YELLOW}WARNING: $1${NC}"; }
log_info() { echo -e "${NC}$1${NC}"; }

retry_command() {
  local max_attempts="${1:-3}"
  local timeout="${2:-5}"
  local command="${@:3}"
  local attempt=1

  while [ $attempt -le $max_attempts ]; do
    if eval "$command"; then
      return 0
    else
      if [ $attempt -lt $max_attempts ]; then
        local wait_time=$((timeout * attempt))
        log_warning "Attempt $attempt/$max_attempts failed. Retrying in ${wait_time}s..."
        sleep $wait_time
        ((attempt++))
      else
        log_error "All $max_attempts attempts failed"
        return 1
      fi
    fi
  done
}

main() {
  echo "==========================================================="
  echo "   Push footbet to johngavin cachix"
  echo "==========================================================="
  echo ""

  # STEP 1: Validate environment
  log_step "Step 1/4: Validating environment..."

  if [ ! -f "DESCRIPTION" ]; then
    log_error "DESCRIPTION not found. Run from footbet package root."
    exit 2
  fi

  if [ ! -f "package.nix" ]; then
    log_error "package.nix not found. Create it first."
    exit 2
  fi

  if ! command -v nix-build &> /dev/null; then
    log_error "nix-build not found. Install Nix first."
    exit 2
  fi

  if ! command -v cachix &> /dev/null; then
    log_error "cachix not found."
    log_info "Install: nix-env -iA cachix -f https://cachix.org/api/v1/install"
    exit 2
  fi

  log_success "Environment validated"
  echo ""

  # STEP 2: Get package info
  log_step "Step 2/4: Reading package information..."

  PKG_NAME=$(grep "^Package:" DESCRIPTION | awk '{print $2}' | tr -d '\r' || echo "")
  PKG_VERSION=$(grep "^Version:" DESCRIPTION | awk '{print $2}' | tr -d '\r' || echo "")

  if [ -z "$PKG_NAME" ] || [ -z "$PKG_VERSION" ]; then
    log_error "Could not read package name/version from DESCRIPTION"
    exit 2
  fi

  log_success "Package: $PKG_NAME v$PKG_VERSION"
  echo ""

  # STEP 3: Build package
  log_step "Step 3/4: Building package with nix-build..."
  log_info "This may take a few minutes on first build..."

  RESULT=$(nix-build package.nix --no-out-link 2>&1 | tail -1)

  if [ -z "$RESULT" ] || { [ ! -d "$RESULT" ] && [ ! -L "$RESULT" ]; }; then
    log_error "nix-build failed"
    log_info "Check syntax: nix-instantiate --parse package.nix"
    exit 3
  fi

  log_success "Built: $RESULT"
  echo ""

  # STEP 4: Pre-check then push ONLY this package
  log_step "Step 4/4: Pushing ONLY $PKG_NAME to johngavin cachix..."

  # CRITICAL: Check johngavin specifically (not rstats-on-nix or cache.nixos.org)
  # because cachix push uploads anything NOT in the TARGET cache, regardless of
  # whether it exists elsewhere. This prevents accidental dep uploads.
  log_info "Pre-check: verifying ALL closure paths are in johngavin..."

  # Get the package store path hash for filtering
  PKG_HASH=$(basename "$RESULT" | cut -c1-32)

  MISSING_IN_JG=0
  MISSING_LIST=""
  for path in $(nix-store -qR "$RESULT"); do
    HASH=$(basename "$path" | cut -c1-32)
    # Skip our own package - it's what we're pushing
    if [ "$HASH" = "$PKG_HASH" ]; then
      continue
    fi
    JG_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
      --max-time 5 "https://johngavin.cachix.org/${HASH}.narinfo" 2>/dev/null || echo "000")
    if [ "$JG_CODE" != "200" ]; then
      MISSING_IN_JG=$((MISSING_IN_JG + 1))
      MISSING_LIST="${MISSING_LIST}  ${path}\n"
    fi
  done

  TOTAL_CLOSURE=$(nix-store -qR "$RESULT" | wc -l | tr -d ' ')

  if [ "$MISSING_IN_JG" -gt 0 ]; then
    log_error "ABORT: $MISSING_IN_JG of $TOTAL_CLOSURE closure paths are NOT in johngavin cache."
    log_error "cachix push would upload these (quota waste, forbidden)."
    echo ""
    log_info "Missing paths (first 10):"
    echo -e "$MISSING_LIST" | head -10
    echo ""
    log_info "These deps should come from rstats-on-nix or cache.nixos.org."
    log_info "To seed johngavin ONE TIME (if absolutely needed):"
    log_info "  nix-store -qR '$RESULT' | cachix push johngavin"
    log_info ""
    log_info "Or update package.nix to use a nixpkgs pin where all deps are pre-built."
    exit 4
  fi

  log_success "All $((TOTAL_CLOSURE - 1)) dependency paths already in johngavin"
  log_info "Pushing package (only $PKG_NAME will be uploaded)..."

  PUSH_LOG="/tmp/cachix-push-${PKG_NAME}.log"

  if ! retry_command 3 5 "echo '$RESULT' | cachix push johngavin > '$PUSH_LOG' 2>&1"; then
    log_error "Failed to push to cachix after 3 attempts"
    log_info "Push log: $PUSH_LOG"
    exit 4
  fi

  PUSHED_COUNT=$(grep -c "^Pushing /nix/store/" "$PUSH_LOG" 2>/dev/null || echo 0)

  if [ "$PUSHED_COUNT" -gt 1 ]; then
    log_error "UNEXPECTED: Pushed $PUSHED_COUNT paths but pre-check passed!"
    log_error "This indicates a race condition or cache eviction."
    grep "^Pushing /nix/store/" "$PUSH_LOG"
    exit 4
  elif [ "$PUSHED_COUNT" -eq 1 ]; then
    log_success "Pushed exactly 1 path (correct)"
  else
    log_info "Package already in cache (0 new paths pushed)"
  fi

  rm -f "$PUSH_LOG"
  echo ""

  # Pin if release version
  if [[ "$PKG_VERSION" == *.9000 ]]; then
    log_warning "Development version detected (.9000 suffix)"
    log_info "Skipping pin - dev versions subject to garbage collection"
  else
    PIN_NAME="${PKG_NAME}-v${PKG_VERSION}"
    log_info "Release version - pinning forever"
    if ! retry_command 3 5 "cachix pin johngavin '$PIN_NAME' '$RESULT' --keep-forever"; then
      log_error "Failed to pin package"
      log_info "Manually pin: cachix pin johngavin $PIN_NAME $RESULT --keep-forever"
      exit 5
    fi
    log_success "Pinned as $PIN_NAME"
  fi

  echo ""
  echo "==========================================================="
  log_success "SUCCESS! $PKG_NAME pushed to cachix"
  echo "==========================================================="
  echo ""
  echo "   $PKG_NAME v$PKG_VERSION ONLY"
  echo "   Dependencies NOT pushed (they are on rstats-on-nix)"
  echo ""
}

main "$@"
