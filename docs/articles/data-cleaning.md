# Data Cleaning & QC

# Data Cleaning & QC

Automated quality control pipeline

Part 2 of the [footbet](https://johngavin.github.io/footbet/) analytics
guide. See also: [Data
Sources](https://johngavin.github.io/footbet/articles/data-sources.md)
\| [EDA](https://johngavin.github.io/footbet/articles/eda.md) \| [Models
&
Betting](https://johngavin.github.io/footbet/articles/models-betting.md)
\| [Glossary](https://johngavin.github.io/footbet/articles/glossary.md)

The footbet pipeline includes automated quality control checks that run
after data parsing. This section summarises the QC outputs.

## Match Completeness

The chart below shows the percentage of matches per league-season with a
valid full-time result (FTR). A value below 100% indicates matches where
the result is missing — typically from ongoing or postponed fixtures in
the current season.

    # A tibble: 3 × 4
      league_code                  season tier    pct_complete
      <chr>                        <chr>  <chr>          <dbl>
    1 F1                           "1516" "Top 5"         99.7
    2 I1                           "1516" "Top 5"         99.7
    3 (108 league-seasons at 100%) ""     ""             100  

*Match completeness by league-season. X-axis: season (year). Y-axis:
percentage of matches with a valid full-time result (FTR). Colour =
league code (E0, D1, etc.). A value of 100% means all matches in that
league-season have a recorded result. Most historical seasons achieve
full completeness. The current season shows partial data because not all
fixtures have been played yet. This metric is critical for ensuring
model training data does not include unresolved matches. Source:
[football-data.co.uk](https://www.football-data.co.uk/) parsed via
`parse_fd_csv()`. See [Glossary \>
FTR](https://johngavin.github.io/footbet/articles/glossary.html#data-terminology).*

Note

**Key Finding:** Most historical league-seasons achieve 100%
completeness. Current season shows partial data (matches not yet
played).

## Pinnacle Coverage

Pinnacle odds are the primary benchmark for model evaluation. The chart
shows the percentage of matches with all three Pinnacle 1X2 closing odds
present.

Coverage gaps arise from:

- **Division 2 leagues**: Pinnacle may not offer odds for lower
  divisions
- **Feed breaks**: The football-data.co.uk Pinnacle feed experienced a
  break from mid-2025
- **Early seasons**: Pinnacle data availability improves in more recent
  seasons

*Pinnacle 1X2 odds coverage by league-season. X-axis: season (year).
Y-axis: percentage of matches with complete Pinnacle home/draw/away
closing odds (PSH, PSD, PSA). Colour = league code. Top-division leagues
(E0, D1, I1, SP1, F1) achieve near-100% coverage from approximately 2016
onward. Division 2 leagues (E1, D2, I2, SP2, F2) show variable and often
lower coverage, as Pinnacle may not offer markets for these
competitions. Coverage of 0% indicates complete feed breaks or no
Pinnacle market for that league-season. Source:
[football-data.co.uk](https://www.football-data.co.uk/) Pinnacle feed.
See [Glossary \> Implied
Probability](https://johngavin.github.io/footbet/articles/glossary.md)
and [Glossary \> Sharp
Bookmaker](https://johngavin.github.io/footbet/articles/glossary.md).*

Note

**Key Finding:** Top divisions have near-100% coverage from ~2016
onward. Division 2 coverage is variable. 0% coverage indicates feed
breaks or no Pinnacle market.

## Missing Data

The chart below shows the percentage of missing values for each column
across all parsed matches. Match statistics (shots, corners, cards) are
more frequently missing than core fields.

*Missing data heatmap by column and league. X-axis: column name (fthg,
ftag, ftr, hs, as\_, hst, ast, hc, ac, hf, af, hy, ay, hr, ar). Y-axis:
league code. Cell colour intensity = percentage of missing values
(darker = more missing). Core result fields (fthg, ftag, ftr) have
near-zero missingness. Match statistics columns (shots, corners, cards)
show higher missingness, especially in older seasons and Division 2
leagues where football-data.co.uk may not collect detailed statistics.
This pattern informs which features are reliably available for
modelling. Source:
[football-data.co.uk](https://www.football-data.co.uk/) parsed data. See
[Glossary \> Match
Statistics](https://johngavin.github.io/footbet/articles/glossary.html#match-statistics).*

The table below provides detailed missing counts with variable
descriptions. See [Glossary \> Data
Terminology](https://johngavin.github.io/footbet/articles/glossary.html#data-terminology)
for full definitions.

*Missing data counts by variable. Columns: variable name, description,
number of missing values, percentage missing, leagues most affected.
Core fields (match_date, home_team, away_team, fthg, ftag, ftr) are
nearly always present. Match statistics (hs, hst, hc, hf, hy, hr and
their away equivalents) have higher missingness, particularly in seasons
before detailed statistics were collected. Pinnacle odds columns (psh,
psd, psa) are missing for league-seasons without Pinnacle coverage.
Source: [football-data.co.uk](https://www.football-data.co.uk/) parsed
data. See [Glossary \> Match
Statistics](https://johngavin.github.io/footbet/articles/glossary.html#match-statistics)
and [Glossary \> Data
Terminology](https://johngavin.github.io/footbet/articles/glossary.html#data-terminology).*

## Anomaly Detection

The pipeline flags matches with:

- **Extreme scorelines**: Total goals \> 10 (very rare, may indicate
  data entry errors)
- **Missing dates**: Matches without a parseable date
- **Future matches**: Dates more than 7 days beyond the pipeline run
  date
- **Missing team names**: Rows with NA home or away team

*Anomaly detection results table. Columns: match_id, league_code,
season, match_date, home_team, away_team, fthg, ftag, anomaly_type
(extreme_score / missing_date / future_date / missing_team). Each row is
a flagged match requiring manual review. Extreme scorelines (\>10 total
goals) are rare but may indicate data entry errors. An empty table
(green banner) means no anomalies were detected, confirming data
integrity. Source: automated QC pipeline applied to
[football-data.co.uk](https://www.football-data.co.uk/) data. See
[Glossary \> FTHG /
FTAG](https://johngavin.github.io/footbet/articles/glossary.html#data-terminology).*

## QC Summary

The `qc_summary` target combines all QC checks into a single report. The
pipeline computes total matches parsed, odds rows, completeness
percentage, Pinnacle coverage, and anomaly count. These targets serve as
data contracts — downstream model targets depend on QC to ensure data
quality.

\[1\] “—\*footbet
**[0.1.0](https://github.com/JohnGavin/footbet/releases/tag/v0.1.0) \|**
Git
**[`5f9af31`](https://github.com/JohnGavin/footbet/commit/5f9af312e630dcbcab4c58bbd70bc6071fafbfac)
\|** R
**[4.5.2](https://cran.r-project.org/doc/manuals/r-release/NEWS.html)
\|** Built\*\* 2026-04-14 16:54:14”
