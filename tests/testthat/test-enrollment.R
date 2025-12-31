# Tests for enrollment functions
# Note: Most tests are marked as skip_on_cran since they require network access

test_that("safe_numeric handles various inputs", {
  # Normal numbers
  expect_equal(safe_numeric("100"), 100)
  expect_equal(safe_numeric("1,234"), 1234)

  # Suppressed values
  expect_true(is.na(safe_numeric("*")))
  expect_true(is.na(safe_numeric("-1")))
  expect_true(is.na(safe_numeric("<5")))
  expect_true(is.na(safe_numeric("<10")))
  expect_true(is.na(safe_numeric("")))
  expect_true(is.na(safe_numeric("N/A")))

  # Whitespace handling
  expect_equal(safe_numeric("  100  "), 100)

  # Empty/NULL handling
  expect_equal(length(safe_numeric(NULL)), 0)
  expect_equal(length(safe_numeric(character(0))), 0)
})

test_that("get_available_years returns valid range", {
  years <- get_available_years()

  expect_true(is.numeric(years))
  expect_true(length(years) > 0)
  expect_true(min(years) >= 2018)
  expect_true(max(years) <= 2025)
})

test_that("fetch_enr validates year parameter", {
  expect_error(fetch_enr(2000), "end_year must be between")
  expect_error(fetch_enr(2030), "end_year must be between")
  expect_error(fetch_enr(2010), "end_year must be between")
})

test_that("fetch_enr_multi validates year parameters", {
  expect_error(fetch_enr_multi(c(2000, 2001)), "Invalid years")
  expect_error(fetch_enr_multi(c(2024, 2030)), "Invalid years")
})

test_that("build_osde_url constructs valid URLs", {
  url <- build_osde_url(2024, "District")
  expect_true(grepl("sde.ok.gov", url))
  expect_true(grepl("2024", url))
  expect_true(grepl("District", url))
  expect_true(grepl("\\.xlsx", url))

  url_site <- build_osde_url(2024, "Site")
  expect_true(grepl("Site", url_site))
})

test_that("get_cache_dir returns valid path", {
  cache_dir <- get_cache_dir()
  expect_true(is.character(cache_dir))
  expect_true(grepl("okschooldata", cache_dir))
})

test_that("cache functions work correctly", {
  # Test cache path generation
  path <- get_cache_path(2024, "tidy")
  expect_true(grepl("enr_tidy_2024.rds", path))

  # Test cache_exists returns FALSE for non-existent cache
  # (Assuming no cache exists for year 9999)
  expect_false(cache_exists(9999, "tidy"))
})

test_that("get_osde_column_map returns expected structure", {
  col_map <- get_osde_column_map()

  expect_true(is.list(col_map))
  expect_true("district_id" %in% names(col_map))
  expect_true("district_name" %in% names(col_map))
  expect_true("total" %in% names(col_map))
  expect_true("white" %in% names(col_map))
  expect_true("black" %in% names(col_map))
  expect_true("hispanic" %in% names(col_map))
  expect_true("grade_k" %in% names(col_map))
})

test_that("create_state_aggregate handles empty data", {
  empty_df <- data.frame(
    end_year = integer(0),
    type = character(0),
    district_id = character(0),
    row_total = integer(0),
    stringsAsFactors = FALSE
  )

  result <- create_state_aggregate(empty_df, 2024)

  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 1)
  expect_equal(result$type, "State")
  expect_equal(result$end_year, 2024)
})

# Integration tests (require network access)
test_that("fetch_enr downloads and processes data", {
  skip_on_cran()
  skip_if_offline()

  # Use a recent year
  result <- tryCatch(
    fetch_enr(2024, tidy = FALSE, use_cache = FALSE),
    error = function(e) {
      skip(paste("Network error:", e$message))
    }
  )

  # Check structure
  expect_true(is.data.frame(result))
  expect_true("district_id" %in% names(result))
  expect_true("row_total" %in% names(result) || "campus_id" %in% names(result))
  expect_true("type" %in% names(result))

  # Check we have multiple levels
  expect_true("State" %in% result$type)
  expect_true("District" %in% result$type || "Campus" %in% result$type)
})

test_that("tidy_enr produces correct long format", {
  skip_on_cran()
  skip_if_offline()

  # Create sample wide data for testing
  wide <- data.frame(
    end_year = 2024,
    type = "District",
    district_id = "55I001",
    campus_id = NA_character_,
    district_name = "Oklahoma City",
    campus_name = NA_character_,
    county = "Oklahoma",
    row_total = 1000,
    white = 300,
    black = 200,
    hispanic = 400,
    asian = 50,
    native_american = 30,
    pacific_islander = 5,
    multiracial = 15,
    grade_k = 100,
    grade_01 = 90,
    grade_02 = 85,
    stringsAsFactors = FALSE
  )

  # Tidy it
  tidy_result <- tidy_enr(wide)

  # Check structure
  expect_true("grade_level" %in% names(tidy_result))
  expect_true("subgroup" %in% names(tidy_result))
  expect_true("n_students" %in% names(tidy_result))
  expect_true("pct" %in% names(tidy_result))

  # Check subgroups include expected values
  subgroups <- unique(tidy_result$subgroup)
  expect_true("total_enrollment" %in% subgroups)
  expect_true("hispanic" %in% subgroups)
  expect_true("white" %in% subgroups)
})

test_that("id_enr_aggs adds correct flags", {
  # Create sample tidy data
  tidy_data <- data.frame(
    end_year = 2024,
    type = c("State", "District", "Campus"),
    district_id = c(NA, "55I001", "55I001"),
    campus_id = c(NA, NA, "55I001001"),
    grade_level = "TOTAL",
    subgroup = "total_enrollment",
    n_students = c(700000, 40000, 500),
    pct = 1.0,
    stringsAsFactors = FALSE
  )

  result <- id_enr_aggs(tidy_data)

  # Check flags exist
  expect_true("is_state" %in% names(result))
  expect_true("is_district" %in% names(result))
  expect_true("is_campus" %in% names(result))

  # Check flags are boolean
  expect_true(is.logical(result$is_state))
  expect_true(is.logical(result$is_district))
  expect_true(is.logical(result$is_campus))

  # Check mutual exclusivity (each row is only one type)
  type_sums <- result$is_state + result$is_district + result$is_campus
  expect_true(all(type_sums == 1))

  # Check specific flags
  expect_true(result$is_state[result$type == "State"])
  expect_true(result$is_district[result$type == "District"])
  expect_true(result$is_campus[result$type == "Campus"])
})

test_that("enr_grade_aggs creates correct aggregates", {
  # Create sample tidy data with grade levels
  tidy_data <- data.frame(
    end_year = 2024,
    type = "State",
    district_id = NA_character_,
    campus_id = NA_character_,
    district_name = NA_character_,
    campus_name = NA_character_,
    county = NA_character_,
    grade_level = c("K", "01", "02", "03", "04", "05", "06", "07", "08",
                    "09", "10", "11", "12"),
    subgroup = "total_enrollment",
    n_students = c(50000, 52000, 51000, 53000, 52000, 51000, 50000, 49000, 48000,
                   47000, 46000, 45000, 44000),
    pct = NA_real_,
    is_state = TRUE,
    is_district = FALSE,
    is_campus = FALSE,
    stringsAsFactors = FALSE
  )

  result <- enr_grade_aggs(tidy_data)

  # Check we have K8, HS, and K12 aggregates
  expect_true("K8" %in% result$grade_level)
  expect_true("HS" %in% result$grade_level)
  expect_true("K12" %in% result$grade_level)

  # Check K-8 sum (K through 08)
  k8_row <- result[result$grade_level == "K8", ]
  expected_k8 <- sum(tidy_data$n_students[tidy_data$grade_level %in%
                     c("K", "01", "02", "03", "04", "05", "06", "07", "08")])
  expect_equal(k8_row$n_students, expected_k8)

  # Check HS sum (09 through 12)
  hs_row <- result[result$grade_level == "HS", ]
  expected_hs <- sum(tidy_data$n_students[tidy_data$grade_level %in%
                     c("09", "10", "11", "12")])
  expect_equal(hs_row$n_students, expected_hs)
})
