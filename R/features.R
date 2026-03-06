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
