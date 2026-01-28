# Process raw OSTP assessment data

Cleans and standardizes raw assessment data from OSDE into a consistent
schema across all years.

## Usage

``` r
process_assessment(raw_df, end_year)
```

## Arguments

- raw_df:

  Raw data frame from get_raw_assessment()

- end_year:

  School year end

## Value

Processed data frame with standardized columns
