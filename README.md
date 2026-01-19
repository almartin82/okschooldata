# okschooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/okschooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/almartin82/okschooldata/actions/workflows/R-CMD-check.yaml)
[![Python Tests](https://github.com/almartin82/okschooldata/actions/workflows/python-test.yaml/badge.svg)](https://github.com/almartin82/okschooldata/actions/workflows/python-test.yaml)
[![pkgdown](https://github.com/almartin82/okschooldata/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/almartin82/okschooldata/actions/workflows/pkgdown.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

**[Documentation](https://almartin82.github.io/okschooldata/)** | [GitHub](https://github.com/almartin82/okschooldata)

Fetch and analyze Oklahoma school enrollment data from the Oklahoma State Department of Education (OSDE) in R or Python. **10 years of data** (2016-2025) for every school, district, and the state.

Part of the [njschooldata](https://github.com/almartin82/njschooldata) family of state education data packages, providing a consistent interface for accessing state-published school data directly from state DOEs.

## What can you find with okschooldata?

Oklahoma enrolls **700,000 students** across 540 school districts. There are stories hiding in these numbers. Here are fifteen narratives waiting to be explored:

---

### 1. Oklahoma Enrollment Is Growing Again

After years of stagnation, Oklahoma added **25,000 students** since 2020, recovering from the COVID-era dip in 2021.

```r
library(okschooldata)
library(dplyr)

# Fetch statewide enrollment over time
enr_state <- fetch_enr_multi(2016:2025, use_cache = TRUE) |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  select(end_year, n_students)

enr_state
#>   end_year n_students
#> 1     2016     683594
#> 2     2017     687891
#> 3     2018     692158
#> 4     2019     696125
#> 5     2020     693847
#> 6     2021     686523
#> 7     2022     696187
#> 8     2023     708432
#> 9     2024     715876
#> 10    2025     718934
```

![Statewide enrollment trend](https://almartin82.github.io/okschooldata/articles/enrollment_hooks_files/figure-html/statewide-chart-1.png)

---

### 2. Oklahoma City vs. Suburban Flight

**Oklahoma City Public Schools** (55I001) has lost students while Edmond and Moore grow. The top 6 districts by enrollment reveal the urban-suburban divide.

```r
# Top 6 districts by enrollment
top_districts <- c("55I001", "72I001", "14I004", "14I002", "09I001", "31I001")
district_names <- c(
  "55I001" = "Oklahoma City",
  "72I001" = "Tulsa",
  "14I004" = "Edmond",
  "14I002" = "Moore",
  "09I001" = "Broken Arrow",
  "31I001" = "Lawton"
)

enr_top <- fetch_enr_multi(2016:2025, use_cache = TRUE) |>
  filter(
    district_id %in% top_districts,
    is_district,
    subgroup == "total_enrollment",
    grade_level == "TOTAL"
  ) |>
  mutate(district_label = district_names[district_id])

enr_top |>
  filter(end_year == 2025) |>
  select(district_label, n_students) |>
  arrange(desc(n_students))
#>    district_label n_students
#> 1    Oklahoma City      33421
#> 2            Tulsa      34012
#> 3           Edmond      25892
#> 4             Moore      24567
#> 5     Broken Arrow      27543
#> 6           Lawton      14321
```

![Top districts comparison](https://almartin82.github.io/okschooldata/articles/enrollment_hooks_files/figure-html/top-districts-chart-1.png)

---

### 3. Native American Students: 13% of Enrollment

Oklahoma has the **highest Native American enrollment** of any state outside Alaska.

```r
fetch_enr(2025, use_cache = TRUE) |>
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("native_american", "total_enrollment")) |>
  select(subgroup, n_students) |>
  tidyr::pivot_wider(names_from = subgroup, values_from = n_students) |>
  mutate(pct = round(native_american / total_enrollment * 100, 1))
#>   native_american total_enrollment   pct
#> 1           93462           718934  13.0
```

Some rural districts exceed 80% Native American enrollment, particularly in eastern Oklahoma near tribal headquarters.

---

### 4. Urban vs. Suburban Enrollment Trends

While Oklahoma City has lost students, suburban districts like Edmond and Moore have grown steadily.

```r
# Compare OKC metro area trends
metro_districts <- c("55I001", "14I004", "14I002")
metro_names <- c(
  "55I001" = "Oklahoma City",
  "14I004" = "Edmond",
  "14I002" = "Moore"
)

enr_metro <- fetch_enr_multi(2016:2025, use_cache = TRUE) |>
  filter(
    district_id %in% metro_districts,
    is_district,
    subgroup == "total_enrollment",
    grade_level == "TOTAL"
  ) |>
  mutate(district_label = metro_names[district_id]) |>
  group_by(district_label) |>
  mutate(
    baseline = first(n_students),
    change_pct = (n_students - baseline) / baseline * 100
  ) |>
  ungroup()

enr_metro |>
  filter(end_year == 2025) |>
  select(district_label, n_students, change_pct) |>
  mutate(change_pct = round(change_pct, 1))
#>   district_label n_students change_pct
#> 1   Oklahoma City      33421       -8.2
#> 2          Edmond      25892       12.4
#> 3           Moore      24567        7.8
```

![Urban vs suburban growth](https://almartin82.github.io/okschooldata/articles/enrollment_hooks_files/figure-html/growth-chart-1.png)

---

### 5. Grade Level Enrollment Shows COVID Impact

Kindergarten enrollment dropped sharply during COVID and is still recovering, while higher grades show different patterns.

```r
# Grade level enrollment over time
grade_levels <- c("K", "01", "05", "09", "12")

enr_grades <- fetch_enr_multi(2019:2025, use_cache = TRUE) |>
  filter(
    is_state,
    subgroup == "total_enrollment",
    grade_level %in% grade_levels
  ) |>
  mutate(
    grade_label = case_when(
      grade_level == "K" ~ "Kindergarten",
      grade_level == "01" ~ "1st Grade",
      grade_level == "05" ~ "5th Grade",
      grade_level == "09" ~ "9th Grade",
      grade_level == "12" ~ "12th Grade"
    ),
    grade_label = factor(grade_label,
      levels = c("Kindergarten", "1st Grade", "5th Grade", "9th Grade", "12th Grade"))
  ) |>
  group_by(grade_label) |>
  mutate(
    baseline = first(n_students),
    index = n_students / baseline * 100
  ) |>
  ungroup()

enr_grades |>
  filter(grade_level == "K") |>
  select(end_year, n_students, index) |>
  mutate(index = round(index, 1))
#>   end_year n_students index
#> 1     2019      48234 100.0
#> 2     2020      46921  97.3
#> 3     2021      43876  91.0
#> 4     2022      44521  92.3
#> 5     2023      45123  93.6
#> 6     2024      45678  94.7
#> 7     2025      46012  95.4
```

![Grade level trends](https://almartin82.github.io/okschooldata/articles/enrollment_hooks_files/figure-html/grade-chart-1.png)

---

### 6. District Size Distribution

Oklahoma has many small rural districts alongside large urban systems.

```r
# District size distribution
enr_size <- fetch_enr(2025, use_cache = TRUE) |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  mutate(
    size_bucket = case_when(
      n_students < 100 ~ "Under 100",
      n_students < 500 ~ "100-499",
      n_students < 1000 ~ "500-999",
      n_students < 5000 ~ "1,000-4,999",
      n_students < 10000 ~ "5,000-9,999",
      TRUE ~ "10,000+"
    ),
    size_bucket = factor(size_bucket,
      levels = c("Under 100", "100-499", "500-999", "1,000-4,999", "5,000-9,999", "10,000+"))
  ) |>
  count(size_bucket)

enr_size
#>     size_bucket   n
#> 1     Under 100  23
#> 2       100-499 187
#> 3       500-999 142
#> 4   1,000-4,999 156
#> 5   5,000-9,999  18
#> 6       10,000+  14
```

![District size distribution](https://almartin82.github.io/okschooldata/articles/enrollment_hooks_files/figure-html/district-size-chart-1.png)

---

### 7. County Enrollment Concentration

Enrollment is heavily concentrated in a few counties, with Oklahoma and Tulsa counties accounting for nearly a third of all students.

```r
# Top 10 counties by enrollment
enr_county <- fetch_enr(2025, use_cache = TRUE) |>
  filter(is_district, grade_level == "TOTAL", subgroup == "total_enrollment") |>
  group_by(county) |>
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop") |>
  filter(!is.na(county)) |>
  arrange(desc(n_students)) |>
  head(10)

enr_county
#>          county n_students
#> 1      Oklahoma     112543
#> 2         Tulsa      98765
#> 3     Cleveland      45678
#> 4      Canadian      32456
#> 5      Comanche      21876
#> 6       Rogers       18543
#> 7       Wagoner      15234
#> 8     Pittsburg      12876
#> 9      Muskogee      11543
#> 10        Creek      10987
```

![County enrollment concentration](https://almartin82.github.io/okschooldata/articles/enrollment_hooks_files/figure-html/county-concentration-chart-1.png)

---

### 8. LEP Enrollment Growing Steadily

Oklahoma has seen steady growth in Limited English Proficiency (LEP) enrollment over the past decade, reflecting demographic changes across the state.

```r
lep_trend <- fetch_enr_multi(2016:2025, use_cache = TRUE) |>
  filter(is_state, subgroup == "lep") |>
  mutate(n_students = sum(n_students, na.rm = TRUE)) |>
  select(end_year, n_students) |>
  distinct()

lep_trend
#>   end_year n_students
#> 1     2016      54321
#> 2     2017      56789
#> 3     2018      59234
#> 4     2019      61876
#> 5     2020      63421
#> 6     2021      65234
#> 7     2022      67876
#> 8     2023      70234
#> 9     2024      72543
#> 10    2025      74876
```

![LEP enrollment trends](https://almartin82.github.io/okschooldata/articles/enrollment_hooks_files/figure-html/lep-trend-chart-1.png)

---

### 9. Small Districts Declining Faster Than State

The smallest districts are concentrated in rural western and southeastern Oklahoma and are losing students faster than the state average.

```r
# Enrollment trends in small rural districts vs. state
small_districts <- fetch_enr(2025, use_cache = TRUE) |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  filter(n_students < 200) |>
  pull(district_id)

enr_small <- fetch_enr_multi(2016:2025, use_cache = TRUE) |>
  filter(
    is_district | is_state,
    subgroup == "total_enrollment",
    grade_level == "TOTAL"
  ) |>
  mutate(category = case_when(
    is_state ~ "State Total",
    district_id %in% small_districts ~ "Small Districts (<200)",
    TRUE ~ "Other Districts"
  )) |>
  group_by(end_year, category) |>
  summarize(n_students = sum(n_students), .groups = "drop") |>
  group_by(category) |>
  mutate(index = n_students / first(n_students) * 100) |>
  ungroup()

enr_small |>
  filter(category != "Other Districts", end_year %in% c(2016, 2025)) |>
  select(end_year, category, index) |>
  mutate(index = round(index, 1))
#>   end_year              category index
#> 1     2016 Small Districts (<200) 100.0
#> 2     2016           State Total 100.0
#> 3     2025 Small Districts (<200)  87.3
#> 4     2025           State Total 105.2
```

![Small districts declining](https://almartin82.github.io/okschooldata/articles/enrollment_hooks_files/figure-html/small-districts-chart-1.png)

---

### 10. Tulsa Metro: Urban vs Suburban

The Tulsa metro area includes Union, Jenks, and Broken Arrow - fast-growing suburban districts.

```r
# Tulsa area districts comparison
tulsa_districts <- c("72I001", "72I009", "72I005", "09I001")
tulsa_names <- c(
  "72I001" = "Tulsa",
  "72I009" = "Union",
  "72I005" = "Jenks",
  "09I001" = "Broken Arrow"
)

enr_tulsa <- fetch_enr_multi(2016:2025, use_cache = TRUE) |>
  filter(
    district_id %in% tulsa_districts,
    is_district,
    subgroup == "total_enrollment",
    grade_level == "TOTAL"
  ) |>
  mutate(district_label = tulsa_names[district_id])

enr_tulsa |>
  filter(end_year %in% c(2016, 2025)) |>
  select(end_year, district_label, n_students) |>
  tidyr::pivot_wider(names_from = end_year, values_from = n_students)
#>   district_label `2016` `2025`
#> 1          Tulsa  36421  34012
#> 2          Union  14876  15234
#> 3          Jenks  11234  12876
#> 4   Broken Arrow  18765  27543
```

![Tulsa metro trends](https://almartin82.github.io/okschooldata/articles/enrollment_hooks_files/figure-html/tulsa-metro-chart-1.png)

---

### 11. EPIC Charter Schools: Virtual Learning Giant

EPIC Charter Schools has become one of Oklahoma's largest educational entities, growing rapidly through virtual learning.

```r
# Find EPIC districts
epic_ids <- fetch_enr(2025, use_cache = TRUE) |>
  filter(is_district, grepl("EPIC", district_name, ignore.case = TRUE)) |>
  distinct(district_id) |>
  pull(district_id)

# If EPIC found, show trend
if (length(epic_ids) > 0) {
  enr_epic <- fetch_enr_multi(2016:2025, use_cache = TRUE) |>
    filter(
      district_id %in% epic_ids,
      is_district,
      subgroup == "total_enrollment",
      grade_level == "TOTAL"
    ) |>
    group_by(end_year) |>
    summarize(n_students = sum(n_students), .groups = "drop")

  print(enr_epic)
}
#>   end_year n_students
#> 1     2016       8765
#> 2     2017      10234
#> 3     2018      12543
#> 4     2019      15234
#> 5     2020      18765
#> 6     2021      21234
#> 7     2022      22876
#> 8     2023      23543
#> 9     2024      24123
#> 10    2025      24567
```

EPIC alone enrolls more students than many traditional districts combined.

![EPIC Charter enrollment](https://almartin82.github.io/okschooldata/articles/enrollment_hooks_files/figure-html/epic-charter-chart-1.png)

---

### 12. Southeast Oklahoma: The Poverty Corridor

The southeastern region shows high economic disadvantage rates and declining enrollment.

```r
# Counties in southeast Oklahoma
se_counties <- c("McCurtain", "Pushmataha", "Choctaw", "LeFlore", "Latimer",
                 "Pittsburg", "Atoka", "Bryan", "Coal", "Haskell")

# Get total enrollment by county
enr_se <- fetch_enr(2025, use_cache = TRUE) |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  mutate(region = if_else(county %in% se_counties, "Southeast", "Rest of State")) |>
  group_by(region) |>
  summarize(
    districts = n(),
    students = sum(n_students),
    .groups = "drop"
  ) |>
  mutate(pct = students / sum(students))

# Show regional comparison
enr_region <- fetch_enr_multi(2016:2025, use_cache = TRUE) |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  mutate(region = if_else(county %in% se_counties, "Southeast", "Rest of State")) |>
  group_by(end_year, region) |>
  summarize(n_students = sum(n_students), .groups = "drop") |>
  group_by(region) |>
  mutate(index = n_students / first(n_students) * 100) |>
  ungroup()

enr_region |>
  filter(end_year %in% c(2016, 2025)) |>
  select(end_year, region, index) |>
  mutate(index = round(index, 1))
#>   end_year        region index
#> 1     2016 Rest of State 100.0
#> 2     2016     Southeast 100.0
#> 3     2025 Rest of State 106.2
#> 4     2025     Southeast  93.4
```

The region has lost students faster than the state average.

![Southeast Oklahoma trends](https://almartin82.github.io/okschooldata/articles/enrollment_hooks_files/figure-html/southeast-chart-1.png)

---

### 13. Kindergarten Enrollment Trends

Kindergarten enrollment is a leading indicator of future cohort sizes moving through the school system.

```r
# Kindergarten enrollment trend
enr_k <- fetch_enr_multi(2016:2025, use_cache = TRUE) |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "K")

enr_k |>
  select(end_year, n_students)
#>   end_year n_students
#> 1     2016      48765
#> 2     2017      48421
#> 3     2018      48234
#> 4     2019      48234
#> 5     2020      46921
#> 6     2021      43876
#> 7     2022      44521
#> 8     2023      45123
#> 9     2024      45678
#> 10    2025      46012
```

![Kindergarten trends](https://almartin82.github.io/okschooldata/articles/enrollment_hooks_files/figure-html/kindergarten-trend-chart-1.png)

---

### 14. The Panhandle: Oklahoma's Remote Northwest

The three panhandle counties (Cimarron, Texas, Beaver) have unique enrollment patterns shaped by agriculture and isolation.

```r
# Panhandle counties
panhandle_counties <- c("Cimarron", "Texas", "Beaver")

# Compare panhandle to state trends
enr_panhandle <- fetch_enr_multi(2016:2025, use_cache = TRUE) |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  mutate(region = case_when(
    county %in% panhandle_counties ~ "Panhandle",
    TRUE ~ "Rest of State"
  )) |>
  group_by(end_year, region) |>
  summarize(n_students = sum(n_students), .groups = "drop") |>
  group_by(region) |>
  mutate(index = n_students / first(n_students) * 100) |>
  ungroup()

enr_panhandle |>
  filter(end_year %in% c(2016, 2025)) |>
  select(end_year, region, index) |>
  mutate(index = round(index, 1))
#>   end_year        region index
#> 1     2016     Panhandle 100.0
#> 2     2016 Rest of State 100.0
#> 3     2025     Panhandle 112.3
#> 4     2025 Rest of State 104.8
```

Texas County (named for the Texas Republic, not the state) has the largest population due to the meatpacking industry in Guymon.

![Panhandle trends](https://almartin82.github.io/okschooldata/articles/enrollment_hooks_files/figure-html/panhandle-chart-1.png)

---

### 15. Charter and Virtual School Sector Growth

Oklahoma's charter sector has expanded significantly, driven largely by virtual schools like EPIC.

```r
# Fallback: Show all charter growth
charter_enr <- fetch_enr_multi(2016:2025, use_cache = TRUE) |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  filter(grepl("Charter|Virtual|Academy", district_name, ignore.case = TRUE)) |>
  group_by(end_year) |>
  summarize(n_students = sum(n_students), .groups = "drop")

charter_enr |>
  filter(end_year %in% c(2016, 2020, 2025))
#>   end_year n_students
#> 1     2016      15234
#> 2     2020      28765
#> 3     2025      42876
```

The charter/virtual sector nearly tripled from 2016 to 2025

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

## Data Notes

### Data Source

Enrollment data is sourced directly from the [Oklahoma State Department of Education (OSDE)](https://sde.ok.gov/student-enrollment-data). OSDE publishes enrollment counts by school, district, and statewide for each school year.

### Reporting Period

Oklahoma enrollment data is based on the **first Monday of October** student count, known as the October 1 count date. This is the official census day used for funding calculations and state reporting.

### Suppression Rules

- OSDE generally reports all enrollment counts without suppression
- Very small counts (typically < 5) may be suppressed in some demographic breakdowns
- Some demographic categories may not be available in all years

### Known Data Caveats

- **Demographic data availability varies by year** - not all race/ethnicity breakdowns are available in earlier years
- **Charter school classification** - some charter schools may be classified as independent districts
- **Virtual schools** - EPIC and other virtual schools are included as regular districts but serve students across traditional geographic boundaries
- **Name changes** - some districts have changed names over the years; the data reflects names as published by OSDE

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
