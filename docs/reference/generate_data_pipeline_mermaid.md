# Generate data pipeline mermaid flowchart

Creates a mermaid flowchart showing the data acquisition and processing
pipeline. Function names are extracted from @family tags.

## Usage

``` r
generate_data_pipeline_mermaid(pkg_path = ".")
```

## Arguments

- pkg_path:

  Character. Path to package root.

## Value

Character. Mermaid flowchart code.

## See also

Other diagrams:
[`generate_cv_walkforward_mermaid()`](https://johngavin.github.io/footbet/reference/generate_cv_walkforward_mermaid.md),
[`generate_kelly_decision_mermaid()`](https://johngavin.github.io/footbet/reference/generate_kelly_decision_mermaid.md),
[`wrap_mermaid_fenced()`](https://johngavin.github.io/footbet/reference/wrap_mermaid_fenced.md),
[`wrap_mermaid_html()`](https://johngavin.github.io/footbet/reference/wrap_mermaid_html.md)
