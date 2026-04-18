# Simple string similarity (bigram Jaccard)

Computes similarity between two strings using character bigrams. No
external dependencies — used for fuzzy team name matching.

## Usage

``` r
stringdist_sim(a, b)
```

## Arguments

- a:

  Character. First string.

- b:

  Character. Second string.

## Value

Numeric between 0 (no overlap) and 1 (identical bigrams).
