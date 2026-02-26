# fix_scaffold.R — PR #1: Package Scaffold
# Issue: https://github.com/JohnGavin/footbet/issues/1
# Branch: feat/scaffold-1
#
# What was done:
# - Created DESCRIPTION with Imports (10 pkgs) and Suggests (25 pkgs)
# - Created 11 R source files across 7 families:
#   - data-acquisition: data_download.R, data_parse.R, data_transfers.R
#   - storage: database.R
#   - devig: devig.R (basic, power, Shin methods)
#   - features: features.R (rolling goals, long format conversion)
#   - models: models_baseline.R (GLM, score matrix), models_dc.R (Dixon-Coles)
#   - evaluation: models_eval.R (log-loss, Brier, RPS, walk-forward)
#   - decisions: kelly.R (Kelly criterion, value bet ID, guardrails)
#   - utilities: utils.R (URL builder, leagues, seasons, match ID)
# - Created 7 targets plan stubs in R/tar_plans/
# - Created _targets.R orchestrator
# - Created 12 test files (7 unit + 5 adversarial QA)
# - Created Nix environment (default.R, default.sh)
# - Created README.qmd
#
# Adversarial QA findings (fixed in this PR):
# - devig functions lacked NULL/Inf/empty vector validation → added validate_odds()
# - Shin formula had incorrect root-finding equation → fixed per Shin (1993)
# - devig_power crashed on single odds → added early return
# - kelly_fraction boundary probs (0, 1) → identify_value_bet clamps
# - apply_guardrails NaN on zero peak_bankroll → NA guard added
# - score_matrix Poisson truncation → normalised after outer product
# - walk_forward_splits used lubridate::months (not exported) → period()
# - connect_db accepted empty string → added nzchar check
# - fd_url accepted NULL/NA/numeric → added rlang::is_string checks
# - target_seasons crashed on reversed range → early return
#
# Quality Gate: 93/100 (Silver)
# - 0 errors, 0 warnings in R CMD check
# - 321 tests pass, 0 failures
# - 5 adversarial test files covering all exported functions
