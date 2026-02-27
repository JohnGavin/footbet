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
