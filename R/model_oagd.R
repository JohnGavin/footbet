#' Opposition-Adjusted Goal Difference (OAGD) Model
#'
#' Rolling mixed-effects paired-comparison model that estimates
#' team strength from goal differences, adjusts recent form for
#' opposition quality, and predicts the full GD distribution.
#'
#' @name oagd
#' @family models
NULL

# -- Data preparation --------------------------------------------------------

#' Prepare match data for OAGD modelling
#'
#' Queries DuckDB for match results and computes matchday numbers
#' (fixture round number: ceiling(row_number() / (n_teams / 2)), sorted by date).
#'
#' @param con A DBI connection to the footbet DuckDB.
#' @param seasons Character vector of season codes (e.g. `"2425"`).
#' @param leagues Character vector of league codes. Defaults to all 10.
#' @return A tibble with columns: `match_id`, `season`, `league_code`,
#'   `match_date`, `matchday`, `home_team`, `away_team`, `gd_home`.
#' @family models
#' @export
oagd_match_data <- function(con,
                            seasons = c("2223", "2324", "2425"),
                            leagues = NULL) {
  rlang::check_required(con)

  q <- dplyr::tbl(con, "matches") |>
    dplyr::filter(.data$season %in% !!seasons) |>
    dplyr::select("match_id", "season", "league_code", "match_date",
                  "home_team", "away_team", "fthg", "ftag")

  if (!is.null(leagues)) {
    q <- q |> dplyr::filter(.data$league_code %in% !!leagues)
  }

  q |>
    dplyr::collect() |>
    dplyr::mutate(gd_home = .data$fthg - .data$ftag) |>
    dplyr::arrange(.data$match_date) |>
    dplyr::group_by(.data$season, .data$league_code) |>
    dplyr::mutate(
      matchday = ceiling(
        dplyr::row_number() /
          (dplyr::n_distinct(c(.data$home_team, .data$away_team)) / 2L)
      )
    ) |>
    dplyr::ungroup() |>
    dplyr::select(-"fthg", -"ftag")
}

#' Add Pinnacle closing odds to match data
#'
#' Left-joins Pinnacle closing 1x2 odds and computes devigged
#' implied probabilities (normalised to sum to 1).
#'
#' @param matches Tibble from [oagd_match_data()].
#' @param con A DBI connection to the footbet DuckDB.
#' @return `matches` with added columns: `odds_h`, `odds_d`, `odds_a`,
#'   `implied_h`, `implied_d`, `implied_a`.
#' @family models
#' @export
oagd_add_odds <- function(matches, con) {
  rlang::check_required(matches)
  rlang::check_required(con)

  odds <- dplyr::tbl(con, "match_odds") |>
    dplyr::filter(
      .data$snapshot_type == "closing",
      .data$market == "1x2"
    ) |>
    dplyr::select("match_id", "odds_h", "odds_d", "odds_a") |>
    dplyr::collect()

  out <- dplyr::left_join(matches, odds, by = "match_id")

  # Devig: normalise raw implied probabilities to sum to 1
  out |>
    dplyr::mutate(
      raw_h = 1 / .data$odds_h,
      raw_d = 1 / .data$odds_d,
      raw_a = 1 / .data$odds_a,
      raw_sum = .data$raw_h + .data$raw_d + .data$raw_a,
      implied_h = .data$raw_h / .data$raw_sum,
      implied_d = .data$raw_d / .data$raw_sum,
      implied_a = .data$raw_a / .data$raw_sum
    ) |>
    dplyr::select(-"raw_h", -"raw_d", -"raw_a", -"raw_sum")
}

# -- Rolling paired-comparison fit -------------------------------------------

#' Fit OAGD model on a single matchday window
#'
#' Fits `lmer(gd_home ~ 1 + (1|home_team) + (1|away_team))` on
#' matches within `[matchday - window + 1, matchday]`. The intercept
#' estimates home advantage; random effects estimate team strengths.
#'
#' @param data Tibble from [oagd_match_data()], filtered to one league-season.
#' @param target_matchday Integer. The matchday to fit up to.
#' @param window Integer. Number of matchdays in the rolling window.
#' @return A list with `fit` (lmerMod), `eta` (home advantage),
#'   `strengths` (tibble of team random effects), `matchday`, `window`.
#'   Returns `NULL` if the fit fails to converge.
#' @family models
#' @export
oagd_fit_window <- function(data, target_matchday, window = 8L) {
  rlang::check_installed("lme4", reason = "to fit OAGD mixed-effects models")
  rlang::check_required(data)

  min_md <- max(1L, target_matchday - window + 1L)
  window_data <- data |>
    dplyr::filter(.data$matchday >= min_md, .data$matchday <= target_matchday)

  if (nrow(window_data) < 10L) {
    return(NULL)
  }

  # Need at least 3 distinct teams on each side

  n_home <- dplyr::n_distinct(window_data$home_team)
  n_away <- dplyr::n_distinct(window_data$away_team)
  if (n_home < 3L || n_away < 3L) {
    return(NULL)
  }

  fit <- tryCatch(
    lme4::lmer(
      gd_home ~ 1 + (1 | home_team) + (1 | away_team),
      data = window_data,
      REML = FALSE,
      control = lme4::lmerControl(
        optimizer = "bobyqa",
        calc.derivs = FALSE
      )
    ),
    error = function(e) {
      cli::cli_warn("OAGD fit failed at matchday {target_matchday}: {conditionMessage(e)}")
      NULL
    }
  )

  if (is.null(fit)) return(NULL)

  eta <- lme4::fixef(fit)[["(Intercept)"]]
  re <- lme4::ranef(fit)

  home_re <- tibble::tibble(
    team = rownames(re$home_team),
    alpha_home = re$home_team[["(Intercept)"]]
  )
  away_re <- tibble::tibble(
    team = rownames(re$away_team),
    alpha_away = re$away_team[["(Intercept)"]]
  )

  strengths <- dplyr::full_join(home_re, away_re, by = "team") |>
    dplyr::mutate(
      alpha_home = tidyr::replace_na(.data$alpha_home, 0),
      alpha_away = tidyr::replace_na(.data$alpha_away, 0),
      alpha = (.data$alpha_home - .data$alpha_away) / 2
    )

  list(
    fit = fit,
    eta = eta,
    strengths = strengths,
    matchday = target_matchday,
    window = window
  )
}

#' Fit OAGD model across all matchdays in a league-season
#'
#' Slides the fitting window forward one matchday at a time.
#'
#' @param data Tibble from [oagd_match_data()], filtered to one league-season.
#' @param window Integer. Rolling window size in matchdays.
#' @return A list of fit results (one per matchday), keyed by matchday.
#'   Failed fits are `NULL`.
#' @family models
#' @export
oagd_roll_fits <- function(data, window = 8L) {
  rlang::check_required(data)

  matchdays <- sort(unique(data$matchday))
  # Start fitting from the window-th matchday
  fit_from <- matchdays[matchdays >= window]

  fits <- purrr::map(fit_from, function(md) {
    oagd_fit_window(data, target_matchday = md, window = window)
  }) |>
    purrr::set_names(fit_from)

  n_ok <- sum(!purrr::map_lgl(fits, is.null))
  n_fail <- length(fits) - n_ok
  if (n_fail > 0L) {
    cli::cli_inform(
      "OAGD rolling fits: {n_ok} OK, {n_fail} failed ({round(100 * n_fail / length(fits), 1)}%)"
    )
  }

  fits
}

# -- Residuals and form -----------------------------------------------------

#' Compute opposition-adjusted residuals
#'
#' For each match, computes `residual = gd_home - expected_gd` where
#' expected GD comes from the OAGD fit at that matchday.
#'
#' @param data Tibble from [oagd_match_data()], one league-season.
#' @param fits List from [oagd_roll_fits()].
#' @return `data` with added column `residual`. Matches without a
#'   corresponding fit get `NA`.
#' @family models
#' @export
oagd_residuals <- function(data, fits) {
  rlang::check_required(data)
  rlang::check_required(fits)

  data |>
    dplyr::mutate(
      residual = purrr::pmap_dbl(
        list(.data$matchday, .data$home_team, .data$away_team, .data$gd_home),
        function(md, ht, at, gd) {
          md_char <- as.character(md)
          f <- fits[[md_char]]
          if (is.null(f)) return(NA_real_)

          s <- f$strengths
          ah <- s$alpha_home[s$team == ht]
          aa <- s$alpha_away[s$team == at]
          if (length(ah) == 0L) ah <- 0
          if (length(aa) == 0L) aa <- 0

          expected <- f$eta + ah + aa
          gd - expected
        }
      )
    )
}

#' Compute exponentially-weighted form from residuals
#'
#' For each team-matchday, takes the last K residuals (from that
#' team's perspective — sign-flipped for away matches) and applies
#' exponential decay weights.
#'
#' @param data_with_resid Tibble from [oagd_residuals()].
#' @param K Integer. Number of past matches to use (default 4).
#' @param half_life Numeric. Half-life in matches for exponential
#'   weighting (default 2).
#' @return A tibble with `team`, `matchday`, `form`.
#' @family models
#' @export
oagd_form <- function(data_with_resid, K = 4L, half_life = 2) {
  rlang::check_required(data_with_resid)

  # Reshape to team-level: one row per team per match
  home <- data_with_resid |>
    dplyr::transmute(
      team = .data$home_team,
      matchday = .data$matchday,
      match_date = .data$match_date,
      resid = .data$residual  # positive = home team beat expectations
    )

  away <- data_with_resid |>
    dplyr::transmute(
      team = .data$away_team,
      matchday = .data$matchday,
      match_date = .data$match_date,
      resid = -.data$residual  # flip: positive = away team beat expectations
    )

  team_matches <- dplyr::bind_rows(home, away) |>
    dplyr::filter(!is.na(.data$resid)) |>
    dplyr::arrange(.data$team, .data$match_date)

  # For each team, compute rolling weighted mean of last K residuals
  team_matches |>
    dplyr::group_by(.data$team) |>
    dplyr::mutate(
      form = purrr::map_dbl(dplyr::row_number(), function(i) {
        if (i == 1L) return(0)
        start <- max(1L, i - K)
        resids <- .data$resid[start:(i - 1L)]
        n_r <- length(resids)
        # Weights: most recent = highest weight
        weights <- 2^(-(n_r:1) / half_life)
        weights <- weights / sum(weights)
        sum(resids * weights)
      })
    ) |>
    dplyr::ungroup() |>
    dplyr::select("team", "matchday", "form")
}
