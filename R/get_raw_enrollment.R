# ==============================================================================
# Raw Enrollment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw enrollment data from OSDE.
#
# Data Sources:
# - OSDE Excel files: District and Site enrollment totals
#   URL pattern: https://sde.ok.gov/sites/default/files/District%20Enrollment%20SY{YEAR}.xlsx
#   URL pattern: https://sde.ok.gov/sites/default/files/Site%20Enrollment%20SY{YEAR}.xlsx
#
# - OklaSchools.com: Report card data with demographics and grade levels
#   Data Matrix: https://oklaschools.com/state/matrix/
#
# Oklahoma District/Site ID System:
# - District ID: County code (2 digits) + District type (1 char) + District number (3 digits)
#   Example: 55I001 = Oklahoma County (55), Independent (I), District 001
# - Site ID: District ID + Site number (3 digits)
#   Example: 55I001001 = Site 001 in Oklahoma City Public Schools
#
# County Codes: 01-77 (77 counties in Oklahoma)
# District Types: I=Independent, D=Dependent, C=City, T=Town, E=Elementary
#
# ==============================================================================

#' Download raw enrollment data from OSDE
#'
#' Downloads district and site enrollment data from OSDE's public data files.
#'
#' @param end_year School year end (2023-24 = 2024)
#' @return List with district and site data frames
#' @keywords internal
get_raw_enr <- function(end_year) {

  # Validate year
  available_years <- get_available_years()
  if (!end_year %in% available_years) {
    stop(paste0("end_year must be between ", min(available_years),
                " and ", max(available_years)))
  }

  message(paste("Downloading OSDE enrollment data for", end_year, "..."))

  # Download district data
  message("  Downloading district data...")
  district_data <- download_osde_enrollment(end_year, "District")

  # Download site data
  message("  Downloading site data...")
  site_data <- download_osde_enrollment(end_year, "Site")

  # Add end_year column if not present
  if (!"end_year" %in% names(district_data)) {
    district_data$end_year <- end_year
  }
  if (!"end_year" %in% names(site_data)) {
    site_data$end_year <- end_year
  }

  list(
    district = district_data,
    site = site_data
  )
}


#' Download OSDE enrollment Excel file
#'
#' Downloads district or site enrollment data from OSDE.
#'
#' @param end_year School year end
#' @param level "District" or "Site"
#' @return Data frame with enrollment data
#' @keywords internal
download_osde_enrollment <- function(end_year, level) {

  # Build URL - OSDE uses consistent naming pattern
  # Example: https://sde.ok.gov/sites/default/files/District%20Enrollment%20SY2024.xlsx
  url <- build_osde_url(end_year, level)

  # Create temp file for download
  tname <- tempfile(
    pattern = paste0("osde_", tolower(level), "_"),
    tmpdir = tempdir(),
    fileext = ".xlsx"
  )

  # Download file with error handling
  tryCatch({
    response <- httr::GET(
      url,
      httr::write_disk(tname, overwrite = TRUE),
      httr::timeout(300),
      httr::user_agent("okschooldata R package")
    )

    # Check for HTTP errors
    if (httr::http_error(response)) {
      # Try alternate URL patterns
      alt_url <- build_osde_url_alt(end_year, level)
      if (!is.null(alt_url)) {
        message(paste0("  Primary URL failed, trying alternate: ", alt_url))
        response <- httr::GET(
          alt_url,
          httr::write_disk(tname, overwrite = TRUE),
          httr::timeout(300),
          httr::user_agent("okschooldata R package")
        )
      }

      if (httr::http_error(response)) {
        stop(paste("HTTP error:", httr::status_code(response),
                   "\nURL:", url))
      }
    }

    # Check file size (small files likely error pages)
    file_info <- file.info(tname)
    if (file_info$size < 1000) {
      # May have received HTML error page
      first_lines <- readLines(tname, n = 5, warn = FALSE)
      if (any(grepl("^<html|^<HTML|^<!DOCTYPE|error|404|not found",
                    first_lines, ignore.case = TRUE))) {
        stop(paste("Received error page instead of Excel file for",
                   level, "year", end_year))
      }
    }

  }, error = function(e) {
    stop(paste("Failed to download", level, "data for year", end_year,
               "\nError:", e$message,
               "\nURL attempted:", url))
  })

  # Read the Excel file
  df <- tryCatch({
    readxl::read_excel(
      tname,
      col_types = "text",  # Read all as text to preserve leading zeros
      .name_repair = "unique"
    )
  }, error = function(e) {
    stop(paste("Failed to read Excel file for", level, "year", end_year,
               "\nError:", e$message))
  })

  # Clean up temp file
  unlink(tname)

  df
}


#' Build OSDE enrollment file URL
#'
#' Constructs the URL for downloading enrollment data from OSDE.
#'
#' @param end_year School year end
#' @param level "District" or "Site"
#' @return URL string
#' @keywords internal
build_osde_url <- function(end_year, level) {
  # Primary URL pattern: https://sde.ok.gov/sites/default/files/District%20Enrollment%20SY2024.xlsx
  base_url <- "https://sde.ok.gov/sites/default/files"
  filename <- paste0(level, "%20Enrollment%20SY", end_year, ".xlsx")
  paste0(base_url, "/", filename)
}


#' Build alternate OSDE enrollment file URL
#'
#' Constructs an alternate URL pattern for OSDE data.
#'
#' @param end_year School year end
#' @param level "District" or "Site"
#' @return URL string or NULL if no alternate
#' @keywords internal
build_osde_url_alt <- function(end_year, level) {
  # Alternate patterns that OSDE has used:
  # - documents/files/ subdirectory
  # - Different file naming (e.g., with school year range)

  base_url <- "https://sde.ok.gov/sites/default/files/documents/files"

  # Try format: District Enrollment SY2024.xlsx (without encoding)
  filename <- paste0(level, " Enrollment SY", end_year, ".xlsx")
  encoded_filename <- utils::URLencode(filename, reserved = TRUE)

  paste0(base_url, "/", encoded_filename)
}


#' Download OklaSchools.com report card data
#'
#' Downloads enrollment and demographics data from OklaSchools.com Data Matrix.
#' This is used as a supplementary data source for demographics and grade levels.
#'
#' @param end_year School year end
#' @return Data frame with report card data
#' @keywords internal
download_oklaschools_data <- function(end_year) {

  # OklaSchools.com provides CSV downloads from the Data Matrix

  # The URLs follow a pattern but may require session-based access
  # This function attempts to download available CSV exports

  message("  Attempting to download OklaSchools.com data...")

  # The data matrix typically has downloadable CSV files
  # However, direct URLs may change - this provides a fallback mechanism

  # For now, return empty data frame as primary source is OSDE Excel files

  # This can be enhanced if direct OklaSchools.com download URLs are confirmed
  warning("OklaSchools.com supplementary data not yet implemented")

  data.frame()
}


#' Get column mappings for OSDE enrollment data
#'
#' Returns a list mapping OSDE column names to standardized names.
#' OSDE uses fairly consistent naming but may vary slightly by year.
#'
#' @return Named list of column mappings
#' @keywords internal
get_osde_column_map <- function() {
  list(
    # District identifiers
    district_id = c("District Code", "DistrictCode", "DISTRICT CODE",
                    "District ID", "DistrictID", "DISTRICT ID",
                    "County-District Code", "CountyDistrictCode"),
    district_name = c("District Name", "DistrictName", "DISTRICT NAME",
                      "District", "DISTRICT"),

    # Site/School identifiers
    site_id = c("Site Code", "SiteCode", "SITE CODE",
                "School Code", "SchoolCode", "SCHOOL CODE",
                "Site ID", "SiteID", "SITE ID"),
    site_name = c("Site Name", "SiteName", "SITE NAME",
                  "School Name", "SchoolName", "SCHOOL NAME",
                  "School", "SCHOOL", "Site", "SITE"),

    # County information
    county_name = c("County", "COUNTY", "County Name", "CountyName"),
    county_code = c("County Code", "CountyCode", "COUNTY CODE"),

    # Enrollment totals
    total = c("Total Enrollment", "TotalEnrollment", "TOTAL ENROLLMENT",
              "Total", "TOTAL", "Enrollment", "ENROLLMENT",
              "ADM", "Average Daily Membership"),

    # Demographics - Race/Ethnicity
    white = c("White", "WHITE", "White Count", "WhiteCount",
              "Caucasian", "CAUCASIAN"),
    black = c("Black", "BLACK", "Black Count", "BlackCount",
              "African American", "AFRICAN AMERICAN",
              "Black or African American"),
    hispanic = c("Hispanic", "HISPANIC", "Hispanic Count", "HispanicCount",
                 "Hispanic/Latino", "HISPANIC/LATINO"),
    asian = c("Asian", "ASIAN", "Asian Count", "AsianCount"),
    native_american = c("American Indian", "AMERICAN INDIAN",
                        "American Indian/Alaska Native",
                        "Native American", "NATIVE AMERICAN",
                        "American Indian Count", "AmericanIndianCount"),
    pacific_islander = c("Pacific Islander", "PACIFIC ISLANDER",
                         "Native Hawaiian", "NATIVE HAWAIIAN",
                         "Native Hawaiian/Pacific Islander",
                         "Pacific Islander Count"),
    multiracial = c("Two or More", "TWO OR MORE",
                    "Two or More Races", "TWO OR MORE RACES",
                    "Multiracial", "MULTIRACIAL",
                    "Two or More Count", "TwoOrMoreCount"),

    # Special populations
    econ_disadv = c("Economically Disadvantaged", "ECONOMICALLY DISADVANTAGED",
                    "Free/Reduced Lunch", "FREE/REDUCED LUNCH",
                    "Low Income", "LOW INCOME",
                    "Economically Disadvantaged Count"),
    lep = c("English Learner", "ENGLISH LEARNER",
            "EL", "ELL", "LEP",
            "Limited English Proficient", "LIMITED ENGLISH PROFICIENT",
            "English Learner Count", "EnglishLearnerCount"),
    special_ed = c("Special Education", "SPECIAL EDUCATION",
                   "IEP", "Students with Disabilities",
                   "Special Education Count", "SpecialEducationCount"),

    # Grade levels - PreK through 12
    grade_pk = c("Pre-K", "PRE-K", "PreK", "PREK",
                 "Pre-Kindergarten", "PRE-KINDERGARTEN",
                 "PK", "Grade PK"),
    grade_k = c("Kindergarten", "KINDERGARTEN", "KG", "K",
                "Grade K", "Grade KG"),
    grade_01 = c("Grade 1", "Grade 01", "1st Grade", "01", "1"),
    grade_02 = c("Grade 2", "Grade 02", "2nd Grade", "02", "2"),
    grade_03 = c("Grade 3", "Grade 03", "3rd Grade", "03", "3"),
    grade_04 = c("Grade 4", "Grade 04", "4th Grade", "04", "4"),
    grade_05 = c("Grade 5", "Grade 05", "5th Grade", "05", "5"),
    grade_06 = c("Grade 6", "Grade 06", "6th Grade", "06", "6"),
    grade_07 = c("Grade 7", "Grade 07", "7th Grade", "07", "7"),
    grade_08 = c("Grade 8", "Grade 08", "8th Grade", "08", "8"),
    grade_09 = c("Grade 9", "Grade 09", "9th Grade", "09", "9"),
    grade_10 = c("Grade 10", "10th Grade", "10"),
    grade_11 = c("Grade 11", "11th Grade", "11"),
    grade_12 = c("Grade 12", "12th Grade", "12")
  )
}
