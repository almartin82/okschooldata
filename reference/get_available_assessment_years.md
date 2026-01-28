# Get available assessment years

Returns the years for which OSTP assessment data is publicly available.

## Usage

``` r
get_available_assessment_years()
```

## Value

A list with components:

- years:

  Vector of available school year ends

- note:

  Note about data gaps

## Examples

``` r
get_available_assessment_years()
#> $years
#> [1] 2017 2018 2019 2022 2023 2024 2025
#> 
#> $note
#> [1] "2020 and 2021 have no public data due to COVID-19 pandemic."
#> 
```
