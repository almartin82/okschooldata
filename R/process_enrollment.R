# ==============================================================================
# Enrollment Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw OSDE enrollment data into a
# clean, standardized format.
#
# Oklahoma ID System:
# - District ID: County code (2 digits) + District type (1 char) + District number (3 digits)
#   Example: 55I001 = Oklahoma County (55), Independent (I), District 001 (OKC Public Schools)
# - Site ID: District ID + Site number (3 digits)
#   Example: 55I001001 = Site 001 in Oklahoma City Public Schools
#
# ==============================================================================

#' Convert to numeric, handling suppression markers
#'
#' OSDE uses various markers for suppressed data (*, <, N/A, etc.)
#' and may use commas in large numbers.
#'
#' @param x Vector to convert
#' @return Numeric vector with NA for non-numeric values
#' @keywords internal
safe_numeric <- function(x) {
  # Handle NULL or empty input
  if (is.null(x) || length(x) == 0) {
    return(numeric(0))
  }

  # Convert to character if needed
  x <- as.character(x)

  # Remove commas and whitespace
  x <- gsub(",", "", x)
  x <- trimws(x)

  # Handle common suppression markers
  x[x %in% c("*", ".", "-", "-1", "<5", "<10", "N/A", "NA", "",
             "n/a", "n<5", "n<10", "suppressed", "SUPPRESSED",
             "--", "***")] <- NA_character_

  # Handle ranges like "<5" or ">1000"
  x[grepl("^[<>]", x)] <- NA_character_

  suppressWarnings(as.numeric(x))
}


#' Process raw OSDE enrollment data
#'
#' Transforms raw OSDE data into a standardized schema combining district
#' and site data.
#'
#' @param raw_data List containing district and site data frames from get_raw_enr
#' @param end_year School year end
#' @return Processed data frame with standardized columns
#' @keywords internal
process_enr <- function(raw_data, end_year) {

  # Process district data
  district_processed <- process_district_enr(raw_data$district, end_year)

  # Process site data (sites are equivalent to campuses in other states)
  site_processed <- process_site_enr(raw_data$site, end_year)

  # Create state aggregate from district data
  state_processed <- create_state_aggregate(district_processed, end_year)

  # Combine all levels
  result <- dplyr::bind_rows(state_processed, district_processed, site_processed)

  result
}


#' Process district-level enrollment data
#'
#' @param df Raw district data frame
#' @param end_year School year end
#' @return Processed district data frame
#' @keywords internal
process_district_enr <- function(df, end_year) {

  # Handle empty data frame
  if (is.null(df) || nrow(df) == 0) {
    return(create_empty_enrollment_df(end_year, "District"))
  }

  cols <- names(df)
  n_rows <- nrow(df)

  # Helper to find column by pattern (case-insensitive)
  find_col <- function(patterns) {
    for (pattern in patterns) {
      # Try exact match first (case-insensitive)
      matched <- grep(paste0("^", gsub("([.+*?^${}()|\\[\\]])", "\\\\\\1", pattern), "$"),
                      cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])

      # Try partial match
      matched <- grep(pattern, cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  col_map <- get_osde_column_map()

  # Build result dataframe with same number of rows as input
  result <- data.frame(
    end_year = rep(end_year, n_rows),
    type = rep("District", n_rows),
    stringsAsFactors = FALSE
  )

  # District ID
  district_col <- find_col(col_map$district_id)
  if (!is.null(district_col)) {
    result$district_id <- trimws(as.character(df[[district_col]]))
  } else {
    result$district_id <- NA_character_
  }

  # Campus/Site ID is NA for district rows
  result$campus_id <- rep(NA_character_, n_rows)

  # District Name
  district_name_col <- find_col(col_map$district_name)
  if (!is.null(district_name_col)) {
    result$district_name <- trimws(as.character(df[[district_name_col]]))
  } else {
    result$district_name <- NA_character_
  }

  result$campus_name <- rep(NA_character_, n_rows)

  # County
  county_col <- find_col(col_map$county_name)
  if (!is.null(county_col)) {
    result$county <- trimws(as.character(df[[county_col]]))
  }

  # Total enrollment
  total_col <- find_col(col_map$total)
  if (!is.null(total_col)) {
    result$row_total <- safe_numeric(df[[total_col]])
  }

  # Demographics - Race/Ethnicity
  demo_cols <- c("white", "black", "hispanic", "asian",
                 "native_american", "pacific_islander", "multiracial")

  for (demo in demo_cols) {
    col <- find_col(col_map[[demo]])
    if (!is.null(col)) {
      result[[demo]] <- safe_numeric(df[[col]])
    }
  }

  # Special populations
  special_cols <- c("econ_disadv", "lep", "special_ed")

  for (special in special_cols) {
    col <- find_col(col_map[[special]])
    if (!is.null(col)) {
      result[[special]] <- safe_numeric(df[[col]])
    }
  }

  # Grade levels
  grade_cols <- c("grade_pk", "grade_k",
                  "grade_01", "grade_02", "grade_03", "grade_04",
                  "grade_05", "grade_06", "grade_07", "grade_08",
                  "grade_09", "grade_10", "grade_11", "grade_12")

  for (grade in grade_cols) {
    col <- find_col(col_map[[grade]])
    if (!is.null(col)) {
      result[[grade]] <- safe_numeric(df[[col]])
    }
  }

  result
}


#' Process site-level enrollment data
#'
#' Sites in Oklahoma are equivalent to campuses/schools in other states.
#'
#' @param df Raw site data frame
#' @param end_year School year end
#' @return Processed site data frame
#' @keywords internal
process_site_enr <- function(df, end_year) {

  # Handle empty data frame
  if (is.null(df) || nrow(df) == 0) {
    return(create_empty_enrollment_df(end_year, "Campus"))
  }

  cols <- names(df)
  n_rows <- nrow(df)

  # Helper to find column by pattern (case-insensitive)
  find_col <- function(patterns) {
    for (pattern in patterns) {
      # Try exact match first (case-insensitive)
      matched <- grep(paste0("^", gsub("([.+*?^${}()|\\[\\]])", "\\\\\\1", pattern), "$"),
                      cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])

      # Try partial match
      matched <- grep(pattern, cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  col_map <- get_osde_column_map()

  # Build result dataframe
  result <- data.frame(
    end_year = rep(end_year, n_rows),
    type = rep("Campus", n_rows),  # Use "Campus" for consistency with other packages
    stringsAsFactors = FALSE
  )

  # Site/Campus ID
  site_col <- find_col(col_map$site_id)
  if (!is.null(site_col)) {
    result$campus_id <- trimws(as.character(df[[site_col]]))
    # Extract district ID from site ID (first 6 characters)
    result$district_id <- substr(result$campus_id, 1, 6)
  } else {
    result$campus_id <- NA_character_
    # Try to get district ID directly
    district_col <- find_col(col_map$district_id)
    if (!is.null(district_col)) {
      result$district_id <- trimws(as.character(df[[district_col]]))
    } else {
      result$district_id <- NA_character_
    }
  }

  # Site/Campus Name
  site_name_col <- find_col(col_map$site_name)
  if (!is.null(site_name_col)) {
    result$campus_name <- trimws(as.character(df[[site_name_col]]))
  } else {
    result$campus_name <- NA_character_
  }

  # District Name
  district_name_col <- find_col(col_map$district_name)
  if (!is.null(district_name_col)) {
    result$district_name <- trimws(as.character(df[[district_name_col]]))
  } else {
    result$district_name <- NA_character_
  }

  # County
  county_col <- find_col(col_map$county_name)
  if (!is.null(county_col)) {
    result$county <- trimws(as.character(df[[county_col]]))
  }

  # Total enrollment
  total_col <- find_col(col_map$total)
  if (!is.null(total_col)) {
    result$row_total <- safe_numeric(df[[total_col]])
  }

  # Demographics - Race/Ethnicity
  demo_cols <- c("white", "black", "hispanic", "asian",
                 "native_american", "pacific_islander", "multiracial")

  for (demo in demo_cols) {
    col <- find_col(col_map[[demo]])
    if (!is.null(col)) {
      result[[demo]] <- safe_numeric(df[[col]])
    }
  }

  # Special populations
  special_cols <- c("econ_disadv", "lep", "special_ed")

  for (special in special_cols) {
    col <- find_col(col_map[[special]])
    if (!is.null(col)) {
      result[[special]] <- safe_numeric(df[[col]])
    }
  }

  # Grade levels
  grade_cols <- c("grade_pk", "grade_k",
                  "grade_01", "grade_02", "grade_03", "grade_04",
                  "grade_05", "grade_06", "grade_07", "grade_08",
                  "grade_09", "grade_10", "grade_11", "grade_12")

  for (grade in grade_cols) {
    col <- find_col(col_map[[grade]])
    if (!is.null(col)) {
      result[[grade]] <- safe_numeric(df[[col]])
    }
  }

  result
}


#' Create state-level aggregate from district data
#'
#' @param district_df Processed district data frame
#' @param end_year School year end
#' @return Single-row data frame with state totals
#' @keywords internal
create_state_aggregate <- function(district_df, end_year) {

  # Columns to sum
  sum_cols <- c(
    "row_total",
    "white", "black", "hispanic", "asian",
    "pacific_islander", "native_american", "multiracial",
    "econ_disadv", "lep", "special_ed",
    "grade_pk", "grade_k",
    "grade_01", "grade_02", "grade_03", "grade_04",
    "grade_05", "grade_06", "grade_07", "grade_08",
    "grade_09", "grade_10", "grade_11", "grade_12"
  )

  # Filter to columns that exist
  sum_cols <- sum_cols[sum_cols %in% names(district_df)]

  # Create state row
  state_row <- data.frame(
    end_year = end_year,
    type = "State",
    district_id = NA_character_,
    campus_id = NA_character_,
    district_name = NA_character_,
    campus_name = NA_character_,
    county = NA_character_,
    stringsAsFactors = FALSE
  )

  # Sum each column
  for (col in sum_cols) {
    if (col %in% names(district_df)) {
      state_row[[col]] <- sum(district_df[[col]], na.rm = TRUE)
    }
  }

  state_row
}


#' Create empty enrollment data frame
#'
#' @param end_year School year end
#' @param type Row type ("State", "District", or "Campus")
#' @return Empty data frame with correct structure
#' @keywords internal
create_empty_enrollment_df <- function(end_year, type) {
  data.frame(
    end_year = integer(0),
    type = character(0),
    district_id = character(0),
    campus_id = character(0),
    district_name = character(0),
    campus_name = character(0),
    county = character(0),
    row_total = integer(0),
    stringsAsFactors = FALSE
  )
}
