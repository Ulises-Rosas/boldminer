#' taxamatch
#'
#' @param spps species name
#'
#' @return species name validation by using WoRMS Rest service
#'
taxamatch <- function(spps){
  ## for testing
  # spps = "Alopias pelagicus"
  ## for testing
  tolower(
    gsub(" ", "%20",
         gsub("[ ]{2,}", " ",
              gsub("\\(.+\\)", "",spps )))) -> spps

  taxHost   = "http://www.marinespecies.org/rest/AphiaRecordsByMatchNames?scientificnames%5B%5D="
  taxHeader = paste0( spps, "&marine_only=false" )

  page  = RCurl::getURL(paste0(taxHost, taxHeader))

  val = gsub('.*,"valid_AphiaID":.*,"valid_name":"(.*)","valid_authority":.*', "\\1", page)

  return(val)
}
