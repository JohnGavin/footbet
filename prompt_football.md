Plan

build profitable betting strategy for football.
Betting on full and half time outcomes when the market odds deviate materially from the expected models' averages.

# Data
+ Source historical football data at league, team, match, player levels.
+ Source funding data for each league and team. e.g. financial records, industry reports.
+ Source opening and closing market odds per full and halftime match
+ All histories to go back upto 10 years.
	+ lines, movements, different odds types
	+ ideal data is Asian handicap betting odds
		+ the goal spread between the two competing teams that makes the odds 50:50 for each approx.
	+ odds sources MUST be sharp bookmakers only 
		+ e.g. Pinnacle, PS3838
			+ https://betinasia.com/blog/academy/ps3838-vs-pinnacle-review/
			+ https://betinasia.com/blog/products/ps3838-full-review/
		+ e.g. sources such as aggregated bookmakers that offer Pinnacle and PS3838 are also acceptable odds sources.

+ sport: the top 2 men professional football leagues in each country
+ countries: germany, UK, italy, france, spain

+ https://rprogrammingbooks.com/collecting-cleaning-sports-data-r/
	+ structured sports data 
		+ https://rprogrammingbooks.com/worldfootballr-guide/
			+ FBref, Sports-Reference, ESPN, and league sites
				+ FBref (soccer): tables for leagues, players, and matches.
			+ https://rprogrammingbooks.com/install-use-worldfootballr-r/

# EDA / Metrics
+ https://rprogrammingbooks.com/soccer-analytics-with-r-worldfootballr/

# Models
+ https://rprogrammingbooks.com/sports-analytics-with-r/
	+ https://rprogrammingbooks.com/machine-learning-sports-analytics-r/
+ https://rprogrammingbooks.com/hierarchical-bayesian-models-in-r-brms-partial-pooling/

## Simulation
+ https://rprogrammingbooks.com/predict-sports-in-r-elo-monte-carlo-simulations/


# Visualisation
+ https://rprogrammingbooks.com/r-soccer-analytics-worldfootballr-ggsoccer/
	+ player, team, and match data from FBref and Transfermarkt using worldfootballR.

# Betting
+ https://rprogrammingbooks.com/football-betting-model-r-guide-2026


# References
+ https://rprogrammingbooks.com/blog/
+ https://rprogrammingbooks.com/quantitative-horse-racing-r-calibration-backtesting-deployment
  + section 13) An “engineering checklist”  
  	+ what is on this list that we might leverage for all projects by adding to or amending skills agents rules commands hooks that we are not already doing 
https://rprogrammingbooks.com/quantitative-horse-racing-r-calibration-backtesting-deployment
13) An “engineering checklist” 
	Canonical schema
	Parquet + DuckDB
	Adapters, not redistribution
Modeling
	GLM/GLMM baselines
	Ranking likelihoods
	Bayesian uncertainty
Evaluation
	Log loss / Brier
	Calibration curves
	Stress-tested backtests
Time dependence
	Odds snapshots
	Drift/volatility features
	Liquidity constraints
Decision layer
	Explicit assumptions
	Fractional Kelly caps
	Drawdown guardrails
Deployment
	pins versioning
	vetiver packaging
	plumber API


## Bookies
+ https://boltodds.com/pricing
+ https://www.goaloo.com/football/italian-serie-a-atalanta-vs-torino/1x2-odds-2784672
+ https://oddspapi.io/en