# Get available years for Oklahoma enrollment data

Returns a vector of school year ends for which enrollment data is
available. Data is available from 2016 (FY15-16) through 2025 (current).

## Usage

``` r
get_available_years()
```

## Value

Integer vector of available years

## Examples

``` r
get_available_years()
#> $min_year
#> [1] 2016
#> 
#> $max_year
#> [1] 2025
#> 
#> $description
#> [1] "Oklahoma enrollment data from OSDE is available for school years 2015-16 through 2024-25 (end years 2016-2025)"
#> 
```
