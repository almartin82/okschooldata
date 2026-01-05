# Get enrollment file information for a given year

Returns the filename and extension for enrollment data based on the
year. Handles the different naming conventions used across eras.

## Usage

``` r
get_enrollment_file_info(end_year, level)
```

## Arguments

- end_year:

  School year end (e.g., 2024 for 2023-24 school year)

- level:

  "District" or "Site"

## Value

List with filename and extension
