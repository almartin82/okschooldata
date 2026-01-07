# Process raw OSDE directory data

Transforms raw OSDE directory data into a standardized schema combining
district and site data.

## Usage

``` r
process_directory(raw_data, end_year)
```

## Arguments

- raw_data:

  List containing district and site data frames from get_raw_directory

- end_year:

  School year end

## Value

Processed data frame with standardized columns
