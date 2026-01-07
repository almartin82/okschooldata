# ==============================================================================
# Utility Functions
# ==============================================================================

#' @importFrom rlang .data
#' @importFrom stats complete.cases
NULL


#' Get available years for Oklahoma enrollment data
#'
#' Returns metadata about the range of school years for which enrollment data
#' is available from the Oklahoma State Department of Education.
#'
#' @return A list with components:
#'   \describe{
#'     \item{min_year}{Earliest available school year end (2016)}
#'     \item{max_year}{Latest available school year end (2024)}
#'     \item{description}{Human-readable description of the data availability}
#'   }
#' @export
#' @examples
#' years <- get_available_years()
#' years$min_year
#' years$max_year
#' years$description
get_available_years <- function() {
  list(
    min_year = 2016L,
    max_year = 2025L,
    description = "Oklahoma enrollment data from OSDE is available for school years 2015-16 through 2024-25 (end years 2016-2025)"
  )
}
