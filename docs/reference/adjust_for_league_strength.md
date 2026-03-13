# Adjust predictions for league strength

Modifies predicted goal expectations based on relative league strength.
Use when comparing teams across different leagues or when a team has
been promoted/relegated.

## Usage

``` r
adjust_for_league_strength(
  predicted_goals,
  from_league,
  to_league,
  league_strengths
)
```

## Arguments

- predicted_goals:

  Numeric. Predicted goals (from model).

- from_league:

  Character. League the prediction is based on.

- to_league:

  Character. League to adjust for.

- league_strengths:

  A tibble from
  [`estimate_league_strength()`](https://johngavin.github.io/footbet/reference/estimate_league_strength.md).

## Value

Numeric. Adjusted predicted goals.

## See also

Other betting:
[`acca_ev()`](https://johngavin.github.io/footbet/reference/acca_ev.md),
[`acca_odds()`](https://johngavin.github.io/footbet/reference/acca_odds.md),
[`analyze_steam_moves()`](https://johngavin.github.io/footbet/reference/analyze_steam_moves.md),
[`bankroll_growth_target()`](https://johngavin.github.io/footbet/reference/bankroll_growth_target.md),
[`detect_flb()`](https://johngavin.github.io/footbet/reference/detect_flb.md),
[`estimate_league_strength()`](https://johngavin.github.io/footbet/reference/estimate_league_strength.md),
[`find_best_accas()`](https://johngavin.github.io/footbet/reference/find_best_accas.md),
[`generate_bias_alerts()`](https://johngavin.github.io/footbet/reference/generate_bias_alerts.md),
[`line_movement()`](https://johngavin.github.io/footbet/reference/line_movement.md),
[`multi_kelly_stakes()`](https://johngavin.github.io/footbet/reference/multi_kelly_stakes.md),
[`simulate_bankroll_growth()`](https://johngavin.github.io/footbet/reference/simulate_bankroll_growth.md),
[`standard_league_strengths()`](https://johngavin.github.io/footbet/reference/standard_league_strengths.md),
[`summarize_flb()`](https://johngavin.github.io/footbet/reference/summarize_flb.md)
