# Plan: Models Dashboard & Leaderboard Refactoring

**Issue:** Comprehensive refactoring of `models-betting.qmd` into a dashboard
with per-model drill-down, fixing 23 identified bugs and UX issues.

**Estimated scope:** 3 files modified, ~40 targets changed in `plan_vignette_outputs.R`,
1 new vignette (dashboard format), 1 GitHub issue created, 2 global rules updated.

## Priority Tiers

| Tier | What | Why First |
|------|------|-----------|
| P0 | Fix bugs visible on deployed site | Users see broken content now |
| P1 | Restructure leaderboard + add drill-down | Core ask |
| P2 | Convert to dashboard format | Layout improvement |
| P3 | perspectiveR / reactable exploration | Enhancement |

---

## Batch 1: P0 Bug Fixes (deploy-blocking)

### 1.1 Spurious precision in model comparison table (#6)

**File:** `R/tar_plans/plan_vignette_outputs.R` target `vig_model_comparison_table`
**Current:** Passes raw `model_vs_pinnacle` with 15-decimal floats
**Fix:** Round: log_loss 3dp, brier 3dp, rps 3dp, edge 3dp. Group by metric then model.
Add caption: "Metrics are not directly comparable across rows — log-loss, Brier, and RPS
measure different aspects of calibration."

### 1.2 Value bets caption lies about columns (#9)

**File:** `R/tar_plans/plan_vignette_outputs.R` target `vig_value_bets_summary`
**Current caption (in qmd):** Claims "hit rate, ROI" columns that don't exist
**Fix:** Update caption in `models-betting.qmd` to match actual columns:
outcome, league_code, n_bets, mean_edge, mean_odds, mean_kelly.
Add definitions: mean_odds = average decimal odds of value bets,
mean_kelly = average quarter-Kelly stake fraction.

### 1.3 Kelly distribution: pre-cap vs post-cap confusion (#12)

**File:** `R/tar_plans/plan_vignette_outputs.R` target `vig_kelly_stake_distribution`
**Current:** Plots raw `kelly_stake` which is pre-cap (goes to 30%)
**Fix options (choose one):**
- (a) Plot capped stakes: `pmin(kelly_stake, 0.03)` — shows what's actually bet
- (b) Keep raw but add vertical annotation + update caption: "Raw quarter-Kelly
  fractions before the 3% cap. In practice, all stakes >3% are capped at 3%."
**Recommended:** (a) — plot what's actually staked, with annotation showing cap line.

### 1.4 Build-info footer raw text (#21)

**File:** `R/tar_plans/plan_vignette_outputs.R` target `vig_build_info`
**Current:** `sprintf()` returns markdown, but rendered as raw text in some contexts
**Fix:** Ensure output is `knitr::asis_output()` wrapped markdown. Check the
`results = "asis"` chunk option is present in all consuming vignettes.

### 1.5 Missing evidence errors in xG sections (#18)

**File:** `R/tar_plans/plan_vignette_outputs.R` target `vig_xg_per_league`
**Current:** `tryCatch(xg_per_league_comparison, error = function(e) NULL)` —
the upstream target `xg_per_league_comparison` doesn't exist or errors.
**Fix:** Either build the upstream target or remove the section from the vignette.
Check: `grep -r "xg_per_league_comparison" R/tar_plans/` to find where it should
come from. If from `plan_xg_features.R` line 387, check if it has missing upstream deps.

### 1.6 CV diagram: no blue/orange colors (#4)

**File:** `R/diagrams.R` function `generate_cv_walkforward_mermaid()`
**Current:** Plain boxes with no styling — caption says "blue/orange" but boxes are gray
**Fix:** Add mermaid style directives:
```
style T1 stroke:#3498db,stroke-width:3px
style T2 stroke:#3498db,stroke-width:3px
style TN stroke:#3498db,stroke-width:3px
style V1 stroke:#e67e22,stroke-width:3px
style V2 stroke:#e67e22,stroke-width:3px
style VN stroke:#e67e22,stroke-width:3px
```
Use stroke (outline) not fill to avoid text color conflicts.

---

## Batch 2: P0 Content Fixes

### 2.1 Remove "no costs" P&L scenario (#13)

**File:** `R/tar_plans/plan_vignette_outputs.R` targets:
- `vig_pnl_curve` — currently shows optimistic only → delete or merge into realistic
- `vig_pnl_curve_realistic` — shows both → show realistic only
- `vig_pnl_summary_table` — has both scenarios → keep realistic only
- `vig_drawdown_plot` — based on `pnl_glm` (no costs) → switch to `pnl_glm_realistic`

**File:** `vignettes/models-betting.qmd` — update prose removing "no costs" references

### 2.2 OOS section: resolve IS vs OOS confusion (#16, #17)

**File:** `vignettes/models-betting.qmd` section "Out-of-Sample Evaluation"
**Current contradictions:**
- "In-sample results above" — no IS results are shown anywhere
- "Train 2015-2020, test 2021-2023" contradicts "24-month train, 1-month test"
**Fix:** Rewrite prose to explain the two evaluation frameworks:
- Framework A (plan_oos.R): fixed split — train 15-20, validate 21-23
- Framework C (plan_ranger_1x2.R etc): rolling 24m train, 1m test
Both are out-of-sample. The P&L section uses Framework A. The CV metrics
section uses Framework C. The leaderboard combines both.

### 2.3 Summary table: transpose (#15)

**File:** `R/tar_plans/plan_vignette_outputs.R` target `vig_pnl_summary_table`
**Fix:** After removing "no costs", transpose so columns = metrics (n_bets,
roi_pct, win_rate, etc.) and there's just one row for the realistic scenario.
Actually better: keep as-is if we add per-model rows later. Revisit in P1.

---

## Batch 3: P1 Leaderboard Restructuring

### 3.1 Split leaderboard into two panels (#20)

**File:** `R/tar_plans/plan_vignette_outputs.R` target `vig_model_leaderboard`
**Current:** Single table with NAs everywhere (AH models have no calibration, 1X2 have no P&L)
**Fix:** Split into two targets:
- `vig_leaderboard_calibration` — 1X2 models: model, log_loss, brier, rps, n_folds
- `vig_leaderboard_pnl` — AH models: model, roi_pct, n_bets, sharpe, max_dd, win_rate

Display as two separate DT tables with proper formatting.

### 3.2 Add drill-down links to per-model detail (#1)

**File:** `vignettes/models-betting.qmd` (or new dashboard)
**Pattern:** Each model name in the leaderboard links to a tabset panel
with that model's detail: equity curve, per-season heatmap, per-league breakdown.
Use `DT::datatable()` with `escape = FALSE` to render HTML links in the model column.

### 3.3 CV metrics plot: complete refactoring (#5)

**File:** `R/tar_plans/plan_vignette_outputs.R` target `vig_cv_metrics_plot`
**Current problems:**
- Too many lines (all folds × all metrics × all models on one plot)
- Dropdown filter doesn't work (wrong `restyle` args)
- X-axis compressed (fold numbers crammed)
- Legend in wrong position

**Refactoring options:**
- **(a) Faceted small multiples** (RECOMMENDED): One subplot per metric (log_loss,
  brier, rps). Each subplot has 2 lines (GLM, DC) + Pinnacle reference.
  Use `plotly::subplot(nrows = 3, shareX = TRUE)`. ~30 fold points per line
  is readable at 3 subplots.
- (b) Summary boxplot: Instead of per-fold lines, show box/violin per model×metric.
  Loses fold-level detail but much cleaner.
- (c) Interactive table: Replace plot entirely with a DT table of per-fold metrics.
  Less visual but completely readable.

### 3.4 Edge distribution: add panel plot (#10)

**File:** `R/tar_plans/plan_vignette_outputs.R` — new target `vig_edge_panels`
**What:** Faceted plotly with one panel per outcome (H/D/A) showing edge histogram +
summary stats (mean, median, >15% count). Replaces or supplements existing overlapping histogram.

### 3.5 Edge histogram: clickable legend caption (#11)

**File:** `vignettes/models-betting.qmd` caption text
**Fix:** Add: "Legend entries are clickable — click to show/hide individual outcomes."

---

## Batch 4: P2 Dashboard Conversion

### 4.1 Convert models-betting.qmd to dashboard format (#22)

**File:** `vignettes/models-betting.qmd`
**Target layout:**

```
Page 1: "Leaderboard"
  - Tab: Calibration (1X2)     → vig_leaderboard_calibration
  - Tab: P&L (AH)              → vig_leaderboard_pnl
  - Tab: Combined               → vig_model_leaderboard (for perspectiveR later)

Page 2: "Cross-Validation"
  - Tab: Walk-Forward Design    → vig_cv_html (mermaid diagram)
  - Tab: Scoring Metrics        → vig_cv_metrics_plot (refactored)
  - Tab: Model Comparison       → vig_model_comparison_table

Page 3: "Betting Strategy"
  - Tab: Value Bets             → vig_value_bets_summary
  - Tab: Edge Distribution      → vig_edge_distribution + vig_edge_panels
  - Tab: Kelly Staking          → vig_kelly_stake_distribution

Page 4: "P&L & Risk"
  - Tab: Equity Curve           → vig_pnl_curve_realistic
  - Tab: Drawdown               → vig_drawdown_plot
  - Tab: Summary                → vig_pnl_summary_table

Page 5: "Out-of-Sample"
  - Tab: OOS Comparison         → vig_oos_comparison
  - Tab: OOS by League          → vig_oos_by_league
  - Tab: xG Calibration         → vig_xg_per_league (if available)
  - Tab: Market Baselines       → vig_market_baselines
```

**YAML:**
```yaml
format:
  dashboard:
    theme: darkly
    orientation: columns
```

### 4.2 perspectiveR / reactable exploration (#3)

**Dependency check:** `perspectiveR` not in DESCRIPTION or default.nix.
**Decision:** Use `reactable` first (lighter, better drill-down support).
Add `perspectiveR` as optional enhancement later.
**Task:** Add `reactable` to DESCRIPTION + default.nix, create
`vig_leaderboard_reactable` target with expandable rows showing per-model detail.

---

## Batch 5: P2 Global Config Updates

### 5.1 Spurious precision rule enforcement (#23)

**File:** `~/.claude/rules/quarto-vignette-format.md` section "Number Formatting"
**Current:** Has a formatting table but it's not prominent enough.
**Fix:** Add to the "ZERO TOLERANCE" heading: "Displaying >4 decimal places for any
metric is a CRITICAL violation equivalent to [MISSING EVIDENCE]. It actively misleads
readers into believing the model distinguishes at precision it cannot achieve."

### 5.2 MISSING EVIDENCE grep in QA (#19)

**File:** `~/.claude/rules/quarto-vignette-validation.md` section 18
**Current:** Says to grep but doesn't make it a blocking gate.
**Fix:** Add mandatory post-build check:
```bash
# MUST return 0 hits — fails the build otherwise
count=$(grep -c "MISSING EVIDENCE" docs/articles/*.html 2>/dev/null | awk -F: '{s+=$2}END{print s}')
if [ "$count" -gt 0 ]; then
  echo "FAIL: $count [MISSING EVIDENCE] found in deployed HTML"
  exit 1
fi
```
Also add to `vignette_check.sh` hook.

---

## Batch 6: GitHub Issue

### 6.1 Drawdown issue (#14)

**Title:** `fix: excessive drawdown in GLM value bet strategy`
**Body:**
- Current max drawdown: ~80% (from P&L simulation)
- The 20% guardrail halves stakes but doesn't prevent further drawdown
- Options to explore:
  1. **Stop-loss**: Halt betting entirely when DD > 30%
  2. **Kelly fraction reduction**: Use 1/8 Kelly instead of 1/4
  3. **Volatility targeting**: Scale position size inversely with recent vol
  4. **Max consecutive losses**: Pause after N losses in a row
  5. **Regime detection**: Reduce/stop in high-vol regimes
  6. **Diversification**: Spread across leagues to reduce correlation
- Acceptance criteria: max DD < 40% while maintaining >50% of current ROI

---

## Execution Order

```
Batch 1 (P0 bugs)    → commit "fix: precision, captions, CV diagram colors"
Batch 2 (P0 content) → commit "fix: remove no-costs scenario, clarify OOS"
Batch 3 (P1 leader)  → commit "feat: split leaderboard, refactor CV plot"
Batch 4 (P2 dash)    → commit "feat: dashboard layout with pages and tabsets"
Batch 5 (P2 config)  → commit "chore: strengthen precision + MISSING EVIDENCE rules"
Batch 6 (issue)      → create GH issue
```

Each batch is independently deployable. Run `tar_make(names = starts_with("vig_"))`
after each batch, export RDS, rebuild site, verify no MISSING EVIDENCE.

---

## Estimated Work

| Batch | Agent | Model | Time |
|-------|-------|-------|------|
| 1 | fixer | sonnet | 20 min |
| 2 | fixer | sonnet | 15 min |
| 3 | fixer | sonnet | 30 min |
| 4 | fixer | sonnet | 45 min |
| 5 | quick-fix | haiku | 5 min |
| 6 | quick-fix | haiku | 5 min |

**Total:** ~2 hours in a sonnet worktree.

## Pre-requisites

- Run in sonnet worktree: `git worktree add ../footbet-sonnet feat/dashboard-leaderboard`
- Nix shell available with all targets built
- `ah_walkforward_all` and `model_comparison_with_brms` targets up to date
