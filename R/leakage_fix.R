#' Bet-time cutoff: as-of feature joins
#'
#' Wraps existing rolling-feature outputs with a bet-time cutoff so
#' that a match M at date `t_M` sees only feature values whose source
#' data is observed at dates `<= t_M - cutoff_days`. This defends
#' against the Wednesday-for-Monday leakage pattern, where a feature
#' for a Saturday match is contaminated by a midweek fixture played
#' between Pinnacle's opening price and kickoff.
#'
#' The existing `rolling_goals()` and `compute_elo()` already produce
#' "pre-match" time series (one row per team per match date with the
#' state *just before* that match). Applying an as-of join that looks
#' up the latest such row with `feature_date <= target_date - cutoff`
#' gives a strictly leak-free feature value without touching their
#' internals.
#'
#' Freshness trade-off: the cutoff feature is what the bettor would
#' have seen `cutoff_days` before kickoff, not what the latest row
#' immediately before the bet timestamp would have been. For a team
#' whose most recent match was `d` days ago, the cutoff feature is
#' equivalent to the standard feature if `d >= cutoff_days`, and
#' slightly staler if `d < cutoff_days` (in which case it reflects an
#' earlier row).
#'
#' @family features
#' @name leakage_fix
NULL

#' Apply an as-of cutoff to a per-team, per-date feature series
#'
#' @param feature_df Tibble with columns `team`, `match_date`, and
#'   one or more feature columns. Must be pre-match values (typically
#'   the output of `rolling_goals()` or `compute_elo()`).
#' @param target_df Tibble with columns `match_id`, `home_team`,
#'   `away_team`, `match_date`. One row per target match.
#' @param feature_cols Character vector of feature columns to carry
#'   through. Columns are suffixed with `home_` and `away_`.
#' @param cutoff_days Integer number of days to step back from
#'   `match_date` before looking up the most recent feature row.
#'   Default 7 (typical top-tier Pinnacle AH opening timing).
#' @return `target_df` with `home_<feature>` and `away_<feature>`
#'   columns added.
#' @family features
#' @export
apply_asof_cutoff <- function(feature_df, target_df,
                              feature_cols, cutoff_days = 7L) {
  rlang::check_required(feature_df)
  rlang::check_required(target_df)
  rlang::check_required(feature_cols)

  cutoff <- as.integer(cutoff_days)

  feat <- feature_df |>
    dplyr::select("team", "match_date", dplyr::all_of(feature_cols)) |>
    dplyr::arrange(.data$team, .data$match_date) |>
    dplyr::rename(feature_date = "match_date")

  targets_with_cut <- target_df |>
    dplyr::mutate(cutoff_date = .data$match_date - cutoff)

  home_feat <- feat |>
    dplyr::rename_with(~ paste0("home_", .x), dplyr::all_of(feature_cols))
  away_feat <- feat |>
    dplyr::rename_with(~ paste0("away_", .x), dplyr::all_of(feature_cols))

  with_home <- targets_with_cut |>
    dplyr::left_join(
      home_feat,
      by = dplyr::join_by(home_team == team, closest(cutoff_date >= feature_date))
    ) |>
    dplyr::select(-"feature_date")

  with_both <- with_home |>
    dplyr::left_join(
      away_feat,
      by = dplyr::join_by(away_team == team, closest(cutoff_date >= feature_date))
    ) |>
    dplyr::select(-"feature_date", -"cutoff_date")

  with_both
}
