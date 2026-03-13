# Generate betting alerts based on bias detection

Identifies specific matches where model predictions diverge from market
odds in profitable directions based on historical biases.

## Usage

``` r
generate_bias_alerts(model_probs, market_odds, flb_summary, min_edge = 0.03)
```

## Arguments

- model_probs:

  A tibble with `match_id`, `prob_h`, `prob_d`, `prob_a`.

- market_odds:

  A tibble with `match_id`, `psh`, `psd`, `psa`.

- flb_summary:

  A tibble from
  [`summarize_flb()`](https://johngavin.github.io/footbet/reference/summarize_flb.md).

- min_edge:

  Numeric. Minimum edge to trigger alert (default 0.03).

## Value

A tibble of betting alerts.

## See also

Other betting:
[`acca_ev()`](https://johngavin.github.io/footbet/reference/acca_ev.md),
[`acca_odds()`](https://johngavin.github.io/footbet/reference/acca_odds.md),
[`adjust_for_league_strength()`](https://johngavin.github.io/footbet/reference/adjust_for_league_strength.md),
[`analyze_steam_moves()`](https://johngavin.github.io/footbet/reference/analyze_steam_moves.md),
[`bankroll_growth_target()`](https://johngavin.github.io/footbet/reference/bankroll_growth_target.md),
[`detect_flb()`](https://johngavin.github.io/footbet/reference/detect_flb.md),
[`estimate_league_strength()`](https://johngavin.github.io/footbet/reference/estimate_league_strength.md),
[`find_best_accas()`](https://johngavin.github.io/footbet/reference/find_best_accas.md),
[`line_movement()`](https://johngavin.github.io/footbet/reference/line_movement.md),
[`multi_kelly_stakes()`](https://johngavin.github.io/footbet/reference/multi_kelly_stakes.md),
[`simulate_bankroll_growth()`](https://johngavin.github.io/footbet/reference/simulate_bankroll_growth.md),
[`standard_league_strengths()`](https://johngavin.github.io/footbet/reference/standard_league_strengths.md),
[`summarize_flb()`](https://johngavin.github.io/footbet/reference/summarize_flb.md)
