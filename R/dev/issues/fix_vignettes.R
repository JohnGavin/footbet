# fix_vignettes.R
# Issue: #16 — Add 4 vignettes: data sources, cleaning, EDA, model fitting
# Branch: feat/vignettes-16
# Date: 2026-03-02
#
# Summary:
# Created 4 Rmd vignettes following zero-computation rule (tar_read only).
# All plots/tables pre-computed as targets in plan_vignette_outputs.R.
#
# Files created:
#   R/tar_plans/plan_vignette_outputs.R  — 22 vig_* targets
#   vignettes/data-sources.Rmd           — Raw data & coverage
#   vignettes/data-cleaning.Rmd          — QC heatmaps & anomalies
#   vignettes/eda.Rmd                    — EDA: goals, home adv, odds
#   vignettes/model-fitting.Rmd          — Models, CV, P&L
#   plans/PLAN_vignettes.md              — Plan document
#
# Files modified:
#   DESCRIPTION                          — VignetteBuilder: knitr
#   _targets.R                           — Added plan_vignette_outputs
#   _pkgdown.yml                         — Added articles section
#   .Rbuildignore                         — vignette artifact exclusion
#   R/tar_plans/plan_doc_examples.R      — Real code examples + validation
#
# Checks:
#   devtools::document()   — PASS (NAMESPACE up to date)
#   devtools::test()       — PASS (565/565, 0 failures)
#   devtools::check()      — PASS (0E / 0W / 0N)
#   Quality gate           — Gold (96/100)
#   Cachix push            — SKIPPED (cachix not in current shell)
