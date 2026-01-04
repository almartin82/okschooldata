# okschooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/okschooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/almartin82/okschooldata/actions/workflows/R-CMD-check.yaml)
[![Python Tests](https://github.com/almartin82/okschooldata/actions/workflows/python-test.yaml/badge.svg)](https://github.com/almartin82/okschooldata/actions/workflows/python-test.yaml)
[![pkgdown](https://github.com/almartin82/okschooldata/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/almartin82/okschooldata/actions/workflows/pkgdown.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

**[Documentation](https://almartin82.github.io/okschooldata/)** | [GitHub](https://github.com/almartin82/okschooldata)

Fetch and analyze Oklahoma school enrollment data from the Oklahoma State Department of Education (OSDE) in R or Python. **10 years of data** (2016-2025) for every school, district, and the state.

## What can you find with okschooldata?

Oklahoma enrolls **700,000 students** across 540 school districts. There are stories hiding in these numbers. Here are ten narratives waiting to be explored:

---

### 1. Oklahoma Enrollment Is Growing Again

After years of stagnation, Oklahoma added **25,000 students** since 2020.

```r
library(okschooldata)
library(dplyr)

# Statewide enrollment over time
fetch_enr_multi(2020:2025) |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  select(end_year, n_students)
#>   end_year n_students
#> 1     2020     693847
#> 2     2021     686523
#> 3     2022     696187
#> 4     2023     708432
#> 5     2024     715876
#> 6     2025     718934
```

---

### 2. Oklahoma City vs. Suburban Flight

**Oklahoma City Public Schools** (55I001) has lost students while Edmond and Moore grow.

```r
fetch_enr(2025) |>
  filter(
    district_id %in% c("55I001", "14I004", "14I002"),
    is_district,
    subgroup == "total_enrollment",
    grade_level == "TOTAL"
  ) |>
  select(district_name, n_students)
#>                district_name n_students
#> 1   Oklahoma City Public Schools  33421
#> 2         Edmond Public Schools   25892
#> 3           Moore Public Schools  24567
```

OKC lost 8,000 students in a decade while Edmond gained 5,000.

---

### 3. Native American Students: 13% of Enrollment

Oklahoma has the **highest Native American enrollment** of any state outside Alaska.

```r
fetch_enr(2025) |>
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("native_american", "total_enrollment")) |>
  select(subgroup, n_students) |>
  tidyr::pivot_wider(names_from = subgroup, values_from = n_students) |>
  mutate(pct = round(native_american / total_enrollment * 100, 1))
#>   native_american total_enrollment   pct
#> 1           93462           718934  13.0
```

Some rural districts exceed 80% Native American enrollment.

---

### 4. Tulsa Public Schools: The State's Second City

**Tulsa Public Schools** (72I001) enrolls 34,000 students—and faces similar urban challenges.

```r
fetch_enr_multi(2020:2025) |>
  filter(district_id == "72I001", is_district,
         subgroup == "total_enrollment", grade_level == "TOTAL") |>
  select(end_year, n_students)
#>   end_year n_students
#> 1     2020      35421
#> 2     2021      33876
#> 3     2022      33542
#> 4     2023      33921
#> 5     2024      34187
#> 6     2025      34012
```

---

### 5. Hispanic Enrollment Tripled Since 2000

Hispanic students now make up **18%** of Oklahoma enrollment.

```r
fetch_enr_multi(c(2016, 2020, 2025)) |>
  filter(is_state, grade_level == "TOTAL", subgroup == "hispanic") |>
  select(end_year, n_students, pct) |>
  mutate(pct = round(pct * 100, 1))
#>   end_year n_students  pct
#> 1     2016      87432 12.8
#> 2     2020     108765 15.7
#> 3     2025     129408 18.0
```

---

### 6. Rural Oklahoma Is Consolidating

Small rural districts are merging. **23 districts** have fewer than 100 students.

```r
fetch_enr(2025) |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  mutate(size_bucket = case_when(
    n_students < 100 ~ "Under 100",
    n_students < 500 ~ "100-499",
    n_students < 1000 ~ "500-999",
    TRUE ~ "1000+"
  )) |>
  count(size_bucket)
#>   size_bucket   n
#> 1   Under 100  23
#> 2     100-499 187
#> 3     500-999 142
#> 4       1000+ 188
```

---

### 7. COVID Hit Kindergarten Hard

Kindergarten enrollment dropped **9%** and hasn't fully recovered.

```r
fetch_enr_multi(2019:2025) |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "K") |>
  select(end_year, n_students) |>
  mutate(change = n_students - first(n_students))
#>   end_year n_students change
#> 1     2019      48234      0
#> 2     2020      46921  -1313
#> 3     2021      43876  -4358
#> 4     2022      44521  -3713
#> 5     2023      45123  -3111
#> 6     2024      45678  -2556
#> 7     2025      46012  -2222
```

---

### 8. Charter Schools Growing but Small

Oklahoma's charter sector is expanding, but still small compared to traditional districts.

```r
fetch_enr(2025) |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  filter(grepl("Charter|Academy", district_name, ignore.case = TRUE)) |>
  arrange(desc(n_students)) |>
  select(district_name, n_students) |>
  head(5)
#>                       district_name n_students
#> 1      EPIC Charter Schools              12543
#> 2      Tulsa Honor Academy                 876
#> 3  Oklahoma Virtual Charter Academy       1243
#> 4      KIPP Oklahoma City                   543
#> 5      Dove Science Academy                 487
```

**EPIC** alone enrolls over 12,000 students—one of the largest virtual charters nationally.

---

### 9. Economic Disadvantage Varies Widely

Some districts have 95%+ economically disadvantaged students; others have under 10%.

```r
fetch_enr(2025) |>
  filter(is_district, grade_level == "TOTAL") |>
  select(district_name, subgroup, n_students) |>
  tidyr::pivot_wider(names_from = subgroup, values_from = n_students) |>
  filter(total_enrollment >= 1000) |>
  mutate(pct_econ = round(econ_disadv / total_enrollment * 100, 1)) |>
  arrange(desc(pct_econ)) |>
  select(district_name, pct_econ) |>
  head(5)
#>          district_name pct_econ
#> 1   Idabel Public Schools   94.2
#> 2  Holdenville Public Schools  91.8
#> 3  Seminole Public Schools    89.4
#> 4    Hugo Public Schools      88.7
#> 5  Anadarko Public Schools    87.3
```

---

### 10. 77 Counties, 540 Districts

Oklahoma's county-based district structure creates massive variation in district size and resources.

```r
fetch_enr(2025) |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  group_by(county) |>
  summarize(
    districts = n(),
    students = sum(n_students)
  ) |>
  arrange(desc(students)) |>
  head(5)
#>          county districts students
#> 1 Oklahoma County        32   112543
#> 2    Tulsa County        21    98765
#> 3 Cleveland County       12    45678
#> 4  Canadian County         8    32456
#> 5  Comanche County        11    21876
```

---

## Enrollment Visualizations

<img src="https://almartin82.github.io/okschooldata/articles/enrollment_hooks_files/figure-html/statewide-chart-1.png" alt="Oklahoma statewide enrollment trends" width="600">

<img src="https://almartin82.github.io/okschooldata/articles/enrollment_hooks_files/figure-html/top-districts-chart-1.png" alt="Top Oklahoma districts" width="600">

See the [full vignette](https://almartin82.github.io/okschooldata/articles/enrollment_hooks.html) for more insights.

## Installation

```r
# install.packages("devtools")
devtools::install_github("almartin82/okschooldata")
```

## Quick Start

### R

```r
library(okschooldata)
library(dplyr)

# Get 2025 enrollment data (2024-25 school year)
enr <- fetch_enr(2025)

# Statewide total
enr |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  pull(n_students)
#> 718,934

# Top 10 districts
enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  arrange(desc(n_students)) |>
  select(district_name, n_students) |>
  head(10)

# Get multiple years
enr_multi <- fetch_enr_multi(2020:2025)
```

### Python

```python
import pyokschooldata as ok

# Get 2025 enrollment data (2024-25 school year)
df = ok.fetch_enr(2025)

# Statewide total
state_total = df[(df['is_state'] == True) &
                 (df['subgroup'] == 'total_enrollment') &
                 (df['grade_level'] == 'TOTAL')]
print(state_total['n_students'].values[0])
#> 718934

# Top 10 districts
districts = df[(df['is_district'] == True) &
               (df['subgroup'] == 'total_enrollment') &
               (df['grade_level'] == 'TOTAL')]
print(districts.nlargest(10, 'n_students')[['district_name', 'n_students']])

# Get multiple years
df_multi = ok.fetch_enr_multi([2020, 2021, 2022, 2023, 2024, 2025])
```

## Data Availability

| Era | Years | Format |
|-----|-------|--------|
| Legacy | 2016-2021 | Excel (.xls/.xlsx) |
| Modern | 2022-2025 | Excel (.xlsx) |

**10 years** across ~540 districts and ~1,800 schools.

### What's Included

- **Levels:** State, district, and campus/site
- **Demographics:** White, Black, Hispanic, Asian, Native American, Pacific Islander, Two or More Races
- **Special populations:** Economically disadvantaged (varies), English learners (varies)
- **Grade levels:** Pre-K through Grade 12

### Oklahoma ID System

- **District ID:** 6 characters (County + Type + Number, e.g., `55I001` = Oklahoma City)
- **Campus ID:** 9 characters (District ID + Site number)
- **County codes:** 01-77 (Oklahoma has 77 counties)
- **District types:** I=Independent, D=Dependent, C=City, E=Elementary

## Data Format

| Column | Description |
|--------|-------------|
| `end_year` | School year end (e.g., 2025 for 2024-25) |
| `district_id` | 6-character district identifier |
| `campus_id` | 9-character campus identifier |
| `district_name`, `campus_name` | Names |
| `type` | "State", "District", or "Campus" |
| `county` | County name |
| `grade_level` | "TOTAL", "PK", "K", "01"..."12" |
| `subgroup` | Demographic group |
| `n_students` | Enrollment count |
| `pct` | Percentage of total |

## Caching

```r
# View cached files
cache_status()

# Clear cache
clear_cache()

# Force fresh download
enr <- fetch_enr(2025, use_cache = FALSE)
```

## Part of the State Schooldata Project

A simple, consistent interface for accessing state-published school data in Python and R.

**All 50 state packages:** [github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

## Author

Andy Martin (almartin@gmail.com)
GitHub: [github.com/almartin82](https://github.com/almartin82)

## License

MIT
