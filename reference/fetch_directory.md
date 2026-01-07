# Fetch Oklahoma school directory data

Downloads and processes school directory data from the Oklahoma State
Department of Education's public data files. Returns contact information
for districts and schools including principal/superintendent names,
addresses, and phone numbers.

## Usage

``` r
fetch_directory(end_year = NULL, tidy = TRUE, use_cache = TRUE)
```

## Arguments

- end_year:

  A school year. Year is the end of the academic year - eg 2024-25
  school year is year '2025'. Valid values are 2025-2026 (limited
  history available).

- tidy:

  If TRUE (default), returns data in a standardized format with
  consistent column names. If FALSE, returns raw column names from
  source.

- use_cache:

  If TRUE (default), uses locally cached data when available. Set to
  FALSE to force re-download from OSDE.

## Value

Data frame with directory data including:

- end_year:

  School year end (e.g., 2025 for 2024-25)

- district_id:

  District code (e.g., "55I001")

- school_id:

  School site code (e.g., "55I001105") - NA for district rows

- district_name:

  District name

- school_name:

  School/site name - NA for district rows

- county:

  County name

- superintendent_name:

  District superintendent (district rows only)

- superintendent_email:

  Superintendent email (district rows only)

- principal_name:

  School principal (school rows only)

- principal_email:

  Principal email (school rows only)

- board_president:

  Board president name (district rows only)

- phone:

  Phone number

- fax:

  Fax number (district rows only)

- website:

  Website URL (district rows only)

- physical_address, physical_city, physical_state, physical_zip:

  Physical address

- mailing_address, mailing_city, mailing_state, mailing_zip:

  Mailing address

- grades_served:

  Grade span (e.g., "PK-12") - school rows only

- enrollment:

  Total enrollment - school rows only

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2025 school directory data (2024-25 school year)
dir_2025 <- fetch_directory(2025)

# Get raw format (original column names)
dir_raw <- fetch_directory(2025, tidy = FALSE)

# Force fresh download (ignore cache)
dir_fresh <- fetch_directory(2025, use_cache = FALSE)

# Filter to specific district
okc_ps <- dir_2025 |>
  dplyr::filter(district_id == "55I001")

# Get all principals
principals <- dir_2025 |>
  dplyr::filter(!is.na(principal_name)) |>
  dplyr::select(district_name, school_name, principal_name, principal_email)
} # }
```
