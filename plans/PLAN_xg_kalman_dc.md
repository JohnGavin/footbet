# PLAN: xG + Kalman filter + Dixon-Coles correction

**Tracks:** [#82](https://github.com/JohnGavin/footbet/issues/82), [#78](https://github.com/JohnGavin/footbet/issues/78), [#57](https://github.com/JohnGavin/footbet/issues/57)
**Status:** Draft
**Created:** 2026-04-04

## Problem

All goals-only models fail against Pinnacle closing odds:
- OAGD (lme4, attack/defence): -13.5% holdout ROI
- Dixon-Coles (goalmodel): -9.5% OOS ROI
- GLM baseline: -7.9% OOS ROI
- brms (best calibration, log-loss 1.03): no ROI test yet

Goals are rare events (~1.3 per team per match). Estimating team strength
from goals alone has high variance. Three improvements address this:

1. **xG replaces goals** — reduces estimation variance (~12 shots → 1 xG vs ~1.3 goals)
2. **Kalman filter replaces rolling windows** — smooth strength evolution, no sharp transitions
3. **Dixon-Coles ρ correction** — fixes Skellam draw overestimation (-21.8% ROI on draws)

## Architecture

```
FBref xG data → Kalman-filtered team strengths → Dixon-Coles adjusted Poisson → Skellam GD dist → bet
```

### Layer 1: xG-based strength estimation

Replace `fthg`/`ftag` with `home_xg`/`away_xg` in the model input.

**Data pipeline:**
- `R/data_fbref.R` already has `fetch_fbref_matches()` returning `home_xg`, `away_xg`
- `join_xg_to_matches()` fuzzy-joins FBref to football-data.co.uk by date + teams
- Need: store xG in DuckDB alongside match results (new table or extra columns)

**Model change:**
```r
# Current (goals): glmer(fthg ~ 1 + (1|home_team) + (1|away_team), family = poisson)
# New (xG):        lmer(home_xg ~ 1 + (1|home_team) + (1|away_team))
```

xG is continuous (not integer), so use `lmer()` with Gaussian, not `glmer()` Poisson.
Or keep Poisson on goals but use xG as an offset/covariate:
```r
glmer(fthg ~ home_xg + (1|home_team) + (1|away_team), family = poisson)
```

**Preferred approach:** Fit on xG directly with `lmer()`. Team random effects
represent "xG creation ability" (attack) and "xG concession tendency" (defence).
Convert back to goal expectations via `lambda = exp(xG_strength)` for Skellam.

### Layer 2: Kalman filter for dynamic strength

Replace rolling-window lme4 with a state-space model:

```
State:      θ_t = [attack_i, defence_i] for each team i
Transition: θ_t = θ_{t-1} + w_t,  w_t ~ N(0, Q)
Observation: xG_t = H * θ_t + v_t,  v_t ~ N(0, R)
```

Where:
- `Q = diag(σ²_process)` — how fast team strength changes between matchdays
- `R = σ²_observation` — single-match xG noise
- `H` — design matrix mapping team states to observed xG

**Implementation options:**

| Option | Package | Pros | Cons |
|--------|---------|------|------|
| A | `KFAS` | Dedicated state-space, exact Kalman | Not in DESCRIPTION/Nix |
| B | `dlm` | Classic dynamic linear models | Not in DESCRIPTION/Nix |
| C | `brms` with AR(1) | Already available, Bayesian | Slow, MCMC not Kalman |
| D | Hand-rolled | No new deps, full control | More code, harder to test |
| E | `FKF` (Fast Kalman Filter) | Fast C implementation | Not in DESCRIPTION/Nix |

**Recommended: Option D (hand-rolled) first, then Option A if it works.**

A Kalman filter is ~50 lines of R. The state dimension is small (2 per team × 20 teams = 40),
so the matrix operations are trivial. No new dependency needed.

```r
kalman_update <- function(state, P, observation, H, Q, R) {
  # Predict
  state_pred <- state  # random walk: F = I
  P_pred <- P + Q

  # Update
  y_hat <- H %*% state_pred
  S <- H %*% P_pred %*% t(H) + R
  K <- P_pred %*% t(H) %*% solve(S)
  state_new <- state_pred + K %*% (observation - y_hat)
  P_new <- (diag(nrow(P)) - K %*% H) %*% P_pred

  list(state = state_new, P = P_new, innovation = observation - y_hat)
}
```

**Hyperparameters to tune:**
- `σ²_process` (Q): 0.001 to 0.05 — how volatile team strength is
- `σ²_observation` (R): 0.3 to 1.0 — single-match xG noise
- These can be estimated via maximum likelihood on training data

### Layer 3: Dixon-Coles ρ correction

The existing `fit_dixon_coles()` in `R/models_dc.R` already uses
`goalmodel::goalmodel(dc = TRUE)` which estimates ρ. The ρ parameter
adjusts P(0-0), P(1-0), P(0-1), P(1-1) probabilities.

**Integration with xG + Kalman:**

Two approaches:

**A. Post-hoc correction (simple):**
1. Get lambda_home, lambda_away from Kalman xG estimates
2. Compute Skellam/Poisson score probabilities
3. Apply Dixon-Coles τ correction to low-score cells:
   ```r
   tau <- function(x, y, lambda1, lambda2, rho) {
     if (x == 0 && y == 0) return(1 - lambda1 * lambda2 * rho)
     if (x == 0 && y == 1) return(1 + lambda1 * rho)
     if (x == 1 && y == 0) return(1 + lambda2 * rho)
     if (x == 1 && y == 1) return(1 - rho)
     return(1)
   }
   ```
4. Re-normalise score matrix
5. ρ estimated from training data (typically -0.10 to -0.15)

**B. Full goalmodel integration:**
Feed Kalman-estimated strengths as offsets into `goalmodel::goalmodel()` and let
it re-estimate ρ. This is cleaner but couples the Kalman filter to goalmodel.

**Recommended: Approach A** — keeps components modular and testable.

## Implementation plan

### Phase 1: xG data pipeline

| Step | Task | File | Done |
|------|------|------|------|
| 1.1 | Add `xg_home`, `xg_away` columns to DuckDB `matches` table | `R/database.R` | [ ] |
| 1.2 | Fetch FBref xG for all 10 leagues, seasons 15-16 to 25-26 | `R/data_fbref.R` | [ ] |
| 1.3 | Join xG to matches and insert into DuckDB | `R/tar_plans/plan_data_acquisition.R` | [ ] |
| 1.4 | Test: xG coverage ≥80% of matches after 2017 (FBref xG starts ~2017) | `tests/` | [ ] |

### Phase 2: Kalman filter

| Step | Task | File | Done |
|------|------|------|------|
| 2.1 | `kalman_update()` — single-step Kalman update | `R/model_kalman.R` | [ ] |
| 2.2 | `kalman_smooth()` — forward pass over full season | `R/model_kalman.R` | [ ] |
| 2.3 | `kalman_strengths()` — extract attack/defence per team per matchday | `R/model_kalman.R` | [ ] |
| 2.4 | `kalman_tune()` — ML estimation of Q, R on training data | `R/model_kalman.R` | [ ] |
| 2.5 | Tests: synthetic data with known strengths → Kalman recovers them | `tests/` | [ ] |
| 2.6 | Tests: snapshot strengths for E0 2425 matchday 20 | `tests/` | [ ] |

### Phase 3: Dixon-Coles correction

| Step | Task | File | Done |
|------|------|------|------|
| 3.1 | `dc_tau(x, y, lambda1, lambda2, rho)` — correction factor | `R/model_predict.R` | [ ] |
| 3.2 | `dc_score_matrix(lambda1, lambda2, rho, max_goals = 8)` — full matrix | `R/model_predict.R` | [ ] |
| 3.3 | `dc_match_probs(score_matrix)` — P(H), P(D), P(A) from matrix | `R/model_predict.R` | [ ] |
| 3.4 | `dc_estimate_rho(matches, lambdas)` — fit ρ from training data | `R/model_predict.R` | [ ] |
| 3.5 | Tests: with ρ=0, dc_score_matrix matches Poisson exactly | `tests/` | [ ] |
| 3.6 | Tests: with ρ<0, P(draw) decreases vs Poisson | `tests/` | [ ] |

### Phase 4: Combined prediction + backtest

| Step | Task | File | Done |
|------|------|------|------|
| 4.1 | `xgk_predict_match()` — Kalman strengths → DC-corrected score matrix → probs | `R/model_predict.R` | [ ] |
| 4.2 | Wire into `oagd_backtest_league()` or new `xgk_backtest_league()` | `R/backtest_oagd.R` | [ ] |
| 4.3 | Backtest on validation (22-25), compare to OAGD (-6.1%) and DC (-9.5%) | Pipeline | [ ] |
| 4.4 | If validation improves, run on holdout (but holdout is burned — use time-expanding CV) | Pipeline | [ ] |

### Phase 5: Pipeline targets

| Step | Task | File | Done |
|------|------|------|------|
| 5.1 | `plan_xgk.R` — targets for xG data, Kalman fits, predictions, backtest | `R/tar_plans/` | [ ] |
| 5.2 | Wire into `_targets.R` | `_targets.R` | [ ] |

## Dependencies

| Package | Status | Needed for |
|---------|--------|-----------|
| worldfootballR | In Suggests | FBref xG data |
| goalmodel | In Nix (custom build) | Optional: full DC integration |
| None new | — | Kalman filter is hand-rolled |

## Risks

| Risk | Impact | Mitigation |
|------|--------|-----------|
| FBref rate limiting | Slow data acquisition | Already handled in `fetch_fbref_matches()` with `Sys.sleep()` |
| xG coverage gaps pre-2017 | Shorter training window | Use goals for 15-17, xG for 17+ |
| Kalman Q/R estimation overfitting | Noisy strengths | Use half-season train, half validate for Q/R selection |
| ρ instability | DC correction hurts instead of helps | Test ρ=0 baseline alongside |
| Still negative ROI | Wasted effort | Document honestly; the calibration improvement alone is valuable |

## Expected outcome

| Metric | Current best | Target |
|--------|-------------|--------|
| RPS | 0.210 (brms) | <0.208 (closer to Pinnacle 0.204) |
| Draw ROI | -21.8% (OAGD) | >-10% (DC correction helps draws) |
| Overall ROI | -9.5% (DC OOS) | >-5% (xG + Kalman + DC combined) |

These are stretch targets. Even partial improvement on RPS validates the approach.
