# Tests for cache functions

test_that("get_cache_dir creates directory if needed", {
  cache_dir <- get_cache_dir()

  expect_true(is.character(cache_dir))
  expect_true(dir.exists(cache_dir))
  expect_true(grepl("okschooldata", cache_dir))
})

test_that("get_cache_path generates correct filenames", {
  path_tidy <- get_cache_path(2024, "tidy")
  path_wide <- get_cache_path(2024, "wide")

  expect_true(grepl("enr_tidy_2024\\.rds$", path_tidy))
  expect_true(grepl("enr_wide_2024\\.rds$", path_wide))

  # Different years should have different paths
  path_2023 <- get_cache_path(2023, "tidy")
  expect_false(path_tidy == path_2023)
})

test_that("cache_exists returns FALSE for non-existent files", {
  # Year 9999 should never have cached data

  expect_false(cache_exists(9999, "tidy"))
  expect_false(cache_exists(9999, "wide"))
})

test_that("write_cache and read_cache roundtrip works", {
  # Create test data
  test_df <- data.frame(
    end_year = 2024,
    district_id = "55I001",
    enrollment = 100,
    stringsAsFactors = FALSE
  )

  # Use a unique year to avoid conflicts
  test_year <- 1999

  # Write to cache
  cache_path <- write_cache(test_df, test_year, "test")
  expect_true(file.exists(cache_path))

  # Read back
  read_df <- read_cache(test_year, "test")

  # Compare
  expect_equal(nrow(read_df), nrow(test_df))
  expect_equal(read_df$end_year, test_df$end_year)
  expect_equal(read_df$district_id, test_df$district_id)
  expect_equal(read_df$enrollment, test_df$enrollment)

  # Clean up
  unlink(cache_path)
})

test_that("clear_cache removes files", {
  # Create test cache file
  test_df <- data.frame(x = 1)
  test_year <- 1998

  cache_path <- write_cache(test_df, test_year, "tidy")
  expect_true(file.exists(cache_path))

  # Clear specific file
  clear_cache(test_year, "tidy")
  expect_false(file.exists(cache_path))
})

test_that("cache_status returns data frame", {
  result <- cache_status()

  # Should return a data frame (possibly empty)
  expect_true(is.data.frame(result) || identical(result, data.frame()))
})
