# ==============================================================================
# Assessment Data Fetching Functions
# ==============================================================================
#
# This file contains the main user-facing functions for fetching Oklahoma
# OSTP (Oklahoma School Testing Program) assessment data.
#
# Available years: 2017, 2018, 2019, 2022, 2023, 2024, 2025
# Note: 2020 and 2021 have no public data due to COVID-19 pandemic
#
# ==============================================================================


#' Fetch Oklahoma OSTP assessment data
#'
#' Downloads and processes OSTP assessment data from the Oklahoma State
#' Department of Education. Includes grades 3-8 for ELA, Math, and Science.
#'
#' Assessment systems:
#' - **OSTP** (Oklahoma School Testing Program): 2017-present for Grades 3-8
#' - **Proficiency levels**: Below Basic, Basic, Proficient, Advanced
#' - **2020-2021**: No public data due to COVID-19 pandemic
#'
#' @param end_year School year end (2023-24 = 2024). Valid years: 2017-2019, 2022-2025.
#' @param tidy If TRUE (default), returns data in long (tidy) format with subject
#'   and proficiency_level columns. If FALSE, returns wide format with separate
#'   columns for each subject/level combination.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#'   Set to FALSE to force re-download from OSDE.
#' @return Data frame with assessment data. Wide format includes columns for
#'   proficiency percentages by subject. Tidy format pivots these into
#'   subject, proficiency_level, and pct columns.
#' @export
#' @examples
#' \dontrun{
#' # Get 2024 assessment data (2023-24 school year) in tidy format
#' assess_2024 <- fetch_assessment(2024)
#'
#' # Get wide format (subject columns not pivoted)
#' assess_wide <- fetch_assessment(2024, tidy = FALSE)
#'
#' # Force fresh download (ignore cache)
#' assess_fresh <- fetch_assessment(2024, use_cache = FALSE)
#'
#' # Filter to state-level ELA results
#' state_ela <- assess_2024 |>
#'   dplyr::filter(is_state, subject == "ELA")
#' }
fetch_assessment <- function(end_year, tidy = TRUE, use_cache = TRUE) {

  # Validate year
  available <- get_available_assessment_years()

  if (end_year %in% c(2020, 2021)) {
    stop(paste0(
      "Assessment data is not available for ", end_year,
      " due to COVID-19 pandemic. ", available$note
    ))
  }

  if (!end_year %in% available$years) {
    stop(paste0(
      "end_year must be one of: ", paste(available$years, collapse = ", "),
      "\nGot: ", end_year, "\n", available$note
    ))
  }

  # Determine cache type
  cache_type <- if (tidy) "assessment_tidy" else "assessment_wide"

  # Check cache first
  if (use_cache && assessment_cache_exists(end_year, cache_type)) {
    message(paste("Using cached assessment data for", end_year))
    return(read_assessment_cache(end_year, cache_type))
  }

  # Get raw data from OSDE
  raw <- get_raw_assessment(end_year)

  # Process to standard schema
  processed <- process_assessment(raw, end_year)

  # Optionally tidy
  if (tidy) {
    processed <- tidy_assessment(processed)
  }

  # Cache the result
  if (use_cache) {
    write_assessment_cache(processed, end_year, cache_type)
  }

  processed
}


#' Fetch assessment data for multiple years
#'
#' Downloads and combines assessment data for multiple school years.
#' Years 2020 and 2021 are automatically excluded (no public data).
#'
#' @param end_years Vector of school year ends (e.g., c(2022, 2023, 2024))
#' @param tidy If TRUE (default), returns data in long (tidy) format.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#' @return Combined data frame with assessment data for all requested years
#' @export
#' @examples
#' \dontrun{
#' # Get 3 years of data
#' assess_multi <- fetch_assessment_multi(c(2022, 2023, 2024))
#'
#' # Track proficiency trends at state level
#' assess_multi |>
#'   dplyr::filter(is_state, subject == "Math", grade == 4) |>
#'   dplyr::filter(proficiency_level %in% c("Proficient", "Advanced")) |>
#'   dplyr::group_by(end_year) |>
#'   dplyr::summarize(pct_proficient = sum(pct, na.rm = TRUE))
#' }
fetch_assessment_multi <- function(end_years, tidy = TRUE, use_cache = TRUE) {

  # Validate years
  available <- get_available_assessment_years()

  # Check for COVID years
  covid_years <- end_years[end_years %in% c(2020, 2021)]
  if (length(covid_years) > 0) {
    warning(paste0(
      "Years ", paste(covid_years, collapse = ", "),
      " excluded: No public data due to COVID-19 pandemic."
    ))
    end_years <- end_years[!end_years %in% c(2020, 2021)]
  }

  invalid_years <- end_years[!end_years %in% available$years]
  if (length(invalid_years) > 0) {
    stop(paste0(
      "Invalid years: ", paste(invalid_years, collapse = ", "),
      "\nend_year must be one of: ", paste(available$years, collapse = ", ")
    ))
  }

  if (length(end_years) == 0) {
    stop("No valid years to fetch")
  }

  # Fetch each year
  results <- purrr::map(
    end_years,
    function(yr) {
      message(paste("Fetching", yr, "..."))
      fetch_assessment(yr, tidy = tidy, use_cache = use_cache)
    }
  )

  # Combine
  dplyr::bind_rows(results)
}


#' Get assessment data for a specific district
#'
#' Convenience function to fetch assessment data for a single district.
#'
#' @param end_year School year end
#' @param district_id 6-character district ID (e.g., "55I001" for Oklahoma City)
#' @param tidy If TRUE (default), returns tidy format
#' @param use_cache If TRUE (default), uses cached data
#' @return Data frame filtered to specified district
#' @export
#' @examples
#' \dontrun{
#' # Get Oklahoma City (district 55I001) assessment data
#' okc_assess <- fetch_district_assessment(2024, "55I001")
#'
#' # Get Tulsa (district 72I001) data
#' tulsa_assess <- fetch_district_assessment(2024, "72I001")
#' }
fetch_district_assessment <- function(end_year, district_id, tidy = TRUE, use_cache = TRUE) {

  # Capture the district_id parameter
  target_district <- district_id

  # Fetch all data
  df <- fetch_assessment(end_year, tidy = tidy, use_cache = use_cache)

  # Filter to requested district (include district aggregate and schools)
  df |>
    dplyr::filter(.data$district_id == target_district |
                  .data$organization_id == target_district)
}


#' Get assessment data for a specific school
#'
#' Convenience function to fetch assessment data for a single school.
#'
#' @param end_year School year end
#' @param school_id 9-character school ID (e.g., "55I001105")
#' @param tidy If TRUE (default), returns tidy format
#' @param use_cache If TRUE (default), uses cached data
#' @return Data frame filtered to specified school
#' @export
#' @examples
#' \dontrun{
#' # Get a specific school's assessment data
#' school_assess <- fetch_school_assessment(2024, "55I001105")
#' }
fetch_school_assessment <- function(end_year, school_id, tidy = TRUE, use_cache = TRUE) {

  # Capture the school_id parameter
  target_school <- school_id

  # Fetch all data
  df <- fetch_assessment(end_year, tidy = tidy, use_cache = use_cache)

  # Filter to requested school
  df |>
    dplyr::filter(.data$organization_id == target_school)
}


# ==============================================================================
# Assessment-specific caching functions
# ==============================================================================


#' Get assessment cache path
#'
#' @param end_year School year end
#' @param type Cache type ("assessment_tidy" or "assessment_wide")
#' @return Full path to cache file
#' @keywords internal
get_assessment_cache_path <- function(end_year, type) {
  cache_dir <- get_cache_dir()
  file.path(cache_dir, paste0(type, "_", end_year, ".rds"))
}


#' Check if assessment cache exists
#'
#' @param end_year School year end
#' @param type Cache type
#' @param max_age Maximum age in days (default 30)
#' @return TRUE if valid cache exists
#' @keywords internal
assessment_cache_exists <- function(end_year, type, max_age = 30) {
  cache_path <- get_assessment_cache_path(end_year, type)

  if (!file.exists(cache_path)) {
    return(FALSE)
  }

  # Check age
  file_info <- file.info(cache_path)
  age_days <- as.numeric(difftime(Sys.time(), file_info$mtime, units = "days"))

  age_days <= max_age
}


#' Read assessment data from cache
#'
#' @param end_year School year end
#' @param type Cache type
#' @return Cached data frame
#' @keywords internal
read_assessment_cache <- function(end_year, type) {
  cache_path <- get_assessment_cache_path(end_year, type)
  readRDS(cache_path)
}


#' Write assessment data to cache
#'
#' @param df Data frame to cache
#' @param end_year School year end
#' @param type Cache type
#' @return Invisibly returns the cache path
#' @keywords internal
write_assessment_cache <- function(df, end_year, type) {
  cache_path <- get_assessment_cache_path(end_year, type)
  saveRDS(df, cache_path)
  invisible(cache_path)
}
