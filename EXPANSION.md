# Oklahoma School Data Expansion Research

**Last Updated:** 2026-01-04
**Theme Researched:** Graduation Rates

## Executive Summary

Oklahoma graduation data is primarily accessible through **OklaSchools.com**, which is a JavaScript SPA with an authenticated API. Direct Excel/CSV downloads are NOT available from oklahoma.gov for graduation rates. The primary data access method requires either:
1. Using the authenticated OklaSchools.com export feature (requires login)
2. Browser automation/Selenium to access the SPA's download functionality
3. Requesting data via Open Records Request

**Complexity: HARD** - No direct public file downloads available for graduation rates.

---

## Data Sources Found

### Source 1: OklaSchools.com (Primary - Report Card Dashboard)
- **URL:** https://oklaschools.com/state/graduation
- **HTTP Status:** 200 (JavaScript SPA)
- **Format:** Interactive dashboard with CSV/Excel export feature
- **Years Available:** 2018-2025 (based on report card history)
- **Access Method:** JavaScript-rendered; requires browser or API authentication

**Notes:**
- SPA at https://oklaschools.com uses Vue.js and requires API authentication
- API endpoints discovered: `/api/years/`, `/api/definitions/`, `/api/download-stats/`
- API returns `{ "error" : "Forbidden: Invalid API Key" }` without authentication
- Has `downloadIndicatorEntity` function in JS for CSV exports
- Download feature available on graduation pages at district/school level

**Metrics Available:**
- 4-year adjusted cohort graduation rate (4Y)
- 5-year adjusted cohort graduation rate (5Y)
- 6-year adjusted cohort graduation rate (6Y)
- Graduation improvement score
- State goal tracking (90% by 2025)

### Source 2: Oklahoma Open Data (data.ok.gov) - Limited Historical
- **URL:** https://data.ok.gov/dataset/high-school-graduation-rate
- **HTTP Status:** 200 (302 redirect to S3)
- **Format:** CSV
- **Years Available:** 2013-2018 (very limited - mostly zeros)
- **Access Method:** Direct download

**Files Available:**
1. `data-high-school-graduation-rate.csv`
   - URL: https://data.ok.gov/dataset/0c1806d4-1510-468c-93f8-4cb92045cf0f/resource/57fbe906-8c0c-457c-936f-cb98f2ac3e8e/download/data-high-school-graduation-rate.csv

**Actual Data Content:**
```csv
Years,Historical Data,Target
2013,84.70%,0.00%
2014,0.00%,0.00%
2015,0.00%,0.00%
2016,0.00%,0.00%
2017,0.00%,0.00%
2018,0.00%,86.20%
```

**Assessment:** Extremely limited - only state-level targets, not district/school data. Not suitable for package implementation.

### Source 3: Oklahoma.gov Statewide Education Metrics
- **URL:** https://oklahoma.gov/content/dam/ok/en/top/documents/datasheets/Statewide-Education-Goal-Metrics-2022.xlsx
- **HTTP Status:** 200
- **Format:** Excel (.xlsx)
- **Years Available:** 2022
- **Access Method:** Direct download

**Assessment:** Contains statewide metrics only, not district/school level granularity needed.

### Source 4: Legacy sde.ok.gov Files (BROKEN)
- **URL:** https://sde.ok.gov/sites/ok.gov.sde/files/documents/files/2015%20District%20Graduation%20Rates.xlsx
- **HTTP Status:** 301 -> 301 (redirects to oklahoma.gov/education)
- **Assessment:** Legacy URLs are broken. Domain has migrated.

### Source 5: OSDE Accountability Archive
- **URL:** https://sde.ok.gov/accountability-archive (referenced in search results)
- **HTTP Status:** Unable to verify (SSL certificate issues)
- **Years Available:** Claimed to have 2015-2016 Four Year Cohort Graduation Rate data
- **Access Method:** May require SSO authentication

**Assessment:** Historical archive may contain older files but current access is problematic.

### Source 6: Accountability Reporting Application (SSO Required)
- **URL:** https://oklahoma.gov/education/services/accountability/resources-accountability-reporting-sso.html
- **Format:** Web application with Excel export
- **Access Method:** Single Sign-On (district/school officials only)

**Assessment:** Not accessible for automated data collection without official credentials.

---

## Schema Analysis

### Graduation Indicator Components (from OklaSchools.com)

Based on documentation and UI analysis:

| Metric | Description | Formula |
|--------|-------------|---------|
| 4Y Rate | Four-year graduation rate | (Graduates in 4 years) / (Adjusted cohort) |
| 5Y Rate | Five-year graduation rate | (Graduates in 5 years) / (Adjusted cohort) |
| 6Y Rate | Six-year graduation rate (since 2018-19) | (Graduates in 6 years) / (Adjusted cohort) |
| Improvement Score | Not a "rate" - measures later graduates | Points for students graduating in 5th/6th year |
| Graduation Indicator | Composite score | Weighted combination of above |

### Adjusted Cohort Graduation Rate (ACGR) Definition

Per Oklahoma's methodology:
- **Cohort:** Students entering 9th grade for first time
- **Adjustments:**
  - Add: Transfer-ins to cohort
  - Subtract: Transfer-outs, emigrations, deaths
- **Graduation:** Regular diploma OR alternate diploma (for significant cognitive disabilities)

### Expected ID Format

Based on existing enrollment data in package:
- **District ID:** 5-6 characters (e.g., "55I001" = County 55, Independent, District 001)
- **Site ID:** 9 characters (e.g., "55I001001" = District 55I001, Site 001)
- **County Codes:** 01-77 (77 counties in Oklahoma)
- **District Types:** I=Independent, D=Dependent, C=City, T=Town, E=Elementary

### Expected Column Names (based on OklaSchools indicators)

| Standard Name | Possible Raw Names |
|---------------|-------------------|
| district_id | District Code, DistrictCode, DISTRICT CODE |
| district_name | District Name, District, DISTRICT |
| site_id | Site Code, Site ID, School Code |
| site_name | Site Name, School Name, SITE NAME |
| end_year | Year, School Year, SY |
| cohort_count | Cohort, Cohort Count, Adjusted Cohort |
| grad_4yr_count | 4 Year Graduates, Four Year Grads |
| grad_4yr_rate | 4Y Rate, Four Year Rate, 4 Yr Graduation Rate |
| grad_5yr_count | 5 Year Graduates, Five Year Grads |
| grad_5yr_rate | 5Y Rate, Five Year Rate |
| grad_6yr_count | 6 Year Graduates, Six Year Grads |
| grad_6yr_rate | 6Y Rate, Six Year Rate |

---

## Time Series Heuristics

Based on publicly available information:

| Metric | Expected Range | Red Flag If |
|--------|---------------|-------------|
| State 4Y Graduation Rate | 78% - 90% | Outside 75%-95% |
| State 4Y Rate YoY Change | -2% to +3% | Change > 5% |
| District Count | ~500 districts | Major change from year to year |
| Cohort Size (State) | 40,000-50,000 students | Outside 35,000-55,000 |
| Major District Rates | 70%-95% | < 50% or > 98% |

### Known Data Points (for fidelity tests)
- 2024 State 4Y Graduation Rate: 82.2%
- 2023 State 4Y Graduation Rate: 81.3%
- State Goal (2025): 90%
- 2023 State Grade: D

---

## Access Challenges

### Primary Issue: No Direct Public File Downloads

Unlike enrollment data (which has Excel files on oklahoma.gov), graduation data is:
1. **Not published as downloadable files** on oklahoma.gov/content/dam
2. **Only accessible via OklaSchools.com** dashboard (authenticated API)
3. **Historical files on legacy.sde.ok.gov** are broken/redirected

### Technical Barriers

1. **OklaSchools.com is a JavaScript SPA**
   - Static scraping won't work
   - Requires Selenium/Playwright for browser automation
   - API requires authentication token

2. **API Authentication Required**
   - `/api/years/` returns "Forbidden: Invalid API Key"
   - No public API documentation found
   - Would need to capture auth token from browser session

3. **Export Feature Requires Authentication**
   - "Download Data" button exists on pages
   - But requires active browser session

### Potential Solutions (in order of preference)

1. **Selenium/Playwright Automation**
   - Navigate to OklaSchools.com graduation pages
   - Click "Download Data" button
   - Capture resulting CSV/Excel file
   - Complexity: HIGH
   - Dependencies: RSelenium or reticulate + selenium

2. **API Token Capture**
   - Reverse-engineer authentication flow
   - Capture and reuse API tokens
   - Risk: Tokens may expire, ToS concerns
   - Not recommended

3. **Open Records Request**
   - Submit formal request to OSDE
   - Receive historical data files
   - One-time only, not automated
   - Use as `import_local_grad()` fallback

4. **Wait for Direct Downloads**
   - Monitor OSDE for future public data releases
   - Check annually for new file URLs

---

## Subgroup Data Availability

Based on OklaSchools.com indicators, graduation rates are available by:

### Demographic Subgroups
- All Students
- American Indian/Alaska Native
- Asian
- Black/African American
- Hispanic/Latino
- Native Hawaiian/Pacific Islander
- White
- Two or More Races

### Special Populations
- Economically Disadvantaged
- English Learners (EL)
- Students with Disabilities (SWD)
- Foster Care
- Homeless
- Migrant
- Military Connected

### Other Breakdowns
- Male/Female
- By School Type (Traditional, Charter, Virtual)

---

## Recommended Implementation

### Priority: LOW
### Complexity: HARD
### Estimated Files to Modify: 5-7 (plus Selenium dependencies)

Given the lack of direct public file downloads, implementation would require:

1. **Add Selenium/browser automation infrastructure**
   - New dependency: RSelenium or reticulate + selenium
   - Complex setup for CI/CD environments

2. **Create browser automation workflow**
   - Navigate to OklaSchools.com
   - Authenticate (if required) or use public download
   - Click download buttons per year
   - Parse resulting files

3. **Alternative: import_local_grad() fallback**
   - Document process for manual data download
   - Provide function to import locally saved files
   - Not ideal but functional

### Implementation Steps (if proceeding)

1. Investigate if OklaSchools.com has any public/unauthenticated download endpoints
2. Set up RSelenium or reticulate + Playwright
3. Create `get_raw_grad()` function with browser automation
4. Process downloaded files to standard schema
5. Add `tidy_grad()` transformation
6. Create fidelity tests with known values

---

## Test Requirements

### Raw Data Fidelity Tests Needed

**Note:** Actual raw values require access to data files. Tests would verify:

```r
test_that("2024: State 4Y graduation rate matches known value", {
  skip_if_offline()
  data <- fetch_grad(2024, tidy = TRUE)
  state_data <- data |> filter(is_state, subgroup == "all_students")
  expect_equal(state_data$grad_4yr_rate, 82.2, tolerance = 0.1)
})

test_that("2023: State 4Y graduation rate matches known value", {
  skip_if_offline()
  data <- fetch_grad(2023, tidy = TRUE)
  state_data <- data |> filter(is_state, subgroup == "all_students")
  expect_equal(state_data$grad_4yr_rate, 81.3, tolerance = 0.1)
})
```

### Data Quality Checks

```r
test_that("Graduation rates are valid percentages", {
  data <- fetch_grad(2024, tidy = TRUE)
  expect_true(all(data$grad_4yr_rate >= 0 & data$grad_4yr_rate <= 100, na.rm = TRUE))
  expect_true(all(data$grad_5yr_rate >= 0 & data$grad_5yr_rate <= 100, na.rm = TRUE))
})

test_that("Cohort counts are non-negative", {
  data <- fetch_grad(2024, tidy = FALSE)
  expect_true(all(data$cohort_count >= 0, na.rm = TRUE))
})

test_that("5Y rate >= 4Y rate (logically)", {
  data <- fetch_grad(2024, tidy = TRUE) |>
    filter(!is.na(grad_4yr_rate) & !is.na(grad_5yr_rate))
  expect_true(all(data$grad_5yr_rate >= data$grad_4yr_rate - 0.1))  # small tolerance for rounding
})
```

---

## Alternative Data Sources Considered

### NOT RECOMMENDED (Federal Sources)
- NCES CCD - Federal aggregation, loses state-specific details
- Urban Institute Education Data Portal - Uses federal data
- Ed Data Express - Federal source

### Why State Data is Preferred
- Oklahoma uses state-specific definitions for graduation cohorts
- Subgroup categorizations may differ from federal
- State data includes improvement scores not in federal data
- Real-time updates vs. federal lag

---

## Contact Information

For data questions:
- **Email:** Accountability@sde.ok.gov
- **Phone:** 405-522-5169
- **Open Records Request:** Contact OSDE directly

---

## Conclusion

Oklahoma graduation data implementation faces significant barriers due to:
1. No direct public file downloads from state DOE
2. OklaSchools.com requires browser automation or API authentication
3. Legacy data files are broken/redirected

**Recommendation:** Defer implementation until either:
- OSDE publishes direct download files (like enrollment)
- Package adds Selenium infrastructure for other purposes
- User specifically needs graduation data and accepts manual download workflow

If proceeding, start with `import_local_grad()` fallback and investigate OklaSchools.com automation as a secondary phase.
