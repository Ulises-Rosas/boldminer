#' getfmt
#'
#' @param spps species vector
#'
#' @return format for print out messages in AuditionBarcode fun
#'
getfmt <- function(spps){

  ml = max(sapply(spps, nchar))

  fmt = paste0("%", ml + 6,"s")

  return(fmt)
}
