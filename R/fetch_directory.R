# ==============================================================================
# School Directory Data Functions
# ==============================================================================
#
# This file contains functions for downloading school directory data from the
# Oklahoma State Department of Education (OSDE) website.
#
# Data Sources:
# - Oklahoma.gov Portal: https://oklahoma.gov/education/resources/state-school-directory.html
# - District Directory: Contains superintendent, board president, addresses, phone
# - Site Directory: Contains principal, enrollment, grades served, addresses, phone
#
# Data Availability:
# - FY25 (2024-25 school year): Both district and site directories available
# - FY26 (2025-26 school year): District directory available (current year)
#
# Oklahoma ID System:
# - District Code: County code (2 digits) + "-" + District type (1 char) + District number (3 digits)
#   Example: 55-I001 = Oklahoma County (55), Independent (I), District 001
# - Site Code: 3-digit site number within district
#
# ==============================================================================

#' Fetch Oklahoma school directory data
#'
#' Downloads and processes school directory data from the Oklahoma State
#' Department of Education's public data files. Returns contact information
#' for districts and schools including principal/superintendent names,
#' addresses, and phone numbers.
#'
#' @param end_year A school year. Year is the end of the academic year - eg 2024-25
#'   school year is year '2025'. Valid values are 2025-2026 (limited history available).
#' @param tidy If TRUE (default), returns data in a standardized format with
#'   consistent column names. If FALSE, returns raw column names from source.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#'   Set to FALSE to force re-download from OSDE.
#' @return Data frame with directory data including:
#'   \describe{
#'     \item{end_year}{School year end (e.g., 2025 for 2024-25)}
#'     \item{district_id}{District code (e.g., "55I001")}
#'     \item{school_id}{School site code (e.g., "55I001105") - NA for district rows}
#'     \item{district_name}{District name}
#'     \item{school_name}{School/site name - NA for district rows}
#'     \item{county}{County name}
#'     \item{superintendent_name}{District superintendent (district rows only)}
#'     \item{superintendent_email}{Superintendent email (district rows only)}
#'     \item{principal_name}{School principal (school rows only)}
#'     \item{principal_email}{Principal email (school rows only)}
#'     \item{board_president}{Board president name (district rows only)}
#'     \item{phone}{Phone number}
#'     \item{fax}{Fax number (district rows only)}
#'     \item{website}{Website URL (district rows only)}
#'     \item{physical_address, physical_city, physical_state, physical_zip}{Physical address}
#'     \item{mailing_address, mailing_city, mailing_state, mailing_zip}{Mailing address}
#'     \item{grades_served}{Grade span (e.g., "PK-12") - school rows only}
#'     \item{enrollment}{Total enrollment - school rows only}
#'   }
#' @export
#' @examples
#' \dontrun{
#' # Get 2025 school directory data (2024-25 school year)
#' dir_2025 <- fetch_directory(2025)
#'
#' # Get raw format (original column names)
#' dir_raw <- fetch_directory(2025, tidy = FALSE)
#'
#' # Force fresh download (ignore cache)
#' dir_fresh <- fetch_directory(2025, use_cache = FALSE)
#'
#' # Filter to specific district
#' okc_ps <- dir_2025 |>
#'   dplyr::filter(district_id == "55I001")
#'
#' # Get all principals
#' principals <- dir_2025 |>
#'   dplyr::filter(!is.na(principal_name)) |>
#'   dplyr::select(district_name, school_name, principal_name, principal_email)
#' }
fetch_directory <- function(end_year = NULL, tidy = TRUE, use_cache = TRUE) {

  # Default to most recent year with full data

  if (is.null(end_year)) {
    end_year <- get_directory_available_years()$max_year
  }

  # Validate year
  years_info <- get_directory_available_years()
  if (end_year < years_info$min_year || end_year > years_info$max_year) {
    stop(paste0(
      "end_year must be between ", years_info$min_year, " and ", years_info$max_year,
      ". Directory data has limited historical availability."
    ))
  }

  # Determine cache type based on tidy parameter
  cache_type <- if (tidy) "directory_tidy" else "directory_wide"

  # Check cache first
  if (use_cache && cache_exists(end_year, cache_type)) {
    message(paste("Using cached directory data for", end_year))
    return(read_cache(end_year, cache_type))
  }

  # Get raw data from OSDE
  raw <- get_raw_directory(end_year)

  # Process to standard schema
  processed <- process_directory(raw, end_year)

  # Optionally keep raw column names
  if (!tidy) {
    # For non-tidy, return the processed but with original-style columns
    processed <- processed
  }

  # Cache the result
  if (use_cache) {
    write_cache(processed, end_year, cache_type)
  }

  processed
}


#' Get available years for Oklahoma school directory data
#'
#' Returns metadata about the range of school years for which directory data
#' is available from the Oklahoma State Department of Education.
#'
#' @return A list with components:
#'   \describe{
#'     \item{min_year}{Earliest available school year end (2025)}
#'     \item{max_year}{Latest available school year end (2026)}
#'     \item{description}{Human-readable description of the data availability}
#'   }
#' @export
#' @examples
#' years <- get_directory_available_years()
#' years$min_year
#' years$max_year
get_directory_available_years <- function() {
  list(
    min_year = 2025L,
    max_year = 2026L,
    description = "Oklahoma school directory data from OSDE is available for school years 2024-25 through 2025-26 (end years 2025-2026). Limited historical data available."
  )
}


#' Download raw directory data from OSDE
#'
#' Downloads district and site directory data from OSDE's public data files.
#'
#' @param end_year School year end (2024-25 = 2025)
#' @return List with district and site data frames
#' @keywords internal
get_raw_directory <- function(end_year) {

  # Validate year
  years_info <- get_directory_available_years()
  if (end_year < years_info$min_year || end_year > years_info$max_year) {
    stop(paste0("end_year must be between ", years_info$min_year,
                " and ", years_info$max_year))
  }

  message(paste("Downloading OSDE directory data for", end_year, "..."))

  # Download district data
  message("  Downloading district directory...")
  district_data <- download_osde_directory(end_year, "District")

  # Download site data (may not be available for current year)
  site_data <- tryCatch({
    message("  Downloading school site directory...")
    download_osde_directory(end_year, "Site")
  }, error = function(e) {
    message("  Note: School site directory not available for ", end_year)
    NULL
  })

  list(
    district = district_data,
    site = site_data
  )
}


#' Download OSDE directory Excel file
#'
#' Downloads district or site directory data from OSDE.
#'
#' @param end_year School year end
#' @param level "District" or "Site"
#' @return Data frame with directory data
#' @keywords internal
download_osde_directory <- function(end_year, level) {

  # Build URL based on year and level
  url <- build_directory_url(end_year, level)

  # Create temp file for download
  tname <- tempfile(
    pattern = paste0("osde_dir_", tolower(level), "_"),
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
      stop(paste("HTTP error:", httr::status_code(response), "\nURL:", url))
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
    stop(paste("Failed to download", level, "directory for year", end_year,
               "\nError:", e$message,
               "\nURL attempted:", url))
  })

  # Determine skip rows based on file structure
  skip_rows <- if (level == "District") 4 else 3

  # Read the Excel file
  df <- tryCatch({
    readxl::read_excel(
      tname,
      col_types = "text",  # Read all as text to preserve formatting
      skip = skip_rows,
      .name_repair = "unique"
    )
  }, error = function(e) {
    stop(paste("Failed to read Excel file for", level, "year", end_year,
               "\nError:", e$message))
  })

  # Clean up temp file
  unlink(tname)

  # Add source metadata
  df$.source_level <- level
  df$.end_year <- as.character(end_year)

  df
}


#' Build OSDE directory file URL
#'
#' Constructs the URL for downloading directory data from OSDE.
#' Handles different file locations based on year and type.
#'
#' @param end_year School year end
#' @param level "District" or "Site"
#' @return URL string
#' @keywords internal
build_directory_url <- function(end_year, level) {

  # Convert end_year to fiscal year format (e.g., 2025 -> "FY25")
  fy <- sprintf("FY%02d", end_year %% 100)

  # URL patterns differ by year
  if (end_year == 2026) {
    # FY26 uses resources/state-directory path
    base_url <- "https://oklahoma.gov/content/dam/ok/en/osde/documents/resources/state-directory"
    if (level == "District") {
      filename <- paste0(fy, "OnlineDirectoryDistrictList.xlsx")
    } else {
      # Site list may not be available for FY26 yet
      filename <- paste0(fy, "OnlineDirectorySiteList.xlsx")
    }
  } else {
    # FY25 and earlier use school-personnel-records path
    base_url <- "https://oklahoma.gov/content/dam/ok/en/osde/documents/services/school-personnel-records"
    if (level == "District") {
      filename <- paste0(fy, "%20EOY%20OnlineDirectoryDistrictList.xlsx")
    } else {
      filename <- paste0(fy, "%20EOY%20OnlineDirectorySiteList.xlsx")
    }
  }

  paste0(base_url, "/", filename)
}


#' Process raw OSDE directory data
#'
#' Transforms raw OSDE directory data into a standardized schema combining
#' district and site data.
#'
#' @param raw_data List containing district and site data frames from get_raw_directory
#' @param end_year School year end
#' @return Processed data frame with standardized columns
#' @keywords internal
process_directory <- function(raw_data, end_year) {

  # Process district data
  district_processed <- process_district_directory(raw_data$district, end_year)

  # Process site data if available
  if (!is.null(raw_data$site) && nrow(raw_data$site) > 0) {
    site_processed <- process_site_directory(raw_data$site, end_year)
  } else {
    site_processed <- NULL
  }

  # Combine both levels
  result <- dplyr::bind_rows(district_processed, site_processed)

  # Sort by district and school
  result <- result |>
    dplyr::arrange(county, district_name, school_name)

  result
}


#' Process district-level directory data
#'
#' @param df Raw district directory data frame
#' @param end_year School year end
#' @return Processed district data frame
#' @keywords internal
process_district_directory <- function(df, end_year) {

  if (is.null(df) || nrow(df) == 0) {
    return(create_empty_directory_df(end_year))
  }

  cols <- names(df)

  # Clean column names (remove line breaks)
  names(df) <- gsub("[\r\n]+", " ", names(df))
  names(df) <- trimws(names(df))
  cols <- names(df)

  # Helper to find column by pattern (case-insensitive)
  find_col <- function(patterns) {
    for (pattern in patterns) {
      matched <- grep(pattern, cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  # Extract columns
  county_col <- find_col(c("^County", "County Name"))
  code_col <- find_col(c("^Code$", "District Code", "Co/Dist"))
  name_col <- find_col(c("^District", "District Name"))
  supt_col <- find_col(c("Superintendent$", "^Superintendent$"))
  supt_email_col <- find_col(c("Superintendent.*Email", "Supt.*Email"))
  board_col <- find_col(c("Board President", "Board Pres"))
  phone_col <- find_col(c("^Phone$", "Telephone"))
  fax_col <- find_col(c("^Fax$"))
  web_col <- find_col(c("Web.*URL", "Website", "Web Site"))

  # Address columns
  phys_addr_col <- find_col(c("Physical Address", "Physical  Address"))
  phys_city_col <- find_col(c("Physical City"))
  phys_state_col <- find_col(c("Physical State"))
  phys_zip_col <- find_col(c("Physical Zip"))
  mail_addr_col <- find_col(c("Mailing Address"))
  mail_city_col <- find_col(c("Mailing City"))
  mail_state_col <- find_col(c("Mailing State"))
  mail_zip_col <- find_col(c("Mailing Zip"))

  n_rows <- nrow(df)

  # Build result dataframe
  result <- data.frame(
    end_year = rep(end_year, n_rows),
    type = rep("District", n_rows),
    stringsAsFactors = FALSE
  )

  # County
  if (!is.null(county_col)) {
    result$county <- trimws(as.character(df[[county_col]]))
  } else {
    result$county <- NA_character_
  }

  # District ID - normalize format (remove dash)
  if (!is.null(code_col)) {
    raw_code <- trimws(as.character(df[[code_col]]))
    result$district_id <- gsub("-", "", raw_code)
  } else {
    result$district_id <- NA_character_
  }

  # School ID is NA for district rows
  result$school_id <- NA_character_

  # District Name
  if (!is.null(name_col)) {
    result$district_name <- trimws(as.character(df[[name_col]]))
  } else {
    result$district_name <- NA_character_
  }

  # School name is NA for district rows
  result$school_name <- NA_character_

  # Superintendent
  if (!is.null(supt_col)) {
    result$superintendent_name <- trimws(as.character(df[[supt_col]]))
  } else {
    result$superintendent_name <- NA_character_
  }

  if (!is.null(supt_email_col)) {
    result$superintendent_email <- trimws(as.character(df[[supt_email_col]]))
  } else {
    result$superintendent_email <- NA_character_
  }

  # Principal is NA for district rows
  result$principal_name <- NA_character_
  result$principal_email <- NA_character_

  # Board President
  if (!is.null(board_col)) {
    result$board_president <- trimws(as.character(df[[board_col]]))
  } else {
    result$board_president <- NA_character_
  }

  # Phone/Fax/Web
  if (!is.null(phone_col)) {
    result$phone <- trimws(as.character(df[[phone_col]]))
  } else {
    result$phone <- NA_character_
  }

  if (!is.null(fax_col)) {
    result$fax <- trimws(as.character(df[[fax_col]]))
  } else {
    result$fax <- NA_character_
  }

  if (!is.null(web_col)) {
    result$website <- trimws(as.character(df[[web_col]]))
  } else {
    result$website <- NA_character_
  }

  # Physical address
  if (!is.null(phys_addr_col)) {
    result$physical_address <- trimws(as.character(df[[phys_addr_col]]))
  } else {
    result$physical_address <- NA_character_
  }

  if (!is.null(phys_city_col)) {
    result$physical_city <- trimws(as.character(df[[phys_city_col]]))
  } else {
    result$physical_city <- NA_character_
  }

  if (!is.null(phys_state_col)) {
    result$physical_state <- trimws(as.character(df[[phys_state_col]]))
  } else {
    result$physical_state <- NA_character_
  }

  if (!is.null(phys_zip_col)) {
    result$physical_zip <- trimws(as.character(df[[phys_zip_col]]))
  } else {
    result$physical_zip <- NA_character_
  }

  # Mailing address
  if (!is.null(mail_addr_col)) {
    result$mailing_address <- trimws(as.character(df[[mail_addr_col]]))
  } else {
    result$mailing_address <- NA_character_
  }

  if (!is.null(mail_city_col)) {
    result$mailing_city <- trimws(as.character(df[[mail_city_col]]))
  } else {
    result$mailing_city <- NA_character_
  }

  if (!is.null(mail_state_col)) {
    result$mailing_state <- trimws(as.character(df[[mail_state_col]]))
  } else {
    result$mailing_state <- NA_character_
  }

  if (!is.null(mail_zip_col)) {
    result$mailing_zip <- trimws(as.character(df[[mail_zip_col]]))
  } else {
    result$mailing_zip <- NA_character_
  }

  # Grades and enrollment are NA for district rows
  result$grades_served <- NA_character_
  result$enrollment <- NA_integer_

  result
}


#' Process site-level directory data
#'
#' @param df Raw site directory data frame
#' @param end_year School year end
#' @return Processed site data frame
#' @keywords internal
process_site_directory <- function(df, end_year) {

  if (is.null(df) || nrow(df) == 0) {
    return(create_empty_directory_df(end_year))
  }

  cols <- names(df)

  # Clean column names (remove line breaks)
  names(df) <- gsub("[\r\n]+", " ", names(df))
  names(df) <- trimws(names(df))
  cols <- names(df)

  # Helper to find column by pattern (case-insensitive)
  find_col <- function(patterns) {
    for (pattern in patterns) {
      matched <- grep(pattern, cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  # Extract columns
  county_col <- find_col(c("^County", "County Name"))
  dist_name_col <- find_col(c("District Name", "^District"))
  dist_code_col <- find_col(c("Co/Dist Code", "District Code"))
  site_code_col <- find_col(c("Site Code", "School Code"))
  site_name_col <- find_col(c("School Site", "Site Name", "School Name"))
  enroll_col <- find_col(c("Total Enrollment", "Enrollment"))
  phone_col <- find_col(c("Telephone", "^Phone$"))
  principal_col <- find_col(c("^Principal$"))
  principal_email_col <- find_col(c("Principal.*Email", "Principal Email"))
  grades_col <- find_col(c("Grades", "Grade.*Low.*High"))

  # Address columns
  phys_addr_col <- find_col(c("Physical Address"))
  phys_city_col <- find_col(c("Physical City"))
  phys_state_col <- find_col(c("Physical State"))
  phys_zip_col <- find_col(c("Physical Zip"))
  mail_addr_col <- find_col(c("Mailing Address"))
  mail_city_col <- find_col(c("Mailing City"))
  mail_state_col <- find_col(c("Mailing State"))
  mail_zip_col <- find_col(c("Mailing Zip"))

  n_rows <- nrow(df)

  # Build result dataframe
  result <- data.frame(
    end_year = rep(end_year, n_rows),
    type = rep("School", n_rows),
    stringsAsFactors = FALSE
  )

  # County
  if (!is.null(county_col)) {
    result$county <- trimws(as.character(df[[county_col]]))
  } else {
    result$county <- NA_character_
  }

  # District ID - normalize format (remove dash)
  if (!is.null(dist_code_col)) {
    raw_code <- trimws(as.character(df[[dist_code_col]]))
    result$district_id <- gsub("-", "", raw_code)
  } else {
    result$district_id <- NA_character_
  }

  # School ID - combine district code and site code
  if (!is.null(dist_code_col) && !is.null(site_code_col)) {
    dist_code <- gsub("-", "", trimws(as.character(df[[dist_code_col]])))
    site_code <- trimws(as.character(df[[site_code_col]]))
    result$school_id <- paste0(dist_code, site_code)
  } else {
    result$school_id <- NA_character_
  }

  # District Name
  if (!is.null(dist_name_col)) {
    result$district_name <- trimws(as.character(df[[dist_name_col]]))
  } else {
    result$district_name <- NA_character_
  }

  # School Name
  if (!is.null(site_name_col)) {
    result$school_name <- trimws(as.character(df[[site_name_col]]))
  } else {
    result$school_name <- NA_character_
  }

  # Superintendent is NA for school rows
  result$superintendent_name <- NA_character_
  result$superintendent_email <- NA_character_

  # Principal
  if (!is.null(principal_col)) {
    result$principal_name <- trimws(as.character(df[[principal_col]]))
  } else {
    result$principal_name <- NA_character_
  }

  if (!is.null(principal_email_col)) {
    result$principal_email <- trimws(as.character(df[[principal_email_col]]))
  } else {
    result$principal_email <- NA_character_
  }

  # Board president is NA for school rows
  result$board_president <- NA_character_

  # Phone
  if (!is.null(phone_col)) {
    result$phone <- trimws(as.character(df[[phone_col]]))
  } else {
    result$phone <- NA_character_
  }

  # Fax and website are NA for school rows
  result$fax <- NA_character_
  result$website <- NA_character_

  # Physical address
  if (!is.null(phys_addr_col)) {
    result$physical_address <- trimws(as.character(df[[phys_addr_col]]))
  } else {
    result$physical_address <- NA_character_
  }

  if (!is.null(phys_city_col)) {
    result$physical_city <- trimws(as.character(df[[phys_city_col]]))
  } else {
    result$physical_city <- NA_character_
  }

  if (!is.null(phys_state_col)) {
    result$physical_state <- trimws(as.character(df[[phys_state_col]]))
  } else {
    result$physical_state <- NA_character_
  }

  if (!is.null(phys_zip_col)) {
    result$physical_zip <- trimws(as.character(df[[phys_zip_col]]))
  } else {
    result$physical_zip <- NA_character_
  }

  # Mailing address
  if (!is.null(mail_addr_col)) {
    result$mailing_address <- trimws(as.character(df[[mail_addr_col]]))
  } else {
    result$mailing_address <- NA_character_
  }

  if (!is.null(mail_city_col)) {
    result$mailing_city <- trimws(as.character(df[[mail_city_col]]))
  } else {
    result$mailing_city <- NA_character_
  }

  if (!is.null(mail_state_col)) {
    result$mailing_state <- trimws(as.character(df[[mail_state_col]]))
  } else {
    result$mailing_state <- NA_character_
  }

  if (!is.null(mail_zip_col)) {
    result$mailing_zip <- trimws(as.character(df[[mail_zip_col]]))
  } else {
    result$mailing_zip <- NA_character_
  }

  # Grades served
  if (!is.null(grades_col)) {
    result$grades_served <- trimws(as.character(df[[grades_col]]))
  } else {
    result$grades_served <- NA_character_
  }

  # Enrollment
  if (!is.null(enroll_col)) {
    result$enrollment <- as.integer(trimws(as.character(df[[enroll_col]])))
  } else {
    result$enrollment <- NA_integer_
  }

  result
}


#' Create empty directory data frame
#'
#' @param end_year School year end
#' @return Empty data frame with correct structure
#' @keywords internal
create_empty_directory_df <- function(end_year) {
  data.frame(
    end_year = integer(0),
    type = character(0),
    county = character(0),
    district_id = character(0),
    school_id = character(0),
    district_name = character(0),
    school_name = character(0),
    superintendent_name = character(0),
    superintendent_email = character(0),
    principal_name = character(0),
    principal_email = character(0),
    board_president = character(0),
    phone = character(0),
    fax = character(0),
    website = character(0),
    physical_address = character(0),
    physical_city = character(0),
    physical_state = character(0),
    physical_zip = character(0),
    mailing_address = character(0),
    mailing_city = character(0),
    mailing_state = character(0),
    mailing_zip = character(0),
    grades_served = character(0),
    enrollment = integer(0),
    stringsAsFactors = FALSE
  )
}
