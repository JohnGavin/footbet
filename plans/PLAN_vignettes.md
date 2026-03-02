# PLAN: Add 4 Vignettes to footbet

## Goal
Create 4 vignettes covering the full pipeline: data sources, data cleaning,
EDA, and model fitting. All vignettes follow zero-computation rule (tar_read only).

## Files Created
- `R/tar_plans/plan_vignette_outputs.R` — 22 pre-computed targets
- `vignettes/data-sources.Rmd` — Raw data sources & coverage
- `vignettes/data-cleaning.Rmd` — QC heatmaps & missing data
- `vignettes/eda.Rmd` — Goal distributions, home advantage, odds calibration
- `vignettes/model-fitting.Rmd` — Walk-forward CV, GLM vs DC vs Pinnacle, P&L

## Files Modified
- `DESCRIPTION` — Added VignetteBuilder: knitr
- `_targets.R` — Added plan_vignette_outputs to pipeline
- `_pkgdown.yml` — Added articles section (Data Pipeline + Analysis)
- `.Rbuildignore` — Added vignettes artifact exclusion
- `R/tar_plans/plan_doc_examples.R` — Replaced placeholder with 3 code examples

## Acceptance Criteria
- [ ] devtools::document() passes
- [ ] devtools::test() — 0 failures
- [ ] devtools::check() — 0 errors, 0 warnings
- [ ] All vignettes have valid VignetteIndexEntry
- [ ] Zero inline computation in vignettes (only safe_tar_read calls)
- [ ] All ggplots have labs(title, subtitle, caption, x, y)
- [ ] pkgdown articles section renders 4 articles
