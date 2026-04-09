#' Closing Line Value (CLV) diagnostics for Asian Handicap bets
#'
#' Implements the standard sharp-bettor CLV test: for each bet the model
#' would place at the Pinnacle pre-match price (`pahh`), compare against
#' the market closing price (`AvgCAHH`) from football-data.co.uk. Positive
#' mean CLV implies the model is finding edges that the market eventually
#' prices in; mean CLV near zero implies market efficiency; negative CLV
#' implies the model is actively worse than the close.
#'
#' Note: football-data.co.uk does NOT publish a Pinnacle-specific closing
#' AH column. `AvgCAHH`/`AvgCAHA` is the market average closing AH price
#' and is used as the honest close proxy. Limitation documented in
#' `plans/MODEL_CATALOGUE.md`.
#'
#' @family decisions
#' @name clv
NULL

#' Load closing Asian Handicap prices from raw football-data.co.uk CSVs
#'
#' Re-parses the raw CSVs to extract the closing AH columns that
#' `parse_fd_odds()` does not currently emit, keyed by `match_id`.
#' This is a post-hoc diagnostic path and does not modify the main
#' odds schema or DuckDB tables.
#'
#' @param raw_dir Directory containing raw football-data.co.uk CSVs.
#' @return Tibble with `match_id`, `league_code`, `psch`, `pscd`, `psca`,
#'   `ah_line_close`, `avg_cahh`, `avg_caha`, `max_cahh`, `max_caha`.
#' @family decisions
#' @export
load_closing_ah_prices <- function(raw_dir = "inst/extdata/raw") {
  rlang::check_required(raw_dir)
  if (!dir.exists(raw_dir)) {
    cli::cli_abort("Raw directory not found: {.path {raw_dir}}")
  }

  files <- list.files(raw_dir, pattern = "\\.csv$", full.names = TRUE)
  if (length(files) == 0L) {
    cli::cli_warn("No CSV files in {.path {raw_dir}}")
    return(tibble::tibble())
  }

  parsed <- purrr::map(files, parse_closing_ah_file)
  dplyr::bind_rows(parsed)
}

#' @noRd
parse_closing_ah_file <- function(file_path) {
  base <- tools::file_path_sans_ext(basename(file_path))
  parts <- strsplit(base, "_", fixed = TRUE)[[1]]
  if (length(parts) < 2L) {
    cli::cli_warn("Skipping {.file {basename(file_path)}}: unexpected filename")
    return(tibble::tibble())
  }
  league_code <- parts[1]

  raw <- readr::read_csv(
    file_path,
    col_types = readr::cols(.default = readr::col_character()),
    locale = readr::locale(encoding = "latin1"),
    na = c("", "NA", "N/A", "n/a", "-", "NULL"),
    show_col_types = FALSE,
    name_repair = "minimal"
  )

  if (nrow(raw) == 0L) return(tibble::tibble())

  n <- nrow(raw)
  match_date <- lubridate::dmy(raw[["Date"]])

  mid <- make_match_id(
    league_code, match_date,
    trimws(raw[["HomeTeam"]]), trimws(raw[["AwayTeam"]])
  )

  to_num <- function(col) {
    if (!col %in% colnames(raw)) return(rep(NA_real_, n))
    x <- raw[[col]]
    n_before <- sum(is.na(x))
    out <- readr::parse_double(x, na = c("", "NA", "N/A", "n/a", "-", "NULL"))
    probs <- readr::problems(out)
    n_failed <- nrow(probs)
    if (n_failed > 0L) {
      cli::cli_inform(c("i" = "{n_failed} value{?s} in {.field {col}} failed numeric parse in {.file {basename(file_path)}}"))
      out[probs$row] <- NA_real_
    }
    unname(out)
  }

  tibble::tibble(
    match_id      = mid,
    league_code   = league_code,
    psch          = to_num("PSCH"),
    pscd          = to_num("PSCD"),
    psca          = to_num("PSCA"),
    ah_line_close = to_num("AHCh"),
    # Pinnacle closing AH (true sharp close — note naming: PCAHH, not PAHCH)
    pcahh         = to_num("PCAHH"),
    pcaha         = to_num("PCAHA"),
    # Market average / max closing AH (looser benchmark, confounded by margin)
    avg_cahh      = to_num("AvgCAHH"),
    avg_caha      = to_num("AvgCAHA"),
    max_cahh      = to_num("MaxCAHH"),
    max_caha      = to_num("MaxCAHA")
  )
}

#' Attach closing AH prices and compute per-bet CLV
#'
#' Joins a bet tibble (from `ah_bets_from_preds()`) to the closing AH
#' price table and computes per-bet Closing Line Value and a beat-the-close
#' flag. All AH bets in the codebase are home-side only, so the home
#' closing average (`avg_cahh`) is the reference.
#'
#' @param bets Tibble from `ah_bets_from_preds()`. Must contain `match_id`
#'   and `odds` (the price the bet was placed at).
#' @param closing Tibble from `load_closing_ah_prices()`.
#' @param benchmark One of `"pcahh"` (Pinnacle closing AH — true sharp close,
#'   **preferred**) or `"avg_cahh"` (market average closing AH — looser,
#'   confounded by Pinnacle's tighter margin). Default `"pcahh"`.
#' @return `bets` with extra columns: `close_price`, `clv`, `beat_close`,
#'   `benchmark` (label).
#' @family decisions
#' @export
attach_clv <- function(bets, closing, benchmark = c("pcahh", "avg_cahh")) {
  rlang::check_required(bets)
  rlang::check_required(closing)
  benchmark <- rlang::arg_match(benchmark)

  if (nrow(bets) == 0L) {
    return(tibble::tibble(
      match_id = character(), market = character(), edge = double(),
      odds = double(), won = logical(), stake = double(), net = double(),
      p_cover = double(), close_price = double(), clv = double(),
      beat_close = logical(), benchmark = character()
    ))
  }

  close_col <- benchmark
  bets |>
    dplyr::left_join(
      closing |> dplyr::select("match_id", close_price = dplyr::all_of(close_col), "league_code"),
      by = "match_id"
    ) |>
    dplyr::mutate(
      clv = dplyr::if_else(
        !is.na(.data$close_price) & .data$close_price > 0,
        (.data$odds / .data$close_price) - 1,
        NA_real_
      ),
      beat_close = dplyr::if_else(
        !is.na(.data$close_price),
        .data$odds > .data$close_price,
        NA
      ),
      benchmark = benchmark
    )
}

#' Summarise CLV metrics overall and by league
#'
#' Produces a long tibble with scenario label, n_bets, mean/median CLV with
#' normal-approx 95% CI, beat-close rate with Clopper-Pearson CI, and
#' ROI-vs-Pinnacle (pre-match) for comparison. Stratification is by
#' `league_code`; a combined row with `league_code = "ALL"` is prepended.
#'
#' @param bets_with_clv Tibble from `attach_clv()`.
#' @param scenario Character label identifying the model.
#' @return Tibble with one row per (scenario, league_code).
#' @family decisions
#' @export
summarise_ah_clv <- function(bets_with_clv, scenario) {
  rlang::check_required(bets_with_clv)
  rlang::check_required(scenario)

  empty <- tibble::tibble(
    scenario = scenario, league_code = "ALL", n_bets = 0L,
    n_with_close = 0L, mean_clv = NA_real_, clv_ci_lo = NA_real_,
    clv_ci_hi = NA_real_, median_clv = NA_real_, beat_close_rate = NA_real_,
    btc_ci_lo = NA_real_, btc_ci_hi = NA_real_, roi_pct = NA_real_
  )
  if (nrow(bets_with_clv) == 0L) return(empty)

  summarise_one <- function(df, league_label) {
    n <- nrow(df)
    with_close <- df |> dplyr::filter(!is.na(.data$clv))
    n_wc <- nrow(with_close)

    if (n_wc == 0L) {
      mean_clv <- NA_real_; sd_clv <- NA_real_; med_clv <- NA_real_
      btc <- NA_real_; btc_lo <- NA_real_; btc_hi <- NA_real_
      ci_lo <- NA_real_; ci_hi <- NA_real_
    } else {
      mean_clv <- mean(with_close$clv)
      sd_clv <- stats::sd(with_close$clv)
      med_clv <- stats::median(with_close$clv)
      se <- if (n_wc > 1L) sd_clv / sqrt(n_wc) else NA_real_
      ci_lo <- mean_clv - 1.96 * se
      ci_hi <- mean_clv + 1.96 * se

      n_beat <- sum(with_close$beat_close, na.rm = TRUE)
      btc <- n_beat / n_wc
      bt <- stats::binom.test(n_beat, n_wc)
      btc_lo <- bt$conf.int[1]
      btc_hi <- bt$conf.int[2]
    }

    total_stake <- sum(df$stake, na.rm = TRUE)
    roi <- if (total_stake > 0) 100 * sum(df$net, na.rm = TRUE) / total_stake else NA_real_

    tibble::tibble(
      scenario        = scenario,
      league_code     = league_label,
      n_bets          = n,
      n_with_close    = n_wc,
      mean_clv        = round(mean_clv, 4),
      clv_ci_lo       = round(ci_lo, 4),
      clv_ci_hi       = round(ci_hi, 4),
      median_clv      = round(med_clv, 4),
      beat_close_rate = round(btc, 3),
      btc_ci_lo       = round(btc_lo, 3),
      btc_ci_hi       = round(btc_hi, 3),
      roi_pct         = round(roi, 1)
    )
  }

  overall <- summarise_one(bets_with_clv, "ALL")

  by_league <- if ("league_code" %in% names(bets_with_clv)) {
    bets_with_clv |>
      dplyr::filter(!is.na(.data$league_code)) |>
      dplyr::group_split(.data$league_code) |>
      purrr::map_dfr(function(df) summarise_one(df, unique(df$league_code)))
  } else {
    tibble::tibble()
  }

  dplyr::bind_rows(overall, by_league)
}
