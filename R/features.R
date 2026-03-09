#' @importFrom rlang .data
NULL

#' Compute rolling goal averages for each team
#'
#' Calculates rolling mean goals scored and conceded over a window
#' of recent matches, using only information available before each match.
#'
#' @param matches_df A tibble of match data with `match_date`, `home_team`,
#'   `away_team`, `fthg`, `ftag`.
#' @param window Integer. Number of past matches to include (default 5).
#' @return A tibble with columns `team`, `match_date`, `rolling_gf`,
#'   `rolling_ga`, `rolling_gd`.
#' @family features
#' @export
rolling_goals <- function(matches_df, window = 5L) {
  rlang::check_required(matches_df)

  # Long format: one row per team per match
  home <- matches_df |>
    dplyr::transmute(
      team = .data$home_team,
      opponent = .data$away_team,
      match_date = .data$match_date,
      goals_for = .data$fthg,
      goals_against = .data$ftag,
      is_home = TRUE
    )

  away <- matches_df |>
    dplyr::transmute(
      team = .data$away_team,
      opponent = .data$home_team,
      match_date = .data$match_date,
      goals_for = .data$ftag,
      goals_against = .data$fthg,
      is_home = FALSE
    )

  long <- dplyr::bind_rows(home, away) |>
    dplyr::arrange(.data$team, .data$match_date)

  long |>
    dplyr::group_by(.data$team) |>
    dplyr::mutate(
      rolling_gf = dplyr::lag(
        slider_mean(.data$goals_for, window),
        default = NA_real_
      ),
      rolling_ga = dplyr::lag(
        slider_mean(.data$goals_against, window),
        default = NA_real_
      ),
      rolling_gd = .data$rolling_gf - .data$rolling_ga
    ) |>
    dplyr::ungroup()
}

#' Simple sliding window mean
#'
#' @param x Numeric vector.
#' @param window Integer window size.
#' @return Numeric vector of rolling means.
#' @noRd
slider_mean <- function(x, window) {
  n <- length(x)
  result <- rep(NA_real_, n)
  for (i in seq_along(x)) {
    start <- max(1L, i - window + 1L)
    result[[i]] <- mean(x[start:i], na.rm = TRUE)
  }
  result
}

#' Convert match results to long format for Poisson modelling
#'
#' Creates a "long" dataset with one row per team per match,
#' suitable for GLM/GLMM Poisson regression.
#'
#' @param matches_df A tibble of match data.
#' @return A tibble with columns: `match_id`, `match_date`, `season`,
#'   `league_code`, `team`, `opponent`, `goals`, `home`.
#' @family features
#' @export
matches_to_long <- function(matches_df) {
  home <- matches_df |>
    dplyr::transmute(
      match_id = .data$match_id,
      match_date = .data$match_date,
      season = .data$season,
      league_code = .data$league_code,
      team = .data$home_team,
      opponent = .data$away_team,
      goals = .data$fthg,
      home = 1L
    )

  away <- matches_df |>
    dplyr::transmute(
      match_id = .data$match_id,
      match_date = .data$match_date,
      season = .data$season,
      league_code = .data$league_code,
      team = .data$away_team,
      opponent = .data$home_team,
      goals = .data$ftag,
      home = 0L
    )

  dplyr::bind_rows(home, away)
}

#' Compute Elo ratings for a league
#'
#' Updates Elo ratings match-by-match using the `elo` package.
#' Matches must be sorted by date. Returns ratings after each match.
#'
#' @param matches_df A tibble with `match_date`, `home_team`, `away_team`, `ftr`.
#' @param k Numeric. K-factor (default 20).
#' @param home_advantage Numeric. Home advantage in Elo points (default 65).
#' @param init Numeric. Initial Elo rating (default 1500).
#' @return A tibble with columns `team`, `match_date`, `elo`.
#' @family features
#' @export
compute_elo <- function(matches_df, k = 20, home_advantage = 65, init = 1500) {
  rlang::check_installed("elo", reason = "to compute Elo ratings")
  rlang::check_required(matches_df)

  if (nrow(matches_df) == 0L) {
    return(tibble::tibble(team = character(), match_date = as.Date(character()),
                          elo = numeric()))
  }

  # Convert FTR to numeric result: H=1, D=0.5, A=0
  matches_df <- matches_df |>
    dplyr::arrange(.data$match_date) |>
    dplyr::mutate(
      result = dplyr::case_when(
        .data$ftr == "H" ~ 1,
        .data$ftr == "D" ~ 0.5,
        .data$ftr == "A" ~ 0,
        TRUE ~ NA_real_
      )
    ) |>
    dplyr::filter(!is.na(.data$result))

  if (nrow(matches_df) == 0L) {
    return(tibble::tibble(team = character(), match_date = as.Date(character()),
                          elo = numeric()))
  }

  elo_run <- elo::elo.run(
    result ~ elo::adjust(home_team, home_advantage) + away_team,
    k = k,
    data = matches_df,
    initial.elos = init
  )

  # Extract final ratings
  final <- elo::final.elos(elo_run)
  tibble::tibble(
    team = names(final),
    elo = as.numeric(final)
  )
}

#' Devig Pinnacle odds for all matches
#'
#' Applies Shin devig to 1X2 odds and power devig to over/under odds
#' for each match in the odds tibble.
#'
#' @param odds_df A tibble from [parse_fd_odds()] with columns
#'   `psh`, `psd`, `psa`, `p_over25`, `p_under25`.
#' @return A tibble with `match_id` and devigged probability columns.
#' @family features
#' @export
devig_odds <- function(odds_df) {
  rlang::check_required(odds_df)
  if (nrow(odds_df) == 0L) {
    return(tibble::tibble(
      match_id = character(),
      fair_h = numeric(), fair_d = numeric(), fair_a = numeric(),
      fair_over25 = numeric(), fair_under25 = numeric()
    ))
  }

  n <- nrow(odds_df)
  fair_h <- rep(NA_real_, n)
  fair_d <- rep(NA_real_, n)
  fair_a <- rep(NA_real_, n)
  fair_over25 <- rep(NA_real_, n)
  fair_under25 <- rep(NA_real_, n)

  for (i in seq_len(n)) {
    # 1X2: use Shin method (best for 3-way markets)
    h <- odds_df$psh[i]
    d <- odds_df$psd[i]
    a <- odds_df$psa[i]
    if (!is.na(h) && !is.na(d) && !is.na(a) && h > 1 && d > 1 && a > 1) {
      probs <- tryCatch(
        devig_shin(c(h, d, a)),
        error = function(e) c(NA_real_, NA_real_, NA_real_)
      )
      fair_h[i] <- probs[1]
      fair_d[i] <- probs[2]
      fair_a[i] <- probs[3]
    }

    # O/U 2.5: use power method (best for 2-way markets)
    ov <- odds_df$p_over25[i]
    un <- odds_df$p_under25[i]
    if (!is.na(ov) && !is.na(un) && ov > 1 && un > 1) {
      probs_ou <- tryCatch(
        devig_power(c(ov, un)),
        error = function(e) c(NA_real_, NA_real_)
      )
      fair_over25[i] <- probs_ou[1]
      fair_under25[i] <- probs_ou[2]
    }
  }

  tibble::tibble(
    match_id = odds_df$match_id,
    fair_h = fair_h,
    fair_d = fair_d,
    fair_a = fair_a,
    fair_over25 = fair_over25,
    fair_under25 = fair_under25
  )
}

# ============================================================================
# xG FEATURES
# ============================================================================

#' Compute rolling xG averages for each team
#'
#' Calculates rolling mean expected goals for and against over a window
#' of recent matches, using only information available before each match.
#' Requires matches to have `home_xg` and `away_xg` columns from FBref.
#'
#' @param matches_df A tibble with `match_date`, `home_team`, `away_team`,
#'   `home_xg`, `away_xg`.
#' @param window Integer. Number of past matches to include (default 5).
#' @return A tibble with columns `team`, `match_date`, `match_id`,
#'   `rolling_xg_for`, `rolling_xg_against`, `rolling_xg_diff`.
#' @family features
#' @export
rolling_xg <- function(matches_df, window = 5L) {
  rlang::check_required(matches_df)

  required_cols <- c("match_date", "home_team", "away_team", "home_xg", "away_xg")
  missing <- setdiff(required_cols, names(matches_df))
  if (length(missing) > 0) {
    cli::cli_abort(c(
      "x" = "Missing required columns: {.val {missing}}",
      "i" = "Use {.fun join_xg_to_matches} to add xG data first."
    ))
  }

  # Long format: one row per team per match
  home <- matches_df |>
    dplyr::transmute(
      match_id = if ("match_id" %in% names(matches_df)) .data$match_id else NA_character_,
      team = .data$home_team,
      opponent = .data$away_team,
      match_date = .data$match_date,
      xg_for = .data$home_xg,
      xg_against = .data$away_xg,
      is_home = TRUE
    )

  away <- matches_df |>
    dplyr::transmute(
      match_id = if ("match_id" %in% names(matches_df)) .data$match_id else NA_character_,
      team = .data$away_team,
      opponent = .data$home_team,
      match_date = .data$match_date,
      xg_for = .data$away_xg,
      xg_against = .data$home_xg,
      is_home = FALSE
    )

  long <- dplyr::bind_rows(home, away) |>
    dplyr::arrange(.data$team, .data$match_date)

  long |>
    dplyr::group_by(.data$team) |>
    dplyr::mutate(
      rolling_xg_for = dplyr::lag(
        slider_mean(.data$xg_for, window),
        default = NA_real_
      ),
      rolling_xg_against = dplyr::lag(
        slider_mean(.data$xg_against, window),
        default = NA_real_
      ),
      rolling_xg_diff = .data$rolling_xg_for - .data$rolling_xg_against
    ) |>
    dplyr::ungroup() |>
    dplyr::select("team", "match_date", "match_id", "is_home",
                  "rolling_xg_for", "rolling_xg_against", "rolling_xg_diff")
}

#' Compute cumulative xG ratio within season
#'
#' Calculates the cumulative xG ratio: team_xG / (team_xG + opponent_xG).
#' This is the key metric from the Tony ElHabr analysis that becomes
#' reliable around matchday 9-13.
#'
#' @param matches_df A tibble with `match_date`, `season`, `home_team`,
#'   `away_team`, `home_xg`, `away_xg`.
#' @return A tibble with columns `team`, `match_date`, `season`,
#'   `cum_xg_for`, `cum_xg_against`, `xg_ratio`.
#' @family features
#' @export
cumulative_xg_ratio <- function(matches_df) {
  rlang::check_required(matches_df)

  required_cols <- c("match_date", "home_team", "away_team", "home_xg", "away_xg")
  missing <- setdiff(required_cols, names(matches_df))
  if (length(missing) > 0) {
    cli::cli_abort(c(
      "x" = "Missing required columns: {.val {missing}}",
      "i" = "Use {.fun join_xg_to_matches} to add xG data first."
    ))
  }

  # Add season if missing (derive from match_date)
  if (!"season" %in% names(matches_df)) {
    matches_df <- matches_df |>
      dplyr::mutate(
        season = dplyr::case_when(
          lubridate::month(.data$match_date) >= 7 ~
            paste0(lubridate::year(.data$match_date) %% 100,
                   (lubridate::year(.data$match_date) + 1) %% 100),
          TRUE ~
            paste0((lubridate::year(.data$match_date) - 1) %% 100,
                   lubridate::year(.data$match_date) %% 100)
        )
      )
  }

  # Long format
  home <- matches_df |>
    dplyr::transmute(
      match_id = if ("match_id" %in% names(matches_df)) .data$match_id else NA_character_,
      team = .data$home_team,
      match_date = .data$match_date,
      season = .data$season,
      xg_for = .data$home_xg,
      xg_against = .data$away_xg
    )

  away <- matches_df |>
    dplyr::transmute(
      match_id = if ("match_id" %in% names(matches_df)) .data$match_id else NA_character_,
      team = .data$away_team,
      match_date = .data$match_date,
      season = .data$season,
      xg_for = .data$away_xg,
      xg_against = .data$home_xg
    )

  long <- dplyr::bind_rows(home, away) |>
    dplyr::arrange(.data$team, .data$season, .data$match_date)

  # Compute cumulative xG within each season
  long |>
    dplyr::group_by(.data$team, .data$season) |>
    dplyr::mutate(
      match_num = dplyr::row_number(),
      # Cumulative sums up to but NOT including current match (lag)
      cum_xg_for = dplyr::lag(cumsum(tidyr::replace_na(.data$xg_for, 0)),
                               default = 0),
      cum_xg_against = dplyr::lag(cumsum(tidyr::replace_na(.data$xg_against, 0)),
                                   default = 0),
      # xG ratio: team's share of total xG
      xg_ratio = dplyr::case_when(
        .data$cum_xg_for + .data$cum_xg_against == 0 ~ 0.5,  # No data yet
        TRUE ~ .data$cum_xg_for / (.data$cum_xg_for + .data$cum_xg_against)
      )
    ) |>
    dplyr::ungroup() |>
    dplyr::select("team", "match_date", "match_id", "season", "match_num",
                  "cum_xg_for", "cum_xg_against", "xg_ratio")
}

#' Compute xG overperformance (goals minus xG)
#'
#' Measures whether a team is scoring more or fewer goals than expected.
#' Positive values indicate overperformance (luck or clinical finishing).
#' Negative values indicate underperformance.
#'
#' @param matches_df A tibble with goals and xG columns.
#' @param window Integer. Rolling window for averaging (default 10).
#' @return A tibble with xG overperformance features.
#' @family features
#' @export
xg_overperformance <- function(matches_df, window = 10L) {
  rlang::check_required(matches_df)

  required_cols <- c("match_date", "home_team", "away_team",
                     "home_xg", "away_xg", "fthg", "ftag")
  missing <- setdiff(required_cols, names(matches_df))
  if (length(missing) > 0) {
    cli::cli_abort(c(
      "x" = "Missing required columns: {.val {missing}}",
      "i" = "Need both goals (fthg/ftag) and xG (home_xg/away_xg)."
    ))
  }

  # Long format
  home <- matches_df |>
    dplyr::transmute(
      match_id = if ("match_id" %in% names(matches_df)) .data$match_id else NA_character_,
      team = .data$home_team,
      match_date = .data$match_date,
      goals = .data$fthg,
      xg = .data$home_xg,
      goals_against = .data$ftag,
      xg_against = .data$away_xg
    )

  away <- matches_df |>
    dplyr::transmute(
      match_id = if ("match_id" %in% names(matches_df)) .data$match_id else NA_character_,
      team = .data$away_team,
      match_date = .data$match_date,
      goals = .data$ftag,
      xg = .data$away_xg,
      goals_against = .data$fthg,
      xg_against = .data$home_xg
    )

  long <- dplyr::bind_rows(home, away) |>
    dplyr::arrange(.data$team, .data$match_date) |>
    dplyr::mutate(
      # Single-match overperformance
      overperf_attack = .data$goals - .data$xg,
      overperf_defense = .data$xg_against - .data$goals_against
    )

  long |>
    dplyr::group_by(.data$team) |>
    dplyr::mutate(
      # Rolling average overperformance (lagged to avoid leakage)
      rolling_overperf_attack = dplyr::lag(
        slider_mean(.data$overperf_attack, window),
        default = NA_real_
      ),
      rolling_overperf_defense = dplyr::lag(
        slider_mean(.data$overperf_defense, window),
        default = NA_real_
      )
    ) |>
    dplyr::ungroup() |>
    dplyr::select("team", "match_date", "match_id",
                  "rolling_overperf_attack", "rolling_overperf_defense")
}

#' Compute all xG-based features
#'
#' Convenience function to compute rolling xG, cumulative xG ratio,
#' and xG overperformance in one call.
#'
#' @param matches_df A tibble with goals and xG columns.
#' @param rolling_window Integer. Window for rolling averages (default 5).
#' @param overperf_window Integer. Window for overperformance (default 10).
#' @return A tibble with all xG features joined.
#' @family features
#' @export
compute_xg_features <- function(matches_df,
                                rolling_window = 5L,
                                overperf_window = 10L) {
  rlang::check_required(matches_df)

  # Check for xG data
  if (!all(c("home_xg", "away_xg") %in% names(matches_df))) {
    cli::cli_warn(c(
      "!" = "No xG data found in matches.",
      "i" = "Use {.fun join_xg_to_matches} to add xG data from FBref."
    ))
    return(tibble::tibble(
      team = character(),
      match_date = as.Date(character()),
      match_id = character()
    ))
  }

  # Compute each feature set
  rolling <- rolling_xg(matches_df, window = rolling_window)
  ratio <- cumulative_xg_ratio(matches_df)

  # Only compute overperformance if goals are available
  if (all(c("fthg", "ftag") %in% names(matches_df))) {
    overperf <- xg_overperformance(matches_df, window = overperf_window)

    # Join all features
    result <- rolling |>
      dplyr::left_join(
        ratio |> dplyr::select("team", "match_date", "match_id",
                               "xg_ratio", "match_num"),
        by = c("team", "match_date", "match_id")
      ) |>
      dplyr::left_join(
        overperf,
        by = c("team", "match_date", "match_id")
      )
  } else {
    result <- rolling |>
      dplyr::left_join(
        ratio |> dplyr::select("team", "match_date", "match_id",
                               "xg_ratio", "match_num"),
        by = c("team", "match_date", "match_id")
      )
  }

  result
}

# ============================================================================
# GAMESTATE-AWARE xG FEATURES
# ============================================================================

#' Compute gamestate-aware xG features
#'
#' Filters xG by match situation: tied (0-0 equivalent pressure), close
#' (1 goal difference), or lopsided (2+ goals). xG from lopsided
#' situations has near-zero predictive value as teams change tactics.
#'
#' This implements the key insight from Tony ElHabr's analysis: gamestate
#' strongly affects xG quality and predictive power.
#'
#' @param matches_df A tibble with xG and goal columns.
#' @param window Integer. Rolling window for averaging (default 5).
#' @return A tibble with gamestate-filtered xG features.
#' @family features
#' @export
compute_gamestate_xg <- function(matches_df, window = 5L)
{
  rlang::check_required(matches_df)


  required_cols <- c("match_date", "home_team", "away_team",
                     "home_xg", "away_xg", "fthg", "ftag")
  missing <- setdiff(required_cols, names(matches_df))
  if (length(missing) > 0) {
    cli::cli_abort(c(
      "x" = "Missing required columns: {.val {missing}}",
      "i" = "Need both goals and xG to compute gamestate-aware features."
    ))
  }

  # Without shot-level data, we approximate gamestate impact

  # by weighting xG based on final score margin
  # Close games (0-1 goal diff) get full weight
  # Lopsided games (3+ goal diff) get reduced weight

  home <- matches_df |>
    dplyr::transmute(
      match_id = if ("match_id" %in% names(matches_df)) .data$match_id else NA_character_,
      team = .data$home_team,
      opponent = .data$away_team,
      match_date = .data$match_date,
      xg_for = .data$home_xg,
      xg_against = .data$away_xg,
      goal_diff = abs(.data$fthg - .data$ftag),
      # Gamestate classification based on final margin
      gamestate = dplyr::case_when(
        .data$goal_diff == 0 ~ "tied",
        .data$goal_diff == 1 ~ "close",
        .data$goal_diff == 2 ~ "comfortable",
        TRUE ~ "lopsided"
      ),
      # Weight: full for competitive games, reduced for blowouts
      gamestate_weight = dplyr::case_when(
        .data$goal_diff <= 1 ~ 1.0,
        .data$goal_diff == 2 ~ 0.8,
        .data$goal_diff == 3 ~ 0.5,
        TRUE ~ 0.25  # 4+ goal difference: mostly garbage time
      ),
      is_competitive = .data$goal_diff <= 1
    )

  away <- matches_df |>
    dplyr::transmute(
      match_id = if ("match_id" %in% names(matches_df)) .data$match_id else NA_character_,
      team = .data$away_team,
      opponent = .data$home_team,
      match_date = .data$match_date,
      xg_for = .data$away_xg,
      xg_against = .data$home_xg,
      goal_diff = abs(.data$fthg - .data$ftag),
      gamestate = dplyr::case_when(
        .data$goal_diff == 0 ~ "tied",
        .data$goal_diff == 1 ~ "close",
        .data$goal_diff == 2 ~ "comfortable",
        TRUE ~ "lopsided"
      ),
      gamestate_weight = dplyr::case_when(
        .data$goal_diff <= 1 ~ 1.0,
        .data$goal_diff == 2 ~ 0.8,
        .data$goal_diff == 3 ~ 0.5,
        TRUE ~ 0.25
      ),
      is_competitive = .data$goal_diff <= 1
    )

  long <- dplyr::bind_rows(home, away) |>
    dplyr::arrange(.data$team, .data$match_date) |>
    dplyr::mutate(
      # Weighted xG: downweight lopsided games
      xg_for_weighted = .data$xg_for * .data$gamestate_weight,
      xg_against_weighted = .data$xg_against * .data$gamestate_weight
    )

  long |>
    dplyr::group_by(.data$team) |>
    dplyr::mutate(
      # Standard rolling xG (lagged)
      rolling_xg_for = dplyr::lag(
        slider_mean(.data$xg_for, window),
        default = NA_real_
      ),
      rolling_xg_against = dplyr::lag(
        slider_mean(.data$xg_against, window),
        default = NA_real_
      ),
      # Gamestate-weighted rolling xG (more predictive)
      rolling_xg_for_gs = dplyr::lag(
        slider_mean(.data$xg_for_weighted, window) /
          slider_mean(.data$gamestate_weight, window),
        default = NA_real_
      ),
      rolling_xg_against_gs = dplyr::lag(
        slider_mean(.data$xg_against_weighted, window) /
          slider_mean(.data$gamestate_weight, window),
        default = NA_real_
      ),
      # Competitive-only xG (strictest filter)
      rolling_xg_competitive = dplyr::lag(
        slider_mean(
          ifelse(.data$is_competitive, .data$xg_for, NA_real_),
          window
        ),
        default = NA_real_
      )
    ) |>
    dplyr::ungroup() |>
    dplyr::select(
      "team", "match_date", "match_id", "gamestate",
      "rolling_xg_for_gs", "rolling_xg_against_gs", "rolling_xg_competitive"
    )
}

# ============================================================================
# RATIO NORMALIZATION
# ============================================================================

#' Normalize features to ratio form
#'
#' Converts team/opponent features to ratio form: team / (team + opponent).
#' This captures relative strength in a bounded 0-1 metric that is
#' more predictive than raw differences.
#'
#' Based on Tony ElHabr's analysis showing ratio metrics outperform
#' difference metrics for xG-based prediction.
#'
#' @param team_value Numeric. Team's metric value.
#' @param opponent_value Numeric. Opponent's metric value.
#' @param na_value Numeric. Value to return when denominator is 0 (default 0.5).
#' @return Numeric in range 0-1. Team's share of total.
#' @family features
#' @export
ratio_normalize <- function(team_value, opponent_value, na_value = 0.5) {
  total <- team_value + opponent_value
  dplyr::case_when(
    is.na(team_value) | is.na(opponent_value) ~ NA_real_,
    total == 0 ~ na_value,
    TRUE ~ team_value / total
  )
}

#' Add ratio-normalized features to match data
#'
#' Computes ratio-normalized versions of rolling features for
#' both home and away teams. Requires rolling features to be
#' already computed (via [rolling_goals()] or [rolling_xg()]).
#'
#' @param matches_df A tibble with rolling feature columns.
#' @return The input tibble with additional ratio columns.
#' @family features
#' @export
add_ratio_features <- function(matches_df) {
  rlang::check_required(matches_df)

  result <- matches_df

  # Check for rolling goal features
  if (all(c("home_rolling_gf", "away_rolling_gf") %in% names(matches_df))) {
    result <- result |>
      dplyr::mutate(
        home_goals_ratio = ratio_normalize(.data$home_rolling_gf, .data$away_rolling_gf),
        away_goals_ratio = ratio_normalize(.data$away_rolling_gf, .data$home_rolling_gf)
      )
  }

  # Check for rolling xG features
  if (all(c("home_rolling_xg_for", "away_rolling_xg_for") %in% names(matches_df))) {
    result <- result |>
      dplyr::mutate(
        home_xg_ratio = ratio_normalize(.data$home_rolling_xg_for, .data$away_rolling_xg_for),
        away_xg_ratio = ratio_normalize(.data$away_rolling_xg_for, .data$home_rolling_xg_for)
      )
  }

  # Check for Elo ratings
  if (all(c("home_elo", "away_elo") %in% names(matches_df))) {
    result <- result |>
      dplyr::mutate(
        # For Elo, use sigmoid normalization instead of ratio
        # since Elo difference has a specific interpretation
        home_elo_prob = 1 / (1 + 10^((.data$away_elo - .data$home_elo) / 400))
      )
  }

  result
}

# ============================================================================
# RELIABILITY THRESHOLD ANALYSIS
# ============================================================================

#' Compute reliability threshold for a metric
#'
#' Calculates how many matches are needed for a metric to become
#' reliable (R² > threshold when predicting future outcomes).
#'
#' Based on Tony ElHabr's analysis showing xG ratio becomes reliable
#' around matchday 9-13 (R² > 0.5).
#'
#' @param matches_df A tibble with cumulative metrics.
#' @param metric_col Character. Name of the metric column.
#' @param outcome_col Character. Name of the outcome column.
#' @param r2_threshold Numeric. R² threshold for "reliable" (default 0.5).
#' @param min_matches Integer. Minimum matches per team to test (default 5).
#' @param max_matches Integer. Maximum matches to test (default 25).
#' @return A tibble with `match_num`, `r_squared`, and `is_reliable`.
#' @family features
#' @export
reliability_threshold <- function(matches_df,
                                   metric_col,
                                   outcome_col,
                                   r2_threshold = 0.5,
                                   min_matches = 5L,
                                   max_matches = 25L) {
  rlang::check_required(matches_df)
  rlang::check_required(metric_col)
  rlang::check_required(outcome_col)

  if (!metric_col %in% names(matches_df)) {
    cli::cli_abort("Column {.val {metric_col}} not found in data.")
  }
  if (!outcome_col %in% names(matches_df)) {
    cli::cli_abort("Column {.val {outcome_col}} not found in data.")
  }
  if (!"match_num" %in% names(matches_df)) {
    cli::cli_abort("Column {.val match_num} required. Use {.fun cumulative_xg_ratio} first.")
  }

  results <- vector("list", max_matches - min_matches + 1L)

  for (n in seq(min_matches, max_matches)) {
    # Filter to teams with at least n matches
    subset <- matches_df |>
      dplyr::filter(.data$match_num == n)

    if (nrow(subset) < 10) {
      results[[n - min_matches + 1L]] <- tibble::tibble(
        match_num = n,
        r_squared = NA_real_,
        n_teams = nrow(subset),
        is_reliable = NA
      )
      next
    }

    # Compute correlation
    metric <- subset[[metric_col]]
    outcome <- subset[[outcome_col]]

    valid <- !is.na(metric) & !is.na(outcome)
    if (sum(valid) < 10) {
      results[[n - min_matches + 1L]] <- tibble::tibble(
        match_num = n,
        r_squared = NA_real_,
        n_teams = sum(valid),
        is_reliable = NA
      )
      next
    }

    cor_val <- stats::cor(metric[valid], outcome[valid])
    r2 <- cor_val^2

    results[[n - min_matches + 1L]] <- tibble::tibble(
      match_num = n,
      r_squared = r2,
      n_teams = sum(valid),
      is_reliable = r2 >= r2_threshold
    )
  }

  dplyr::bind_rows(results)
}

#' Find first reliable matchday for a metric
#'
#' Returns the earliest match number where the metric achieves
#' the reliability threshold.
#'
#' @param reliability_df A tibble from [reliability_threshold()].
#' @return Integer. First reliable matchday, or NA if never reliable.
#' @family features
#' @export
first_reliable_matchday <- function(reliability_df) {
  reliable <- reliability_df |>
    dplyr::filter(.data$is_reliable == TRUE) |>
    dplyr::arrange(.data$match_num)

  if (nrow(reliable) == 0) {
    return(NA_integer_)
  }

  reliable$match_num[[1]]
}

# ============================================================================
# xG + xAG COMPOSITE
# ============================================================================

#' Compute xG + xAG composite metric
#'
#' Combines expected goals and expected assists (xAG) into a composite
#' metric. xG+xAG is more predictive than xG alone as it captures
#' build-up play quality.
#'
#' @param matches_df A tibble with xG and xAG columns.
#' @param window Integer. Rolling window (default 5).
#' @return A tibble with xG+xAG composite features.
#' @family features
#' @export
compute_xg_xag_composite <- function(matches_df, window = 5L) {
  rlang::check_required(matches_df)

  # Check for required columns
  has_xag <- all(c("home_xag", "away_xag") %in% names(matches_df))
  has_xg <- all(c("home_xg", "away_xg") %in% names(matches_df))

  if (!has_xg) {
    cli::cli_abort("Requires {.val home_xg} and {.val away_xg} columns.")
  }

  if (!has_xag) {
    cli::cli_warn(c(
      "!" = "No xAG columns found ({.val home_xag}, {.val away_xag}).",
      "i" = "Returning xG-only features. Add xAG data from FBref for full composite."
    ))
    return(rolling_xg(matches_df, window = window))
  }

  home <- matches_df |>
    dplyr::transmute(
      match_id = if ("match_id" %in% names(matches_df)) .data$match_id else NA_character_,
      team = .data$home_team,
      match_date = .data$match_date,
      xg = .data$home_xg,
      xag = .data$home_xag,
      xg_xag = .data$home_xg + .data$home_xag,
      xg_against = .data$away_xg,
      xag_against = .data$away_xag,
      xg_xag_against = .data$away_xg + .data$away_xag
    )

  away <- matches_df |>
    dplyr::transmute(
      match_id = if ("match_id" %in% names(matches_df)) .data$match_id else NA_character_,
      team = .data$away_team,
      match_date = .data$match_date,
      xg = .data$away_xg,
      xag = .data$away_xag,
      xg_xag = .data$away_xg + .data$away_xag,
      xg_against = .data$home_xg,
      xag_against = .data$home_xag,
      xg_xag_against = .data$home_xg + .data$home_xag
    )

  long <- dplyr::bind_rows(home, away) |>
    dplyr::arrange(.data$team, .data$match_date)

  long |>
    dplyr::group_by(.data$team) |>
    dplyr::mutate(
      # Rolling xG
      rolling_xg = dplyr::lag(
        slider_mean(.data$xg, window), default = NA_real_
      ),
      # Rolling xAG
      rolling_xag = dplyr::lag(
        slider_mean(.data$xag, window), default = NA_real_
      ),
      # Rolling xG+xAG composite
      rolling_xg_xag = dplyr::lag(
        slider_mean(.data$xg_xag, window), default = NA_real_
      ),
      # Against versions
      rolling_xg_against = dplyr::lag(
        slider_mean(.data$xg_against, window), default = NA_real_
      ),
      rolling_xg_xag_against = dplyr::lag(
        slider_mean(.data$xg_xag_against, window), default = NA_real_
      ),
      # Ratio form (most predictive)
      xg_xag_ratio = ratio_normalize(.data$rolling_xg_xag, .data$rolling_xg_xag_against)
    ) |>
    dplyr::ungroup() |>
    dplyr::select(
      "team", "match_date", "match_id",
      "rolling_xg", "rolling_xag", "rolling_xg_xag",
      "rolling_xg_against", "rolling_xg_xag_against", "xg_xag_ratio"
    )
}

#' Compute head-to-head record between two teams
#'
#' Returns historical record of matches between home and away teams,
#' using only information available before the specified date.
#'
#' @param matches_df A tibble with `match_date`, `home_team`, `away_team`, `ftr`.
#' @param home_team Character. Name of home team.
#' @param away_team Character. Name of away team.
#' @param as_of_date Date. Only consider matches before this date.
#' @param n Integer. Maximum number of past meetings to include (default 10).
#' @return A tibble with one row containing H2H statistics:
#'   `n_matches`, `home_wins`, `draws`, `away_wins`, `home_goals`, `away_goals`,
#'   `home_win_pct`, `draw_pct`, `away_win_pct`.
#' @family features
#' @export
h2h_record <- function(matches_df, home_team, away_team, as_of_date = Sys.Date(), n = 10L) {
  rlang::check_required(matches_df)
  rlang::check_required(home_team)
  rlang::check_required(away_team)

  # Rename parameters to avoid column name clash

  team_h <- home_team
  team_a <- away_team

  # Find all past meetings between these teams (in either direction)
  h2h <- matches_df |>
    dplyr::filter(
      .data$match_date < as_of_date,
      (.data$home_team == team_h & .data$away_team == team_a) |
        (.data$home_team == team_a & .data$away_team == team_h)
    ) |>
    dplyr::arrange(dplyr::desc(.data$match_date)) |>
    utils::head(n)

  if (nrow(h2h) == 0L) {
    return(tibble::tibble(
      home_team = home_team,
      away_team = away_team,
      n_matches = 0L,
      home_wins = NA_integer_,
      draws = NA_integer_,
      away_wins = NA_integer_,
      home_goals = NA_integer_,
      away_goals = NA_integer_,
      home_win_pct = NA_real_,
      draw_pct = NA_real_,
      away_win_pct = NA_real_
    ))
  }

  # Standardise perspective: count from `home_team`'s viewpoint
  # When home_team was actually at home
  home_at_home <- h2h |>
    dplyr::filter(.data$home_team == team_h)
  # When home_team was away (flip the result)
  home_away <- h2h |>
    dplyr::filter(.data$away_team == team_h)

  # Count results from home_team's perspective
  home_wins <- sum(home_at_home$ftr == "H", na.rm = TRUE) +
    sum(home_away$ftr == "A", na.rm = TRUE)
  draws <- sum(h2h$ftr == "D", na.rm = TRUE)
  away_wins <- sum(home_at_home$ftr == "A", na.rm = TRUE) +
    sum(home_away$ftr == "H", na.rm = TRUE)

  # Goals from home_team's perspective
  home_goals <- sum(home_at_home$fthg, na.rm = TRUE) +
    sum(home_away$ftag, na.rm = TRUE)
  away_goals <- sum(home_at_home$ftag, na.rm = TRUE) +
    sum(home_away$fthg, na.rm = TRUE)

  n_matches <- nrow(h2h)

  tibble::tibble(
    home_team = home_team,
    away_team = away_team,
    n_matches = n_matches,
    home_wins = home_wins,
    draws = draws,
    away_wins = away_wins,
    home_goals = home_goals,
    away_goals = away_goals,
    home_win_pct = home_wins / n_matches,
    draw_pct = draws / n_matches,
    away_win_pct = away_wins / n_matches
  )
}

#' Add H2H features to match data
#'
#' Computes head-to-head record for each match in the dataset,
#' using only historical data available before each match.
#'
#' @param matches_df A tibble with `match_date`, `home_team`, `away_team`, `ftr`.
#' @param n Integer. Number of past meetings to consider (default 10).
#' @return The input tibble with additional H2H columns.
#' @family features
#' @export
add_h2h_features <- function(matches_df, n = 10L) {
  rlang::check_required(matches_df)

  # Handle empty input
  if (nrow(matches_df) == 0L) {
    return(dplyr::mutate(
      matches_df,
      h2h_n_matches = integer(),
      h2h_home_wins = integer(),
      h2h_draws = integer(),
      h2h_away_wins = integer(),
      h2h_home_goals = integer(),
      h2h_away_goals = integer(),
      h2h_home_win_pct = numeric(),
      h2h_draw_pct = numeric(),
      h2h_away_win_pct = numeric()
    ))
  }

  # Pre-compute for each match
  h2h_list <- vector("list", nrow(matches_df))

  for (i in seq_len(nrow(matches_df))) {
    h2h_list[[i]] <- h2h_record(
      matches_df,
      home_team = matches_df$home_team[[i]],
      away_team = matches_df$away_team[[i]],
      as_of_date = matches_df$match_date[[i]],
      n = n
    )
  }

  h2h_df <- dplyr::bind_rows(h2h_list) |>
    dplyr::select(-"home_team", -"away_team") |>
    dplyr::rename_with(~ paste0("h2h_", .x))

  dplyr::bind_cols(matches_df, h2h_df)
}

# ============================================================================
# FORM STREAK FEATURES
# ============================================================================

#' Compute form streaks for a team
#'
#' Calculates current win streak, loss streak, unbeaten streak, and winless
#' streak as of each match date.
#'
#' @param matches_df A tibble with `match_date`, `home_team`, `away_team`, `ftr`.
#' @param team Character. Team name.
#' @param as_of_date Date. Calculate streaks as of this date.
#' @return A tibble with streak statistics.
#' @family features
#' @export
form_streak <- function(matches_df, team, as_of_date = Sys.Date()) {
  rlang::check_required(matches_df)
  rlang::check_required(team)

  # Get all matches for this team before the date
  team_matches <- matches_df |>
    dplyr::filter(
      .data$match_date < as_of_date,
      .data$home_team == team | .data$away_team == team
    ) |>
    dplyr::arrange(dplyr::desc(.data$match_date)) |>
    dplyr::mutate(
      # Result from team's perspective
      result = dplyr::case_when(
        .data$home_team == team & .data$ftr == "H" ~ "W",
        .data$away_team == team & .data$ftr == "A" ~ "W",
        .data$ftr == "D" ~ "D",
        TRUE ~ "L"
      )
    )

  if (nrow(team_matches) == 0L) {
    return(tibble::tibble(
      team = team,
      win_streak = 0L,
      loss_streak = 0L,
      unbeaten_streak = 0L,
      winless_streak = 0L,
      n_matches = 0L
    ))
  }

  # Count current streaks (from most recent backwards)
  results <- team_matches$result

  # Win streak: consecutive wins from most recent

  win_streak <- 0L
  for (r in results) {
    if (r == "W") win_streak <- win_streak + 1L else break
  }

  # Loss streak: consecutive losses from most recent
  loss_streak <- 0L
  for (r in results) {
    if (r == "L") loss_streak <- loss_streak + 1L else break
  }

  # Unbeaten streak: consecutive non-losses (W or D)
  unbeaten_streak <- 0L
  for (r in results) {
    if (r %in% c("W", "D")) unbeaten_streak <- unbeaten_streak + 1L else break
  }

  # Winless streak: consecutive non-wins (L or D)
  winless_streak <- 0L
  for (r in results) {
    if (r %in% c("L", "D")) winless_streak <- winless_streak + 1L else break
  }

  tibble::tibble(
    team = team,
    win_streak = win_streak,
    loss_streak = loss_streak,
    unbeaten_streak = unbeaten_streak,
    winless_streak = winless_streak,
    n_matches = nrow(team_matches)
  )
}

#' Add form streak features to match data
#'
#' Computes current form streaks for home and away teams at each match,
#' using only historical data available before each match.
#'
#' @param matches_df A tibble with `match_date`, `home_team`, `away_team`, `ftr`.
#' @return The input tibble with additional form streak columns.
#' @family features
#' @export
add_form_streaks <- function(matches_df) {
  rlang::check_required(matches_df)

  if (nrow(matches_df) == 0L) {
    return(dplyr::mutate(
      matches_df,
      home_win_streak = integer(),
      home_loss_streak = integer(),
      home_unbeaten_streak = integer(),
      home_winless_streak = integer(),
      away_win_streak = integer(),
      away_loss_streak = integer(),
      away_unbeaten_streak = integer(),
      away_winless_streak = integer()
    ))
  }

  # Pre-compute for each match
  n <- nrow(matches_df)
  home_win <- integer(n)
  home_loss <- integer(n)
  home_unbeaten <- integer(n)
  home_winless <- integer(n)
  away_win <- integer(n)
  away_loss <- integer(n)
  away_unbeaten <- integer(n)
  away_winless <- integer(n)

  for (i in seq_len(n)) {
    home_streak <- form_streak(
      matches_df,
      team = matches_df$home_team[[i]],
      as_of_date = matches_df$match_date[[i]]
    )
    away_streak <- form_streak(
      matches_df,
      team = matches_df$away_team[[i]],
      as_of_date = matches_df$match_date[[i]]
    )

    home_win[[i]] <- home_streak$win_streak
    home_loss[[i]] <- home_streak$loss_streak
    home_unbeaten[[i]] <- home_streak$unbeaten_streak
    home_winless[[i]] <- home_streak$winless_streak
    away_win[[i]] <- away_streak$win_streak
    away_loss[[i]] <- away_streak$loss_streak
    away_unbeaten[[i]] <- away_streak$unbeaten_streak
    away_winless[[i]] <- away_streak$winless_streak
  }

  matches_df |>
    dplyr::mutate(
      home_win_streak = home_win,
      home_loss_streak = home_loss,
      home_unbeaten_streak = home_unbeaten,
      home_winless_streak = home_winless,
      away_win_streak = away_win,
      away_loss_streak = away_loss,
      away_unbeaten_streak = away_unbeaten,
      away_winless_streak = away_winless
    )
}

# ============================================================================
# REST DAYS FEATURES
# ============================================================================

#' Compute days since last match for a team
#'
#' Returns the number of days since the team's previous match,
#' using only information available before the specified date.
#'
#' @param matches_df A tibble with `match_date`, `home_team`, `away_team`.
#' @param team Character. Team name.
#' @param as_of_date Date. Calculate rest days as of this date.
#' @return Integer. Days since last match, or NA if no previous match.
#' @family features
#' @export
rest_days <- function(matches_df, team, as_of_date) {
  rlang::check_required(matches_df)
  rlang::check_required(team)
  rlang::check_required(as_of_date)

  # Find most recent match before as_of_date

  last_match <- matches_df |>
    dplyr::filter(
      .data$match_date < as_of_date,
      .data$home_team == team | .data$away_team == team
    ) |>
    dplyr::arrange(dplyr::desc(.data$match_date)) |>
    utils::head(1L)

  if (nrow(last_match) == 0L) {
    return(NA_integer_)
  }

  as.integer(as.Date(as_of_date) - as.Date(last_match$match_date[[1]]))
}

#' Add rest days features to match data
#'
#' Computes days since last match for both home and away teams,
#' plus the rest advantage (home rest - away rest).
#'
#' @param matches_df A tibble with `match_date`, `home_team`, `away_team`.
#' @return The input tibble with `home_rest_days`, `away_rest_days`,
#'   `rest_advantage` columns.
#' @family features
#' @export
add_rest_days <- function(matches_df) {
  rlang::check_required(matches_df)

  if (nrow(matches_df) == 0L) {
    return(dplyr::mutate(
      matches_df,
      home_rest_days = integer(),
      away_rest_days = integer(),
      rest_advantage = integer()
    ))
  }

  n <- nrow(matches_df)
  home_rest <- integer(n)
  away_rest <- integer(n)

  for (i in seq_len(n)) {
    home_rest[[i]] <- rest_days(
      matches_df,
      team = matches_df$home_team[[i]],
      as_of_date = matches_df$match_date[[i]]
    )
    away_rest[[i]] <- rest_days(
      matches_df,
      team = matches_df$away_team[[i]],
      as_of_date = matches_df$match_date[[i]]
    )
  }

  matches_df |>
    dplyr::mutate(
      home_rest_days = home_rest,
      away_rest_days = away_rest,
      rest_advantage = home_rest - away_rest
    )
}

# ============================================================================
# LEAGUE POSITION FEATURES
# ============================================================================

#' Compute league table at a specific date
#'
#' Calculates league standings using only matches played before the
#' specified date. Standard points system: 3 for win, 1 for draw, 0 for loss.
#'
#' @param matches_df A tibble with `match_date`, `home_team`, `away_team`,
#'   `ftr`, `fthg`, `ftag`.
#' @param as_of_date Date. Calculate table as of this date.
#' @param league_code Character. Optional league filter (default NULL = all).
#' @param season Character. Optional season filter (default NULL = all).
#' @return A tibble with league table: `position`, `team`, `played`, `won`,
#'   `drawn`, `lost`, `gf`, `ga`, `gd`, `points`.
#' @family features
#' @export
league_table <- function(matches_df, as_of_date, league_code = NULL, season = NULL) {
  rlang::check_required(matches_df)
  rlang::check_required(as_of_date)

  # Filter to relevant matches
  df <- matches_df |>
    dplyr::filter(.data$match_date < as_of_date)

  if (!is.null(league_code) && "league_code" %in% names(df)) {
    df <- df |> dplyr::filter(.data$league_code == !!league_code)
  }
  if (!is.null(season) && "season" %in% names(df)) {
    df <- df |> dplyr::filter(.data$season == !!season)
  }

  if (nrow(df) == 0L) {
    return(tibble::tibble(
      position = integer(),
      team = character(),
      played = integer(),
      won = integer(),
      drawn = integer(),
      lost = integer(),
      gf = integer(),
      ga = integer(),
      gd = integer(),
      points = integer()
    ))
  }

  # Home stats
  home_stats <- df |>
    dplyr::group_by(team = .data$home_team) |>
    dplyr::summarise(
      played = dplyr::n(),
      won = sum(.data$ftr == "H", na.rm = TRUE),
      drawn = sum(.data$ftr == "D", na.rm = TRUE),
      lost = sum(.data$ftr == "A", na.rm = TRUE),
      gf = sum(.data$fthg, na.rm = TRUE),
      ga = sum(.data$ftag, na.rm = TRUE),
      .groups = "drop"
    )

  # Away stats
  away_stats <- df |>
    dplyr::group_by(team = .data$away_team) |>
    dplyr::summarise(
      played = dplyr::n(),
      won = sum(.data$ftr == "A", na.rm = TRUE),
      drawn = sum(.data$ftr == "D", na.rm = TRUE),
      lost = sum(.data$ftr == "H", na.rm = TRUE),
      gf = sum(.data$ftag, na.rm = TRUE),
      ga = sum(.data$fthg, na.rm = TRUE),
      .groups = "drop"
    )

  # Combine and compute table
  table <- dplyr::bind_rows(home_stats, away_stats) |>
    dplyr::group_by(.data$team) |>
    dplyr::summarise(
      played = sum(.data$played),
      won = sum(.data$won),
      drawn = sum(.data$drawn),
      lost = sum(.data$lost),
      gf = sum(.data$gf),
      ga = sum(.data$ga),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      gd = .data$gf - .data$ga,
      points = 3L * .data$won + .data$drawn
    ) |>
    dplyr::arrange(
      dplyr::desc(.data$points),
      dplyr::desc(.data$gd),
      dplyr::desc(.data$gf)
    ) |>
    dplyr::mutate(position = dplyr::row_number()) |>
    dplyr::select("position", "team", "played", "won", "drawn", "lost",
                  "gf", "ga", "gd", "points")

  table
}

#' Get team position at a specific date
#'
#' Returns the league position of a team based on matches played
#' before the specified date.
#'
#' @param matches_df A tibble with match data.
#' @param team Character. Team name.
#' @param as_of_date Date. Calculate position as of this date.
#' @param league_code Character. Optional league filter.
#' @param season Character. Optional season filter.
#' @return Integer. League position (1 = top), or NA if team not found.
#' @family features
#' @export
team_position <- function(matches_df, team, as_of_date,
                          league_code = NULL, season = NULL) {
  rlang::check_required(matches_df)
  rlang::check_required(team)
  rlang::check_required(as_of_date)

  table <- league_table(matches_df, as_of_date,
                        league_code = league_code, season = season)

  if (nrow(table) == 0L) {
    return(NA_integer_)
  }

  pos <- table$position[table$team == team]
  if (length(pos) == 0L) {
    return(NA_integer_)
  }

  pos[[1]]
}

#' Add league position features to match data
#'
#' Computes league position for both home and away teams at match time,
#' plus position difference (away_pos - home_pos, positive = home higher).
#'
#' @param matches_df A tibble with match data including `league_code`, `season`.
#' @return The input tibble with `home_position`, `away_position`,
#'   `position_diff` columns.
#' @family features
#' @export
add_league_positions <- function(matches_df) {
  rlang::check_required(matches_df)

  if (nrow(matches_df) == 0L) {
    return(dplyr::mutate(
      matches_df,
      home_position = integer(),
      away_position = integer(),
      position_diff = integer()
    ))
  }

  # Check if we have league/season columns
  has_league <- "league_code" %in% names(matches_df)
  has_season <- "season" %in% names(matches_df)

  n <- nrow(matches_df)
  home_pos <- integer(n)
  away_pos <- integer(n)

  for (i in seq_len(n)) {
    league <- if (has_league) matches_df$league_code[[i]] else NULL
    season <- if (has_season) matches_df$season[[i]] else NULL

    home_pos[[i]] <- team_position(
      matches_df,
      team = matches_df$home_team[[i]],
      as_of_date = matches_df$match_date[[i]],
      league_code = league,
      season = season
    )
    away_pos[[i]] <- team_position(
      matches_df,
      team = matches_df$away_team[[i]],
      as_of_date = matches_df$match_date[[i]],
      league_code = league,
      season = season
    )
  }

  matches_df |>
    dplyr::mutate(
      home_position = home_pos,
      away_position = away_pos,
      position_diff = away_pos - home_pos  # Positive = home is higher
    )
}
