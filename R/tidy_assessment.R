# ==============================================================================
# Tidy Assessment Data Functions
# ==============================================================================
#
# This file contains functions for converting wide-format assessment data
# to tidy (long) format.
#
# ==============================================================================


#' Convert assessment data to tidy format
#'
#' Transforms wide-format assessment data (with separate columns for each
#' subject and proficiency level) into a tidy long format with one row
#' per organization/grade/subject/proficiency level combination.
#'
#' @param df Wide-format data frame from process_assessment()
#' @return Tidy data frame with columns: end_year, grade, aggregation_level,
#'   is_state, is_district, is_school, organization_id, district_id, school_id,
#'   county_name, group_name, subject, valid_n, proficiency_level, n_students, pct
#' @keywords internal
tidy_assessment <- function(df) {

  if (nrow(df) == 0) {
    return(create_empty_tidy_assessment())
  }

  # Extract identifier columns
  id_cols <- c(
    "end_year", "grade", "aggregation_level",
    "is_state", "is_district", "is_school",
    "organization_id", "district_id", "school_id",
    "county_name", "group_name"
  )

  # Keep only columns that exist
  id_cols <- id_cols[id_cols %in% names(df)]

  # Create tidy data for each subject
  tidy_ela <- tidy_subject(df, id_cols, "ela", "ELA")
  tidy_math <- tidy_subject(df, id_cols, "math", "Math")
  tidy_science <- tidy_subject(df, id_cols, "science", "Science")

  # Combine all subjects
  tidy_df <- dplyr::bind_rows(tidy_ela, tidy_math, tidy_science)

  # Remove rows with all NA proficiency data
  tidy_df <- tidy_df[!is.na(tidy_df$valid_n) | !is.na(tidy_df$pct), ]

  tidy_df
}


#' Tidy a single subject's data
#'
#' @param df Wide-format data frame
#' @param id_cols Vector of identifier column names
#' @param prefix Column prefix (e.g., "ela", "math", "science")
#' @param subject_name Human-readable subject name
#' @return Tidy data frame for one subject
#' @keywords internal
tidy_subject <- function(df, id_cols, prefix, subject_name) {

  # Check if this subject has data
  valid_n_col <- paste0(prefix, "_valid_n")
  if (!valid_n_col %in% names(df)) {
    return(data.frame())
  }

  # Define proficiency levels and their column suffixes
  proficiency_levels <- c(
    "below_basic" = "Below Basic",
    "basic" = "Basic",
    "proficient" = "Proficient",
    "advanced" = "Advanced"
  )

  # Build tidy data
  tidy_list <- list()

  for (level_suffix in names(proficiency_levels)) {
    n_col <- paste0(prefix, "_", level_suffix, "_n")
    pct_col <- paste0(prefix, "_", level_suffix, "_pct")

    # Skip if columns don't exist
    if (!n_col %in% names(df) && !pct_col %in% names(df)) {
      next
    }

    level_df <- df[, id_cols, drop = FALSE]
    level_df$subject <- subject_name
    level_df$valid_n <- if (valid_n_col %in% names(df)) df[[valid_n_col]] else NA_integer_
    level_df$proficiency_level <- proficiency_levels[level_suffix]
    level_df$n_students <- if (n_col %in% names(df)) df[[n_col]] else NA_integer_
    level_df$pct <- if (pct_col %in% names(df)) df[[pct_col]] else NA_real_

    tidy_list[[level_suffix]] <- level_df
  }

  if (length(tidy_list) == 0) {
    return(data.frame())
  }

  dplyr::bind_rows(tidy_list)
}


#' Create empty tidy assessment data frame
#'
#' Returns an empty data frame with the expected tidy assessment schema.
#'
#' @return Empty data frame with tidy assessment columns
#' @keywords internal
create_empty_tidy_assessment <- function() {
  data.frame(
    end_year = integer(0),
    grade = integer(0),
    aggregation_level = character(0),
    is_state = logical(0),
    is_district = logical(0),
    is_school = logical(0),
    organization_id = character(0),
    district_id = character(0),
    school_id = character(0),
    county_name = character(0),
    group_name = character(0),
    subject = character(0),
    valid_n = integer(0),
    proficiency_level = character(0),
    n_students = integer(0),
    pct = numeric(0),
    stringsAsFactors = FALSE
  )
}
