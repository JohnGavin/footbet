# Exploratory Data Analysis

Part 3 of the [footbet](https://johngavin.github.io/footbet/) analytics
guide. See also: [Data
Sources](https://johngavin.github.io/footbet/articles/data-sources.md)
\| [Data
Cleaning](https://johngavin.github.io/footbet/articles/data-cleaning.md)
\| [Models &
Betting](https://johngavin.github.io/footbet/articles/models-betting.md)
\| [Glossary](https://johngavin.github.io/footbet/articles/glossary.md)

This section explores key statistical patterns in European football
match data across 10 leagues and multiple seasons.

## Goal Distributions

Football goals are often modelled as
[Poisson-distributed](https://en.wikipedia.org/wiki/Poisson_distribution)
random variables. The chart below compares the observed goal
distribution against a Poisson overlay for home and away teams.

*Observed vs Poisson-fitted goal distributions for home and away teams.
X-axis: number of goals per match (0, 1, 2, 3, 4, 5+). Y-axis:
proportion of matches. Blue bars = observed frequency, orange line =
Poisson distribution fit. Two panels: home goals (left) and away goals
(right). Home teams have a higher mean (~1.5 goals) than away teams
(~1.2 goals), reflecting home advantage. The Poisson fit is reasonable
but slightly underpredicts 0-0 draws and overpredicts mid-range scores.
Source: all parsed matches from
[football-data.co.uk](https://www.football-data.co.uk/). See [Glossary
\> Poisson
Regression](https://johngavin.github.io/footbet/articles/glossary.md).*

    # A tibble: 1 × 10
      test       mean_home mean_away mean_all variance dispersion_ratio lr_statistic
      <chr>          <dbl>     <dbl>    <dbl>    <dbl>            <dbl>        <dbl>
    1 Poisson F…      1.46      1.16     1.31     1.41             1.07        1420.
    # ℹ 3 more variables: lr_pvalue <chr>, n_goals <int>, conclusion <chr>

*Poisson fit summary with home/away likelihood ratio test. Columns: mean
home goals, mean away goals, overall mean, variance, dispersion ratio,
LR test statistic, p-value. The LR test compares a single-lambda Poisson
(all goals pooled) against separate home and away lambdas. A significant
p-value (p\<0.05) confirms that home and away goal distributions differ,
justifying separate Poisson parameters in prediction models.
Overdispersion (variance/mean \> 1.1) motivates the Dixon-Coles
correction. Source: aggregated goal counts from
[football-data.co.uk](https://www.football-data.co.uk/). See [Glossary
\> Poisson
Regression](https://johngavin.github.io/footbet/articles/glossary.md)
and [Glossary \> Dixon-Coles
Model](https://johngavin.github.io/footbet/articles/glossary.md).*

> **Note**
>
> **Key Finding:** Home teams score slightly more than away teams (home
> advantage). The Poisson distribution is a reasonable first
> approximation, though it underpredicts 0-0 draws and some high-scoring
> outcomes.

## Result Proportions

Home advantage is a well-documented phenomenon in football. The chart
below shows the proportion of Home wins, Draws, and Away wins by league,
compared to a uniform 33/33/33 baseline.

*Result proportions by league. X-axis: league code (E0, E1, D1, D2, I1,
I2, SP1, SP2, F1, F2). Y-axis: proportion (0-1). Stacked bars: green =
Home wins, grey = Draws, red = Away wins. Dashed horizontal line at
0.333 = uniform baseline. Home win rates range 43-47% across all
leagues, well above the 33% baseline. Draw rates are 25-28%, and away
win rates are 27-30%. Serie A (I1) and La Liga (SP1) show among the
highest home advantages. Source: all parsed matches from
[football-data.co.uk](https://www.football-data.co.uk/). See [Glossary
\> 1X2 (Match
Result)](https://johngavin.github.io/footbet/articles/glossary.md) and
[Glossary \>
FTR](https://johngavin.github.io/footbet/articles/glossary.html#data-terminology).*

> **Note**
>
> **Key Finding:** Home win rate ranges 43-47% across leagues. Draws:
> 25-28%. Away wins: 27-30%. All leagues show significant home
> advantage.

## Home Advantage Trends

Home advantage has declined in recent years, with a notable drop during
the COVID-19 pandemic (2020-21 season) when matches were played in empty
stadiums.

*Home win percentage by league over time. X-axis: season (year). Y-axis:
home win percentage. Lines: one per league, colour-coded by league code.
Dashed horizontal line at 33% = no home advantage baseline. Home
advantage has gradually declined from ~48% in 2010 to ~44% in recent
seasons. The COVID-19 season (2020-21) shows a sharp drop across all
leagues when matches were played behind closed doors. Post-COVID
recovery varies — some leagues have rebounded while others remain below
pre-pandemic levels. Source:
[football-data.co.uk](https://www.football-data.co.uk/). See [Glossary
\> 1X2 (Match
Result)](https://johngavin.github.io/footbet/articles/glossary.md).*

    # A tibble: 1 × 4
      trend_per_season r_squared n_seasons conclusion
                 <dbl>     <dbl>     <int> <chr>
    1           -0.198     0.198        11 No clear trend

*Statistical test for declining home advantage trend. Columns:
coefficient, standard error, t-statistic, p-value. A linear regression
of home win percentage on season tests whether the long-term decline is
statistically significant. A negative coefficient confirms the downward
trend. The effect size is small but consistent across leagues. Source:
season-level aggregation from
[football-data.co.uk](https://www.football-data.co.uk/). See [Glossary
\> 1X2 (Match
Result)](https://johngavin.github.io/footbet/articles/glossary.md).*

> **Note**
>
> **Key Finding:** COVID seasons (2020-21) show reduced home advantage
> across all leagues. Post-COVID recovery varies by league.

## Common Scorelines

The heatmap below shows the frequency of each scoreline (home goals x
away goals). Hover over cells to see exact percentages.

*Scoreline frequency heatmap. X-axis: away goals (0-6+). Y-axis: home
goals (0-6+). Cell colour intensity = proportion of matches with that
scoreline (darker = more frequent). The most common scorelines are 1-0
(~12%), 1-1 (~11%), and 2-1 (~10%). The 0-0 scoreline accounts for ~7%
of matches — higher than independent Poisson would predict. The heatmap
asymmetry (more mass below the diagonal) reflects home advantage. The
excess probability at (0,0) and along the diagonal suggests positive
lower-tail dependence between home and away goals, consistent with a
Frank or Clayton copula structure. This motivates the Dixon-Coles rho
correction and the copula investigation in [issue
\#43](https://github.com/JohnGavin/footbet/issues/43). Source: all
parsed matches from
[football-data.co.uk](https://www.football-data.co.uk/). See [Glossary
\> FTHG /
FTAG](https://johngavin.github.io/footbet/articles/glossary.html#data-terminology)
and [Glossary \> Dixon-Coles
Model](https://johngavin.github.io/footbet/articles/glossary.md).*

> **Note**
>
> **Key Finding:** 1-0 (~12%), 1-1 (~11%), 2-1 (~10%) are most common.
> Scorelines above 4-4 are extremely rare (\<0.5% combined).

## Goals Per Season

Is scoring increasing over time? The chart below tracks mean total goals
per match by season and league.

*Mean total goals per match by season and league. X-axis: season (year).
Y-axis: mean total goals per match (home + away). Lines: one per league,
colour-coded by league code. The Bundesliga (D1) consistently ranks
among the highest-scoring leagues at approximately 3.0 goals per match.
Most leagues show a slight upward trend since 2015, possibly driven by
tactical evolution toward more attacking football. Ligue 1 (F1) and
Serie A (I1) tend to have lower-scoring matches (~2.5 goals/match).
Source: [football-data.co.uk](https://www.football-data.co.uk/). See
[Glossary \> FTHG /
FTAG](https://johngavin.github.io/footbet/articles/glossary.html#data-terminology).*

> **Note**
>
> **Key Finding:** Slight upward trend since 2015 in most leagues.
> Bundesliga consistently among highest-scoring (~3.0 goals/match).

## Outliers

Matches with more than 7 total goals are rare outliers. These are worth
inspecting for data quality and as edge cases for model robustness.

*High-scoring outlier matches table. Columns: league_code, season,
match_date, home_team, away_team, fthg (home goals), ftag (away goals),
total_goals. Filtered to matches with more than 7 total goals,
representing approximately 0.1% of all matches. These extreme scorelines
are important for model robustness testing — Poisson and Dixon-Coles
models may underpredict their frequency. They also serve as data quality
checkpoints, since some may reflect data entry errors. Source:
[football-data.co.uk](https://www.football-data.co.uk/). See [Glossary
\> FTHG /
FTAG](https://johngavin.github.io/footbet/articles/glossary.html#data-terminology)
and [Glossary \> Poisson
Regression](https://johngavin.github.io/footbet/articles/glossary.md).*

## Match Statistics

Median match statistics (shots, corners, fouls, cards) by league. See
[Glossary \> Match
Statistics](https://johngavin.github.io/footbet/articles/glossary.html#match-statistics)
for variable definitions.

*Median match statistics by league. Columns: league_code, HS (home
shots), AS (away shots), HST (home shots on target), AST (away shots on
target), HC (home corners), AC (away corners), HF (home fouls), AF (away
fouls), HY (home yellow cards), AY (away yellow cards). Home teams
consistently record more shots and corners than away teams across all
leagues, reflecting home advantage beyond just results. La Liga (SP1)
and Serie A (I1) tend to have higher foul counts and yellow cards.
Bundesliga (D1) shows higher shot counts. Source:
[football-data.co.uk](https://www.football-data.co.uk/). See [Glossary
\> Match
Statistics](https://johngavin.github.io/footbet/articles/glossary.html#match-statistics).*

## Pinnacle Overround

The [overround](https://en.wikipedia.org/wiki/Vigorish) is the
bookmaker’s built-in margin. Pinnacle’s margin (~2-4%) is the lowest in
the industry.

*Pinnacle 1X2 overround distribution by league. X-axis: league code.
Y-axis: overround percentage (sum of implied probabilities minus 100%).
Box plots show the distribution across matches within each league.
Median overround is approximately 2-4%, far below soft bookmakers which
charge 5-15%. The overround is remarkably consistent across leagues,
indicating Pinnacle applies a uniform margin policy. Lower overround
means the market is closer to fair odds, making Pinnacle the strongest
benchmark for model evaluation. Source: Pinnacle closing odds from
[football-data.co.uk](https://www.football-data.co.uk/). See [Glossary
\> Overround](https://johngavin.github.io/footbet/articles/glossary.md)
and [Glossary \> Fair
Odds](https://johngavin.github.io/footbet/articles/glossary.md).*

> **Note**
>
> **Key Finding:** Pinnacle margin is ~2-4%, far below soft bookmakers
> (5-15%). Consistent across all leagues.

## Pinnacle Calibration

A well-calibrated bookmaker’s implied probabilities should match actual
outcome frequencies.

*Pinnacle calibration plot (reliability diagram). X-axis: Pinnacle
implied probability (binned). Y-axis: observed outcome frequency.
Diagonal line = perfect calibration. Points near the diagonal indicate
well-calibrated probabilities. Pinnacle is near-perfectly calibrated
across most of the probability range. A slight favourite-longshot bias
appears at the extremes: favourites (high implied probability) win
slightly less often than implied, while longshots (low implied
probability) win slightly more often. This near-perfect calibration
makes Pinnacle the gold-standard benchmark for model comparison. Source:
Pinnacle closing odds vs actual results from
[football-data.co.uk](https://www.football-data.co.uk/). See [Glossary
\> Implied
Probability](https://johngavin.github.io/footbet/articles/glossary.md)
and [Glossary \> Closing Line
Value](https://johngavin.github.io/footbet/articles/glossary.md).*

> **Note**
>
> **Key Finding:** Pinnacle is near-perfectly calibrated (points near
> diagonal). Slight favourite-longshot bias at extremes.

## Elo Ratings

[Elo ratings](https://en.wikipedia.org/wiki/Elo_rating_system) quantify
relative team strength, updated match-by-match with
[COOPER/FiveThirtyEight
enhancements](https://www.natesilver.net/p/introducing-cooper-silver-bulletins):
dynamic K-factor, margin weighting, league reversion, and asymmetric
wins.

*Elo rating spread by league. X-axis: league code. Y-axis: Elo rating.
Box plots show the distribution of current team Elo ratings within each
league. Top-division leagues (E0, D1, I1, SP1, F1) have wider spreads,
indicating greater competitive imbalance between elite and weaker teams.
Division 2 leagues show more compressed distributions, reflecting more
even competition. Outliers at the top represent dominant teams (e.g.,
Bayern Munich in D1, PSG in F1). The overall median is approximately
1500 (starting rating). Source: Elo ratings computed via
[`compute_elo()`](https://johngavin.github.io/footbet/reference/compute_elo.md)
on [football-data.co.uk](https://www.football-data.co.uk/) data. See
[Glossary \> Elo
Rating](https://johngavin.github.io/footbet/articles/glossary.md).*

> **Note**
>
> **Key Finding:** Top divisions have wider Elo spreads (more
> competitive imbalance). Division 2 leagues show more compressed rating
> distributions.

\[1\] “—\*footbet
**[0.1.0](https://github.com/JohnGavin/footbet/releases/tag/v0.1.0) \|**
Git
**[`5f9af31`](https://github.com/JohnGavin/footbet/commit/5f9af312e630dcbcab4c58bbd70bc6071fafbfac)
\|** R
**[4.5.2](https://cran.r-project.org/doc/manuals/r-release/NEWS.html)
\|** Built\*\* 2026-04-14 16:54:14”
