# plan_data_validation.R
# Data validation targets for quality gate scoring (20% of total)
#
# These targets validate:
# - Temporal coverage (expected vs actual matches)
# - Duplicate detection
# - Parse problem tracking
# - Value range validation
# - Data freshness

plan_data_validation <- list(

  # 1. Temporal coverage - verify expected match counts per league/season
  targets::tar_target(
    dv_temporal_coverage,
    validate_temporal_coverage(parsed_matches),
    cue = targets::tar_cue(mode = "always")
  ),

  # 2. Duplicate detection - ensure unique match_ids
  targets::tar_target(
    dv_duplicate_check,
    validate_no_duplicates(parsed_matches, key_col = "match_id"),
    cue = targets::tar_cue(mode = "always")
  ),

  # 3. Parse problems tracking - inspect readr problems
  targets::tar_target(
    dv_parse_problems,
    validate_parse_problems(parsed_matches, parsed_odds, max_problems = 50L),
    cue = targets::tar_cue(mode = "always")
  ),

  # 4. Value range validation - catch impossible values
  targets::tar_target(
    dv_value_ranges,
    validate_value_ranges(parsed_matches),
    cue = targets::tar_cue(mode = "always")
  ),

  # 5. Freshness check - ensure data is recent
  targets::tar_target(
    dv_freshness,
    validate_data_freshness(parsed_matches, max_stale_days = 14L),
    cue = targets::tar_cue(mode = "always")
  ),

  # 6. Combined validation report
  targets::tar_target(
    dv_report,
    {
      all_passed <- all(
        dv_temporal_coverage$passed,
        dv_duplicate_check$passed,
        dv_value_ranges$passed,
        dv_freshness$passed
      )

      if (!all_passed) {
        cli::cli_warn(c(
          "!" = "Data validation has issues",
          "i" = "Check individual dv_* targets for details"
        ))
      }

      list(
        temporal = dv_temporal_coverage,
        duplicates = dv_duplicate_check,
        parse_problems = dv_parse_problems,
        value_ranges = dv_value_ranges,
        freshness = dv_freshness,
        passed = all_passed,
        timestamp = Sys.time()
      )
    }
  )
)
