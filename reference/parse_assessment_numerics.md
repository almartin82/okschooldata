# Parse numeric columns in assessment data

Converts string columns to appropriate numeric types, handling
suppression markers like "\*\*\*" and "N/A".

## Usage

``` r
parse_assessment_numerics(df)
```

## Arguments

- df:

  Data frame with standardized column names

## Value

Data frame with parsed numeric columns
