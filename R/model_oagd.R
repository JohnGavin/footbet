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
    dplyr::ungroup()
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
#' Fits two Poisson GLMMs — one for home goals, one for away goals —
#' to separate attack and defence strengths (Dixon-Coles style).
#' Uses `lme4::glmer()` with Poisson family.
#'
#' @param data Tibble from [oagd_match_data()], filtered to one league-season.
#'   Must contain `fthg` and `ftag` columns.
#' @param target_matchday Integer. The matchday to fit up to.
#' @param window Integer. Number of matchdays in the rolling window.
#' @return A list with `eta_home` (home goals intercept), `eta_away`
#'   (away goals intercept), `strengths` (tibble with `team`, `attack`,
#'   `defence`), `matchday`, `window`. Returns `NULL` if fit fails.
#' @family models
#' @export
oagd_fit_window <- function(data, target_matchday, window = 8L) {
  rlang::check_installed("lme4", reason = "to fit OAGD mixed-effects models")
  rlang::check_required(data)

  min_md <- max(1L, target_matchday - window + 1L)
  window_data <- data |>
    dplyr::filter(.data$matchday >= min_md, .data$matchday <= target_matchday)

  if (nrow(window_data) < 10L) return(NULL)

  n_home <- dplyr::n_distinct(window_data$home_team)
  n_away <- dplyr::n_distinct(window_data$away_team)
  if (n_home < 3L || n_away < 3L) return(NULL)

  ctrl <- lme4::glmerControl(optimizer = "bobyqa", calc.derivs = FALSE)

  # Model 1: home goals ~ (1|home_team) + (1|away_team)
  # home_team RE = attack strength, away_team RE = defence weakness
  fit_h <- tryCatch(
    lme4::glmer(fthg ~ 1 + (1 | home_team) + (1 | away_team),
                data = window_data, family = "poisson", control = ctrl),
    error = function(e) NULL
  )

  # Model 2: away goals ~ (1|away_team) + (1|home_team)
  # away_team RE = attack strength, home_team RE = defence weakness
  fit_a <- tryCatch(
    lme4::glmer(ftag ~ 1 + (1 | away_team) + (1 | home_team),
                data = window_data, family = "poisson", control = ctrl),
    error = function(e) NULL
  )

  if (is.null(fit_h) || is.null(fit_a)) {
    cli::cli_warn("OAGD fit failed at matchday {target_matchday}")
    return(NULL)
  }

  eta_home <- lme4::fixef(fit_h)[["(Intercept)"]]
  eta_away <- lme4::fixef(fit_a)[["(Intercept)"]]

  # Attack: how many goals a team scores (home_team RE from fit_h + away_team RE from fit_a)
  re_h <- lme4::ranef(fit_h)
  re_a <- lme4::ranef(fit_a)

  attack_home <- tibble::tibble(
    team = rownames(re_h$home_team),
    att_h = re_h$home_team[["(Intercept)"]]
  )
  attack_away <- tibble::tibble(
    team = rownames(re_a$away_team),
    att_a = re_a$away_team[["(Intercept)"]]
  )
  # Defence: how many goals a team concedes (away_team RE from fit_h = defence weakness at home,
  #          home_team RE from fit_a = defence weakness away)
  defence_home <- tibble::tibble(
    team = rownames(re_h$away_team),
    def_h = re_h$away_team[["(Intercept)"]]
  )
  defence_away <- tibble::tibble(
    team = rownames(re_a$home_team),
    def_a = re_a$home_team[["(Intercept)"]]
  )

  # Combine: attack = mean of home/away attack REs, defence = mean of home/away defence REs
  strengths <- attack_home |>
    dplyr::full_join(attack_away, by = "team") |>
    dplyr::full_join(defence_home, by = "team") |>
    dplyr::full_join(defence_away, by = "team") |>
    dplyr::mutate(
      dplyr::across(c("att_h", "att_a", "def_h", "def_a"),
                    \(x) tidyr::replace_na(x, 0)),
      attack = (.data$att_h + .data$att_a) / 2,
      defence = (.data$def_h + .data$def_a) / 2
    ) |>
    dplyr::select("team", "attack", "defence")

  list(
    eta_home = eta_home,
    eta_away = eta_away,
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
          att_h <- s$attack[s$team == ht]
          def_a <- s$defence[s$team == at]
          att_a <- s$attack[s$team == at]
          def_h <- s$defence[s$team == ht]
          if (length(att_h) == 0L) att_h <- 0
          if (length(def_a) == 0L) def_a <- 0
          if (length(att_a) == 0L) att_a <- 0
          if (length(def_h) == 0L) def_h <- 0

          # Expected goals from Poisson (log-link)
          exp_home <- exp(f$eta_home + att_h + def_a)
          exp_away <- exp(f$eta_away + att_a + def_h)
          expected_gd <- exp_home - exp_away
          gd - expected_gd
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
