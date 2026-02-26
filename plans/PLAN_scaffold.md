# PLAN: Package Scaffold (PR #1)

## Goal
Create the footbet R package scaffold with all source files, tests,
targets pipeline stubs, and Nix environment.

## Scope
- DESCRIPTION with all planned dependencies
- R source files: utils, data_download, data_parse, data_transfers,
  database, devig, features, models_baseline, models_dc, models_eval, kelly
- Test files: unit tests + adversarial QA for all exported functions
- Targets pipeline: _targets.R orchestrator + 7 plan stubs
- Nix: default.R, default.sh
- README.qmd

## Out of Scope
- Actual data downloading (PR #2)
- Actual model fitting (PR #6-7)
- GitHub Actions CI setup
- Cachix push (no package.nix yet)

## Acceptance Criteria
- [ ] devtools::document() — no errors
- [ ] devtools::test() — 0 failures
- [ ] devtools::check(--as-cran) — 0 errors, 0 warnings
- [ ] Adversarial QA — >= 95% pass rate on exported functions
- [ ] Quality gate >= Silver (90)
