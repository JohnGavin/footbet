# Bet-time cutoff refit targets (definitive leakage test)
#
# Builds a parallel feature_matrix + Ranger pipeline with a 7-day
# bet-time cutoff on rolling goals and Elo, then re-runs CLV against
# the Pinnacle close. Comparison with the current (cut0) numbers
# tells us whether the +0.6-1.0% decimal CLV excess was real signal
# or within-fold leakage from midweek fixtures.
#
# See R/leakage_fix.R for the as-of join function and CHANGELOG for
# the full rationale.

plan_cutoff <- list(

  targets::tar_target(
    cutoff_days_default,
    7L
  ),

  # Feature matrix built with a bet-time cutoff.
  # Joins rolling_5 and elo_ratings using as-of semantics
  # (match_date - cutoff_days); everything else (devigged odds,
  # rest days) comes straight from the current pipeline because
  # devigged odds are a point-in-time Pinnacle quote and rest
  # days don't carry information beyond match_date.
  targets::tar_target(
    feature_matrix_cut7,
    {
      # Start from parsed_matches, carry the columns the downstream
      # Ranger needs (same set as feature_matrix).
      fm <- parsed_matches |>
        dplyr::select(
          match_id, league_code, season, match_date,
          home_team, away_team, fthg, ftag, ftr
        )

      roll_feats <- c("rolling_gf", "rolling_ga", "rolling_gd")
      fm <- apply_asof_cutoff(
        feature_df = rolling_5 |>
          dplyr::select("team", "match_date", dplyr::all_of(roll_feats)),
        target_df = fm,
        feature_cols = roll_feats,
        cutoff_days = cutoff_days_default
      )
      # apply_asof_cutoff names them home_rolling_gf etc; rename
      # to the names Ranger expects (home_roll_gf/ga/gd).
      fm <- fm |>
        dplyr::rename(
          home_roll_gf = home_rolling_gf,
          home_roll_ga = home_rolling_ga,
          home_roll_gd = home_rolling_gd,
          away_roll_gf = away_rolling_gf,
          away_roll_ga = away_rolling_ga,
          away_roll_gd = away_rolling_gd
        )

      # Elo: same pattern, feature_cols = c("elo"), renamed to
      # home_elo / away_elo.
      fm <- apply_asof_cutoff(
        feature_df = elo_ratings |>
          dplyr::select("team", "match_date", "elo"),
        target_df = fm,
        feature_cols = "elo",
        cutoff_days = cutoff_days_default
      )
      fm <- fm |>
        dplyr::mutate(elo_diff = home_elo - away_elo)

      fm
    }
  ),

  # Ranger fit on cut7 features. Same train/validate split and
  # feature columns as oos_ranger_predictions in plan_oos.R so the
  # comparison is strictly like-for-like.
  targets::tar_target(
    oos_ranger_cut7_predictions,
    {
      if (!requireNamespace("ranger", quietly = TRUE)) return(tibble::tibble())

      fm <- feature_matrix_cut7
      train_fm <- fm |>
        dplyr::filter(season <= "1920", !is.na(ftr), !is.na(home_elo))
      validate_fm <- fm |>
        dplyr::filter(season > "1920", season <= "2223", !is.na(ftr), !is.na(home_elo))

      feature_cols <- c(
        "home_elo", "away_elo", "elo_diff",
        "home_roll_gf", "home_roll_ga", "home_roll_gd",
        "away_roll_gf", "away_roll_ga", "away_roll_gd"
      )
      available <- intersect(feature_cols, names(train_fm))
      train_fm$ftr_factor <- factor(train_fm$ftr, levels = c("H", "D", "A"))

      rf <- ranger::ranger(
        ftr_factor ~ .,
        data = train_fm[, c("ftr_factor", available)] |> tidyr::drop_na(),
        num.trees = 500, probability = TRUE, seed = 42
      )

      validate_clean <- validate_fm[, available] |> tidyr::drop_na()
      valid_idx <- stats::complete.cases(validate_fm[, available])
      preds <- stats::predict(rf, validate_clean)$predictions

      tibble::tibble(
        match_id = validate_fm$match_id[valid_idx],
        pred_h = preds[, "H"],
        pred_d = preds[, "D"],
        pred_a = preds[, "A"]
      )
    }
  ),

  targets::tar_target(
    oos_ah_ranger_cut7,
    {
      ah_bets_from_preds(
        preds = oos_ranger_cut7_predictions,
        odds = parsed_odds |> dplyr::filter(!is.na(.data$ah_line)),
        matches = parsed_matches,
        rho = -0.13, min_edge = 0.03, use_kelly = FALSE, base_stake = 10
      )
    }
  ),

  targets::tar_target(
    oos_ah_ranger_cut7_clv,
    attach_clv(oos_ah_ranger_cut7, closing_ah_prices)
  ),

  targets::tar_target(
    oos_ah_ranger_cut7_clv_summary,
    summarise_ah_clv(oos_ah_ranger_cut7_clv, scenario = "Ranger AH cut7")
  ),

  targets::tar_target(
    oos_ah_ranger_cut7_clv_expanding,
    expanding_clv_window(
      bets = oos_ah_ranger_cut7,
      odds = parsed_odds,
      closing = closing_ah_prices,
      scenario = "Ranger cut7",
      seasons = clv_validation_seasons
    )
  ),

  # Paired comparison: cut0 (current leaky) vs cut7 (clean).
  targets::tar_target(
    oos_ah_cutoff_comparison,
    {
      cut0 <- oos_ah_ranger_clv_expanding |>
        dplyr::filter(scenario == "Ranger") |>
        dplyr::mutate(variant = "cut0 (leaky)")
      cut7 <- oos_ah_ranger_cut7_clv_expanding |>
        dplyr::filter(scenario == "Ranger cut7") |>
        dplyr::mutate(variant = "cut7 (clean)")
      dplyr::bind_rows(cut0, cut7) |>
        dplyr::select(
          "variant", "through_season", "n_bets",
          "decimal_clv_pct", "devig_clv_pp", "devig_excess_pp"
        )
    }
  )
)
