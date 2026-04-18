# Glossary

This glossary defines betting and statistical terms used throughout the
[footbet](https://johngavin.github.io/footbet/) package. See also: [Data
Sources](https://johngavin.github.io/footbet/articles/data-sources.md)
\| [Data
Cleaning](https://johngavin.github.io/footbet/articles/data-cleaning.md)
\| [EDA](https://johngavin.github.io/footbet/articles/eda.md) \| [Models
&
Betting](https://johngavin.github.io/footbet/articles/models-betting.md)

## Odds Formats

**Decimal:** Total payout per unit staked (e.g., 2.50 = 1.50 profit +
1.00 stake). Standard in Europe.

**Fractional:** Profit relative to stake (e.g., 3/2 = 3 units profit per
2 staked). UK format.

**American:** Positive = profit on 100 stake (+150 = 150 profit).
Negative = stake to win 100 (-200 = bet 200 to win 100).

| Format         | Example                | Implied Probability   |
|----------------|------------------------|-----------------------|
| Decimal 2.50   | Win 2.50 per 1 staked  | 40% (1/2.50)          |
| Fractional 3/2 | Win 3 per 2 staked     | 40% (2/(2+3))         |
| American +150  | Win 150 per 100 staked | 40% (100/(100+150))   |
| American -200  | Stake 200 to win 100   | 66.7% (200/(200+100)) |

## Market Types

- **1X2 (Match Result):** Home win (H), Draw (D), Away win (A)
- **Over/Under (O/U):** Total goals vs a line (usually 2.5)
- **Asian Handicap (AH):** Handicap eliminating the draw outcome
- **BTTS:** Both teams to score (yes/no)

## Probability Concepts

- **Implied Probability:** `1 / odds`. For 2.50 odds = 40%.
- **Overround (Vig):** Bookmaker margin. Sum of implied probs minus
  100%.
- **Fair Odds:** After removing overround. Methods: multiplicative,
  power, Shin.
- **Closing Line Value (CLV):** Your odds vs closing odds. See
  [`closing_line_value()`](https://johngavin.github.io/footbet/reference/closing_line_value.md).

## Performance Metrics

- **Log Loss:** $`-\frac{1}{n} \sum \log(p_i)`$ — penalizes confident
  wrong predictions
- **Brier Score:** $`\frac{1}{n} \sum (p_i - o_i)^2`$ — MSE for
  probabilities
- **RPS:** Ranked probability score for ordered outcomes (H \> D \> A)
- **ROI:** Total profit / total staked (%)
- **Sharpe Ratio:** Risk-adjusted return. See
  [`betting_sharpe_ratio()`](https://johngavin.github.io/footbet/reference/betting_sharpe_ratio.md).
- **Maximum Drawdown:** Largest peak-to-trough decline

## Statistical Models

- **Poisson Regression:** Goals ~ Poisson(lambda) with team
  attack/defense parameters
- **Dixon-Coles:** Poisson + correlation correction for low-scoring
  outcomes + time decay
- **Expected Goals (xG):** Shot-level goal probability, better predictor
  than actual goals
- **Elo Rating:** Match-by-match team strength. See
  [`compute_elo()`](https://johngavin.github.io/footbet/reference/compute_elo.md)
  with COOPER enhancements (dynamic K, margin weighting, league
  reversion, asymmetric wins)

### Copula Models

A [copula](https://en.wikipedia.org/wiki/Copula_(probability_theory))
models the dependence structure between home and away goals separately
from their marginal distributions. This is important because:

1.  **Independent Poisson underpredicts 0-0 draws.** The observed
    frequency of 0-0 is ~7%, but independent Poisson(1.5) × Poisson(1.2)
    predicts ~5%. This excess clustering at (0,0) indicates positive
    lower-tail dependence.

2.  **Home advantage creates asymmetry.** More mass below the diagonal
    (home \> away) than above, violating exchangeability assumed by
    symmetric copulas.

**Candidate copulas for football scorelines:**

- **[Frank
  copula](https://en.wikipedia.org/wiki/Copula_(probability_theory)#Most_important_Archimedean_copulas):**
  Single parameter $`\theta`$ controlling concordance. Symmetric
  dependence, captures the general positive association between
  low-scoring outcomes. $`\theta > 0`$ means low home goals tend to
  coincide with low away goals.

- **[Clayton copula](https://en.wikipedia.org/wiki/Clayton_copula):**
  Parameter $`\alpha > 0`$ gives strong lower-tail dependence — high
  probability of both teams scoring zero or one goal simultaneously.
  This directly models the excess 0-0 and 1-1 scorelines that
  Dixon-Coles corrects via its $`\rho`$ parameter.

**Parameterisation for football data:**

``` math
C(u, v; \theta) = \left(u^{-\theta} + v^{-\theta} - 1\right)^{-1/\theta}
```

where $`u = F_H(h)`$ and $`v = F_A(a)`$ are the marginal Poisson CDFs
for home and away goals, and $`\theta`$ is estimated from the observed
scoreline frequencies. The Dixon-Coles $`\rho`$ parameter is effectively
a discrete approximation to this copula at the (0,0), (1,0), (0,1),
(1,1) cells.

See [issue \#43](https://github.com/JohnGavin/footbet/issues/43) for the
planned copula investigation and [McHale & Scarf
(2011)](https://doi.org/10.1111/j.1467-9876.2011.00782.x) for
copula-based football models.

## Betting Strategy

- **Kelly Criterion:** $`f^* = \frac{p \cdot b - q}{b}`$ — optimal bet
  sizing
- **Value Bet:** Model probability exceeds market implied probability
- **Edge:** $`p \times (o-1) - (1-p)`$ — expected profit per unit staked
- **Sharp Bookmaker:** Accurate odds (Pinnacle). **Soft Bookmaker:**
  Less accurate, slower to adjust.

## Data Terminology

- **FTR:** Full Time Result (H/D/A)
- **FTHG / FTAG:** Full Time Home/Away Goals
- **HTHG / HTAG / HTR:** Half Time Home/Away Goals / Result

### Match Statistics

- **HS/AS:** Home/Away Shots
- **HST/AST:** Home/Away Shots on Target
- **HC/AC:** Home/Away Corners
- **HF/AF:** Home/Away Fouls
- **HY/AY:** Home/Away Yellow Cards
- **HR/AR:** Home/Away Red Cards

## References

**Package functions:**
[`?target_leagues`](https://johngavin.github.io/footbet/reference/target_leagues.md),
[`?parse_fd_csv`](https://johngavin.github.io/footbet/reference/parse_fd_csv.md),
[`?devig_shin`](https://johngavin.github.io/footbet/reference/devig_shin.md),
[`?fit_dixon_coles`](https://johngavin.github.io/footbet/reference/fit_dixon_coles.md),
`?kelly_stake`,
[`?closing_line_value`](https://johngavin.github.io/footbet/reference/closing_line_value.md),
[`?betting_sharpe_ratio`](https://johngavin.github.io/footbet/reference/betting_sharpe_ratio.md)

**External:** [football-data.co.uk](https://www.football-data.co.uk/) \|
[Pinnacle](https://www.pinnacle.com/) \| [Dixon & Coles
(1997)](https://doi.org/10.1111/1467-9876.00065) \|
[goalmodel](https://cran.r-project.org/package=goalmodel)

\[1\] “—\*footbet
**[0.1.0](https://github.com/JohnGavin/footbet/releases/tag/v0.1.0) \|**
Git
**[`5f9af31`](https://github.com/JohnGavin/footbet/commit/5f9af312e630dcbcab4c58bbd70bc6071fafbfac)
\|** R
**[4.5.2](https://cran.r-project.org/doc/manuals/r-release/NEWS.html)
\|** Built\*\* 2026-04-14 16:54:14”
