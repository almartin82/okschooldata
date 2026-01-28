# Fetch Oklahoma OSTP assessment data

Downloads and processes OSTP assessment data from the Oklahoma State
Department of Education. Includes grades 3-8 for ELA, Math, and Science.

## Usage

``` r
fetch_assessment(end_year, tidy = TRUE, use_cache = TRUE)
```

## Arguments

- end_year:

  School year end (2023-24 = 2024). Valid years: 2017-2019, 2022-2025.

- tidy:

  If TRUE (default), returns data in long (tidy) format with subject and
  proficiency_level columns. If FALSE, returns wide format with separate
  columns for each subject/level combination.

- use_cache:

  If TRUE (default), uses locally cached data when available. Set to
  FALSE to force re-download from OSDE.

## Value

Data frame with assessment data. Wide format includes columns for
proficiency percentages by subject. Tidy format pivots these into
subject, proficiency_level, and pct columns.

## Details

Assessment systems:

- **OSTP** (Oklahoma School Testing Program): 2017-present for Grades
  3-8

- **Proficiency levels**: Below Basic, Basic, Proficient, Advanced

- **2020-2021**: No public data due to COVID-19 pandemic

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2024 assessment data (2023-24 school year) in tidy format
assess_2024 <- fetch_assessment(2024)

# Get wide format (subject columns not pivoted)
assess_wide <- fetch_assessment(2024, tidy = FALSE)

# Force fresh download (ignore cache)
assess_fresh <- fetch_assessment(2024, use_cache = FALSE)

# Filter to state-level ELA results
state_ela <- assess_2024 |>
  dplyr::filter(is_state, subject == "ELA")
} # }
```
