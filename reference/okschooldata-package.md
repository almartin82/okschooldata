# okschooldata: Fetch and Process Oklahoma School Data

Downloads and processes school data from the Oklahoma State Department
of Education (OSDE). Provides functions for fetching enrollment data
from OSDE's public reporting systems and transforming it into tidy
format for analysis.

## Main functions

- [`fetch_enr`](https://almartin82.github.io/okschooldata/reference/fetch_enr.md):

  Fetch enrollment data for a school year

- [`fetch_enr_multi`](https://almartin82.github.io/okschooldata/reference/fetch_enr_multi.md):

  Fetch enrollment data for multiple years

- [`get_available_years`](https://almartin82.github.io/okschooldata/reference/get_available_years.md):

  Get list of available data years

- [`tidy_enr`](https://almartin82.github.io/okschooldata/reference/tidy_enr.md):

  Transform wide data to tidy (long) format

- [`id_enr_aggs`](https://almartin82.github.io/okschooldata/reference/id_enr_aggs.md):

  Add aggregation level flags

- [`enr_grade_aggs`](https://almartin82.github.io/okschooldata/reference/enr_grade_aggs.md):

  Create grade-level aggregations

## Cache functions

- [`cache_status`](https://almartin82.github.io/okschooldata/reference/cache_status.md):

  View cached data files

- [`clear_cache`](https://almartin82.github.io/okschooldata/reference/clear_cache.md):

  Remove cached data files

## ID System

Oklahoma uses an alphanumeric ID system:

- District IDs: County code (2 digits) + Type (1 letter) + Number (3
  digits)

- Site IDs: District ID + Site number (3 digits)

- Example: 55I001 = Oklahoma County (55), Independent (I), District 001
  (OKC Public Schools)

- Example: 55I001001 = Site 001 in Oklahoma City Public Schools

## District Types

- I = Independent school district

- D = Dependent school district

- C = City school district

- E = Elementary school district

## Data Sources

Data is sourced from the Oklahoma State Department of Education:

- OSDE Public Records: <https://sde.ok.gov/reporting-index>

- State Public Enrollment:
  <https://sde.ok.gov/documents/state-student-public-enrollment>

- OklaSchools.com: <https://oklaschools.com/>

## See also

Useful links:

- <https://almartin82.github.io/okschooldata/>

- <https://github.com/almartin82/okschooldata>

- Report bugs at <https://github.com/almartin82/okschooldata/issues>

## Author

**Maintainer**: Al Martin <almartin@example.com>
