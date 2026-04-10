# Snapshot tests for mermaid diagram output stability (#65).
# Catches changes in diagram structure, theme, and HTML wrapping.
# Review changes with: testthat::snapshot_review("snapshot-diagrams")

# --- Diagram generators ---

test_that("generate_data_pipeline_mermaid() output is stable", {
  diagram <- generate_data_pipeline_mermaid(pkg_path = here::here())
  expect_snapshot(cat(diagram))
})

test_that("generate_cv_walkforward_mermaid() output is stable", {
  diagram <- generate_cv_walkforward_mermaid(pkg_path = here::here())
  expect_snapshot(cat(diagram))
})

test_that("generate_kelly_decision_mermaid() output is stable", {
  diagram <- generate_kelly_decision_mermaid(pkg_path = here::here())
  expect_snapshot(cat(diagram))
})

# --- HTML wrapper ---

test_that("wrap_mermaid_html() structure is stable", {
  simple_diagram <- "flowchart LR\n    A --> B"
  html <- wrap_mermaid_html(simple_diagram)
  expect_s3_class(html, "html")
  # Snapshot the theme init block and structure
  expect_snapshot(cat(html))
})

test_that("wrap_mermaid_html() with caption includes caption", {
  simple_diagram <- "flowchart LR\n    A --> B"
  html <- wrap_mermaid_html(simple_diagram, caption = "Test caption.")
  expect_snapshot(cat(html))
})

# --- Fenced wrapper ---

test_that("wrap_mermaid_fenced() structure is stable", {
  simple_diagram <- "flowchart LR\n    A --> B"
  fenced <- wrap_mermaid_fenced(simple_diagram)
  expect_snapshot(cat(fenced))
})

# --- Theme and styling assertions ---

test_that("wrap_mermaid_html() uses dark theme with correct colors", {
  html <- wrap_mermaid_html("flowchart LR\n    A --> B")
  expect_match(html, "#000000", fixed = TRUE)  # black background
  expect_match(html, "#999999", fixed = TRUE)  # gray-60 nodes
  expect_match(html, "#CC0000", fixed = TRUE)  # red arrows
  expect_match(html, "stroke-width:3px", fixed = TRUE)
})

test_that("diagram generators return non-empty character", {
  expect_type(generate_data_pipeline_mermaid(here::here()), "character")
  expect_type(generate_cv_walkforward_mermaid(here::here()), "character")
  expect_type(generate_kelly_decision_mermaid(here::here()), "character")
  expect_true(nchar(generate_data_pipeline_mermaid(here::here())) > 50)
  expect_true(nchar(generate_cv_walkforward_mermaid(here::here())) > 50)
  expect_true(nchar(generate_kelly_decision_mermaid(here::here())) > 50)
})
