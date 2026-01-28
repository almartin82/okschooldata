# ==============================================================================
# Raw Assessment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw assessment data from the
# Oklahoma State Department of Education (OSDE).
#
# Data Sources:
# - Oklahoma.gov State Testing Resources
#   https://oklahoma.gov/education/services/assessments/state-testing-resources.html
#
# Assessment Systems:
# - OSTP (Oklahoma School Testing Program): 2017-present, Grades 3-8
# - CCRA (College and Career Readiness Assessment): Grade 11
# - Note: 2020 had no testing due to COVID-19 pandemic
# - Note: 2021 had limited testing and data is not publicly available
#
# ==============================================================================


#' Get assessment URL for a given year
#'
#' Constructs the URL for downloading OSTP assessment data from Oklahoma DOE.
#' URLs vary by year with different file naming conventions.
#'
#' @param end_year School year end (e.g., 2024 for 2023-24 school year)
#' @return URL string or NULL if year not available
#' @keywords internal
get_assessment_url <- function(end_year) {

  base_url <- "https://oklahoma.gov/content/dam/ok/en/osde/documents/services/assessments/state-testing-resources"

  # URL patterns by year (verified January 2026)
  # Note: 2020 and 2021 have no public data (COVID-19)
  url_patterns <- list(
    "2025" = paste0(base_url, "/2025-state-testing-resources/2425OKOSTPMediaRedacted.csv"),
    "2024" = paste0(base_url, "/2023-2024-Grade3-8%20OKOSTPMediaRedacted.xlsx"),
    "2023" = paste0(base_url, "/2022-23-OKOSTP-Grade3-8-MediaRedacted.xlsx"),
    "2022" = paste0(base_url, "/2021-2022-OKMediaRedacted.xlsx"),
    "2019" = paste0(base_url, "/2018-19-OSTP-Grade3-8-SummaryRedactedReport.xlsx")
  )

  year_key <- as.character(end_year)

  if (year_key %in% names(url_patterns)) {
    return(url_patterns[[year_key]])
  }

  # For 2017-2018, data is split by grade level
  # Return NULL to trigger grade-by-grade download
  if (end_year %in% c(2017, 2018)) {
    return(NULL)
  }

  NULL
}


#' Get assessment URLs by grade for historical years
#'
#' Returns URLs for grade-specific assessment files for 2017-2018.
#' These years have separate files per grade level.
#'
#' @param end_year School year end (2017 or 2018)
#' @return Named list of URLs by grade
#' @keywords internal
get_assessment_urls_by_grade <- function(end_year) {

  base_url <- "https://oklahoma.gov/content/dam/ok/en/osde/documents/services/assessments/state-testing-resources"

  grades <- c("3", "4", "5", "6", "7", "8")

  if (end_year == 2018) {
    # 2018 format: G{grade}-OSTP-2018-Redacted.xlsx
    urls <- setNames(
      paste0(base_url, "/G", grades, "-OSTP-2018-Redacted.xlsx"),
      paste0("grade_", grades)
    )
    return(urls)
  }

  if (end_year == 2017) {
    # 2017 format: Grade-{grade}-OSTP-2017-Redacted.xlsx
    urls <- setNames(
      paste0(base_url, "/Grade-", grades, "-OSTP-2017-Redacted.xlsx"),
      paste0("grade_", grades)
    )
    return(urls)
  }

  NULL
}


#' Download raw assessment data from OSDE
#'
#' Downloads OSTP assessment data from the Oklahoma State Department of
#' Education's public data files.
#'
#' @param end_year School year end (2017-2019, 2022-2025; no 2020-2021 due to COVID)
#' @return Data frame with raw assessment data
#' @keywords internal
get_raw_assessment <- function(end_year) {

  # Validate year
  available <- get_available_assessment_years()

  if (end_year %in% c(2020, 2021)) {
    stop(paste0(
      "Assessment data is not available for ", end_year, " due to COVID-19. ",
      "2020 had no testing; 2021 data is not publicly available."
    ))
  }

  if (!end_year %in% available$years) {
    stop(paste0(
      "end_year must be one of: ", paste(available$years, collapse = ", "),
      "\nGot: ", end_year
    ))
  }

  message(paste("Downloading OSDE assessment data for", end_year, "..."))

  # Check if year has combined file or grade-level files
  url <- get_assessment_url(end_year)

  if (!is.null(url)) {
    # Download combined file
    df <- download_assessment_file(url, end_year)
  } else {
    # Download grade-by-grade files (2017-2018)
    df <- download_assessment_by_grade(end_year)
  }

  # Add end_year column
  if (!"end_year" %in% names(df)) {
    df$end_year <- end_year
  }

  df
}


#' Download a single assessment file
#'
#' @param url URL to download
#' @param end_year School year end (for error messages)
#' @return Data frame with assessment data
#' @keywords internal
download_assessment_file <- function(url, end_year) {

  message(paste("  Downloading from:", basename(url)))

  # Determine file type
  is_csv <- grepl("\\.csv$", url, ignore.case = TRUE)
  file_ext <- if (is_csv) ".csv" else ".xlsx"

  # Create temp file
  tname <- tempfile(
    pattern = paste0("ok_ostp_", end_year, "_"),
    tmpdir = tempdir(),
    fileext = file_ext
  )

  result <- tryCatch({
    # Download with httr
    response <- httr::GET(
      url,
      httr::write_disk(tname, overwrite = TRUE),
      httr::timeout(180),
      httr::user_agent("okschooldata R package")
    )

    if (httr::http_error(response)) {
      stop(paste("HTTP error:", httr::status_code(response)))
    }

    # Check file size
    file_info <- file.info(tname)
    if (is.na(file_info$size) || file_info$size < 1000) {
      stop("Downloaded file is too small or missing")
    }

    # Read file based on type
    if (is_csv) {
      df <- readr::read_csv(tname, col_types = readr::cols(.default = "c"), show_col_types = FALSE)
    } else {
      df <- readxl::read_excel(tname, col_types = "text")
    }

    unlink(tname)

    if (nrow(df) == 0) {
      stop("Downloaded file contains no data")
    }

    df

  }, error = function(e) {
    unlink(tname)
    stop(paste("Failed to download assessment data for year", end_year,
               "\nError:", e$message,
               "\nURL:", url))
  })

  result
}


#' Download assessment data by grade
#'
#' Downloads grade-level assessment files for 2017-2018 and combines them.
#'
#' @param end_year School year end (2017 or 2018)
#' @return Combined data frame with all grades
#' @keywords internal
download_assessment_by_grade <- function(end_year) {

  urls <- get_assessment_urls_by_grade(end_year)

  if (is.null(urls)) {
    stop(paste("No grade-level URLs defined for year", end_year))
  }

  all_data <- list()

  for (grade_name in names(urls)) {
    url <- urls[[grade_name]]
    grade_num <- gsub("grade_", "", grade_name)

    message(paste("  Downloading grade", grade_num, "..."))

    tryCatch({
      df <- download_assessment_file(url, end_year)

      # Add Grade column if not present
      if (!"Grade" %in% names(df)) {
        df$Grade <- grade_num
      }

      all_data[[grade_name]] <- df
    }, error = function(e) {
      warning(paste("Failed to download grade", grade_num, ":", e$message))
    })
  }

  if (length(all_data) == 0) {
    stop(paste("Failed to download any grade-level data for year", end_year))
  }

  # Combine all grades
  dplyr::bind_rows(all_data)
}


#' Get available assessment years
#'
#' Returns the years for which OSTP assessment data is publicly available.
#'
#' @return A list with components:
#'   \describe{
#'     \item{years}{Vector of available school year ends}
#'     \item{note}{Note about data gaps}
#'   }
#' @export
#' @examples
#' get_available_assessment_years()
get_available_assessment_years <- function() {
  list(
    years = c(2017L, 2018L, 2019L, 2022L, 2023L, 2024L, 2025L),
    note = "2020 and 2021 have no public data due to COVID-19 pandemic."
  )
}
