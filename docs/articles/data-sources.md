# Data Sources & Coverage

Part 1 of the [footbet](https://johngavin.github.io/footbet/) analytics
guide. See also: [Data
Cleaning](https://johngavin.github.io/footbet/articles/data-cleaning.md)
\| [EDA](https://johngavin.github.io/footbet/articles/eda.md) \| [Models
&
Betting](https://johngavin.github.io/footbet/articles/models-betting.md)
\| [Glossary](https://johngavin.github.io/footbet/articles/glossary.md)

The [footbet](https://johngavin.github.io/footbet/) package downloads
match data from [football-data.co.uk](https://www.football-data.co.uk/),
a free source of European football results and bookmaker odds maintained
since the mid-1990s. Each CSV file contains one league-season and
includes full-time and half-time scores, match statistics (shots,
corners, cards), and closing odds from multiple bookmakers including
[Pinnacle](https://en.wikipedia.org/wiki/Pinnacle_(sportsbook)) — widely
regarded as the sharpest bookmaker in the industry.

The URL pattern is
`https://www.football-data.co.uk/mmz4281/{season}/{league}.csv`, where
[season](https://github.com/agbarnett/season) is a 4-digit code (e.g.,
`2324` for 2023-24) and `{league}` is a 2-character code (e.g., `E0` for
the English Premier League).

[`footbet::target_leagues()`](https://johngavin.github.io/footbet/reference/target_leagues.md)
returns 10 leagues covering the top 2 divisions of the “big five”
European football countries.

## Data Pipeline Overview

%%{init: {'theme': 'dark', 'themeVariables': {'background':
'#000000','primaryColor': '#999999','primaryTextColor':
'#000000','primaryBorderColor': '#CC0000','lineColor':
'#CC0000','secondaryColor': '#333333','tertiaryColor': '#333333'}}}%%
flowchart LR subgraph Data\["Data Acquisition"\]
FD\[football-data.co.uk\] --\> Parse\[parse_fd_csv\] FD --\>
Odds\[parse_fd_odds\] FB\[FBref/Understat\] --\>
XG\[fetch_fbref_matches\] end subgraph Features\["Feature Engineering"\]
Parse --\> Roll\[rolling_goals\] XG --\> Roll Roll --\>
Elo\[compute_elo\] end subgraph Models\["Prediction Models"\] Elo --\>
GLM\[Poisson GLM\] Elo --\> DC\[Dixon-Coles\] GLM --\>
Eval\[Walk-Forward CV\] DC --\> Eval end subgraph Betting\["Accumulators
& Bankroll"\] Eval --\> Value\[find_value_bets\] Odds --\>
Devig\[devig_odds\] Devig --\> Value Value --\> Kelly\[kelly_fraction\]
end linkStyle default stroke:#CC0000,stroke-width:3px

Data pipeline: CSV download → parsing → validation → modelling →
evaluation. Nodes link to package functions.

*Data pipeline flowchart showing the end-to-end processing stages. Nodes
represent pipeline steps: CSV download, parsing via
[`parse_fd_csv()`](https://johngavin.github.io/footbet/reference/parse_fd_csv.md),
odds extraction via
[`parse_fd_odds()`](https://johngavin.github.io/footbet/reference/parse_fd_odds.md),
quality control, and model fitting. Red arrows indicate data flow
direction. The pipeline is implemented as a targets DAG (directed
acyclic graph) ensuring reproducibility and incremental builds. Source:
[footbet](https://johngavin.github.io/footbet/) package architecture.
See [Glossary \> Data
Terminology](https://johngavin.github.io/footbet/articles/glossary.html#data-terminology).*

## Data Coverage

*Data coverage summary table. Columns: league code (e.g., E0 = English
Premier League), country, division, number of seasons available, total
matches parsed. The dataset covers 10 leagues across England, Germany,
Italy, Spain, and France, with top two divisions each. Division 1
leagues typically span more seasons than Division 2 due to longer data
availability on football-data.co.uk. Total match counts range from
several thousand for well-covered leagues to fewer for recently added
ones. Source: [football-data.co.uk](https://www.football-data.co.uk/).
See [Glossary \> Data
Terminology](https://johngavin.github.io/footbet/articles/glossary.html#data-terminology).*

## Coverage Grid

The grid below shows the number of parsed matches per league-season
cell. Zeroes indicate seasons where the CSV was unavailable or empty.

*League-season coverage grid. Rows: league codes (E0, E1, D1, D2, I1,
I2, SP1, SP2, F1, F2). Columns: season codes (e.g., 2324). Cell values:
number of matches parsed for that league-season combination. Zero values
indicate missing or empty CSV files. Division 1 leagues (E0, D1, I1,
SP1, F1) have approximately 380 matches per season (20 teams, 38
rounds). Division 2 leagues have more matches (460-550) due to larger
league sizes (24 teams). Coverage is most complete for recent seasons.
Source: [football-data.co.uk](https://www.football-data.co.uk/). See
[Glossary \> Data
Terminology](https://johngavin.github.io/footbet/articles/glossary.html#data-terminology).*

*Matches per season by league over time. X-axis: season (year). Y-axis:
number of matches. Lines/bars: one per league, colour-coded by league
code. Division 1 leagues show a stable ~380 matches per season. Division
2 leagues show higher counts (~460-550) reflecting larger league sizes.
Gaps indicate seasons where data was unavailable. The plot confirms
consistent data collection for recent seasons across all 10 leagues.
Source: [football-data.co.uk](https://www.football-data.co.uk/). See
[Glossary \> Data
Terminology](https://johngavin.github.io/footbet/articles/glossary.html#data-terminology).*

> **Note**
>
> **Key Finding:** Division 1 leagues (E0, D1, I1, SP1, F1) have ~380
> matches/season. Division 2 leagues have more (~460-550
> matches/season).

## Pinnacle Odds

Not all leagues and seasons have Pinnacle odds. The table below shows
the percentage of matches with complete Pinnacle 1X2 closing odds (PSH,
PSD, PSA) and over/under odds.

*Pinnacle odds availability by league and season. Columns: league code,
season, pct_1x2 (percentage of matches with complete home/draw/away
Pinnacle closing odds), pct_over_under (percentage with over/under 2.5
goals odds). Top-division leagues achieve near-100% Pinnacle coverage
from approximately 2016 onward. Division 2 leagues show variable
coverage — Pinnacle may not offer markets for lower divisions. Coverage
gaps also arise from feed interruptions on football-data.co.uk. This
coverage determines which matches can be used for model evaluation
against the sharp-market benchmark. Source:
[football-data.co.uk](https://www.football-data.co.uk/) Pinnacle feed.
See [Glossary \> Implied
Probability](https://johngavin.github.io/footbet/articles/glossary.md)
and [Glossary \>
Overround](https://johngavin.github.io/footbet/articles/glossary.md).*

## Column Schema

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
| `fthg` / `ftag` | Full-time home/away goals | integer |
| `ftr` | Full-time result: H, D, or A | character |
| `hthg` / `htag` | Half-time home/away goals | integer |
| `htr` | Half-time result | character |
| `hs` / `as_` | Home/away shots | integer |
| `hst` / `ast` | Home/away shots on target | integer |
| `hf` / `af` | Home/away fouls | integer |
| `hc` / `ac` | Home/away corners | integer |
| `hy` / `ay` | Home/away yellow cards | integer |
| `hr` / `ar` | Home/away red cards | integer |

Columns produced by
[`parse_fd_csv()`](https://johngavin.github.io/footbet/reference/parse_fd_csv.md).
See
[Glossary](https://johngavin.github.io/footbet/articles/glossary.html#data-terminology)
for definitions.

[`footbet::parse_fd_odds()`](https://johngavin.github.io/footbet/reference/parse_fd_odds.md)
extracts Pinnacle closing odds:

| Column                   | Description                                |
|--------------------------|--------------------------------------------|
| `psh` / `psd` / `psa`    | Pinnacle closing 1X2 odds (Home/Draw/Away) |
| `p_over25` / `p_under25` | Pinnacle over/under 2.5 goals odds         |

Columns produced by
[`parse_fd_odds()`](https://johngavin.github.io/footbet/reference/parse_fd_odds.md).
Pinnacle odds serve as the sharp-market benchmark.

\[1\] “—\*footbet
**[0.1.0](https://github.com/JohnGavin/footbet/releases/tag/v0.1.0) \|**
Git
**[`5f9af31`](https://github.com/JohnGavin/footbet/commit/5f9af312e630dcbcab4c58bbd70bc6071fafbfac)
\|** R
**[4.5.2](https://cran.r-project.org/doc/manuals/r-release/NEWS.html)
\|** Built\*\* 2026-04-14 16:54:14”
