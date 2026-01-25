# ==============================================================================
# Assessment Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing and standardizing raw assessment
# data from OSDE into a consistent schema.
#
# ==============================================================================


#' Process raw OSTP assessment data
#'
#' Cleans and standardizes raw assessment data from OSDE into a consistent
#' schema across all years.
#'
#' @param raw_df Raw data frame from get_raw_assessment()
#' @param end_year School year end
#' @return Processed data frame with standardized columns
#' @keywords internal
process_assessment <- function(raw_df, end_year) {

  if (nrow(raw_df) == 0) {
    return(create_empty_assessment())
  }

  # Standardize column names
  df <- standardize_assessment_columns(raw_df, end_year)

  # Parse numeric columns
  df <- parse_assessment_numerics(df)

  # Add derived columns
  df <- add_assessment_derived_cols(df, end_year)

  # Reorder columns to standard order
  df <- order_assessment_columns(df)

  df
}


#' Standardize assessment column names
#'
#' Maps various column name formats across years to standard names.
#'
#' @param df Data frame with raw column names
#' @param end_year School year end
#' @return Data frame with standardized column names
#' @keywords internal
standardize_assessment_columns <- function(df, end_year) {

  # Clean column names - replace spaces and special chars
  orig_names <- names(df)
  clean_names <- tolower(orig_names)
  clean_names <- gsub("\\s+", "_", clean_names)
  clean_names <- gsub("[^a-z0-9_]", "_", clean_names)
  clean_names <- gsub("_+", "_", clean_names)
  clean_names <- gsub("^_|_$", "", clean_names)

  names(df) <- clean_names

  # Map to standard names
  name_map <- list(
    # Core identifiers
    grade = c("grade"),
    county_name = c("countyname", "county_name", "county"),
    organization_id = c("organizationid", "organization_id", "org_id", "id"),
    group_name = c("group", "group_name", "organization", "name"),
    administration = c("administration", "admin_year", "year"),

    # ELA columns
    ela_total_n = c("ela_total_n", "ela___total_n"),
    ela_valid_n = c("ela_valid_n", "ela___valid_n"),
    ela_mean_opi = c("ela_mean_opi", "ela___mean_opi"),
    ela_below_basic_n = c("ela_below_basic_no", "ela___below_basic_no"),
    ela_below_basic_pct = c("ela_below_basic", "ela___below_basic"),
    ela_basic_n = c("ela_basic_no", "ela___basic_no"),
    ela_basic_pct = c("ela_basic", "ela___basic"),
    ela_proficient_n = c("ela_proficient_no", "ela___proficient_no"),
    ela_proficient_pct = c("ela_proficient", "ela___proficient"),
    ela_advanced_n = c("ela_advanced_no", "ela___advanced_no"),
    ela_advanced_pct = c("ela_advanced", "ela___advanced"),

    # Math columns
    math_total_n = c("mathematics_total_n", "mathematics___total_n", "math_total_n"),
    math_valid_n = c("mathematics_valid_n", "mathematics___valid_n", "math_valid_n"),
    math_mean_opi = c("mathematics_mean_opi", "mathematics___mean_opi", "math_mean_opi"),
    math_below_basic_n = c("mathematics_below_basic_no", "mathematics___below_basic_no"),
    math_below_basic_pct = c("mathematics_below_basic", "mathematics___below_basic"),
    math_basic_n = c("mathematics_basic_no", "mathematics___basic_no"),
    math_basic_pct = c("mathematics_basic", "mathematics___basic"),
    math_proficient_n = c("mathematics_proficient_no", "mathematics___proficient_no"),
    math_proficient_pct = c("mathematics_proficient", "mathematics___proficient"),
    math_advanced_n = c("mathematics_advanced_no", "mathematics___advanced_no"),
    math_advanced_pct = c("mathematics_advanced", "mathematics___advanced"),

    # Science columns
    science_total_n = c("science_total_n", "science___total_n"),
    science_valid_n = c("science_valid_n", "science___valid_n"),
    science_mean_opi = c("science_mean_opi", "science___mean_opi"),
    science_below_basic_n = c("science_below_basic_no", "science___below_basic_no"),
    science_below_basic_pct = c("science_below_basic", "science___below_basic"),
    science_basic_n = c("science_basic_no", "science___basic_no"),
    science_basic_pct = c("science_basic", "science___basic"),
    science_proficient_n = c("science_proficient_no", "science___proficient_no"),
    science_proficient_pct = c("science_proficient", "science___proficient"),
    science_advanced_n = c("science_advanced_no", "science___advanced_no"),
    science_advanced_pct = c("science_advanced", "science___advanced")
  )

  # Apply mapping
  current_names <- names(df)
  new_names <- current_names

  for (std_name in names(name_map)) {
    matches <- name_map[[std_name]]
    for (i in seq_along(current_names)) {
      if (current_names[i] %in% matches) {
        new_names[i] <- std_name
        break
      }
    }
  }

  names(df) <- new_names

  df
}


#' Parse numeric columns in assessment data
#'
#' Converts string columns to appropriate numeric types, handling suppression
#' markers like "***" and "N/A".
#'
#' @param df Data frame with standardized column names
#' @return Data frame with parsed numeric columns
#' @keywords internal
parse_assessment_numerics <- function(df) {

  # Columns that should be numeric
  numeric_cols <- c(
    "grade",
    "ela_total_n", "ela_valid_n", "ela_mean_opi",
    "ela_below_basic_n", "ela_below_basic_pct",
    "ela_basic_n", "ela_basic_pct",
    "ela_proficient_n", "ela_proficient_pct",
    "ela_advanced_n", "ela_advanced_pct",
    "math_total_n", "math_valid_n", "math_mean_opi",
    "math_below_basic_n", "math_below_basic_pct",
    "math_basic_n", "math_basic_pct",
    "math_proficient_n", "math_proficient_pct",
    "math_advanced_n", "math_advanced_pct",
    "science_total_n", "science_valid_n", "science_mean_opi",
    "science_below_basic_n", "science_below_basic_pct",
    "science_basic_n", "science_basic_pct",
    "science_proficient_n", "science_proficient_pct",
    "science_advanced_n", "science_advanced_pct",
    "end_year"
  )

  for (col in numeric_cols) {
    if (col %in% names(df)) {
      # Replace suppression markers with NA
      df[[col]] <- gsub("^\\*+$", NA, df[[col]])
      df[[col]] <- gsub("^N/A$", NA, df[[col]], ignore.case = TRUE)
      df[[col]] <- gsub("^-$", NA, df[[col]])
      df[[col]] <- gsub("^$", NA, df[[col]])

      # Convert to numeric
      df[[col]] <- suppressWarnings(as.numeric(df[[col]]))
    }
  }

  df
}


#' Add derived columns to assessment data
#'
#' Adds aggregation flags and other derived columns.
#'
#' @param df Data frame with standardized columns
#' @param end_year School year end
#' @return Data frame with derived columns
#' @keywords internal
add_assessment_derived_cols <- function(df, end_year) {

  # Ensure end_year column exists
  if (!"end_year" %in% names(df)) {
    df$end_year <- end_year
  }

  # Add aggregation flag based on organization_id
  if ("organization_id" %in% names(df)) {
    df$aggregation_level <- dplyr::case_when(
      df$organization_id == "0" ~ "state",
      nchar(df$organization_id) <= 6 ~ "district",
      TRUE ~ "school"
    )

    # Add convenience flag columns
    df$is_state <- df$aggregation_level == "state"
    df$is_district <- df$aggregation_level == "district"
    df$is_school <- df$aggregation_level == "school"
  }

  # Extract district_id from organization_id (first 6 chars for schools)
  if ("organization_id" %in% names(df)) {
    df$district_id <- dplyr::case_when(
      df$aggregation_level == "state" ~ NA_character_,
      df$aggregation_level == "district" ~ df$organization_id,
      TRUE ~ substr(df$organization_id, 1, 6)
    )

    df$school_id <- dplyr::case_when(
      df$aggregation_level == "school" ~ df$organization_id,
      TRUE ~ NA_character_
    )
  }

  # Calculate proficiency rate (proficient + advanced)
  if (all(c("ela_proficient_pct", "ela_advanced_pct") %in% names(df))) {
    df$ela_proficient_plus_pct <- df$ela_proficient_pct + df$ela_advanced_pct
  }

  if (all(c("math_proficient_pct", "math_advanced_pct") %in% names(df))) {
    df$math_proficient_plus_pct <- df$math_proficient_pct + df$math_advanced_pct
  }

  if (all(c("science_proficient_pct", "science_advanced_pct") %in% names(df))) {
    df$science_proficient_plus_pct <- df$science_proficient_pct + df$science_advanced_pct
  }

  df
}


#' Order assessment columns to standard order
#'
#' @param df Data frame to reorder
#' @return Data frame with columns in standard order
#' @keywords internal
order_assessment_columns <- function(df) {

  # Define preferred column order
  preferred_order <- c(
    "end_year",
    "grade",
    "aggregation_level",
    "is_state", "is_district", "is_school",
    "organization_id", "district_id", "school_id",
    "county_name", "group_name",
    # ELA
    "ela_total_n", "ela_valid_n", "ela_mean_opi",
    "ela_below_basic_n", "ela_below_basic_pct",
    "ela_basic_n", "ela_basic_pct",
    "ela_proficient_n", "ela_proficient_pct",
    "ela_advanced_n", "ela_advanced_pct",
    "ela_proficient_plus_pct",
    # Math
    "math_total_n", "math_valid_n", "math_mean_opi",
    "math_below_basic_n", "math_below_basic_pct",
    "math_basic_n", "math_basic_pct",
    "math_proficient_n", "math_proficient_pct",
    "math_advanced_n", "math_advanced_pct",
    "math_proficient_plus_pct",
    # Science
    "science_total_n", "science_valid_n", "science_mean_opi",
    "science_below_basic_n", "science_below_basic_pct",
    "science_basic_n", "science_basic_pct",
    "science_proficient_n", "science_proficient_pct",
    "science_advanced_n", "science_advanced_pct",
    "science_proficient_plus_pct"
  )

  # Get columns that exist in df
  existing_preferred <- preferred_order[preferred_order %in% names(df)]
  other_cols <- setdiff(names(df), existing_preferred)

  # Combine preferred order first, then other columns
  df[, c(existing_preferred, other_cols)]
}


#' Create empty assessment data frame
#'
#' Returns an empty data frame with the expected assessment schema.
#'
#' @return Empty data frame with assessment columns
#' @keywords internal
create_empty_assessment <- function() {
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
    ela_valid_n = integer(0),
    ela_proficient_pct = numeric(0),
    ela_advanced_pct = numeric(0),
    math_valid_n = integer(0),
    math_proficient_pct = numeric(0),
    math_advanced_pct = numeric(0),
    stringsAsFactors = FALSE
  )
}
