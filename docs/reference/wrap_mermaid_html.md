# Wrap mermaid code in HTML div for vignettes

Creates an HTML structure that renders with mermaid.js CDN. Used for
vignettes where click/href works with securityLevel: loose.

## Usage

``` r
wrap_mermaid_html(mermaid_code)
```

## Arguments

- mermaid_code:

  Character. Mermaid diagram code.

## Value

Character with class "html" for auto-printing with output: asis.

## See also

Other diagrams:
[`generate_cv_walkforward_mermaid()`](https://johngavin.github.io/footbet/reference/generate_cv_walkforward_mermaid.md),
[`generate_data_pipeline_mermaid()`](https://johngavin.github.io/footbet/reference/generate_data_pipeline_mermaid.md),
[`generate_kelly_decision_mermaid()`](https://johngavin.github.io/footbet/reference/generate_kelly_decision_mermaid.md),
[`wrap_mermaid_fenced()`](https://johngavin.github.io/footbet/reference/wrap_mermaid_fenced.md)
