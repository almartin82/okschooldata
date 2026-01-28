# Get assessment URL for a given year

Constructs the URL for downloading OSTP assessment data from Oklahoma
DOE. URLs vary by year with different file naming conventions.

## Usage

``` r
get_assessment_url(end_year)
```

## Arguments

- end_year:

  School year end (e.g., 2024 for 2023-24 school year)

## Value

URL string or NULL if year not available
