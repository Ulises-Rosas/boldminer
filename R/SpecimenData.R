#' SpecimenData
#'
#' This function let us mine associated metadata
#' from any specimen according to query arguments.
#' It takes very specific queries and
#' use them as headers for BOLD API host
#' for downloading metadata. More than one query
#' can be specified by using "|".
#'
#' @param taxon Species or taxa to look for
#' @param ids IDs from specimen records. e.g. ANGBF12704-15
#' @param bin barcode-based cluster ID. e.g. BOLD:AAA4689
#' @param container container name. e.g. FIPP
#' @param institutions institution names. e.g. Smithsonian Institution
#' @param researchers names of identifiers or specimen collectors
#' @param geo name of geographical area to look for.
#' @param ... others query name or column name that can be present in metadata
#'
#' @return metadata information
#' @export
#'
#' @examples
#' specimendata <- SpecimenData(taxon = "Elasmobranchii", geo = "Peru")
#' head(specimendata)


SpecimenData <- function(taxon, ids, bin, container, institutions, researchers, geo, ...){

  input <- data.frame(
    names = names(as.list(environment())),
    args  = sapply(as.list(environment()), paste),
    stringsAsFactors = F)

  #text <- RCurl::getURL(
  URLtxt <- paste(if(list(...)[1] == "only"){
    "http://www.boldsystems.org/index.php/API_Public/sequence?"}
    else{if(list(...)[1] == "combined"){
      "http://www.boldsystems.org/index.php/API_Public/combined?"}
      else{
        "http://www.boldsystems.org/index.php/API_Public/specimen?"}
    },
    paste(
      paste(input[!(input$args == ""),]$names,
            "=",
            sapply(input[!(input$args == ""),]$args, function(x){
              if(length(strsplit(x, " ")[[1]]) > 1){
                paste(gsub(" ", "%20", x), "&", sep = "")
              }else{paste(x, "&", sep = "")}}
            ),
            sep = ""),
      collapse = ""),
    "format=tsv",
    sep = "")

  text <- RCurl::getURL(URLtxt)

  if(text == "")
    return(NULL)

  if(list(...)[1] == "only")
    return(ape::read.FASTA(textConnection(text)))

  df = data.table::fread(text, quote = "", stringsAsFactors = T)

  if( !nrow(df) )
    return(NULL)

  return(df)
}
