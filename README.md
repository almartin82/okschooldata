# okschooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/okschooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/almartin82/okschooldata/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

An R package for fetching and analyzing Oklahoma public school enrollment data from the Oklahoma State Department of Education (OSDE).

## Installation

You can install the development version of okschooldata from GitHub:
```r
# install.packages("devtools")
devtools::install_github("almartin82/okschooldata")
```

## Quick Start

```r
library(okschooldata)

# Fetch 2024 enrollment data (2023-24 school year)
enr_2024 <- fetch_enr(2024)

# View state totals
enr_2024 %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")

# View Oklahoma City Public Schools enrollment
enr_2024 %>%
  filter(district_id == "55I001", subgroup == "total_enrollment", grade_level == "TOTAL")

# Get multiple years
enr_multi <- fetch_enr_multi(2020:2024)
```

## Data Availability

### Available Years

| Era | Years | Format | Source |
|-----|-------|--------|--------|
| Modern | 2018-2025 | Excel (.xlsx) | OSDE Public Records |

**Earliest available year**: 2018 (2017-18 school year)
**Most recent available year**: 2025 (2024-25 school year)
**Total years of data**: 8 years

### Aggregation Levels

- **State**: Oklahoma statewide totals (aggregated from district data)
- **District**: ~540 public school districts
- **Campus/Site**: ~1,800+ school sites

### Demographics Available

| Category | Available | Notes |
|----------|-----------|-------|
| Total Enrollment | Yes | All years |
| White | Yes | All years |
| Black/African American | Yes | All years |
| Hispanic/Latino | Yes | All years |
| Asian | Yes | All years |
| American Indian/Alaska Native | Yes | All years |
| Native Hawaiian/Pacific Islander | Yes | All years |
| Two or More Races | Yes | All years |
| Economically Disadvantaged | Varies | May not be in all files |
| English Learners (EL/LEP) | Varies | May not be in all files |
| Special Education | Varies | May not be in all files |

### Grade Levels Available

- Pre-Kindergarten (PK)
- Kindergarten (K)
- Grades 1-12

### What's NOT Available

- Historical data prior to 2018 in downloadable format
- Student-level data (only aggregates)
- Private school enrollment
- Homeschool enrollment

### Known Caveats

1. **Data Suppression**: Small cell sizes may be suppressed to protect student privacy (shown as NA)
2. **Charter Schools**: Charter schools sponsored by districts appear under "Site" data; independent charters appear as separate districts
3. **Column Names**: OSDE may change column names between years; the package attempts to map common variations
4. **File Availability**: OSDE occasionally updates or moves files; if a download fails, check the OSDE website directly

## Oklahoma ID System

Oklahoma uses an alphanumeric identifier system:

### District IDs
Format: `CCTNNN` (6 characters)
- `CC`: County code (01-77, Oklahoma has 77 counties)
- `T`: District type (I=Independent, D=Dependent, C=City, E=Elementary)
- `NNN`: District number within county

Examples:
- `55I001`: Oklahoma City Public Schools (Oklahoma County, Independent, #001)
- `72I001`: Tulsa Public Schools (Tulsa County, Independent, #001)
- `14I004`: Edmond Public Schools (Cleveland County, Independent, #004)

### Site IDs
Format: `CCTNNNXXX` (9 characters)
- First 6 characters: District ID
- `XXX`: Site number within district

Example:
- `55I001001`: Site 001 in Oklahoma City Public Schools

## Data Sources

Data is sourced from the Oklahoma State Department of Education:

- **OSDE Public Records**: https://sde.ok.gov/reporting-index
- **State Public Enrollment Totals**: https://sde.ok.gov/documents/state-student-public-enrollment
- **Oklahoma School Report Cards**: https://oklaschools.com/

## Functions

### Main Functions

| Function | Description |
|----------|-------------|
| `fetch_enr(end_year)` | Fetch enrollment data for a single year |
| `fetch_enr_multi(end_years)` | Fetch enrollment data for multiple years |
| `get_available_years()` | Get vector of available years |
| `tidy_enr(df)` | Transform wide data to tidy format |
| `id_enr_aggs(df)` | Add aggregation level flags |
| `enr_grade_aggs(df)` | Create grade-level aggregations |

### Cache Functions

| Function | Description |
|----------|-------------|
| `cache_status()` | View cached data files |
| `clear_cache()` | Remove cached data |

## Output Schema

### Wide Format (`tidy = FALSE`)

| Column | Type | Description |
|--------|------|-------------|
| end_year | integer | School year end (2024 = 2023-24) |
| type | character | "State", "District", or "Campus" |
| district_id | character | Oklahoma district ID (e.g., "55I001") |
| campus_id | character | Oklahoma site ID (NA for district rows) |
| district_name | character | District name |
| campus_name | character | Site/campus name |
| county | character | County name |
| row_total | integer | Total enrollment |
| white, black, hispanic, ... | integer | Demographic counts |
| grade_pk, grade_k, grade_01, ... | integer | Grade-level enrollment |

### Tidy Format (`tidy = TRUE`, default)

| Column | Type | Description |
|--------|------|-------------|
| end_year | integer | School year end |
| type | character | Aggregation level |
| district_id | character | District ID |
| campus_id | character | Campus/Site ID |
| district_name | character | District name |
| campus_name | character | Campus name |
| county | character | County name |
| grade_level | character | "TOTAL", "PK", "K", "01"-"12" |
| subgroup | character | "total_enrollment", "white", etc. |
| n_students | integer | Student count |
| pct | numeric | Percentage of total |
| is_state | logical | State-level record flag |
| is_district | logical | District-level record flag |
| is_campus | logical | Campus-level record flag |

## Related Packages

This package is part of the state schooldata package family:
- [txschooldata](https://github.com/almartin82/txschooldata) - Texas
- [ilschooldata](https://github.com/almartin82/ilschooldata) - Illinois
- [caschooldata](https://github.com/almartin82/caschooldata) - California
- [nyschooldata](https://github.com/almartin82/nyschooldata) - New York
- [paschooldata](https://github.com/almartin82/paschooldata) - Pennsylvania
- [ohschooldata](https://github.com/almartin82/ohschooldata) - Ohio

## License

MIT License
