# Get available years for Oklahoma school directory data

Returns metadata about the range of school years for which directory
data is available from the Oklahoma State Department of Education.

## Usage

``` r
get_directory_available_years()
```

## Value

A list with components:

- min_year:

  Earliest available school year end (2025)

- max_year:

  Latest available school year end (2026)

- description:

  Human-readable description of the data availability

## Examples

``` r
years <- get_directory_available_years()
years$min_year
#> [1] 2025
years$max_year
#> [1] 2026
```
