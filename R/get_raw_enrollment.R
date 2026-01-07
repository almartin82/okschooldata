# ==============================================================================
# Raw Enrollment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw enrollment data from OSDE.
#
# Data Sources:
# - Oklahoma.gov portal: Primary source for enrollment data
#   Base URL: https://oklahoma.gov/content/dam/ok/en/osde/documents/services/student-information/state-public-enrollment-totals/
#
# Data Eras:
# - Legacy Era (2016-2021): Files with FY naming pattern (e.g., FY15-16, FY16-17)
#   Pattern: GG_ByDIST_2F_GradeTots-FY{YY-YY}_...xls
#   Pattern: GG_BySITE_2F_GradeTots-FY{YY-YY}-...xls
#
# - Modern Era (2022-2025): Files with SY naming or dated files
#   Pattern: District%20Enrollment%20SY{YEAR}.xlsx
#   Pattern: School%20Totals%20SY{YEAR}...xlsx
#   Pattern: 03_DistrictEnrollment_{date}_final.xlsx
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
  years_info <- get_available_years()
  if (end_year < years_info$min_year || end_year > years_info$max_year) {
    stop(paste0("end_year must be between ", years_info$min_year,
                " and ", years_info$max_year))
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

  # Build URL based on year and level
  url <- build_osde_url(end_year, level)

  # Get file extension from the URL info
  url_info <- get_enrollment_file_info(end_year, level)
  file_ext <- url_info$extension

  # Create temp file for download
  tname <- tempfile(
    pattern = paste0("osde_", tolower(level), "_"),
    tmpdir = tempdir(),
    fileext = file_ext
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
  # OSDE files have headers in row 1, but readxl doesn't detect them properly
  # So we read the file, extract headers from row 1, and set them manually
  df <- tryCatch({
    # For 2025, specify the correct sheet
    if (end_year == 2025) {
      if (level == "District") {
        # District data is in "Distrct Enrollment" sheet (note the typo in "District")
        df_temp <- readxl::read_excel(
          tname,
          sheet = "Distrct Enrollment",
          col_types = "text",
          .name_repair = "unique"
        )
      } else {
        # Site data is in "School Totals by Grade" sheet
        df_temp <- readxl::read_excel(
          tname,
          sheet = "School Totals by Grade",
          col_types = "text",
          .name_repair = "unique"
        )
      }
    } else {
      # Other years use the first sheet
      df_temp <- readxl::read_excel(
        tname,
        col_types = "text",
        .name_repair = "unique"
      )
    }

    # Extract actual column names from first row
    actual_col_names <- as.character(df_temp[1, ])

    # Remove first row (header row) from data
    df_temp <- df_temp[-1, , drop = FALSE]

    # Set column names
    names(df_temp) <- actual_col_names

    df_temp
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
#' Handles different file naming patterns across eras.
#'
#' @param end_year School year end
#' @param level "District" or "Site"
#' @return URL string
#' @keywords internal
build_osde_url <- function(end_year, level) {

  base_url <- "https://oklahoma.gov/content/dam/ok/en/osde/documents/services/student-information/state-public-enrollment-totals"

  # Get the URL pattern based on year and level
  url_info <- get_enrollment_file_info(end_year, level)

  paste0(base_url, "/", url_info$filename)
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

  # Try sde.ok.gov as fallback for modern era files
  if (end_year >= 2022) {
    base_url <- "https://sde.ok.gov/sites/default/files"
    filename <- paste0(level, "%20Enrollment%20SY", end_year, ".xlsx")
    return(paste0(base_url, "/", filename))
  }

  # No alternate for legacy era
 NULL
}


#' Get enrollment file information for a given year
#'
#' Returns the filename and extension for enrollment data based on the year.
#' Handles the different naming conventions used across eras.
#'
#' @param end_year School year end (e.g., 2024 for 2023-24 school year)
#' @param level "District" or "Site"
#' @return List with filename and extension
#' @keywords internal
get_enrollment_file_info <- function(end_year, level) {

  # Convert end_year to fiscal year format (e.g., 2016 -> "15-16")
  fy_start <- sprintf("%02d", (end_year - 1) %% 100)
  fy_end <- sprintf("%02d", end_year %% 100)
  fy_label <- paste0(fy_start, "-", fy_end)

  # File patterns by era
  # Note: These are the known working URLs from oklahoma.gov enrollment page

  if (end_year == 2025) {
    # SY2025 uses a combined file format
    if (level == "District" || level == "Site") {
      return(list(
        filename = "ORR%20ALL%20Grids%20Oct%201%202024%20SY2025_Format.xlsx",
        extension = ".xlsx"
      ))
    }
  }

  if (end_year == 2024) {
    if (level == "District") {
      return(list(
        filename = "District%20Enrollment%20SY2024.xlsx",
        extension = ".xlsx"
      ))
    } else {
      return(list(
        filename = "School%20Totals%20SY2024%203.xlsx",
        extension = ".xlsx"
      ))
    }
  }

  if (end_year == 2023) {
    if (level == "District") {
      return(list(
        filename = "03_DistrictEnrollment_11-30-2022%20135728_final.xlsx",
        extension = ".xlsx"
      ))
    } else {
      return(list(
        filename = "01_SchoolSiteTotals_11-30-2022%20135728_final.xlsx",
        extension = ".xlsx"
      ))
    }
  }

  if (end_year == 2022) {
    if (level == "District") {
      return(list(
        filename = "03_DistrictEnrollment_12-14-2021%20172057.xlsx",
        extension = ".xlsx"
      ))
    } else {
      return(list(
        filename = "01_SchoolSiteTotals_12-14-2021%20173848.xlsx",
        extension = ".xlsx"
      ))
    }
  }

  if (end_year == 2021) {
    if (level == "District") {
      return(list(
        filename = "GG_ByDIST_2FCH_GradeTots-FY20-21_Public.xlsx",
        extension = ".xlsx"
      ))
    } else {
      return(list(
        filename = "GG_BySITE_2FCH_GradeTots-FY120-21_Public%20.xlsx",
        extension = ".xlsx"
      ))
    }
  }

  if (end_year == 2020) {
    if (level == "District") {
      # FY19-20 uses comparison file as main source (has enrollment data)
      return(list(
        filename = "GG_ByDIST_2T_Compare_FYC_FYP_2019-12-06_FY1920_0.xlsx",
        extension = ".xlsx"
      ))
    } else {
      return(list(
        filename = "GG_BySITE_2FCH_GradeTots-FY1920_Public_2019-12-09.xlsx",
        extension = ".xlsx"
      ))
    }
  }

  if (end_year == 2019) {
    if (level == "District") {
      return(list(
        filename = "GG_ByDIST_2FCH_GradeTots-FY18-19_Public_2019-01-18.xls",
        extension = ".xls"
      ))
    } else {
      return(list(
        filename = "GG_BySITE_2FCH_GradeTots-FY18-19_Public_2019-01-18.xls",
        extension = ".xls"
      ))
    }
  }

  if (end_year == 2018) {
    # FY17-18 has site files but district files use comparison format
    if (level == "District") {
      return(list(
        filename = "GG_ByDIST_2T_Compare_FYC_FYP_2017-12-06.xlsx",
        extension = ".xlsx"
      ))
    } else {
      return(list(
        filename = "GG_BySITE_2F_GradeTots-FY17-18-Public_2017-12-06.xls",
        extension = ".xls"
      ))
    }
  }

  if (end_year == 2017) {
    if (level == "District") {
      return(list(
        filename = "GG_ByDIST_2F_GradeTots-FY16-17_Public_2016-12-02_0.xls",
        extension = ".xls"
      ))
    } else {
      return(list(
        filename = "GG_BySITE_2F_GradeTots-FY16-17-Public_2016-12-02.xls",
        extension = ".xls"
      ))
    }
  }

  if (end_year == 2016) {
    if (level == "District") {
      return(list(
        filename = "GG_ByDIST_2F_GradeTots-FY15-16_2015-12-18.xls",
        extension = ".xls"
      ))
    } else {
      return(list(
        filename = "GG_BySITE_2F_GradeTots-FY15-16-Public_2015-12-18.xls",
        extension = ".xls"
      ))
    }
  }

  # Default fallback for unknown years
  stop(paste("No URL pattern defined for year", end_year))
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
    district_id = c("CoDist Code", "District Code", "DistrictCode", "DISTRICT CODE",
                    "District ID", "DistrictID", "DISTRICT ID",
                    "County-District Code", "CountyDistrictCode"),
    district_name = c("District", "District Name", "DistrictName", "DISTRICT NAME",
                      "DISTRICT"),

    # Site/School identifiers
    site_id = c("Site Code", "SiteCode", "SITE CODE",
                "School Code", "SchoolCode", "SCHOOL CODE",
                "Site ID", "SiteID", "SITE ID"),
    site_name = c("School Site", "Site Name", "SiteName", "SITE NAME",
                  "School Name", "SchoolName", "SCHOOL NAME",
                  "School", "SCHOOL", "Site", "SITE"),

    # County information
    county_name = c("County", "COUNTY", "County Name", "CountyName"),
    county_code = c("County Code", "CountyCode", "COUNTY CODE"),

    # Enrollment totals
    total = c("Total Enrollment", "TotalEnrollment", "TOTAL ENROLLMENT",
              "Total", "TOTAL", "Enrollment", "ENROLLMENT",
              "ADM", "Average Daily Membership"),

    # Demographics - Race/Ethnicity (Note: OSDE files don't have demographic breakdowns)
    # These are kept for potential future data sources
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

    # Special populations (Note: OSDE files don't have these in enrollment reports)
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

    # Grade levels - OSDE uses "Total  {grade}" format
    # Pre-K grades
    grade_pk = c("Total  PK3 (half day)", "Total  PK3 (full day)",
                 "Total  PK4 (half day)", "Total  PK4 (full day)",
                 "Pre-K", "PRE-K", "PreK", "PREK",
                 "Pre-Kindergarten", "PRE-KINDERGARTEN",
                 "PK", "Grade PK"),
    grade_k = c("Total  KG  (half day)", "Total  KG  (full day)",
                "Kindergarten", "KINDERGARTEN", "KG", "K",
                "Grade K", "Grade KG"),
    grade_01 = c("Total  1st", "Grade 1", "Grade 01", "1st Grade", "01", "1"),
    grade_02 = c("Total  2nd", "Grade 2", "Grade 02", "2nd Grade", "02", "2"),
    grade_03 = c("Total  3rd", "Grade 3", "Grade 03", "3rd Grade", "03", "3"),
    grade_04 = c("Total  4th", "Grade 4", "Grade 04", "4th Grade", "04", "4"),
    grade_05 = c("Total  5th", "Grade 5", "Grade 05", "5th Grade", "05", "5"),
    grade_06 = c("Total  6th", "Grade 6", "Grade 06", "6th Grade", "06", "6"),
    grade_07 = c("Total  7th", "Grade 7", "Grade 07", "7th Grade", "07", "7"),
    grade_08 = c("Total  8th", "Grade 8", "Grade 08", "8th Grade", "08", "8"),
    grade_09 = c("Total  9th", "Grade 9", "Grade 09", "9th Grade", "09", "9"),
    grade_10 = c("Total 10th", "Grade 10", "10th Grade", "10"),
    grade_11 = c("Total 11th", "Grade 11", "11th Grade", "11"),
    grade_12 = c("Total 12th", "Grade 12", "12th Grade", "12")
  )
}
