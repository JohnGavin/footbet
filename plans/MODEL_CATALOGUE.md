# Model Catalogue

All prediction models attempted in footbet, with results against Pinnacle closing odds.
Updated as new models are added.

## How to read this document

Each model has: what it does, how it works, what it scored, and what we learned.
**ROI %** is the headline metric — percentage return on total staked against
Pinnacle closing odds. Negative = losing money. The Pinnacle overround is ~2%
per outcome, so a model at -2% is essentially pricing matches as well as the
sharpest bookmaker but paying the vig.

## Leaderboard

| # | Model | ROI % | Bets | Period | Subset | Issue |
|---|-------|------:|-----:|--------|--------|-------|
| 1 | W/D/L pattern: fade bounce | -0.6% | 1,307 | 22-25 | All (validation) | — |
| 2 | OAGD 1-param home only | -2.2% | ~3,400 | 22-25 | Home (validation) | #77 |
| 3 | W/D/L pattern: pair trade Tier1 | -2.1% | 114 | 22-25 | Home (tiny N) | — |
| 4 | W/D/L pattern: home slip | -3.9% | 2,283 | 22-25 | All (validation) | — |
| 5 | OAGD 1-param no draws | -5.4% | ~7,000 | 22-25 | H+A (validation) | #77 |
| 6 | OAGD 1-param all bets | -6.1% | 7,544 | 22-25 | All (validation) | #77 |
| 7 | OOS static GLM | -7.9%* | — | 20-23 | All (validation) | — |
| — | **OAGD v2 attack/defence (HOLDOUT)** | **-13.5%** | **5,629** | **23-26** | **H+A, with costs** | **#67** |
| 8 | OOS Dixon-Coles per-league | — | — | 20-23 | All | #70 |
| 9 | OOS GLM + market blend | — | — | 20-23 | All | #44 |
| 10 | OOS XGBoost | — | — | 20-23 | All | #37 |
| 11 | OOS ranger RF | — | — | 20-23 | All | — |
| 12 | OOS CLV (B365 vs Pinnacle) | — | — | 20-23 | All | — |
| 13 | OOS GLM + isotonic calibration | — | — | 20-23 | All | #68 |
| 14 | OOS rolling refit GLM (quarterly) | — | — | 20-23 | All | #69 |

*From CHANGELOG 2026-03-28: "7-model OOS comparison (-7.9% best ROI)".
Models 7-14 use a different evaluation framework (plan_oos.R, train 15-20,
validate 20-23, tiered staking with transaction costs). Results marked "—"
need to be re-extracted from the pipeline.

## Baseline to beat

**-6.1% ROI** (OAGD, all bets, best grid search params). Any future model
must outperform this on the same validation set or it is not worth deploying.

For home-only strategies: **-2.2%** is the bar.

---

## Model details

### 1. Naive W/D/L pattern strategies

**What:** Back or lay based on a team's recent win/draw/loss sequence, ignoring
opponent quality and goal difference.

**How:** For each team, track the last 3-4 non-draw results (W or L). When a
pattern matches a signal (e.g. away team trailing LLW = "dead cat bounce"),
bet on the predicted outcome at Pinnacle closing odds.

**Three variants tested:**

| Strategy | Signal | Bet | ROI % | Bets |
|----------|--------|-----|------:|-----:|
| Fade dead-cat bounce | Away trailing LLW | Back home | -0.6% | 1,307 |
| Back home after slip | Home trailing WWL or WLW | Back home | -3.9% | 2,283 |
| Pair trade (both signals) | Both fire same match | Back home | -2.1% | 287 |

**What we learned:**
- The market already prices simple form patterns. No edge exists in W/D/L
  sequences against Pinnacle.
- The pair trade's Tier 1 result (+7.6%) was noise on 114 bets.
- Motivation: these results led to the OAGD model — if raw form doesn't work,
  maybe opposition-adjusted form will.

**Files:** Ad-hoc analysis (not in R/ source). Results in CHANGELOG 2026-04-02.

---

### 2. OAGD (Opposition-Adjusted Goal Difference)

**What:** Rolling mixed-effects model that estimates team strength from goal
differences, adjusts recent form for opposition quality, and predicts the full
GD distribution via Skellam.

**How:**

1. **Rolling paired comparison** (lme4): `gd_home ~ 1 + (1|home_team) + (1|away_team)`
   on a sliding window of W matchdays. Intercept = home advantage. Random effects =
   team strengths, shrunk toward league mean.

2. **Opposition-adjusted form**: for each team, compute residuals
   (actual GD - expected GD given opponent). Exponentially weight the last K
   residuals (half-life H matches). This is the "Johnson difficulty adjustment"
   applied to football.

3. **Skellam prediction**: convert strength + form to expected goals via
   λ_home = (avg_goals + μ) / 2, λ_away = (avg_goals - μ) / 2.
   GD ~ Skellam(λ_home, λ_away) gives P(H), P(D), P(A).

4. **Tiered staking**: bet 1 unit if model edge > τ_min, 2 units if > τ_double.

**Grid search results** (54 combinations, 3 seasons × 10 leagues):

| Subset | Best ROI | Best params |
|--------|--------:|-------------|
| All bets | -6.1% | W=6, H=2, τ=0.05, β=0.3 |
| Home only | -2.2% | W=6, H=1, τ=0.07, β=0.3 |
| No draws | -5.4% | W=6, H=2, τ=0.05, β=0.3 |

**Form signal test** (β=0 vs β=0.3):
- β=0.3 improves ROI by ~1pp everywhere (-7.3% vs -8.3%)
- The opposition-adjusted form signal is real but insufficient

**What we learned:**
- Skellam systematically overestimates draws (-21.8% ROI on draw bets) → #78
- Short windows (W=6) beat longer ones — lme4 singular fits at W=8/10 add noise
- Home bets at -2.2% are within Pinnacle's ~2% overround
- 1-parameter strength can't distinguish good attack + weak defence → #79
- Form helps directionally (+1pp) but not enough to overcome the margin

**Files:** `R/model_oagd.R`, `R/model_predict.R`, `R/backtest_oagd.R`,
`R/tar_plans/plan_oagd.R`. Tests: 60 (42 unit + 18 integration, 10 snapshots).

**Issues:** #77 (umbrella), #78 (draw bias), #79 (attack/defence split), #80 (Sharpe bug)

---

### 3. Poisson GLM baseline

**What:** Simple Poisson GLM on goals with team attack/defence strengths
and home advantage. The mandatory baseline all advanced models must beat.

**How:** `goals ~ home + team + opponent`, Poisson family. Trained on
15-16 to 19-20, validated on 20-21 to 22-23.

**Results:** -7.9% ROI (from CHANGELOG, with tiered staking + transaction costs).

**What we learned:** The simplest reasonable model. Every other model is
compared against this.

**Files:** `R/models_baseline.R`, `R/tar_plans/plan_oos.R`

---

### 4. Dixon-Coles per-league

**What:** Dixon-Coles (1997) model with low-score correction (ρ parameter
adjusting 0-0, 1-0, 0-1, 1-1 probabilities) and exponential time-decay
weights. Fitted separately per league.

**How:** Uses `goalmodel::goalmodel()` with `dc = TRUE`. Time-decay parameter
ξ = 0.003. Trained per-league on 15-16 to 19-20, validated on 20-21 to 22-23.

**Results:** In pipeline (oos_validate_summary_dc), not yet extracted here.

**What we learned:** The ρ correction specifically addresses the draw
overestimation that Skellam/Poisson models suffer from. This is the
natural next step for OAGD (#78).

**Files:** `R/models_dc.R`, `R/tar_plans/plan_oos.R` (oos_dc_per_league)

**Issues:** #70

---

### 5. GLM + market blend

**What:** Linear blend of GLM model probabilities with Pinnacle devigged
market probabilities. Optimal weight found on training data.

**How:** `P_blend = w × P_model + (1-w) × P_market`. Grid search for w
on train set, apply to validate.

**Results:** In pipeline (oos_validate_summary_blended), not yet extracted.

**What we learned:** Market probabilities are very informative. The optimal
blend weight typically puts most weight on the market (~70-90%).

**Files:** `R/tar_plans/plan_oos.R` (oos_blend_result)

**Issues:** #44

---

### 6. XGBoost

**What:** Gradient-boosted trees on engineered features (Elo, rolling stats,
market odds, rest days, H2H).

**How:** `xgboost::xgb.train()` with multi:softprob objective, 100 rounds,
early stopping. 12 features from feature_matrix target.

**Results:** In pipeline (oos_validate_summary_xgb), not yet extracted.
Requires xgboost package (not in Nix, excluded via `not_in_nix`).

**Files:** `R/models_xgboost.R`, `R/tar_plans/plan_oos.R`

**Issues:** #37

---

### 7. Ranger random forest

**What:** Random forest probability predictions as alternative to XGBoost
(available in Nix).

**How:** `ranger::ranger()` with `probability = TRUE`, 500 trees, same
12-feature set as XGBoost.

**Results:** In pipeline (oos_validate_summary_ranger), not yet extracted.

**Files:** `R/tar_plans/plan_oos.R`

---

### 8. CLV strategy (B365 vs Pinnacle)

**What:** Not a model — a market arbitrage strategy. Bet where Bet365
offers longer odds than Pinnacle closing (soft book mispricing vs sharp book).

**How:** For each match and outcome, if `1/B365_odds < 1/Pinnacle_odds - 0.02`,
bet at B365 odds. This exploits the fact that soft bookmakers are slower to
adjust than Pinnacle.

**Results:** In pipeline (oos_validate_summary_clv), not yet extracted.

**What we learned:** This tests whether the edge is in *modelling* or in
*market structure*. If CLV beats all models, the value is in finding
slow-to-update bookmakers, not in building better predictions.

**Files:** `R/tar_plans/plan_oos.R`

---

### 9. GLM + isotonic calibration

**What:** Post-hoc calibration of GLM probabilities using isotonic regression
(monotone step function fitted on training data).

**How:** Fit `isoreg()` on train predictions vs actuals. Apply transform
to validate predictions. Renormalise to sum to 1.

**Results:** In pipeline (oos_validate_summary_calibrated), not yet extracted.

**Files:** `R/tar_plans/plan_oos.R` (oos_isotonic)

**Issues:** #68

---

### 10. Rolling refit GLM (quarterly)

**What:** GLM baseline but refitted every 3 months on the preceding 24
months of data, instead of a single static fit.

**How:** Slide a 24-month training window forward by 3 months. Predict the
next quarter. Accumulate bets.

**Results:** In pipeline (oos_validate_summary_rolling), not yet extracted.

**What we learned:** Tests whether model staleness (static training set)
is a source of loss.

**Files:** `R/tar_plans/plan_oos.R` (oos_validate_pnl_rolling)

**Issues:** #69

---

### 11. brms hierarchical Bayesian Poisson

**What:** Full Bayesian Poisson regression with random effects for teams
via Stan/brms. Enables partial pooling (shrinkage) of attack/defence
strengths with proper uncertainty quantification.

**How:** `brms::brm(goals ~ home + (1|team) + (1|opponent), family = poisson())`.
4 chains × 2000 iterations. Slow but principled.

**Results:** Not yet backtested against odds. Implemented but not wired
into plan_oos.R evaluation framework.

**What we learned:** Could provide proper posterior predictive distributions
instead of point estimates. Natural extension of OAGD's lme4 approach
with full Bayesian inference.

**Files:** `R/models_brms.R`

---

## Planned models (not yet implemented)

| Model | Idea | Issue | Status |
|-------|------|-------|--------|
| OAGD + Dixon-Coles ρ | Fix Skellam draw bias with low-score correction | #78 | Planned |
| OAGD attack/defence split | Separate attack and defence strengths | #79 | Planned |
| OAGD + brms | Replace lme4 with full Bayesian via brms | — | Idea |
| Bivariate Poisson | Model (home, away) goals jointly with covariance | #43 | Idea |
| SPI-style xG model | Non-shot + shot expected goals (FiveThirtyEight approach) | #57 | Idea |
| Match importance weighting | Weight end-of-season games by stakes | — | Idea |

---

## Evaluation frameworks

Two separate evaluation setups exist. Results are **not directly comparable**
between them due to different periods, staking, and cost assumptions.

### Framework A: plan_oos.R (models 3-10)

- **Train:** 15-16 to 19-20 (5 seasons)
- **Validate:** 20-21 to 22-23 (3 seasons)
- **Staking:** Tiered (5-25 units based on edge tiers)
- **Costs:** 2% transaction + 1% slippage
- **Benchmark:** Pinnacle closing odds, devigged

### Framework B: OAGD backtest (models 1-2)

- **Validate:** 22-23 to 24-25 (3 seasons)
- **Staking:** Flat (1 or 2 units based on τ_min/τ_double)
- **Costs:** None (raw odds, no transaction/slippage)
- **Benchmark:** Pinnacle closing odds, raw

**TODO:** Unify frameworks so all models are evaluated on the same basis.
Either adapt plan_oos.R to include OAGD, or adapt OAGD backtest to include
transaction costs. This is prerequisite for a fair leaderboard.
