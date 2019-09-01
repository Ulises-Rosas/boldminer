#' \code{boldminer} package
#'
#'
#' Wrapper for BOLD API and DNA barcode auditing
#'
#' @docType package
#' @name boldminer

NULL

## quiets concerns of R CMD check re: the .'s that appear in pipelines
## The way global variables are defined for passing checkings was taken from here:
## https://github.com/jennybc/googlesheets/blob/master/R/googlesheets.R
if (getRversion() >= "2.15.1") {
  utils::globalVariables(names = c(".",".N",".SD",
                                   "bin_uri", "institution_storing",
                                   "processid", "species_name", "species_taxID"))

}
