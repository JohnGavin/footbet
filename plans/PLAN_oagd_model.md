# PLAN: Opposition-Adjusted Goal Difference (OAGD) Model

**Status:** Draft
**Created:** 2026-04-01
**Tracks:** GitHub issue (see bottom)

## Motivation

Raw W/D/L sequences ignore opposition quality. Inspired by Valen Johnson's
relative comparison indexes for grade inflation (Gans & Kominers formalisation):
teams are "students", opponents are "courses", goal difference is the "grade".
The full round-robin within each league gives a complete overlap network —
the ideal case for paired-comparison estimation.

## Architecture

### Step 1: Rolling paired-comparison model

For each league-season, fit on a rolling window of W matchdays:

```
GD_ij = α_i - α_j + η * home_flag + ε_ij
```

- `α_i`: latent team strength (random effect, shrunk toward league mean)
- `η`: home advantage (fixed, league-specific)
- Window W: hyperparameter, candidates = {6, 8, 10, half-season}
- Implementation: `lme4::lmer(gd ~ home_flag + (1|home_team) + (1|away_team))`
- Refit every matchday (slide window forward by 1)

Mixed effects rationale: with 18-24 teams and 10-match windows, each team
contributes ~10 observations. Random effects shrink noisy estimates
(especially early-season, extreme results, Bundesliga's 18-team leagues).

### Step 2: Extract opposition-adjusted form

For each team's last K matches (K=4 default), compute:

```
residual_k = observed_GD_k - (α̂_i - α̂_j + η̂)
form_i = Σ w_k * residual_k  (exponential weights, half-life H matches)
```

Half-life H: hyperparameter, candidates = {1, 2, 3}

Interpretation:
- form > 0: team overperforming relative to opponents faced
- form < 0: team underperforming
- form ≈ 0: performing exactly as opponent quality predicts

### Step 3: Predict next-match GD distribution

For upcoming match (team i home vs team j away):

```
log(λ_home) = μ + α̂_attack_i - α̂_defence_j + η/2 + β * form_i
log(λ_away) = μ + α̂_attack_j - α̂_defence_i - η/2 + β * form_j
GD ~ Skellam(λ_home, λ_away)
```

Alternative: split α into attack/defence components (Dixon-Coles style).
Test both 1-parameter and 2-parameter team strength.

### Step 4: Convert to outcome probabilities

```r
P(H) = P(GD > 0)  = sum(dskellam(k, λ_h, λ_a) for k in 1:max)
P(D) = P(GD == 0) = dskellam(0, λ_h, λ_a)
P(A) = P(GD < 0)  = 1 - P(H) - P(D)
```

## Betting thresholds (Kelly-inspired)

### Tier 1: Minimum edge to bet (1 unit)

```
edge_ij = P_model(outcome) - P_implied(outcome)
```

Where `P_implied = 1 / odds_closing` (Pinnacle, already near-efficient).

Bet 1 unit IF `edge > τ_min`.

Candidates for τ_min: {0.03, 0.05, 0.07, 0.10}

Rationale: Pinnacle overround is ~2% per outcome. Below 3% edge,
you're likely inside the noise band.

### Tier 2: Double-size bet threshold

Bet 2 units IF `edge > τ_double`.

Candidates for τ_double: {0.08, 0.10, 0.15}

Constraint: τ_double >= 2 * τ_min (otherwise tier 2 fires too easily).

### Staking plan

| Edge | Stake |
|------|-------|
| < τ_min | No bet |
| τ_min <= edge < τ_double | 1 unit |
| edge >= τ_double | 2 units |

Extension: fractional Kelly = edge / odds * fraction (fraction = 0.25 typical).
Test flat staking first, then Kelly, to isolate model edge from staking edge.

### Threshold selection protocol

1. Grid search over (W, H, β, τ_min, τ_double) on training seasons (15-16 to 21-22)
2. Select by Sharpe ratio of PnL (not ROI — accounts for variance)
3. Validate on holdout seasons (22-23 to 24-25)
4. Report: ROI, Sharpe, max drawdown, bets/season, hit rate
5. Split results by tier (Tier1/Tier2 leagues) and league

## Hyperparameter summary

| Parameter | Role | Candidates |
|-----------|------|-----------|
| W | Rolling window (matchdays) | 6, 8, 10, half-season |
| H | Form half-life (matches) | 1, 2, 3 |
| K | Form lookback (matches) | 3, 4, 5 |
| β | Form weight in prediction | Estimated from data |
| τ_min | Minimum edge to bet | 0.03, 0.05, 0.07, 0.10 |
| τ_double | Edge to double stake | 0.08, 0.10, 0.15 |
| Attack/defence split | 1-param vs 2-param strength | Binary |
| GD distribution | Skellam vs Normal | Binary |

Total grid: 4 × 3 × 3 × 4 × 3 × 2 × 2 = 1,728 combinations.
Use coarse grid first (W, H, τ_min only), then refine.

## Implementation order

1. [ ] `R/model_oagd.R`: rolling paired-comparison fit + residual extraction
2. [ ] `R/model_predict.R`: Skellam prediction + probability conversion
3. [ ] `R/backtest_oagd.R`: backtest harness with threshold staking
4. [ ] `tests/testthat/test-model_oagd.R`: unit tests (known matchday, expected α)
5. [ ] `vignettes/oagd-backtest.qmd`: results vignette
6. [ ] Integrate into `_targets.R` pipeline

## Data requirements

- Seasons 15-16 to 24-25 (11 seasons, 10 leagues) — all in DuckDB
- Pinnacle closing odds — all in `match_odds` table
- League sizes: 18 (D1/D2), 20 (E0/F1/F2/I1/I2/SP1), 22 (SP2), 24 (E1)

## References

- Johnson, V. (1997). An alternative to traditional GPA for evaluating student performance. Statistical Science.
- Gans & Kominers. Relative comparison indexes. (via MarginalRevolution 2026-03-31)
- Dixon & Coles (1997). Modelling association football scores. JRSS-C.
- Skellam distribution: difference of two independent Poissons.
