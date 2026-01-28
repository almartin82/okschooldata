# Get assessment data for a specific district

Convenience function to fetch assessment data for a single district.

## Usage

``` r
fetch_district_assessment(end_year, district_id, tidy = TRUE, use_cache = TRUE)
```

## Arguments

- end_year:

  School year end

- district_id:

  6-character district ID (e.g., "55I001" for Oklahoma City)

- tidy:

  If TRUE (default), returns tidy format

- use_cache:

  If TRUE (default), uses cached data

## Value

Data frame filtered to specified district

## Examples

``` r
if (FALSE) { # \dontrun{
# Get Oklahoma City (district 55I001) assessment data
okc_assess <- fetch_district_assessment(2024, "55I001")

# Get Tulsa (district 72I001) data
tulsa_assess <- fetch_district_assessment(2024, "72I001")
} # }
```
