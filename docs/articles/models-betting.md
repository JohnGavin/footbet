# Models & Betting Strategy

Part 4 of the [footbet](https://johngavin.github.io/footbet/) analytics
guide. See also: [Data
Sources](https://johngavin.github.io/footbet/articles/data-sources.md)
\| [Data
Cleaning](https://johngavin.github.io/footbet/articles/data-cleaning.md)
\| [EDA](https://johngavin.github.io/footbet/articles/eda.md) \|
[Glossary](https://johngavin.github.io/footbet/articles/glossary.md)

## Cross-Validation

Football data is time-ordered, so standard k-fold CV would leak future
information. The pipeline uses **walk-forward** (expanding window)
splits:

- **Training window**: 24 months of historical matches
- **Test window**: 1 month of subsequent matches
- The window slides forward by 1 month for each fold

%%{init: {'theme': 'dark', 'themeVariables': {'background':
'#000000','primaryColor': '#999999','primaryTextColor':
'#000000','primaryBorderColor': '#CC0000','lineColor':
'#CC0000','secondaryColor': '#333333','tertiaryColor': '#333333'}}}%%
flowchart TB subgraph Fold1\[Fold 1\] T1\[Train: Months 1-24\] --\>
V1\[Test: Month 25\] end subgraph Fold2\[Fold 2\] T2\[Train: Months
1-25\] --\> V2\[Test: Month 26\] end subgraph FoldN\[Fold N\] TN\[Train:
Months 1 to N-1\] --\> VN\[Test: Month N\] end V1 -.-\> T2 V2 -.-\>
\|...\| TN V1 --\> Agg((Aggregate Metrics)) V2 --\> Agg VN --\> Agg
linkStyle default stroke:#CC0000,stroke-width:3px

Walk-forward cross-validation: 24-month rolling training window, 1-month
test. Each fold fits GLM and Dixon-Coles per league.

*Walk-forward cross-validation diagram. X-axis: time (months). Y-axis:
CV fold index. Blue shading = training window (24 months), orange
shading = test window (1 month). Each row represents one fold, with the
window sliding forward by one month. This design prevents future data
from leaking into model training — a critical requirement for
time-series prediction. Source:
[footbet](https://johngavin.github.io/footbet/) pipeline. See [Glossary
\>
Cross-Validation](https://johngavin.github.io/footbet/articles/glossary.md).*

### GLM Poisson

The baseline model is a [Poisson
regression](https://en.wikipedia.org/wiki/Poisson_regression) for goal
counts, following Maher (1982):

``` math
\text{goals}_{ij} \sim \text{Poisson}(\lambda_{ij})
```

``` math
\log(\lambda_{ij}) = \mu + \alpha_i + \beta_j + \gamma \cdot \mathbb{1}[\text{home}]
```

where $`\alpha_i`$ is team $`i`$’s attack strength, $`\beta_j`$ is team
$`j`$’s defence weakness, and $`\gamma`$ captures home advantage.

### Dixon-Coles

Dixon & Coles (1997) extend the Poisson model with:

1.  **Correlation correction**: A parameter $`\rho`$ adjusts the joint
    probability of low-scoring outcomes (0-0, 1-0, 0-1, 1-1)
2.  **Time-decay weights**: Recent matches receive higher weight via
    exponential decay ($`\xi = 0.003`$, ~1-year half-life)

### CV Metrics

Log-loss, Brier score, and RPS per CV fold for both models, with
Pinnacle as benchmark. All are **proper scoring rules** — lower is
better.

*Cross-validation scoring metrics by fold. X-axis: CV fold number.
Y-axis: metric value (lower = better). Lines: GLM Poisson (blue),
Dixon-Coles (orange), Pinnacle benchmark (grey dashed). Three panels
show log-loss, Brier score, and RPS respectively. Dixon-Coles slightly
outperforms GLM on most folds, but both trail Pinnacle closing odds.
Pinnacle’s sharp market remains the hardest benchmark to beat. Source:
walk-forward CV on
[football-data.co.uk](https://www.football-data.co.uk/) match data. See
[Glossary \> Performance
Metrics](https://johngavin.github.io/footbet/articles/glossary.md).*

    # A tibble: 1 × 5
      mean_glm_logloss mean_dc_logloss mean_diff n_folds conclusion
                 <dbl>           <dbl>     <dbl>   <int> <chr>
    1             1.07            1.07   -0.0028     776 Models perform similarly

*Statistical comparison of model performance. Columns: model name, mean
metric, confidence interval, p-value. This table tests whether
Dixon-Coles significantly outperforms GLM Poisson on log-loss. While
Dixon-Coles shows a small improvement, the difference is often not
statistically significant. Neither model consistently beats the Pinnacle
closing line. Source: paired t-test across CV folds using
[football-data.co.uk](https://www.football-data.co.uk/) data. See
[Glossary \> Log
Loss](https://johngavin.github.io/footbet/articles/glossary.md).*

> **Note**
>
> **Key Finding:** Dixon-Coles slightly outperforms GLM. Both models
> trail Pinnacle on most folds.

### Model Comparison

*Summary model comparison table. Columns: model
(GLM/Dixon-Coles/Pinnacle), mean log-loss, mean Brier score, mean RPS,
edge vs Pinnacle (%). Lower scoring metrics indicate better calibration.
Positive edge means the model outperforms Pinnacle on average.
Dixon-Coles achieves the lowest log-loss among the fitted models. The
edge column quantifies how close each model comes to the sharp-market
benchmark. Source: aggregated CV results from
[football-data.co.uk](https://www.football-data.co.uk/). See [Glossary
\> Performance
Metrics](https://johngavin.github.io/footbet/articles/glossary.md).*

## Betting Strategy

### Value Bets

A **value bet** exists when the model’s estimated probability exceeds
the market’s implied probability by a minimum edge threshold:

- **Minimum edge**: 3% (model_prob - market_prob \> 0.03)
- **Odds filter**: Only bets between 1.50 and 10.00 decimal odds
- **Devigged odds**: Market probabilities via Shin (1993) method

*Value bet summary table. Columns: league code, outcome (H/D/A), number
of value bets identified, mean edge (%), hit rate (%), ROI (%). Edge =
model probability minus Shin-devigged market probability. Home value
bets tend to be more frequent; draw value bets show the highest mean
edge but lowest hit rate. Away value bets are rarest due to lower model
confidence. Source: Dixon-Coles model applied to
[football-data.co.uk](https://www.football-data.co.uk/) with Pinnacle
odds. See [Glossary \> Value
Bet](https://johngavin.github.io/footbet/articles/glossary.md) and
[Glossary \>
Edge](https://johngavin.github.io/footbet/articles/glossary.md).*

### Edge Distribution

*Distribution of betting edges across all identified value bets. X-axis:
edge size (%, model probability minus market probability). Y-axis:
frequency count. The histogram shows most edges cluster between 3-8%,
with a long right tail. Edges above 15% are rare and may indicate model
mis-specification rather than genuine value. The 3% minimum threshold
filters out noise. Source: Dixon-Coles predictions vs Pinnacle devigged
odds from [football-data.co.uk](https://www.football-data.co.uk/). See
[Glossary \>
Edge](https://johngavin.github.io/footbet/articles/glossary.md) and
[Glossary \> Fair
Odds](https://johngavin.github.io/footbet/articles/glossary.md).*

> **Note**
>
> **Key Finding:** Most edges cluster at 3-8%. Large edges (\>15%) are
> rare and may signal model error.

### Kelly Staking

The pipeline uses **quarter Kelly** staking with guardrails:

``` math
f^* = \frac{1}{4} \cdot \frac{p \cdot (b + 1) - 1}{b}
```

- **Max stake**: 3% of current bankroll per bet
- **Drawdown halt**: Stakes halved when bankroll drops 20% from peak

%%{init: {'theme': 'dark', 'themeVariables': {'background':
'#000000','primaryColor': '#999999','primaryTextColor':
'#000000','primaryBorderColor': '#CC0000','lineColor':
'#CC0000','secondaryColor': '#333333','tertiaryColor': '#333333'}}}%%
flowchart TD Input\[Model Prob + Odds\] --\> Edge\[Calculate Edge\] Edge
--\> Check{{Edge \> 3%?}} Check --\>\|No\| NoBet\[No Bet\] Check
--\>\|Yes\| Kelly\[Calculate Kelly f\*\] Kelly --\> Frac\[Apply 0.25
Kelly\] Frac --\> Max{{Stake \> 3%?}} Max --\>\|Yes\| Cap\[Cap at 3%\]
Max --\>\|No\| DD Cap --\> DD{{Drawdown \> 20%?}} DD --\>\|Yes\|
Halve\[Halve Stake\] DD --\>\|No\| Final\[Final Stake\] Halve --\> Final
linkStyle default stroke:#CC0000,stroke-width:3px

Kelly staking decision tree: edge ≥ 3% and odds 1.50–10.00 triggers
quarter-Kelly stake with 3% max and 20% drawdown halt.

*Kelly criterion staking flowchart. The diagram shows the decision tree:
compute full Kelly fraction, apply quarter-Kelly scaling, cap at 3% of
bankroll, then check the drawdown guard (if bankroll is 20%+ below peak,
halve the stake). This risk management pipeline prevents catastrophic
losses from model error while still exploiting value bets. Source:
[footbet](https://johngavin.github.io/footbet/) staking module. See
[Glossary \> Kelly
Criterion](https://johngavin.github.io/footbet/articles/glossary.md).*

*Distribution of Kelly stake sizes. X-axis: stake as percentage of
bankroll. Y-axis: frequency count. Most stakes fall between 0.5-2% of
bankroll due to the quarter-Kelly scaling and 3% cap. The distribution
is right-skewed, with very few bets reaching the 3% maximum. Smaller
stakes correspond to lower-edge bets. Source: simulated staking on
[football-data.co.uk](https://www.football-data.co.uk/) value bets. See
[Glossary \> Kelly
Criterion](https://johngavin.github.io/footbet/articles/glossary.md) and
[Glossary \>
Edge](https://johngavin.github.io/footbet/articles/glossary.md).*

## P&L

### P&L Simulation

The bankroll curve below shows the simulated profit & loss trajectory
for all GLM value bets, staked with quarter Kelly and drawdown
guardrails.

*Bankroll comparison: optimistic vs realistic. Blue dotted line =
optimistic (no transaction costs, quarter-Kelly compounding). Orange
solid line = realistic (2% transaction cost, 1% odds slippage, tiered
stakes £5-25 based on predicted edge). Edge tiers: \<3% → £5, 3-5% →
£10, 5-8% → £15, 8-12% → £20, \>12% → £25. Y-axis: log scale. The
optimistic scenario shows compound growth from 1,000 to millions — a
backtest artefact. The realistic scenario accounts for the bookmaker’s
spread and uses edge-proportional staking: higher-confidence bets get
larger stakes. Source: GLM value bets on
[football-data.co.uk](https://www.football-data.co.uk/). See [Glossary
\> Kelly
Criterion](https://johngavin.github.io/footbet/articles/glossary.md) and
[issue \#66](https://github.com/JohnGavin/footbet/issues/66).*

### Drawdown

*Drawdown over time. X-axis: date. Y-axis: drawdown percentage (0% = at
peak, negative = below peak). Red shading = drawdown depth. The deepest
trough represents the maximum drawdown — worst-case loss from peak
bankroll. Source: quarter-Kelly P&L simulation on
[football-data.co.uk](https://www.football-data.co.uk/) data. See
[Glossary \> Maximum
Drawdown](https://johngavin.github.io/footbet/articles/glossary.md).*

> **Warning**
>
> **Caveat:** The optimistic scenario (no costs, Kelly compounding)
> produces unrealistic returns. Real-world constraints include: 2-4%
> transaction costs (Pinnacle spread), account limits on profitable
> bettors, odds slippage, and backtesting bias. See [issue
> \#66](https://github.com/JohnGavin/footbet/issues/66).

### Summary

*P&L comparison table. See [issue
\#66](https://github.com/JohnGavin/footbet/issues/66) for assumptions.*

## Out-of-Sample Evaluation

The in-sample results above are misleading because the model was
developed by looking at the full dataset. A true test requires fitting
the model on PAST data only and evaluating on FUTURE data it has never
seen.

**Design:** Train on 2015-2020 (5 seasons), evaluate on 2021-2023
(validate period). The test period (2024-2026) is reserved for a final
one-shot evaluation ([issue
\#67](https://github.com/JohnGavin/footbet/issues/67)).

*Out-of-sample comparison using flat £10 stakes with 2% transaction cost
and 1% slippage. The model finds value bets at 30% win rate (similar to
in-sample), but the ROI is -9.3% out-of-sample vs +422% in-sample. The
edge from the model (~5-10%) is consumed by the bookmaker’s margin
(~2-4%) plus slippage.*

### Out-of-Sample by League

*Out-of-sample ROI by league. E0 (Premier League) is closest to
breakeven at -2.1%, while I2 (Serie B) is worst at -20.1%. No league is
profitable after costs. Top 5 and 2nd Tier leagues show similar
patterns. The variation in ROI across leagues suggests league-specific
models or features might improve performance, but the fundamental
barrier is the Pinnacle spread. See [issue
\#67](https://github.com/JohnGavin/footbet/issues/67) for the
test-period evaluation and [issue
\#43](https://github.com/JohnGavin/footbet/issues/43) for copula model
investigation.*

## xG Calibration (#84)

Rolling xG features improve 1X2 calibration by ~7% log-loss over a
goals-only GLM baseline in walk-forward CV. This improvement survives
the 7-day bet-time cutoff leakage correction unchanged (cut7 vs cut0
Brier differs by 0.001). The effect is real, not a leakage artefact.

### Per-League xG Improvement

\[MISSING EVIDENCE\] Target \`vig_xg_per_league\` not found.

### GLM vs Dixon-Coles vs GLM+xG

\[MISSING EVIDENCE\] Target \`vig_dc_vs_glm_xg\` not found.

*xG features make average predictions better calibrated (real,
measurable), but this calibration improvement does not translate to
profitable per-match AH bet selection. The closing Pinnacle line has
already absorbed what xG knows; the model cannot outbid it by enough to
clear vig. See [issue
\#84](https://github.com/JohnGavin/footbet/issues/84) for the full
analysis.*

### Market Baselines (Pinnacle vs Consensus)

\[MISSING EVIDENCE\] Target \`vig_market_baselines\` not found.

## Model Leaderboard

All models evaluated in footbet, ranked by market and performance. 1X2
models are scored on calibration (log-loss, Brier, RPS). AH models are
scored on walk-forward P&L (ROI%, Sharpe, max drawdown). See also the
[AH Backtest
vignette](https://johngavin.github.io/footbet/articles/ah-backtest.md)
for equity curves and per-season detail.

*Cross-model comparison table. Columns: model name, market (1X2 or AH),
ROI% (AH only), number of bets (AH) or CV folds (1X2), Sharpe ratio,
maximum drawdown, log-loss, Brier score, RPS. 1X2 calibration: brms
hierarchical achieves the best log-loss (1.03) among fitted models, but
all trail Pinnacle closing (1.01). AH P&L: GLM-Ranger intersection is
least bad at +0.3% ROI over 2,106 bets. No systematic edge exists
against Pinnacle. Source: walk-forward CV and AH backtest from
[football-data.co.uk](https://www.football-data.co.uk/). See
[MODEL_CATALOGUE.md](https://github.com/JohnGavin/footbet/blob/main/plans/MODEL_CATALOGUE.md)
for full details.*

\[1\] “—\*footbet
**[0.1.0](https://github.com/JohnGavin/footbet/releases/tag/v0.1.0) \|**
Git
**[`5f9af31`](https://github.com/JohnGavin/footbet/commit/5f9af312e630dcbcab4c58bbd70bc6071fafbfac)
\|** R
**[4.5.2](https://cran.r-project.org/doc/manuals/r-release/NEWS.html)
\|** Built\*\* 2026-04-14 16:54:14”
