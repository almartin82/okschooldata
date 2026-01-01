#' okschooldata: Fetch and Process Oklahoma School Data
#'
#' Downloads and processes school data from the Oklahoma State Department of
#' Education (OSDE). Provides functions for fetching enrollment data from
#' OSDE's public reporting systems and transforming it into tidy format for
#' analysis.
#'
#' @section Main functions:
#' \describe{
#'   \item{\code{\link{fetch_enr}}}{Fetch enrollment data for a school year}
#'   \item{\code{\link{fetch_enr_multi}}}{Fetch enrollment data for multiple years}
#'   \item{\code{\link{get_available_years}}}{Get list of available data years}
#'   \item{\code{\link{tidy_enr}}}{Transform wide data to tidy (long) format}
#'   \item{\code{\link{id_enr_aggs}}}{Add aggregation level flags}
#'   \item{\code{\link{enr_grade_aggs}}}{Create grade-level aggregations}
#' }
#'
#' @section Cache functions:
#' \describe{
#'   \item{\code{\link{cache_status}}}{View cached data files}
#'   \item{\code{\link{clear_cache}}}{Remove cached data files}
#' }
#'
#' @section ID System:
#' Oklahoma uses an alphanumeric ID system:
#' \itemize{
#'   \item District IDs: County code (2 digits) + Type (1 letter) + Number (3 digits)
#'   \item Site IDs: District ID + Site number (3 digits)
#'   \item Example: 55I001 = Oklahoma County (55), Independent (I), District 001 (OKC Public Schools)
#'   \item Example: 55I001001 = Site 001 in Oklahoma City Public Schools
#' }
#'
#' @section District Types:
#' \itemize{
#'   \item I = Independent school district
#'   \item D = Dependent school district
#'   \item C = City school district
#'   \item E = Elementary school district
#' }
#'
#' @section Data Sources:
#' Data is sourced from the Oklahoma State Department of Education:
#' \itemize{
#'   \item OSDE Public Records: \url{https://sde.ok.gov/reporting-index}
#'   \item State Public Enrollment: \url{https://sde.ok.gov/documents/state-student-public-enrollment}
#'   \item OklaSchools.com: \url{https://oklaschools.com/}
#' }
#'
#' @docType package
#' @name okschooldata-package
#' @aliases okschooldata
#' @keywords internal
"_PACKAGE"

