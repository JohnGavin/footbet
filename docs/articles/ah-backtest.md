# AH Backtest: P&L, Drawdown & CLV

# AH Backtest: P&L, Drawdown & CLV

Walk-forward Asian Handicap evaluation across 4 models and 6 seasons

NoteOnline documentation

This vignette shows pre-computed results from the targets pipeline. All
data comes from walk-forward evaluation: models trained on seasons
1516–1920, rolled forward month-by-month through 2425.

## Summary

The Asian Handicap (AH) market is more interesting than 1X2 for model
evaluation because the vig is lower and the closing line is a precise
benchmark. Four models are compared: GLM (Poisson baseline), Ranger
(random forest), xG-Kalman-DC (xG + Kalman filter + Dixon-Coles
correction), and Intersection (bets where GLM and Ranger agree).

## Equity Curves

*Cumulative P&L for 4 AH models using flat £10 stakes across
~5,000–6,000 bets per model over 6 seasons (1920–2425). Blue = GLM
Poisson baseline; green = Ranger random forest; red = xG-Kalman-DC
(worst); orange = Intersection (GLM ∩ Ranger, best). The Intersection
model stays closest to zero throughout, consistent with -0.3% ROI. The
xGK model shows a sustained downtrend from season 2122 onward. Range
slider at bottom for zooming into specific periods. Source:
`ah_walkforward_all` target with walk-forward month-by-month
retraining.*

## Drawdown

*Underwater plot showing how far each model drops from its peak
cumulative P&L. The xGK model (red) reaches a maximum drawdown of £3,355
— the deepest sustained decline. Intersection (orange) has the
shallowest drawdown at £512, reflecting its conservative bet selection
(only bets where GLM and Ranger agree). GLM and Ranger show similar
drawdown profiles (~£1,300). Source: derived from `ah_walkforward_all`
cumulative P&L.*

## CLV Per League

Closing Line Value measures whether the model’s price at bet time beats
the closing line — a positive CLV means the model identifies prices that
move in its favour.

## Per-Season Breakdown

*ROI by model and season for flat-stake AH bets. Season 2223 is the only
period where GLM (+0.7%) and Intersection (+2.1%) show positive returns.
The xGK model (red) is consistently negative across all seasons. Ranger
shows high variance: +1.5% in 2223 but -5.2% in 2425. No model is
consistently profitable across all 6 seasons. Source:
`ah_walkforward_by_season` target.*

## Methodology

### Walk-Forward Setup

- **Training**: Expanding window starting from season 1516, retrained
  monthly
- **Testing**: Next month’s matches (out-of-sample)
- **Markets**: Asian Handicap -0.5 (equivalent to match winner with no
  draw)
- **Edge threshold**: Model probability \> devigged closing line
  probability + 3%
- **Staking**: Flat £10 per bet, or quarter-Kelly scaled by edge

### CLV Definition

\\\text{CLV} = \frac{P\_{\text{bet}}}{P\_{\text{close}}} - 1\\

Where \\P\_{\text{bet}}\\ is the model’s probability at bet time and
\\P\_{\text{close}}\\ is the devigged closing line probability. Positive
CLV means the model’s price moved in its favour — the market agreed with
the bet.

### Leakage Controls

All rolling features use `dplyr::lag()` to exclude the current match.
The 7-day as-of cutoff (`apply_asof_cutoff()`) ensures features are
available at bet decision time — see
[\#82](https://github.com/JohnGavin/footbet/issues/82) for the full
leakage analysis.

\[1\] “—\*footbet
**[0.1.0](https://github.com/JohnGavin/footbet/releases/tag/v0.1.0) \|**
Git
**[`5f9af31`](https://github.com/JohnGavin/footbet/commit/5f9af312e630dcbcab4c58bbd70bc6071fafbfac)
\|** R
**[4.5.2](https://cran.r-project.org/doc/manuals/r-release/NEWS.html)
\|** Built\*\* 2026-04-14 16:54:14”
