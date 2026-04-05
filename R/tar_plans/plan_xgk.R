# plan_xgk.R
# xG data acquisition (Understat) + Kalman filter team strengths
# Tracks: #82 (xG/Kalman/DC), plans/PLAN_xg_kalman_dc.md

plan_xgk <- list(

  # ====================================================================
  # Phase 1: xG data from Understat (FBref is HTTP 403 blocked)
  # ====================================================================

  # Fetch shot-level xG for Tier 1 leagues via worldfootballR GitHub mirror
  targets::tar_target(
    understat_shots_raw,
    {
      if (!requireNamespace("worldfootballR", quietly = TRUE)) {
        cli::cli_warn("worldfootballR not available. Skipping xG fetch.")
        return(tibble::tibble())
      }

      leagues <- c("EPL", "La liga", "Bundesliga", "Serie A", "Ligue 1")
      cli::cli_alert_info("Fetching Understat shot data for {length(leagues)} leagues...")

      purrr::map_dfr(leagues, function(lg) {
        tryCatch({
          cli::cli_alert("Fetching {lg}...")
          worldfootballR::load_understat_league_shots(league = lg)
        }, error = function(e) {
          cli::cli_warn("Failed to fetch {lg}: {conditionMessage(e)}")
          tibble::tibble()
        })
      })
    },
    cue = targets::tar_cue(mode = "thorough")
  ),

  # Aggregate shots to match-level xG totals
  targets::tar_target(
    understat_match_xg,
    {
      if (nrow(understat_shots_raw) == 0L) return(tibble::tibble())

      understat_shots_raw |>
        dplyr::mutate(
          xG = as.numeric(.data$xG),
          match_date = as.Date(.data$date)
        ) |>
        dplyr::group_by(
          .data$match_id, .data$home_team, .data$away_team,
          .data$match_date, .data$season, .data$league
        ) |>
        dplyr::summarise(
          home_xg = sum(.data$xG[.data$h_a == "h"], na.rm = TRUE),
          away_xg = sum(.data$xG[.data$h_a == "a"], na.rm = TRUE),
          home_shots = sum(.data$h_a == "h"),
          away_shots = sum(.data$h_a == "a"),
          .groups = "drop"
        )
    }
  ),

  # Map Understat league names to our league codes
  targets::tar_target(
    matches_with_xg,
    {
      if (nrow(understat_match_xg) == 0L) {
        cli::cli_warn("No Understat xG data. Returning matches without xG.")
        return(parsed_matches |>
                 dplyr::mutate(home_xg = NA_real_, away_xg = NA_real_))
      }

      # Understat delivers league names with either spaces or underscores
      # (e.g. "La liga" and "La_liga" both appear). Normalise to space form.
      league_map <- tibble::tibble(
        league = c("EPL", "La liga", "Bundesliga", "Serie A", "Ligue 1"),
        league_code = c("E0", "SP1", "D1", "I1", "F1")
      )

      # Normalise league names then join
      xg <- understat_match_xg |>
        dplyr::mutate(league = gsub("_", " ", .data$league)) |>
        dplyr::left_join(league_map, by = "league") |>
        dplyr::filter(!is.na(.data$league_code))

      # Join by date + team names (fuzzy: understat uses full names, fd uses abbreviated)
      joined <- parsed_matches |>
        dplyr::left_join(
          xg |> dplyr::select("match_date", "league_code",
                               home_xg = "home_xg", away_xg = "away_xg",
                               us_home = "home_team", us_away = "away_team"),
          by = c("match_date", "league_code"),
          relationship = "many-to-many"
        ) |>
        # Keep the best match: team name similarity
        dplyr::mutate(
          name_sim = stringdist_sim(.data$home_team, .data$us_home) +
            stringdist_sim(.data$away_team, .data$us_away)
        ) |>
        dplyr::group_by(.data$match_id) |>
        dplyr::slice_max(.data$name_sim, n = 1, with_ties = FALSE) |>
        dplyr::ungroup() |>
        dplyr::select(-"us_home", -"us_away", -"name_sim")

      joined
    }
  ),

  # xG coverage summary
  targets::tar_target(
    xg_coverage,
    {
      matches_with_xg |>
        dplyr::group_by(.data$season, .data$league_code) |>
        dplyr::summarise(
          n_matches = dplyr::n(),
          n_xg = sum(!is.na(.data$home_xg)),
          pct_xg = round(100 * sum(!is.na(.data$home_xg)) / dplyr::n(), 1),
          .groups = "drop"
        )
    }
  ),

  # ====================================================================
  # Phase 2: Kalman filter on xG data
  # ====================================================================

  # Run Kalman filter per league on xG-enriched matches (Tier 1 only)
  targets::tar_target(
    kalman_xg_strengths,
    {
      tier1 <- c("E0", "D1", "I1", "SP1", "F1")
      xg_data <- matches_with_xg |>
        dplyr::filter(
          .data$league_code %in% tier1,
          !is.na(.data$home_xg)
        )

      if (nrow(xg_data) == 0L) {
        cli::cli_warn("No xG data for Kalman filter.")
        return(tibble::tibble())
      }

      purrr::map_dfr(tier1, function(lg) {
        lg_data <- xg_data |> dplyr::filter(.data$league_code == lg)
        if (nrow(lg_data) < 50L) return(tibble::tibble())

        tryCatch({
          s <- kalman_strengths(lg_data, sigma_process = 0.05,
                                sigma_obs = 0.7, use_xg = TRUE)
          s$league_code <- lg
          s
        }, error = function(e) {
          cli::cli_warn("Kalman failed for {lg}: {conditionMessage(e)}")
          tibble::tibble()
        })
      })
    }
  ),

  # ====================================================================
  # Phase 4: Backtest Kalman xG + DC correction vs Pinnacle
  # ====================================================================

  targets::tar_target(
    xgk_backtest,
    {
      if (nrow(kalman_xg_strengths) == 0L) return(tibble::tibble())

      # Validate period: 20-21 to 22-23 (same as plan_oos)
      validate <- matches_with_xg |>
        dplyr::filter(
          .data$season > "1920", .data$season <= "2223",
          !is.na(.data$home_xg), !is.na(.data$ftr)
        )

      # Get Pinnacle closing odds
      validate_odds <- parsed_odds |>
        dplyr::semi_join(validate, by = "match_id") |>
        dplyr::filter(!is.na(.data$psh))

      combined <- dplyr::inner_join(validate, validate_odds, by = "match_id")

      if (nrow(combined) == 0L) return(tibble::tibble())

      # For each match: look up Kalman pre-match strengths → DC score matrix → probs → edge
      strengths <- kalman_xg_strengths
      rho <- -0.13  # Dixon-Coles default

      purrr::pmap_dfr(
        list(combined$match_id, combined$match_date, combined$league_code,
             combined$home_team, combined$away_team,
             combined$fthg, combined$ftag, combined$ftr,
             combined$psh, combined$psd, combined$psa),
        function(mid, mdate, lg, ht, at, fthg, ftag, ftr,
                 psh, psd, psa) {
          # Look up pre-match strengths (latest before this date)
          ht_str <- strengths |>
            dplyr::filter(.data$team == ht, .data$league_code == lg,
                          .data$match_date <= mdate) |>
            dplyr::slice_tail(n = 1)
          at_str <- strengths |>
            dplyr::filter(.data$team == at, .data$league_code == lg,
                          .data$match_date <= mdate) |>
            dplyr::slice_tail(n = 1)

          if (nrow(ht_str) == 0L || nrow(at_str) == 0L) return(tibble::tibble())

          # Lambda from Kalman strengths (home attack + away defence weakness)
          lh <- max(0.3, exp(0.3 + ht_str$attack + at_str$defence))
          la <- max(0.3, exp(0.1 + at_str$attack + ht_str$defence))

          # DC-corrected score matrix
          mat <- dc_score_matrix(lh, la, rho = rho)
          probs <- score_matrix_probs(mat)

          # Devig Pinnacle odds
          raw_sum <- 1/psh + 1/psd + 1/psa
          imp_h <- (1/psh) / raw_sum
          imp_d <- (1/psd) / raw_sum
          imp_a <- (1/psa) / raw_sum

          # Check all 3 outcomes for edge
          bets <- list()
          for (info in list(
            list(out = "H", model = probs$prob_h, implied = imp_h, odds = psh),
            list(out = "D", model = probs$prob_d, implied = imp_d, odds = psd),
            list(out = "A", model = probs$prob_a, implied = imp_a, odds = psa)
          )) {
            edge <- info$model - info$implied
            if (edge > 0.03 && info$odds >= 1.5 && info$odds <= 10) {
              won <- info$out == ftr
              net <- if (won) 10 * (info$odds * 0.99 - 1) else -10
              net <- net - 10 * 0.02  # transaction cost
              bets <- c(bets, list(tibble::tibble(
                match_id = mid, outcome = info$out, edge = edge,
                odds = info$odds, won = won, net = net
              )))
            }
          }
          if (length(bets) == 0L) return(tibble::tibble())
          dplyr::bind_rows(bets)
        }
      )
    }
  ),

  targets::tar_target(
    xgk_backtest_summary,
    {
      if (nrow(xgk_backtest) == 0L) {
        return(tibble::tibble(
          scenario = "xG-Kalman-DC", n_bets = 0L,
          roi_pct = NA_real_, win_rate = NA_real_, avg_odds = NA_real_
        ))
      }

      tibble::tibble(
        scenario = "xG-Kalman-DC",
        n_bets = nrow(xgk_backtest),
        roi_pct = round(100 * sum(xgk_backtest$net) / (nrow(xgk_backtest) * 10), 1),
        win_rate = round(100 * mean(xgk_backtest$won), 1),
        avg_odds = round(mean(xgk_backtest$odds), 2)
      )
    }
  ),

  # ====================================================================
  # Phase 4b: xG-Kalman-DC on Asian Handicap market
  # ====================================================================

  # Expose match-level predictions with lambdas for AH
  targets::tar_target(
    xgk_predictions,
    {
      if (nrow(kalman_xg_strengths) == 0L) return(tibble::tibble())

      validate <- matches_with_xg |>
        dplyr::filter(
          .data$season > "1920", .data$season <= "2223",
          !is.na(.data$home_xg), !is.na(.data$ftr)
        )

      strengths <- kalman_xg_strengths

      purrr::pmap_dfr(
        list(validate$match_id, validate$match_date, validate$league_code,
             validate$home_team, validate$away_team),
        function(mid, mdate, lg, ht, at) {
          ht_str <- strengths |>
            dplyr::filter(.data$team == ht, .data$league_code == lg,
                          .data$match_date <= mdate) |>
            dplyr::slice_tail(n = 1)
          at_str <- strengths |>
            dplyr::filter(.data$team == at, .data$league_code == lg,
                          .data$match_date <= mdate) |>
            dplyr::slice_tail(n = 1)

          if (nrow(ht_str) == 0L || nrow(at_str) == 0L) return(tibble::tibble())

          lh <- max(0.3, exp(0.3 + ht_str$attack + at_str$defence))
          la <- max(0.3, exp(0.1 + at_str$attack + ht_str$defence))
          mat <- dc_score_matrix(lh, la, rho = -0.13)
          probs <- score_matrix_probs(mat)

          tibble::tibble(
            match_id = mid, pred_h = probs$prob_h, pred_d = probs$prob_d,
            pred_a = probs$prob_a, lambda_home = lh, lambda_away = la
          )
        }
      )
    }
  ),

  targets::tar_target(
    xgk_ah_backtest,
    {
      if (nrow(xgk_predictions) == 0L) return(tibble::tibble())
      ah_bets_from_preds(
        preds = xgk_predictions,
        odds = parsed_odds |> dplyr::filter(!is.na(.data$ah_line)),
        matches = parsed_matches
      )
    }
  ),

  targets::tar_target(
    xgk_ah_summary,
    {
      if (nrow(xgk_ah_backtest) == 0L) {
        return(tibble::tibble(scenario = "xGK AH", n_bets = 0L,
                              roi_pct = NA_real_, win_rate = NA_real_))
      }
      tibble::tibble(
        scenario = "xGK AH",
        n_bets = nrow(xgk_ah_backtest),
        roi_pct = round(100 * sum(xgk_ah_backtest$net) / sum(xgk_ah_backtest$stake), 1),
        win_rate = round(100 * mean(xgk_ah_backtest$won), 1),
        avg_odds = round(mean(xgk_ah_backtest$odds), 2)
      )
    }
  )
)
