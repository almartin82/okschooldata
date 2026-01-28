# Convert assessment data to tidy format

Transforms wide-format assessment data (with separate columns for each
subject and proficiency level) into a tidy long format with one row per
organization/grade/subject/proficiency level combination.

## Usage

``` r
tidy_assessment(df)
```

## Arguments

- df:

  Wide-format data frame from process_assessment()

## Value

Tidy data frame with columns: end_year, grade, aggregation_level,
is_state, is_district, is_school, organization_id, district_id,
school_id, county_name, group_name, subject, valid_n, proficiency_level,
n_students, pct
