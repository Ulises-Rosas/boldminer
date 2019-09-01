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
# if (getRversion() >= "2.15.1") {
#   utils::globalVariables(names = c(".", "processid", "bin_uri", "species_name", "institution_storing", "species_taxID", ".N",".SD","ID", "similarity", "taxonomicidentification"))
# }
