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
#' specimendata <- boldminer::SpecimenData(taxon = "Elasmobranchii", geo = "Peru")
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

#' sumSData
#'
#' short utility to summarize data frame
#'
#' @param df specimen data from \code{\link{SpecimenData}} function
#' @param cols columns to summarize on
#'
#' @return summarized data frame
#' @export
#'
#' @examples
#' \dontrun{
#' specimendata <- boldminer::SpecimenData(taxon = "Elasmobranchii", geo = "Peru")
#' boldminer::sumSData(df = specimendata, cols = c("species_name", "country"))
#' }
sumSData <- function(df, cols){
  # cols = c("species_name","country", "bin_uril" )
  # df = specimendata

  colEval = cols[cols %in% colnames(df)]

  if( !length(colEval) ){

    warning("Any input column found in specimen data")
    return(NULL)

  }else if( length(colEval) != length(cols) ){

    msg    = "Following input column not found in specimen data: "
    notCol = cols[!cols %in% colEval]

    warning( paste0(msg, paste(notCol, collapse = ", ")) )
  }

  df[,
     j = list(n = .N),
     by = colEval
     ][
       i = order(-n),
       ] -> out

  return(out)
}

#' leafletPlot
#'
#' Interactive map of barcodes, when geographic information is available
#'
#' @param df specimen data from \code{\link{SpecimenData}} function
#' @param col column used as label
#'
#' @return leaflet map
#' @export
#' @importFrom data.table .SD
#' @importFrom magrittr %>%
#' @importFrom stats complete.cases
#' @importFrom leaflet leaflet addProviderTiles fitBounds addCircleMarkers providerTileOptions
#' @examples
#' \dontrun{
#' specimendata <- boldminer::SpecimenData(taxon = "Elasmobranchii", geo = "Peru")
#' boldminer::leafletPlot(df = specimendata, col = "species_name")
#' }

leafletPlot <- function(df, col = "species_name"){
  # df = specimendata
  # col = "species_name"

  sumSData(
    df   = df,
    cols = c(col, "lat", "lon")
    ) -> wholedf

  toPlot <- wholedf[complete.cases(wholedf),]

  if( !nrow(toPlot) ){
    warning("Any geographic information in specimen data")
    return(NULL)
  }

  ifelse(
    col == "species_name",
    "<i><strong>%s</strong><br/></i>%g specimens",
    "<strong>%s</strong><br/>%g specimens"
    ) -> fmt

  as.list(
    sprintf(
      fmt,
      unlist(
        toPlot[,
               col,
               with = F
               ][,
                 lapply( .SD, function(y) ifelse(y == "", "NA", as.character(y)) )
                 ]
        ),
      toPlot$n
      )
    ) -> labels

  leaflet::leaflet(toPlot) %>%
    leaflet::addProviderTiles(
      leaflet::providers$Esri.WorldImagery,
      options = leaflet::providerTileOptions(minZoom = 2, maxZoom = 17)
    ) %>%
    leaflet::fitBounds(
      min(toPlot$lon),
      min(toPlot$lat),
      max(toPlot$lon),
      max(toPlot$lat)
    ) %>%
    leaflet::addCircleMarkers(
      ~lon,
      ~lat,
      weight = 15,
      radius = ~(n*100/sum(n)),
      clusterOptions = leaflet::markerClusterOptions(),
      popup = labels,
      stroke = T,
      fillOpacity = 1,
      opacity = 0.8,
      color = "#ff0000"
    ) -> q

  return(q)
}


