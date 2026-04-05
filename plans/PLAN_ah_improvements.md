# PLAN: AH Market Improvements

**Status:** Draft
**Created:** 2026-04-05
**Tracks:** #81

## Current state

GLM∩Ranger AH intersection: +0.3% ROI, 2,106 bets, seasons 20-23.
Flat 10-unit stakes, 3% min edge filter, 2% costs + 1% slippage.

## Issues to address

### 1. xGK hardcoded intercepts (0.3 home, 0.1 away)

**Problem:** `plan_xgk.R` line 206-207 uses:
```r
lh <- max(0.3, exp(0.3 + ht_str$attack + at_str$defence))
la <- max(0.3, exp(0.1 + at_str$attack + ht_str$defence))
```
These 0.3/0.1 are league-average log-goals, hardcoded. Real values vary:
Bundesliga ~2.9 total goals, Ligue 1 ~2.4. Wrong intercepts shift all
lambdas, biasing score matrices.

**Fix:** Estimate per-league intercepts from training data:
```r
league_means <- matches |>
  filter(season <= "1920") |>
  group_by(league_code) |>
  summarise(
    mean_home = mean(log(pmax(fthg, 0.5))),
    mean_away = mean(log(pmax(ftag, 0.5)))
  )
```
Then look up per match: `exp(league_mean_home + attack + defence)`.

**Implementation:** Add `kalman_league_intercepts()` target, pass to
`xgk_predictions` and `xgk_ah_backtest`.

### 2. Kalman process noise σ=0.05 not tuned

**Problem:** σ_process controls how fast team strength can change.
Too low = strength frozen (ignores form). Too high = overreacts to noise.
0.05 was chosen by default, not estimated.

**Fix:** Maximum likelihood estimation on training data:
```r
# Grid search over sigma_process, sigma_obs
# Maximize log-likelihood: sum(log(P(observed_xG | Kalman_state)))
# The Kalman filter innovation variance S_t gives this directly
kalman_tune <- function(matches, sigma_process_grid, sigma_obs_grid) {
  # For each (sigma_p, sigma_o), run Kalman, compute sum of
  # log-likelihoods from the innovation sequence
}
```

**Implementation:** Add `kalman_tune()` to `R/model_kalman.R`, add
`kalman_best_params` target to `plan_xgk.R`.

### 3. AH market already integrates model information

**Problem:** By closing time, Pinnacle's AH line reflects all publicly
available information — including the kind of team strength estimates
our models produce. The model adds value only if it processes information
the market hasn't fully incorporated by close.

**No code fix for this.** This is a fundamental market efficiency issue.
Possible mitigations:
- Use opening odds (if available) instead of closing — market less efficient early
- Focus on leagues with lower AH liquidity (Tier 2) where prices may be less sharp
- Time the bet: compute edge against early-week lines, not closing

### 4. Kelly staking (from issue #82 comment)

**Problem:** Flat stakes ignore edge magnitude. A bet with 8% edge gets
the same stake as one with 3.1% edge.

**Fix:** Apply fractional Kelly:
```r
kelly_stake <- kelly_fraction(p_cover, odds_ahh, fraction = 0.25)
```
Already implemented in `R/kelly.R`. Wire into `ah_bets_from_preds()`.

**Variant:** Half-Kelly (fraction = 0.5) for moderate risk, quarter-Kelly
(0.25) for conservative.

**Implementation:** Add `kelly` parameter to `ah_bets_from_preds()`.
Compare flat vs Kelly on the intersection filter.

### 5. Expand AH backtest to 19-20 (available in train period)

**Problem:** Current AH backtests only cover 20-23 (OOS validate).
Season 19-20 has 3,698 AH odds but falls in the training period.
This means we can't use it for OOS evaluation of the GLM/ranger models
(they were trained on 19-20 data).

**Fix:** For the Kalman model specifically, we can use 19-20 as an
additional test period because:
- Kalman is online (no fixed train/validate split)
- Kalman strengths for 19-20 use only pre-match data
- The Kalman filter was not "trained" in the traditional sense

For GLM/ranger, we need a walk-forward approach: train on 15-19,
validate on 19-20 AH, then train on 15-20, validate on 20-23 AH.

### 6. brms posterior CI betting (independent model)

**Problem:** The intersection filter is binary — both agree or not.
brms gives a continuous confidence measure via posterior distributions.

**Approach:**
1. Fit brms on training data (already done: `oos_brms_train`)
2. For each AH match, draw 1000 posterior predictions of λ_home, λ_away
3. For each draw, compute P(cover) via DC score matrix
4. Get 95% CI on P(cover): [lower, upper]
5. Bet only when `lower_CI > implied_cover`

This is an independent competing model, not a replacement for the
intersection. Compare side-by-side.

**Implementation:** Add `brms_ah_ci_backtest` target to `plan_oos.R`.
Use `brms::posterior_predict()` for draws, then vectorised DC correction.

**Challenge:** 1000 draws × 3000 matches × DC matrix = ~3M matrix
computations. May need to reduce draws to 200 for speed.

## Implementation order

| Step | What | Difficulty | Impact |
|------|------|-----------|--------|
| 1 | Kelly staking on intersection | Easy | Better risk-adjusted returns |
| 2 | Per-league intercepts for xGK | Easy | May fix xGK AH from -5.8% |
| 3 | Kalman σ tuning | Medium | Better Kalman estimates |
| 4 | brms CI betting | Medium | Independent competing model |
| 5 | Walk-forward AH evaluation | Medium | More data for validation |
| 6 | Opening odds / timing | Hard | Requires data (#72) |
