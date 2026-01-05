# Get available years for Oklahoma enrollment data

Returns metadata about the range of school years for which enrollment
data is available from the Oklahoma State Department of Education.

## Usage

``` r
get_available_years()
```

## Value

A list with components:

- min_year:

  Earliest available school year end (2016)

- max_year:

  Latest available school year end (2024)

- description:

  Human-readable description of the data availability

## Examples

``` r
years <- get_available_years()
years$min_year
#> [1] 2016
years$max_year
#> [1] 2025
years$description
#> [1] "Oklahoma enrollment data from OSDE is available for school years 2015-16 through 2024-25 (end years 2016-2025)"
```
