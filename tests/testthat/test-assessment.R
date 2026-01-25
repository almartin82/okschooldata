# ==============================================================================
# Assessment Data Tests
# ==============================================================================
#
# Tests for Oklahoma OSTP assessment data functions.
# All tests use ACTUAL VALUES from raw OSDE data files.
#
# ==============================================================================

test_that("get_available_assessment_years returns correct structure", {
  available <- get_available_assessment_years()

  expect_type(available, "list")
  expect_named(available, c("years", "note"))
  expect_type(available$years, "integer")
  expect_type(available$note, "character")

  # Should include years 2017-2019 and 2022-2025
  expect_true(2017 %in% available$years)
  expect_true(2024 %in% available$years)
  expect_true(2025 %in% available$years)

  # Should NOT include COVID years

  expect_false(2020 %in% available$years)
  expect_false(2021 %in% available$years)
})


test_that("fetch_assessment rejects COVID years", {
  expect_error(fetch_assessment(2020), "not available.*COVID")
  expect_error(fetch_assessment(2021), "not available.*COVID")
})


test_that("fetch_assessment rejects invalid years", {
  expect_error(fetch_assessment(2015), "must be one of")
  expect_error(fetch_assessment(2030), "must be one of")
})


# ==============================================================================
# Live data tests - require network access
# ==============================================================================

test_that("2025 OSTP URL is accessible", {
  skip_on_cran()
  skip_if_offline()

  url <- "https://oklahoma.gov/content/dam/ok/en/osde/documents/services/assessments/state-testing-resources/2025-state-testing-resources/2425OKOSTPMediaRedacted.csv"
  response <- httr::HEAD(url, httr::timeout(30))

  expect_equal(httr::status_code(response), 200)
})


test_that("2024 OSTP URL is accessible", {
  skip_on_cran()
  skip_if_offline()

  url <- "https://oklahoma.gov/content/dam/ok/en/osde/documents/services/assessments/state-testing-resources/2023-2024-Grade3-8%20OKOSTPMediaRedacted.xlsx"
  response <- httr::HEAD(url, httr::timeout(30))

  expect_equal(httr::status_code(response), 200)
})


test_that("2023 OSTP URL is accessible", {
  skip_on_cran()
  skip_if_offline()

  url <- "https://oklahoma.gov/content/dam/ok/en/osde/documents/services/assessments/state-testing-resources/2022-23-OKOSTP-Grade3-8-MediaRedacted.xlsx"
  response <- httr::HEAD(url, httr::timeout(30))

  expect_equal(httr::status_code(response), 200)
})


test_that("fetch_assessment returns correct structure for 2024 (wide)", {
  skip_on_cran()
  skip_if_offline()

  df <- fetch_assessment(2024, tidy = FALSE, use_cache = TRUE)

  # Check structure
  expect_s3_class(df, "data.frame")
  expect_gt(nrow(df), 0)

  # Check required columns
  expect_true("end_year" %in% names(df))
  expect_true("grade" %in% names(df))
  expect_true("organization_id" %in% names(df))
  expect_true("aggregation_level" %in% names(df))
  expect_true("is_state" %in% names(df))
  expect_true("is_district" %in% names(df))
  expect_true("is_school" %in% names(df))

  # Check ELA columns exist
  expect_true("ela_valid_n" %in% names(df))
  expect_true("ela_proficient_pct" %in% names(df))

  # Check Math columns exist
  expect_true("math_valid_n" %in% names(df))
  expect_true("math_proficient_pct" %in% names(df))

  # Check all end_year values are 2024
  expect_true(all(df$end_year == 2024))
})


test_that("fetch_assessment returns correct structure for 2024 (tidy)", {
  skip_on_cran()
  skip_if_offline()

  df <- fetch_assessment(2024, tidy = TRUE, use_cache = TRUE)

  # Check structure
  expect_s3_class(df, "data.frame")
  expect_gt(nrow(df), 0)

  # Check tidy-specific columns
  expect_true("subject" %in% names(df))
  expect_true("proficiency_level" %in% names(df))
  expect_true("pct" %in% names(df))
  expect_true("valid_n" %in% names(df))

  # Check subjects
  expect_true("ELA" %in% df$subject)
  expect_true("Math" %in% df$subject)

  # Check proficiency levels
  expect_true("Proficient" %in% df$proficiency_level)
  expect_true("Advanced" %in% df$proficiency_level)
})


# ==============================================================================
# Data fidelity tests - verify actual values from raw data
# ==============================================================================

test_that("2024 Grade 3 State ELA values match raw data", {
  skip_on_cran()
  skip_if_offline()

  df <- fetch_assessment(2024, tidy = FALSE, use_cache = TRUE)

  # Filter to Grade 3 State
  state_g3 <- df[df$is_state == TRUE & df$grade == 3, ]

  expect_equal(nrow(state_g3), 1)

  # Actual values from raw OSDE 2024 data:
  # Grade 3 State: ELA Valid N = 50069, ELA Below Basic % = 30
  expect_equal(state_g3$ela_valid_n, 50069)
  expect_equal(state_g3$ela_below_basic_pct, 30)
})


test_that("2024 Grade 3 State Math values match raw data", {
  skip_on_cran()
  skip_if_offline()

  df <- fetch_assessment(2024, tidy = FALSE, use_cache = TRUE)

  # Filter to Grade 3 State
  state_g3 <- df[df$is_state == TRUE & df$grade == 3, ]

  # Actual values from raw OSDE 2024 data:
  # Grade 3 State: Math Valid N = 50034, Math Below Basic % = 34
  expect_equal(state_g3$math_valid_n, 50034)
  expect_equal(state_g3$math_below_basic_pct, 34)
})


test_that("2025 Grade 3 State ELA values match raw data", {
  skip_on_cran()
  skip_if_offline()

  df <- fetch_assessment(2025, tidy = FALSE, use_cache = TRUE)

  # Filter to Grade 3 State
  state_g3 <- df[df$is_state == TRUE & df$grade == 3, ]

  expect_equal(nrow(state_g3), 1)

  # Actual values from raw OSDE 2025 data:
  # Grade 3 State: ELA Valid N = 49994, ELA Below Basic % = 43
  expect_equal(state_g3$ela_valid_n, 49994)
  expect_equal(state_g3$ela_below_basic_pct, 43)
})


test_that("2025 Grade 3 State Math values match raw data", {
  skip_on_cran()
  skip_if_offline()

  df <- fetch_assessment(2025, tidy = FALSE, use_cache = TRUE)

  # Filter to Grade 3 State
  state_g3 <- df[df$is_state == TRUE & df$grade == 3, ]

  # Actual values from raw OSDE 2025 data:
  # Grade 3 State: Math Valid N = 49954, Math Below Basic % = 32
  expect_equal(state_g3$math_valid_n, 49954)
  expect_equal(state_g3$math_below_basic_pct, 32)
})


# ==============================================================================
# Data quality tests
# ==============================================================================

test_that("Assessment data has valid grades", {
  skip_on_cran()
  skip_if_offline()

  df <- fetch_assessment(2024, tidy = FALSE, use_cache = TRUE)

  # OSTP grades are 3-8
  expect_true(all(df$grade %in% 3:8))
})


test_that("Assessment data has valid aggregation levels", {
  skip_on_cran()
  skip_if_offline()

  df <- fetch_assessment(2024, tidy = FALSE, use_cache = TRUE)

  expect_true(all(df$aggregation_level %in% c("state", "district", "school")))

  # Verify flags match aggregation level
  expect_equal(sum(df$is_state), sum(df$aggregation_level == "state"))
  expect_equal(sum(df$is_district), sum(df$aggregation_level == "district"))
  expect_equal(sum(df$is_school), sum(df$aggregation_level == "school"))
})


test_that("Assessment percentages are in valid range", {
  skip_on_cran()
  skip_if_offline()

  df <- fetch_assessment(2024, tidy = FALSE, use_cache = TRUE)

  # ELA percentages should be 0-100 (or NA)
  pct_cols <- c("ela_below_basic_pct", "ela_basic_pct",
                "ela_proficient_pct", "ela_advanced_pct",
                "math_below_basic_pct", "math_basic_pct",
                "math_proficient_pct", "math_advanced_pct")

  for (col in pct_cols) {
    if (col %in% names(df)) {
      valid <- is.na(df[[col]]) | (df[[col]] >= 0 & df[[col]] <= 100)
      expect_true(all(valid), info = paste("Invalid values in", col))
    }
  }
})


test_that("Assessment data has state-level records", {
  skip_on_cran()
  skip_if_offline()

  df <- fetch_assessment(2024, tidy = FALSE, use_cache = TRUE)

  # Should have state records
  state_rows <- df[df$is_state == TRUE, ]
  expect_gt(nrow(state_rows), 0)

  # Should have one state row per grade (6 grades: 3-8)
  expect_equal(nrow(state_rows), 6)
})


test_that("Assessment data has district and school records", {
  skip_on_cran()
  skip_if_offline()

  df <- fetch_assessment(2024, tidy = FALSE, use_cache = TRUE)

  # Should have district records
  expect_gt(sum(df$is_district), 0)

  # Should have school records
  expect_gt(sum(df$is_school), 0)

  # Schools should outnumber districts
  expect_gt(sum(df$is_school), sum(df$is_district))
})


test_that("No Inf or NaN values in assessment data", {
  skip_on_cran()
  skip_if_offline()

  df <- fetch_assessment(2024, tidy = FALSE, use_cache = TRUE)

  numeric_cols <- names(df)[sapply(df, is.numeric)]

  for (col in numeric_cols) {
    expect_false(any(is.infinite(df[[col]]), na.rm = TRUE),
                 info = paste("Inf found in", col))
    expect_false(any(is.nan(df[[col]]), na.rm = TRUE),
                 info = paste("NaN found in", col))
  }
})


# ==============================================================================
# Multi-year tests
# ==============================================================================

test_that("fetch_assessment_multi combines years correctly", {
  skip_on_cran()
  skip_if_offline()

  df <- fetch_assessment_multi(c(2024, 2025), tidy = TRUE, use_cache = TRUE)

  # Should have both years
  expect_true(2024 %in% df$end_year)
  expect_true(2025 %in% df$end_year)

  # Should have multiple rows
  expect_gt(nrow(df), 1000)
})


test_that("fetch_assessment_multi warns about COVID years", {
  skip_on_cran()
  skip_if_offline()

  expect_warning(
    df <- fetch_assessment_multi(c(2020, 2024), use_cache = TRUE),
    "excluded.*COVID"
  )

  # Should only have 2024 data
  expect_true(all(df$end_year == 2024))
})


# ==============================================================================
# Tidy format fidelity tests
# ==============================================================================

test_that("tidy format preserves values from wide format", {
  skip_on_cran()
  skip_if_offline()

  wide <- fetch_assessment(2024, tidy = FALSE, use_cache = TRUE)
  tidy <- fetch_assessment(2024, tidy = TRUE, use_cache = TRUE)

  # Get state Grade 3 ELA Proficient from both
  wide_state <- wide[wide$is_state == TRUE & wide$grade == 3, ]
  tidy_state <- tidy[tidy$is_state == TRUE & tidy$grade == 3 &
                      tidy$subject == "ELA" &
                      tidy$proficiency_level == "Proficient", ]

  # Values should match
  expect_equal(wide_state$ela_proficient_pct, tidy_state$pct)
})
