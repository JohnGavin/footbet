# Tests for player availability functions (Issue #36)

# ---- fetch_league_injuries ----

test_that("fetch_league_injuries: validates inputs", {
  expect_error(fetch_league_injuries(123), "must be a single string")
  expect_error(fetch_league_injuries(c("England", "Spain")), "must be a single string")
})

test_that("fetch_league_injuries: handles missing worldfootballR gracefully", {
  skip_if_not_installed("mockery")

  mockery::stub(
    fetch_league_injuries,
    "rlang::check_installed",
    function(...) cli::cli_abort("worldfootballR not installed")
  )

  expect_error(fetch_league_injuries("England"), "worldfootballR")
})

test_that("fetch_league_injuries: returns empty tibble on error", {
  skip_if_not_installed("worldfootballR")
  skip_if_not_installed("mockery")

  mockery::stub(
    fetch_league_injuries,
    "worldfootballR::tm_league_injuries",
    function(...) stop("API error")
  )

  expect_warning(
    result <- fetch_league_injuries("InvalidCountry"),
    "Failed to fetch injuries"
  )
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0L)
})

# ---- fetch_league_suspensions ----

test_that("fetch_league_suspensions: validates inputs", {
  expect_error(fetch_league_suspensions(123), "must be a single string")
  expect_error(fetch_league_suspensions(NULL), "must be a single string")
})

test_that("fetch_league_suspensions: returns empty tibble on error", {
  skip_if_not_installed("worldfootballR")
  skip_if_not_installed("mockery")

  mockery::stub(
    fetch_league_suspensions,
    "worldfootballR::tm_get_suspensions",
    function(...) stop("API error")
  )

  expect_warning(
    result <- fetch_league_suspensions("InvalidCountry"),
    "Failed to fetch suspensions"
  )
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0L)
})

# ---- key_players_unavailable ----

test_that("key_players_unavailable: validates inputs", {
  expect_error(key_players_unavailable(123), "must be a single string")
})
test_that("key_players_unavailable: returns NA when team not found", {
  injuries <- tibble::tibble(
    player_name = "Injured Player",
    team = "Other FC"
  )
  suspensions <- tibble::tibble(
    player_name = "Suspended Player",
    team = "Other FC"
  )
  squad <- tibble::tibble(
    player_name = c("Star", "Bench"),
    team = c("Other FC", "Other FC"),
    market_value_eur = c(50e6, 10e6)
  )

  expect_warning(
    result <- key_players_unavailable(
      team = "Arsenal",
      injuries_df = injuries,
      suspensions_df = suspensions,
      squad_values_df = squad
    ),
    "No player data found"
  )

  expect_true(is.na(result$n_unavailable))
  expect_true(is.na(result$pct_value_missing))
})

test_that("key_players_unavailable: computes correctly with injuries", {
  squad <- tibble::tibble(
    player_name = c("Star Player", "Good Player", "Average Player", "Bench 1", "Bench 2"),
    team = rep("Arsenal", 5),
    market_value_eur = c(100e6, 50e6, 30e6, 10e6, 5e6)
  )

  injuries <- tibble::tibble(
    player_name = c("Star Player"),
    team = c("Arsenal")
  )

  suspensions <- tibble::tibble(
    player_name = character(0),
    team = character(0)
  )

  result <- key_players_unavailable(
    team = "Arsenal",
    injuries_df = injuries,
    suspensions_df = suspensions,
    squad_values_df = squad,
    top_n = 5L
  )

  expect_equal(result$n_unavailable, 1L)
  expect_equal(result$unavailable_value_eur, 100e6)
  # Star is 100M out of top 5 total (195M)
  expect_equal(result$pct_value_missing, 100 * 100e6 / 195e6, tolerance = 0.01)
  expect_equal(result$key_players_out, "Star Player")
})

test_that("key_players_unavailable: combines injuries and suspensions", {
  squad <- tibble::tibble(
    player_name = c("Player A", "Player B", "Player C"),
    team = rep("Chelsea", 3),
    market_value_eur = c(80e6, 60e6, 40e6)
  )

  injuries <- tibble::tibble(
    player_name = "Player A",
    team = "Chelsea"
  )

  suspensions <- tibble::tibble(
    player_name = "Player C",
    team = "Chelsea"
  )

  result <- key_players_unavailable(
    team = "Chelsea",
    injuries_df = injuries,
    suspensions_df = suspensions,
    squad_values_df = squad,
    top_n = 3L
  )

  expect_equal(result$n_unavailable, 2L)
  expect_equal(result$unavailable_value_eur, 120e6)  # 80M + 40M
  expect_setequal(result$key_players_out, c("Player A", "Player C"))
})

test_that("key_players_unavailable: respects top_n parameter", {
  squad <- tibble::tibble(
    player_name = paste0("Player", 1:10),
    team = rep("Liverpool", 10),
    market_value_eur = 10:1 * 1e6
  )

  injuries <- tibble::tibble(
    player_name = "Player5",  # 6th most valuable
    team = "Liverpool"
  )

  suspensions <- tibble::tibble(
    player_name = character(0),
    team = character(0)
  )

  # With top_n = 3, Player5 is not a key player
  result3 <- key_players_unavailable(
    team = "Liverpool",
    injuries_df = injuries,
    suspensions_df = suspensions,
    squad_values_df = squad,
    top_n = 3L
  )
  expect_equal(result3$n_unavailable, 0L)

  # With top_n = 6, Player5 is a key player
  result6 <- key_players_unavailable(
    team = "Liverpool",
    injuries_df = injuries,
    suspensions_df = suspensions,
    squad_values_df = squad,
    top_n = 6L
  )
  expect_equal(result6$n_unavailable, 1L)
})

test_that("key_players_unavailable: handles case-insensitive team matching", {
  squad <- tibble::tibble(
    player_name = c("Star"),
    team = c("MANCHESTER UNITED"),
    market_value_eur = c(50e6)
  )

  injuries <- tibble::tibble(
    player_name = "Star",
    team = "manchester united"
  )

  suspensions <- tibble::tibble(
    player_name = character(0),
    team = character(0)
  )

  result <- key_players_unavailable(
    team = "Manchester United",
    injuries_df = injuries,
    suspensions_df = suspensions,
    squad_values_df = squad,
    top_n = 5L
  )

  expect_equal(result$n_unavailable, 1L)
})

# ---- add_player_availability ----

test_that("add_player_availability: validates inputs", {
  bad_df <- tibble::tibble(x = 1)
  expect_error(
    add_player_availability(bad_df, tibble::tibble(), tibble::tibble(), tibble::tibble()),
    "home_team.*away_team"
  )
})

test_that("add_player_availability: adds features to matches", {
  matches <- tibble::tibble(
    home_team = c("Arsenal", "Chelsea"),
    away_team = c("Liverpool", "Spurs")
  )

  squad <- tibble::tibble(
    player_name = c("A1", "A2", "L1", "L2", "C1", "C2", "S1", "S2"),
    team = c("Arsenal", "Arsenal", "Liverpool", "Liverpool",
             "Chelsea", "Chelsea", "Spurs", "Spurs"),
    market_value_eur = c(100e6, 50e6, 80e6, 40e6, 70e6, 30e6, 60e6, 20e6)
  )

  injuries <- tibble::tibble(
    player_name = c("A1", "L1"),
    team = c("Arsenal", "Liverpool")
  )

  suspensions <- tibble::tibble(
    player_name = character(0),
    team = character(0)
  )

  result <- add_player_availability(
    matches = matches,
    injuries_df = injuries,
    suspensions_df = suspensions,
    squad_values_df = squad,
    top_n = 2L
  )

  expect_true("home_key_out" %in% colnames(result))
  expect_true("away_key_out" %in% colnames(result))
  expect_true("home_value_missing_pct" %in% colnames(result))
  expect_true("away_value_missing_pct" %in% colnames(result))
  expect_true("availability_advantage" %in% colnames(result))

  # Arsenal has A1 out (100M of 150M = 66.7%)
  expect_equal(result$home_key_out[1], 1L)
  expect_equal(result$home_value_missing_pct[1], 100 * 100e6 / 150e6, tolerance = 0.1)

  # Liverpool has L1 out (80M of 120M = 66.7%)
  expect_equal(result$away_key_out[1], 1L)
})

# ---- standardise_injuries ----

test_that("standardise_injuries: handles various column names", {
  # Simulate worldfootballR output with different column names
  raw <- tibble::tibble(
    Player = c("John Doe", "Jane Smith"),
    club = c("Arsenal", "Chelsea"),
    Position = c("FW", "MF"),
    Injury = c("Knee", "Hamstring"),
    Since = c("2024-01-15", "2024-01-20"),
    Return = c("2024-02-15", "2024-02-10"),
    Days = c(30L, 20L),
    `Market Value` = c("50m", "30m")
  )

  result <- footbet:::standardise_injuries(raw, "England", 2024L)

  expect_equal(nrow(result), 2L)
  expect_equal(result$player_name, c("John Doe", "Jane Smith"))
  expect_equal(result$team, c("Arsenal", "Chelsea"))
  expect_equal(result$injury, c("Knee", "Hamstring"))
  expect_equal(result$market_value_eur, c(50e6, 30e6))
  expect_true(all(result$season == "2425"))
})

# ---- standardise_suspensions ----

test_that("standardise_suspensions: handles various column names", {
  raw <- tibble::tibble(
    Player = c("Red Card Player"),
    Team = c("Manchester City"),
    Position = c("DF"),
    Reason = c("Red card"),
    Games = c(3L),
    `Market Value` = c("40m")
  )

  result <- footbet:::standardise_suspensions(raw, "England", 2024L)

  expect_equal(nrow(result), 1L)
  expect_equal(result$player_name, "Red Card Player")
  expect_equal(result$suspension_type, "Red card")
  expect_equal(result$games_remaining, 3L)
  expect_equal(result$market_value_eur, 40e6)
})

# ---- Edge cases ----

test_that("key_players_unavailable: handles empty injury/suspension data",
{
  squad <- tibble::tibble(
    player_name = c("Star", "Backup"),
    team = rep("Everton", 2),
    market_value_eur = c(30e6, 10e6)
  )

  result <- key_players_unavailable(
    team = "Everton",
    injuries_df = tibble::tibble(player_name = character(), team = character()),
    suspensions_df = tibble::tibble(player_name = character(), team = character()),
    squad_values_df = squad,
    top_n = 5L
  )

  expect_equal(result$n_unavailable, 0L)
  expect_equal(result$unavailable_value_eur, 0)
  expect_equal(result$pct_value_missing, 0)
  expect_length(result$key_players_out, 0L)
})

test_that("key_players_unavailable: handles duplicate unavailable players", {
  # Player appears in both injuries and suspensions
  squad <- tibble::tibble(
    player_name = c("Unlucky Player"),
    team = c("Newcastle"),
    market_value_eur = c(25e6)
  )

  injuries <- tibble::tibble(
    player_name = "Unlucky Player",
    team = "Newcastle"
  )

  suspensions <- tibble::tibble(
    player_name = "Unlucky Player",
    team = "Newcastle"
  )

  result <- key_players_unavailable(
    team = "Newcastle",
    injuries_df = injuries,
    suspensions_df = suspensions,
    squad_values_df = squad,
    top_n = 5L
  )

  # Should count as 1, not 2
  expect_equal(result$n_unavailable, 1L)
  expect_equal(result$unavailable_value_eur, 25e6)
})
