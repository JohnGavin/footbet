# Generate walk-forward CV mermaid flowchart

Creates a mermaid flowchart showing the walk-forward cross-validation
strategy. Train window months are extracted from code.

## Usage

``` r
generate_cv_walkforward_mermaid(pkg_path = ".")
```

## Arguments

- pkg_path:

  Character. Path to package root.

## Value

Character. Mermaid flowchart code.

## See also

Other diagrams:
[`generate_data_pipeline_mermaid()`](https://johngavin.github.io/footbet/reference/generate_data_pipeline_mermaid.md),
[`generate_kelly_decision_mermaid()`](https://johngavin.github.io/footbet/reference/generate_kelly_decision_mermaid.md),
[`wrap_mermaid_fenced()`](https://johngavin.github.io/footbet/reference/wrap_mermaid_fenced.md),
[`wrap_mermaid_html()`](https://johngavin.github.io/footbet/reference/wrap_mermaid_html.md)
