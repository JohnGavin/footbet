# IMPL: Opposition-Adjusted Goal Difference (OAGD) Model

**Tracks:** [#77](https://github.com/JohnGavin/footbet/issues/77) | Design: `plans/PLAN_oagd_model.md`
**Status:** In progress — Phases 1-5 code + Phase 7 pipeline written, 42 unit/snapshot tests passing, integration tests written (await lme4 Nix build)
**Created:** 2026-04-01

## Prerequisites

| Dependency | Status | Action |
|---|---|---|
| `lme4` | In Suggests, not installed in Nix | Add to `default.R` / rebuild Nix shell |
| `skellam` pkg | Not needed | Use base R `besselI()` — tested, works |
| `Matrix` | In Imports | Already available (lme4 dependency) |
| DuckDB data | 11 seasons, 10 leagues, Pinnacle closing odds | All present |

## Phase 0: Environment (before any code)

| Step | Task | Command / Detail | Done |
|------|------|-----------------|------|
| 0.1 | Add lme4 to `default.R` | Add `"lme4"` to the rpkgs vector | [ ] |
| 0.2 | Rebuild Nix shell | `nix-build` then re-enter shell | [ ] |
| 0.3 | Verify lme4 loads | `Rscript -e 'library(lme4)'` | [ ] |

## Phase 1: Data preparation (`R/model_oagd.R`, part 1)

| Step | Task | Detail | Done |
|------|------|--------|------|
| 1.1 | `oagd_match_data(con, seasons, leagues)` | Query DuckDB, return tibble: `match_id, season, league_code, match_date, matchday, home_team, away_team, gd_home` where `gd_home = fthg - ftag`. Compute `matchday` as dense rank of `match_date` within league-season. | [ ] |
| 1.2 | Test: known matchday numbering | E0 2425 matchday 1 should have 10 matches. Final matchday should have 10. Total matchdays ~ 38. | [ ] |
| 1.3 | `oagd_add_odds(matches, con)` | Left-join Pinnacle closing 1x2 odds. Compute `implied_h = 1/odds_h`, normalise to remove overround. | [ ] |
| 1.4 | Test: odds coverage | <1% NA after join. Implied probs sum to 1.0 per match. | [ ] |

## Phase 2: Rolling paired-comparison fit (`R/model_oagd.R`, part 2)

| Step | Task | Detail | Done |
|------|------|--------|------|
| 2.1 | `oagd_fit_window(data, league, season, matchday, window_size)` | Subset to `[matchday - window_size + 1, matchday]`. Fit `lmer(gd_home ~ 1 + (1|home_team) + (1|away_team), data = window)`. The intercept = home advantage η. Team random effects = α_i. | [ ] |
| 2.2 | Why this formula | `(1|home_team)` captures "how much better is GD when team X is at home" (attack + home boost). `(1|away_team)` captures "how much worse is GD when team Y visits" (negative = strong away). The *difference* between a team's home RE and away RE reflects their true strength, with home advantage separated into the intercept. | [ ] |
| 2.3 | `oagd_extract_strengths(fit)` | Extract `ranef(fit)$home_team` and `ranef(fit)$away_team`. Combine into a tibble: `team, alpha_home, alpha_away, alpha_combined = (alpha_home - alpha_away) / 2`. | [ ] |
| 2.4 | `oagd_roll_fits(data, league, season, window_size)` | Loop matchdays `window_size` to `max_matchday`. Return list of fits or tibble of strengths per matchday. Use `possibly()` to handle convergence failures (return NA, log warning). | [ ] |
| 2.5 | Test: shrinkage works | Fit on E0 2425 matchday 10 (window=10). Team with most extreme GD should have `alpha < max(gd)`. Compare `ranef` to `fixef` from equivalent `lm()` — random effects should be shrunk toward zero. | [ ] |
| 2.6 | Test: home advantage sign | Intercept η should be positive (~0.3-0.5 goals). | [ ] |
| 2.7 | Test: convergence rate | Over all league-seasons with window=8, <5% of fits should fail to converge. | [ ] |

## Phase 3: Residuals and form (`R/model_oagd.R`, part 3)

| Step | Task | Detail | Done |
|------|------|--------|------|
| 3.1 | `oagd_residuals(data, fits)` | For each match in the dataset, compute `expected_gd = η + alpha_home[home_team] + alpha_away[away_team]` from the fit *at that matchday*. Then `residual = gd_home - expected_gd`. | [ ] |
| 3.2 | `oagd_form(residuals, team, matchday, K, half_life)` | For each team-matchday, take the last K residuals (from that team's perspective — flip sign for away matches). Apply exponential weights: `w_k = 2^(-k/half_life)`, normalise. Return weighted mean residual = `form`. | [ ] |
| 3.3 | Test: form of a team on a winning streak vs losing streak | A team that beats expectations (positive residuals) should have `form > 0`. A team underperforming should have `form < 0`. | [ ] |
| 3.4 | Test: form decays | If a team had a big upset 4 matches ago but performed as expected since, form should be near zero with half_life=2. | [ ] |

## Phase 4: GD distribution prediction (`R/model_predict.R`)

| Step | Task | Detail | Done |
|------|------|--------|------|
| 4.1 | `dskellam(k, lambda1, lambda2)` | Skellam PMF via base R `besselI()`. `exp(-(l1+l2)) * (l1/l2)^(k/2) * besselI(2*sqrt(l1*l2), abs(k))`. Already tested — works for k in -8:8, sums to ~1. | [ ] |
| 4.2 | `oagd_predict_match(alpha_i, alpha_j, eta, form_i, form_j, beta)` | Compute `mu = eta + alpha_i - alpha_j + beta * (form_i - form_j)`. Estimate `lambda_home` and `lambda_away` such that `lambda_home - lambda_away = mu` and `lambda_home + lambda_away = league_avg_goals` (constrained). Return Skellam probabilities for GD = -8 to +8. | [ ] |
| 4.3 | `oagd_match_probs(skellam_probs)` | `P(H) = sum(P(GD > 0))`, `P(D) = P(GD == 0)`, `P(A) = sum(P(GD < 0))`. | [ ] |
| 4.4 | Test: probabilities sum to 1 | For a range of inputs, `P(H) + P(D) + P(A)` must equal 1 (within 1e-4). | [ ] |
| 4.5 | Test: symmetry | With equal teams and η=0, P(H) should equal P(A) and P(D) should be the mode. | [ ] |
| 4.6 | Test: home advantage shifts distribution | With η > 0 and equal teams, P(H) > P(A). | [ ] |

## Phase 5: Backtest harness (`R/backtest_oagd.R`)

| Step | Task | Detail | Done |
|------|------|--------|------|
| 5.1 | `oagd_edge(model_prob, implied_prob)` | `edge = model_prob - implied_prob`. Compute for all 3 outcomes (H, D, A) per match. | [ ] |
| 5.2 | `oagd_stake(edge, tau_min, tau_double)` | `0` if `edge < tau_min`, `1` if `tau_min <= edge < tau_double`, `2` if `edge >= tau_double`. | [ ] |
| 5.3 | `oagd_pnl(stake, odds, outcome_hit)` | `if (outcome_hit) stake * (odds - 1) else -stake`. | [ ] |
| 5.4 | `oagd_backtest(data, params)` | For each match in validation set: (a) get model probs from rolling fit at prior matchday, (b) compute edge vs Pinnacle implied, (c) apply staking, (d) compute PnL. Return tibble with one row per bet placed. | [ ] |
| 5.5 | `oagd_backtest_summary(bets, grouping)` | Group by `tier`, `league_code`, `season`. Report: n_bets, n_wins, total_pnl, roi, sharpe, max_drawdown. | [ ] |
| 5.6 | Test: with tau_min = 1.0 (impossible edge), zero bets placed | [ ] |
| 5.7 | Test: with tau_min = 0.0, every match generates a bet | [ ] |
| 5.8 | Test: PnL is deterministic (same data + params = same result) | [ ] |

## Phase 6: Hyperparameter tuning (`R/backtest_oagd.R`, part 2)

| Step | Task | Detail | Done |
|------|------|--------|------|
| 6.1 | `oagd_grid()` | Generate coarse grid: W={6,8,10}, H={1,2,3}, tau_min={0.05,0.07,0.10} = 27 combos. Fix K=4, tau_double=2*tau_min, 1-param strength, Skellam. | [ ] |
| 6.2 | `oagd_tune(data_train, grid)` | Run backtest for each grid row on seasons 15-16 to 21-22. Store results. Parallelise over grid rows with `furrr::future_map()` or `crew`. | [ ] |
| 6.3 | Select best params | Rank by Sharpe ratio. Top 3 must agree on direction (all positive Sharpe, or reject model). | [ ] |
| 6.4 | `oagd_validate(data_test, best_params)` | Run on 22-23 to 24-25. Report by tier + league. | [ ] |
| 6.5 | Refine grid (if coarse grid shows signal) | Expand to full grid: add K={3,5}, tau_double, attack/defence split. 1,728 combos — run overnight via `targets` + `crew`. | [ ] |
| 6.6 | Test: training Sharpe > 0 does not guarantee validation Sharpe > 0 | Document this explicitly in vignette as overfitting risk. | [ ] |

## Phase 7: Pipeline integration (`_targets.R`)

| Step | Task | Detail | Done |
|------|------|--------|------|
| 7.1 | `tar_plans/plan_oagd.R` | Define targets: `oagd_data`, `oagd_fits`, `oagd_residuals`, `oagd_predictions`, `oagd_backtest`, `oagd_tune`. | [ ] |
| 7.2 | Source plan in `_targets.R` | Add `source("R/tar_plans/plan_oagd.R")` and include in `list(...)`. | [ ] |
| 7.3 | Test: `tar_make(oagd_backtest)` completes | End-to-end pipeline from raw data to PnL table. | [ ] |

## Phase 8: Vignette (`vignettes/oagd-backtest.qmd`)

| Step | Task | Detail | Done |
|------|------|--------|------|
| 8.1 | Motivation section | Johnson analogy, why W/D/L fails (cite the earlier backtest: -0.6% to -3.9% ROI). | [ ] |
| 8.2 | Model description | Formula, mixed-effects rationale, Skellam. | [ ] |
| 8.3 | Results tables | All from `tar_read()` — no hardcoded values. PnL by tier, league, season. | [ ] |
| 8.4 | GD distribution plots | For a specific match, show predicted Skellam vs observed GD histogram. | [ ] |
| 8.5 | Threshold sensitivity | Plot ROI and Sharpe vs tau_min for best W and H. | [ ] |
| 8.6 | Honest conclusion | State whether the model beats the market or not. | [ ] |

## Decision log

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Skellam via `besselI()` | Base R, no new dep | Tested: sums to 1, handles k=-8:8 |
| lme4 over stan/brms | Already in Suggests, faster | Mixed effects sufficient; full Bayes = Phase 5 moonshot |
| 1-param strength first | Simpler, fewer params | Attack/defence split is Phase 6 refinement |
| Pinnacle closing odds | Sharpest book | If no edge vs Pinnacle, no edge anywhere |
| Train/test split by season | 15-22 train, 22-25 test | 7 seasons train, 3 test — no leakage |

## Risk register

| Risk | Impact | Mitigation |
|------|--------|-----------|
| lme4 convergence failures in small windows | Missing predictions | `possibly()` wrapper, skip match, log rate |
| Skellam lambda constraint | Negative lambda impossible | Clamp `lambda = max(0.1, ...)` |
| Overfitting hyperparameters on 7 training seasons | False signal | Require top-3 grid points to agree; require positive Sharpe on each individual test season |
| lme4 not in Nix shell | Can't run | Phase 0 blocker — must resolve first |
| Form signal = noise | No edge, wasted effort | β is estimated — if zero, model degrades to plain paired-comparison (still useful as baseline) |
