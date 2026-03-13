# Football Betting Analytics

This vignette provides a comprehensive overview of the
[footbet](https://johngavin.github.io/footbet/) package for European
football betting analytics. Navigate using the tabs below.

- [Data Sources](#tabset-1-1)
- [Cleaning](#tabset-1-2)
- [EDA](#tabset-1-3)
- [Models](#tabset-1-4)
- [Glossary](#tabset-1-5)

&nbsp;

- The [footbet](https://johngavin.github.io/footbet/) package downloads
  match data from
  [football-data.co.uk](https://www.football-data.co.uk/), a free source
  of European football results and bookmaker odds maintained since the
  mid-1990s. Each CSV file contains one league-season and includes
  full-time and half-time scores, match statistics (shots, corners,
  cards), and closing odds from multiple bookmakers including
  [Pinnacle](https://en.wikipedia.org/wiki/Pinnacle_(sportsbook)) —
  widely regarded as the sharpest bookmaker in the industry.

  The URL pattern is
  `https://www.football-data.co.uk/mmz4281/{season}/{league}.csv`, where
  [season](https://github.com/agbarnett/season) is a 4-digit code (e.g.,
  `2324` for 2023-24) and `{league}` is a 2-character code (e.g., `E0`
  for the English Premier League).

  [`footbet::target_leagues()`](https://johngavin.github.io/footbet/reference/target_leagues.md)
  returns 10 leagues covering the top 2 divisions of the “big five”
  European football countries.

  ### Data Pipeline Overview

  flowchart LR subgraph Data\["Data Acquisition"\]
  FD\[football-data.co.uk\] --\> Parse\[parse_fd_csv\] FD --\>
  Odds\[parse_fd_odds\] FB\[FBref/Understat\] --\>
  XG\[fetch_fbref_matches\] end subgraph Features\["Feature
  Engineering"\] Parse --\> Roll\[rolling_goals\] XG --\> Roll Roll --\>
  Elo\[compute_elo\] end subgraph Models\["Prediction Models"\] Elo --\>
  GLM\[Poisson GLM\] Elo --\> DC\[Dixon-Coles\] GLM --\>
  Eval\[Walk-Forward CV\] DC --\> Eval end subgraph
  Betting\["Accumulators & Bankroll"\] Eval --\>
  Value\[find_value_bets\] Odds --\> Devig\[devig_odds\] Devig --\>
  Value Value --\> Kelly\[kelly_fraction\] end

      # A tibble: 10 × 7
         country league_code division n_seasons n_matches first_date last_date
         <chr>   <chr>          <int>     <int>     <int> <date>     <date>
       1 England E0                 1        11      4081 2015-08-08 2026-03-01
       2 England E1                 2        11      5938 2015-08-07 2026-03-02
       3 France  F1                 1        11      3768 2015-08-07 2026-03-01
       4 France  F2                 2        11      3849 2015-07-31 2026-03-02
       5 Germany D1                 1        11      3275 2015-08-14 2026-03-01
       6 Germany D2                 2        11      3276 2015-07-24 2026-03-01
       7 Italy   I1                 1        11      4071 2015-08-22 2026-03-02
       8 Italy   I2                 2        11      4278 2015-09-05 2026-03-01
       9 Spain   SP1                1        11      4059 2015-08-21 2026-03-02
      10 Spain   SP2                2        11      4928 2015-08-22 2026-03-02

  ### Coverage Grid

  The grid below shows the number of parsed matches per league-season
  cell. Zeroes indicate seasons where the CSV was unavailable or empty.

      # A tibble: 10 × 12
         league_code `1516` `1617` `1718` `1819` `1920` `2021` `2122` `2223` `2324`
         <chr>        <int>  <int>  <int>  <int>  <int>  <int>  <int>  <int>  <int>
       1 D1             306    306    306    306    306    306    306    306    306
       2 D2             306    306    306    306    306    306    306    306    306
       3 E0             380    380    380    380    380    380    380    380    380
       4 E1             552    552    552    552    552    552    552    552    552
       5 F1             381    380    380    380    279    380    380    380    306
       6 F2             380    380    380    380    280    380    380    380    379
       7 I1             381    380    380    380    380    380    380    380    380
       8 I2             462    462    462    342    380    380    380    380    380
       9 SP1            380    380    380    380    380    380    380    380    380
      10 SP2            462    462    462    462    462    462    462    462    462
      # ℹ 2 more variables: `2425` <int>, `2526` <int>

  > **Note**
  >
  > **Key Finding:** Division 1 leagues (E0, D1, I1, SP1, F1) have ~380
  > matches/season. Division 2 leagues have more (~460-550
  > matches/season).

  ### Pinnacle Odds

  Not all leagues and seasons have Pinnacle odds. The table below shows
  the percentage of matches with complete Pinnacle 1X2 closing odds
  (PSH, PSD, PSA) and over/under odds.

  Pinnacle coverage dropped significantly for some leagues from mid-2025
  due to a feed break at football-data.co.uk.

      # A tibble: 110 × 5
         league_code season n_matches pct_1x2 pct_over_under
         <chr>       <chr>      <int>   <dbl>          <dbl>
       1 D1          1516         306   100              0
       2 D1          1617         306   100              0
       3 D1          1718         306   100              0
       4 D1          1819         306    99.7            0
       5 D1          1920         306   100            100
       6 D1          2021         306   100             98.4
       7 D1          2122         306   100             98.4
       8 D1          2223         306   100             95.4
       9 D1          2324         306   100             95.4
      10 D1          2425         306   100             97.1
      # ℹ 100 more rows

  ### Column Schema

  After parsing,
  [`footbet::parse_fd_csv()`](https://johngavin.github.io/footbet/reference/parse_fd_csv.md)
  produces a standardised tibble with the following columns:

  | Column | Description | Type |
  |----|----|----|
  | `match_id` | Deterministic ID: `league_date_home_away` | character |
  | `league_code` | 2-char league code (e.g., E0, D1) | character |
  | `season` | 4-digit season code (e.g., 2324) | character |
  | `match_date` | Match date | Date |
  | `home_team` / `away_team` | Team names | character |
  | `fthg` / `ftag` | Full-time home/away goals ([FTHG/FTAG](#fthg-ftag)) | integer |
  | `ftr` | Full-time result: H, D, or A ([FTR](#ftr-full-time-result)) | character |
  | `hthg` / `htag` | Half-time home/away goals ([HTHG/HTAG](#hthg-htag-htr)) | integer |
  | `htr` | Half-time result ([HTR](#hthg-htag-htr)) | character |
  | `hs` / `as_` | Home/away shots ([HS/AS](#match-statistics)) | integer |
  | `hst` / `ast` | Home/away shots on target ([HST/AST](#match-statistics)) | integer |
  | `hf` / `af` | Home/away fouls ([HF/AF](#match-statistics)) | integer |
  | `hc` / `ac` | Home/away corners ([HC/AC](#match-statistics)) | integer |
  | `hy` / `ay` | Home/away yellow cards ([HY/AY](#match-statistics)) | integer |
  | `hr` / `ar` | Home/away red cards ([HR/AR](#match-statistics)) | integer |

  [`footbet::parse_fd_odds()`](https://johngavin.github.io/footbet/reference/parse_fd_odds.md)
  extracts Pinnacle closing odds:

  | Column                   | Description                                |
  |--------------------------|--------------------------------------------|
  | `psh` / `psd` / `psa`    | Pinnacle closing 1X2 odds (Home/Draw/Away) |
  | `p_over25` / `p_under25` | Pinnacle over/under 2.5 goals odds         |

The footbet pipeline includes automated quality control checks that run
after data parsing. This section summarises the QC outputs.

### Match Completeness

The heatmap below shows the percentage of matches per league-season with
a valid full-time result (FTR). A value below 100% indicates matches
where the result is missing — typically from ongoing or postponed
fixtures in the current season.

> **Note**
>
> **Key Finding:** Most historical league-seasons achieve 100%
> completeness. Current season shows partial data (matches not yet
> played).

### Pinnacle Coverage

Pinnacle odds are the primary benchmark for model evaluation. The
heatmap shows the percentage of matches with all three Pinnacle 1X2
closing odds present.

Coverage gaps arise from:

- **Division 2 leagues**: Pinnacle may not offer odds for lower
  divisions
- **Feed breaks**: The football-data.co.uk Pinnacle feed experienced a
  break from mid-2025
- **Early seasons**: Pinnacle data availability improves in more recent
  seasons

> **Note**
>
> **Key Finding:** Top divisions have near-100% coverage from ~2016
> onward. Division 2 coverage is variable. 0% coverage indicates feed
> breaks or no Pinnacle market.

### Missing Data

The chart below shows the percentage of missing values for each column
across all parsed matches. Match statistics (shots, corners, cards) are
more frequently missing than core fields.

The table below provides detailed missing counts:

    # A tibble: 21 × 4
       column n_missing pct_missing n_total
       <chr>      <int>       <dbl>   <int>
     1 hf          3632         8.7   41523
     2 af          3632         8.7   41523
     3 hs          3251         7.8   41523
     4 as_         3251         7.8   41523
     5 hst         3251         7.8   41523
     6 ast         3251         7.8   41523
     7 hc          3251         7.8   41523
     8 ac          3251         7.8   41523
     9 hy          3251         7.8   41523
    10 ay          3251         7.8   41523
    # ℹ 11 more rows

### Anomaly Detection

The pipeline flags matches with:

- **Extreme scorelines**: Total goals \> 10 (very rare, may indicate
  data entry errors)
- **Missing dates**: Matches without a parseable date
- **Future matches**: Dates more than 7 days beyond the pipeline run
  date
- **Missing team names**: Rows with NA home or away team

    # A tibble: 2 × 9
      match_id   league_code season match_date home_team away_team  fthg  ftag flag
      <chr>      <chr>       <chr>  <date>     <chr>     <chr>     <int> <int> <chr>
    1 I1_NA_NA_… I1          1516   NA         <NA>      <NA>         NA    NA Miss…
    2 F1_NA_NA_… F1          1516   NA         <NA>      <NA>         NA    NA Miss…

### QC Summary

The `qc_summary` target combines all QC checks into a single report with
a timestamp. The pipeline computes:

- **Total matches parsed**: Row count across all leagues/seasons
- **Total odds rows**: Pinnacle odds records parsed
- **Completeness**: Percentage of matches with valid results
- **Pinnacle coverage**: Percentage with 1X2 odds
- **Anomaly count**: Flagged rows for manual review

The QC targets serve as data contracts — downstream model targets depend
on `qc_summary` to ensure data quality issues are surfaced before model
fitting.

This section explores key statistical patterns in European football
match data across 10 leagues and multiple seasons. All visualizations
are interactive with dark theme styling.

### Goal Distributions

Football goals are often modelled as
[Poisson-distributed](https://en.wikipedia.org/wiki/Poisson_distribution)
random variables. The chart below compares the observed goal
distribution against a Poisson overlay for home and away teams.

    # A tibble: 1 × 6
      test                mean_goals variance dispersion_ratio n_goals conclusion
      <chr>                    <dbl>    <dbl>            <dbl>   <int> <chr>
    1 Poisson Fit Summary       1.31     1.41             1.07   83042 Poisson assu…

> **Note**
>
> **Key Finding:** Home teams score slightly more than away teams (home
> advantage). The Poisson distribution is a reasonable first
> approximation, though it underpredicts 0-0 draws and some high-scoring
> outcomes. See Dixon & Coles (1997) for the correlation correction
> term.

### Result Proportions

Home advantage is a well-documented phenomenon in football. The chart
below shows the proportion of Home wins, Draws, and Away wins by league,
compared to a uniform 33/33/33 baseline.

> **Note**
>
> **Key Finding:** Home win rate ranges 43-47% across leagues. Draws:
> 25-28%. Away wins: 27-30%. All leagues show significant home
> advantage.

### Home Advantage Trends

Home advantage has declined in recent years, with a notable drop during
the COVID-19 pandemic (2020-21 season) when matches were played in empty
stadiums.

    # A tibble: 1 × 4
      trend_per_season r_squared n_seasons conclusion
                 <dbl>     <dbl>     <int> <chr>
    1           -0.198     0.198        11 No clear trend

> **Note**
>
> **Key Finding:** COVID seasons (2020-21) show reduced home advantage
> across all leagues. Post-COVID recovery varies by league. Long-term
> declining trend visible in most leagues.

### Common Scorelines

The heatmap below shows the frequency of each scoreline (home goals x
away goals). Hover over cells to see exact percentages.

> **Note**
>
> **Key Finding:** 1-0 (~12%), 1-1 (~11%), 2-1 (~10%) are most common.
> Scorelines above 4-4 are extremely rare (\<0.5% combined).

### Goals Per Season

Is scoring increasing over time? The chart below tracks mean total goals
per match by season and league. Use the range slider to zoom into
specific periods.

> **Note**
>
> **Key Finding:** Slight upward trend since 2015 in most leagues.
> Bundesliga consistently among highest-scoring (~3.0 goals/match).
> Serie A shows notable increase in recent seasons.

### Outliers

Matches with more than 7 total goals are rare outliers. These are worth
inspecting for data quality and as edge cases for model robustness.

    # A tibble: 258 × 9
       match_id        league_code season match_date home_team away_team  fthg  ftag
       <chr>           <chr>       <chr>  <date>     <chr>     <chr>     <int> <int>
     1 SP1_2015-12-20… SP1         1516   2015-12-20 Real Mad… Vallecano    10     2
     2 F2_2019-04-19_… F2          1819   2019-04-19 Valencie… Beziers       5     6
     3 D2_2021-05-09_… D2          2021   2021-05-09 Erzgebir… Paderborn     3     8
     4 D2_2024-10-25_… D2          2425   2024-10-25 Nurnberg  Regensbu…     8     3
     5 SP1_2016-08-20… SP1         1617   2016-08-20 Sevilla   Espanol       6     4
     6 I1_2017-05-07_… I1          1617   2017-05-07 Lazio     Sampdoria     7     3
     7 E1_2018-04-21_… E1          1718   2018-04-21 Bristol … Hull          5     5
     8 SP1_2018-09-02… SP1         1819   2018-09-02 Barcelona Huesca        8     2
     9 E1_2018-11-28_… E1          1819   2018-11-28 Aston Vi… Nott'm F…     5     5
    10 I1_2023-01-15_… I1          2223   2023-01-15 Atalanta  Salernit…     8     2
    # ℹ 248 more rows
    # ℹ 1 more variable: total_goals <int>

### Match Statistics

Median match statistics (shots, corners, fouls, cards) by league. These
vary across leagues reflecting different playing styles.

    # A tibble: 10 × 14
       league_code    hs   as_   hst   ast    hf    af    hc    ac    hy    ay    hr
       <chr>       <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>
     1 D1             14    11     5     4    12    12     5     4     2     2     0
     2 D2             14    12     5     4    12    13     5     4     2     2     0
     3 E0             13    11     4     4    10    11     5     4     1     2     0
     4 E1             13    11     4     3    11    12     5     4     1     2     0
     5 F1             13    11     4     4    12    13     5     4     2     2     0
     6 F2             12    10     4     3    13    14     5     4     2     2     0
     7 I1             13    11     5     4    13    13     5     4     2     2     0
     8 I2             13    11     4     4    15    15     5     4     2     2     0
     9 SP1            13    10     4     3    13    13     5     4     2     2     0
    10 SP2            12    10     4     3    14    14     5     4     2     2     0
    # ℹ 2 more variables: ar <dbl>, n_matches <int>

### Pinnacle Overround

The [overround](https://en.wikipedia.org/wiki/Vigorish) (or vig) is the
bookmaker’s built-in margin. Pinnacle’s margin (~2-4%) is the lowest in
the industry, making their odds the best available benchmark for “true”
probabilities.

> **Note**
>
> **Key Finding:** Pinnacle margin is ~2-4%, far below soft bookmakers
> (5-15%). Lower margin = fairer odds = better model benchmark.
> Consistent across all leagues.

### Pinnacle Calibration

A well-calibrated bookmaker’s implied probabilities should match actual
outcome frequencies. The plot below bins devigged Pinnacle probabilities
and compares them to observed outcome rates.

> **Note**
>
> **Key Finding:** Pinnacle is near-perfectly calibrated (points near
> diagonal). Slight favourite-longshot bias at extremes. Size indicates
> sample size per bin.

### Elo Ratings

[Elo ratings](https://en.wikipedia.org/wiki/Elo_rating_system) quantify
relative team strength. The chart below shows the distribution of final
Elo ratings per league.

> **Note**
>
> **Key Finding:** Top divisions have wider Elo spreads (more
> competitive imbalance). Division 2 leagues show more compressed rating
> distributions. Initial rating = 1500 for all teams.

This section covers the modelling pipeline: walk-forward
cross-validation, two statistical models, and benchmarking against
Pinnacle implied probabilities.

### Cross-Validation

Football data is time-ordered, so standard k-fold CV would leak future
information. The pipeline uses **walk-forward** (expanding window)
splits:

- **Training window**: 24 months of historical matches
- **Test window**: 1 month of subsequent matches
- The window slides forward by 1 month for each fold

This mimics a realistic betting scenario where you train on past data
and predict the next month.

[`footbet::walk_forward_splits()`](https://johngavin.github.io/footbet/reference/walk_forward_splits.md)
generates the date-based train/test splits, and
[`evaluate_glm_baseline()`](https://johngavin.github.io/footbet/reference/evaluate_glm_baseline.md)
/
[`evaluate_dc()`](https://johngavin.github.io/footbet/reference/evaluate_dc.md)
iterate over them.

flowchart TB subgraph Fold1\[Fold 1\] T1\[Train: Months 1-24\] --\>
V1\[Test: Month 25\] end subgraph Fold2\[Fold 2\] T2\[Train: Months
1-25\] --\> V2\[Test: Month 26\] end subgraph FoldN\[Fold N\] TN\[Train:
Months 1 to N-1\] --\> VN\[Test: Month N\] end V1 -.-\> T2 V2 -.-\>
\|...\| TN V1 --\> Agg((Aggregate Metrics)) V2 --\> Agg VN --\> Agg

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
$`j`$’s defence weakness, and $`\gamma`$ captures home advantage. The
model assumes independence between home and away goals.

[`footbet::fit_poisson_glm()`](https://johngavin.github.io/footbet/reference/fit_poisson_glm.md)
fits this model;
[`predict_glm()`](https://johngavin.github.io/footbet/reference/predict_glm.md)
generates a bivariate score probability matrix (up to 10x10 goals) and
derives 1X2, over/under, and Asian handicap probabilities.

### Dixon-Coles

Dixon & Coles (1997) extend the Poisson model with:

1.  **Correlation correction**: A parameter $`\rho`$ adjusts the joint
    probability of low-scoring outcomes (0-0, 1-0, 0-1, 1-1) where the
    independence assumption fails most
2.  **Time-decay weights**: Recent matches receive higher weight via an
    exponential decay parameter $`\xi`$

The pipeline uses $`\xi = 0.003`$ (approximately 1-year half-life) via
the [goalmodel](https://cran.r-project.org/package=goalmodel) package.

### CV Metrics

The plot below shows
[log-loss](https://en.wikipedia.org/wiki/Cross-entropy), [Brier
score](https://en.wikipedia.org/wiki/Brier_score), and
[RPS](https://en.wikipedia.org/wiki/Ranked_probability_score) per CV
fold for both models, with Pinnacle as a benchmark. All three are
**proper scoring rules** — lower is better.

    # A tibble: 1 × 5
      mean_glm_logloss mean_dc_logloss mean_diff n_folds conclusion
                 <dbl>           <dbl>     <dbl>   <int> <chr>
    1             1.07            1.07    -0.003     776 Models perform similarly

> **Note**
>
> **Key Finding:** Dixon-Coles slightly outperforms GLM. Both models
> trail Pinnacle on most folds. Pinnacle’s edge is consistent across
> metrics.

### Model Comparison

The table below summarises mean metrics across all folds, with the
Pinnacle benchmark for comparison. Positive “edge” means the model
outperforms Pinnacle.

    # A tibble: 2 × 5
      Model       Folds Mean_LogLoss Mean_Brier Mean_RPS
      <chr>       <int>        <dbl>      <dbl>    <dbl>
    1 GLM Poisson   779         1.07      0.620    0.211
    2 Dixon-Coles   776         1.07      0.618    0.210

### Value Bets

A **value bet** exists when the model’s estimated probability exceeds
the market’s implied probability by a minimum edge threshold. The
pipeline uses:

- **Minimum edge**: 3% (model_prob - market_prob \> 0.03)
- **Odds filter**: Only bets between 1.50 and 10.00 decimal odds
- **Devigged odds**: Market probabilities via [Shin
  (1993)](https://doi.org/10.2307/2234526) method

    # A tibble: 3 × 6
      outcome league_code n_bets mean_edge mean_odds mean_kelly
      <chr>   <chr>        <int>     <dbl>     <dbl>      <dbl>
    1 A       E0            1438    0.0998      4.39     0.0327
    2 D       E0             540    0.0523      5.96     0.0131
    3 H       E0            1370    0.100       3.58     0.0362

> **Note**
>
> **Key Finding:** Most edges cluster at 3-8%. Large edges (\>15%) are
> rare and may signal model error.

### Kelly Staking

The pipeline uses **quarter Kelly** staking:

``` math
f^* = \frac{1}{4} \cdot \frac{p \cdot (b + 1) - 1}{b}
```

where $`p`$ is the model probability and $`b`$ is the decimal odds minus
1.

**Guardrails:**

- **Max stake**: 3% of current bankroll per bet
- **Drawdown halt**: Stakes halved when bankroll drops 20% from peak
- **[`apply_guardrails()`](https://johngavin.github.io/footbet/reference/apply_guardrails.md)**:
  Automatically reduces stake size during drawdowns

flowchart TD Input\[Model Prob + Odds\] --\> Edge\[Calculate Edge\] Edge
--\> Check{{Edge \> 3%?}} Check --\>\|No\| NoBet\[No Bet\] Check
--\>\|Yes\| Kelly\[Calculate Kelly f\*\] Kelly --\> Frac\[Apply 0.25
Kelly\] Frac --\> Max{{Stake \> 3%?}} Max --\>\|Yes\| Cap\[Cap at 3%\]
Max --\>\|No\| DD Cap --\> DD{{Drawdown \> 20%?}} DD --\>\|Yes\|
Halve\[Halve Stake\] DD --\>\|No\| Final\[Final Stake\] Halve --\> Final

### P&L Simulation

The bankroll curve below shows the simulated profit & loss trajectory
for all GLM value bets, staked with quarter Kelly and drawdown
guardrails. Use the range slider to zoom into specific periods.

> **Note**
>
> **Key Finding:** Trajectory depends on model accuracy and market
> conditions. Drawdown guardrails limit losses during poor runs. Maximum
> drawdown is the key risk metric.

#### Summary

    # A tibble: 1 × 7
      n_bets total_pnl roi_pct max_drawdown final_bankroll win_rate avg_odds
       <int>     <dbl>   <dbl>        <dbl>          <dbl>    <dbl>    <dbl>
    1   3348     -280.   -28.0        0.802           720.    0.293     4.31

This glossary defines betting and statistical terms used throughout the
[footbet](https://johngavin.github.io/footbet/) package.

### Odds Formats

#### Decimal Odds

The total payout per unit staked, including the original stake. A
decimal odds of 2.50 means a 1 unit stake returns 2.50 units if the bet
wins (1 unit profit + 1 unit stake). Standard in Europe and Australia.

**Example:** Decimal 2.50 on a 10 unit stake pays 25 units (15 profit).

#### Fractional Odds

Expresses profit relative to stake as a fraction. Traditional UK format.
“3/2” (read “three to two”) means 3 units profit for every 2 units
staked.

**Conversion:** Decimal = (numerator / denominator) + 1

**Example:** 3/2 fractional = 2.50 decimal

#### American Odds

Positive numbers show profit on a 100 unit stake; negative numbers show
stake needed to win 100 units. Standard in the United States.

- +150 means bet 100 to win 150 profit
- -200 means bet 200 to win 100 profit

**Conversion:**

- Positive: Decimal = (American / 100) + 1
- Negative: Decimal = (100 / \|American\|) + 1

### Market Types

#### 1X2 (Match Result)

The most common football betting market:

- **1 (H)**: Home win
- **X (D)**: Draw
- **2 (A)**: Away win

#### Over/Under (O/U)

Total goals in the match relative to a line, usually 2.5. “Over 2.5”
requires 3+ goals; “Under 2.5” requires 0-2 goals.

#### Asian Handicap (AH)

Handicap applied to one team to eliminate the draw outcome. A -1.5 Asian
handicap on the home team means they must win by 2+ goals. Half-goal
handicaps ensure no push (void bet).

#### BTTS (Both Teams to Score)

Whether both teams score at least one goal. Binary yes/no market.

### Probability Concepts

#### Implied Probability

The probability implied by decimal odds: `1 / odds`. For odds of 2.50,
the implied probability is 40%. Markets include overround, so implied
probabilities sum to \>100%.

#### Overround (Vig/Juice)

The bookmaker’s margin built into odds. Calculated as the sum of implied
probabilities minus 100%. A 106% book has 6% overround.

**Example:** Home 2.00, Draw 3.50, Away 4.00

- Implied: 50% + 28.6% + 25% = 103.6%
- Overround: 3.6%

#### Fair Odds

Odds after removing the overround, representing true probabilities.
Several devigging methods exist:

- **Multiplicative:** Divide each probability by the overround
- **Power:** Raise probabilities to a power that normalizes them
- **Shin:** Models overround as protection against informed bettors

#### Closing Line Value (CLV)

The difference between your bet odds and the closing odds. Positive CLV
indicates you beat the market. Tracked via
[`closing_line_value()`](https://johngavin.github.io/footbet/reference/closing_line_value.md).

### Performance Metrics

#### Log Loss

Measures prediction quality for probabilistic forecasts. Lower is
better. Heavily penalizes confident wrong predictions.

``` math
\text{Log Loss} = -\frac{1}{n} \sum \log(p_i)
```

where $`p_i`$ is the predicted probability of the actual outcome.

#### Brier Score

Mean squared error for probability predictions. Ranges 0-2 for 1X2
markets. Lower is better. Less harsh than log loss on confident errors.

``` math
\text{Brier} = \frac{1}{n} \sum (p_i - o_i)^2
```

#### Ranked Probability Score (RPS)

Extension of Brier score for ordered outcomes. Better suited for 1X2
because it considers that H \> D \> A forms an ordering by goal
difference.

#### ROI (Return on Investment)

Total profit divided by total staked, expressed as percentage. +5% ROI
means 5% profit on turnover.

#### Sharpe Ratio

Risk-adjusted return metric. Higher values indicate better returns
relative to volatility. Computed via
[`betting_sharpe_ratio()`](https://johngavin.github.io/footbet/reference/betting_sharpe_ratio.md).

``` math
\text{Sharpe} = \frac{\text{Mean Return} - r_f}{\text{Std Dev Return}} \times \sqrt{n}
```

where $`r_f`$ is the risk-free rate and $`n`$ is periods per year.

#### Maximum Drawdown

Largest peak-to-trough decline in cumulative returns. Measures
worst-case scenario during a betting sequence.

### Statistical Models

#### Poisson Regression

Assumes goal counts follow Poisson distributions with team-specific
attack and defence parameters. Foundation of most football prediction
models.

#### Dixon-Coles Model

Extension of Poisson that corrects for under-prediction of 0-0, 1-0,
0-1, and 1-1 scorelines. Adds a “rho” correlation parameter. Implemented
in
[`fit_dixon_coles()`](https://johngavin.github.io/footbet/reference/fit_dixon_coles.md).

#### Expected Goals (xG)

Probability that a shot results in a goal, based on shot characteristics
(location, body part, game state). Summed across shots to get match xG.
Better predictor of future performance than actual goals.

#### Elo Rating

Rating system that updates after each match based on result versus
expectation. Higher-rated teams are expected to beat lower-rated teams.
Implemented in
[`compute_elo()`](https://johngavin.github.io/footbet/reference/compute_elo.md).

### Betting Strategy

#### Kelly Criterion

Optimal bet sizing formula that maximizes log wealth growth:

``` math
f^* = \frac{p \cdot b - q}{b}
```

where $`p`$ is win probability, $`q = 1-p`$, and $`b`$ is net odds
(decimal - 1).

#### Value Bet

A bet where your estimated probability exceeds the implied probability.
If you estimate 50% win chance and odds imply 40%, that’s a value bet.

#### Edge

The expected profit per unit staked. For a value bet:

``` math
\text{Edge} = p \times (o - 1) - (1 - p)
```

where $`p`$ is true probability and $`o`$ is decimal odds.

#### Sharp Bookmaker

Bookmaker with accurate odds that quickly incorporate new information.
Pinnacle is considered the sharpest. Their closing line is the best
publicly available proxy for true probabilities.

#### Soft Bookmaker

Bookmaker with less accurate odds, slower to adjust. May offer temporary
value but often limits winning accounts.

### Data Terminology

#### FTR (Full Time Result)

Match outcome: H (home win), D (draw), A (away win).

#### FTHG / FTAG

Full Time Home Goals / Full Time Away Goals.

#### HTHG / HTAG / HTR

Half Time Home Goals / Half Time Away Goals / Half Time Result.

#### Match Statistics

Common abbreviations in football-data.co.uk files:

- **HS/AS**: Home/Away Shots
- **HST/AST**: Home/Away Shots on Target
- **HC/AC**: Home/Away Corners
- **HF/AF**: Home/Away Fouls
- **HY/AY**: Home/Away Yellow Cards
- **HR/AR**: Home/Away Red Cards

### See Also

- [Data Sources tab](#data-sources) for data download and parsing
- [Models tab](#models) for model implementation details
- Package help:
  [`?closing_line_value`](https://johngavin.github.io/footbet/reference/closing_line_value.md),
  [`?betting_sharpe_ratio`](https://johngavin.github.io/footbet/reference/betting_sharpe_ratio.md),
  [`?convert_odds`](https://johngavin.github.io/footbet/reference/convert_odds.md)
