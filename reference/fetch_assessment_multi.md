# Fetch assessment data for multiple years

Downloads and combines assessment data for multiple school years. Years
2020 and 2021 are automatically excluded (no public data).

## Usage

``` r
fetch_assessment_multi(end_years, tidy = TRUE, use_cache = TRUE)
```

## Arguments

- end_years:

  Vector of school year ends (e.g., c(2022, 2023, 2024))

- tidy:

  If TRUE (default), returns data in long (tidy) format.

- use_cache:

  If TRUE (default), uses locally cached data when available.

## Value

Combined data frame with assessment data for all requested years

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 3 years of data
assess_multi <- fetch_assessment_multi(c(2022, 2023, 2024))

# Track proficiency trends at state level
assess_multi |>
  dplyr::filter(is_state, subject == "Math", grade == 4) |>
  dplyr::filter(proficiency_level %in% c("Proficient", "Advanced")) |>
  dplyr::group_by(end_year) |>
  dplyr::summarize(pct_proficient = sum(pct, na.rm = TRUE))
} # }
```
