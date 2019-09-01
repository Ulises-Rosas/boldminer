#' ID_engine
#'
#' @description ID_engine finds best matches between a query sequence and a
#' database of BOLD by using BLASTn-based algorithms.
#' Arguments of this function are `query` and `db`. The first
#' one are query sequences and the second one are one
#' of avilable databases in BOLD:
#'
#' @description - `COX1`
#' @description - `COX1_SPECIES`
#' @description - `COX1_SPECIES_PUBLIC`
#' @description - `COX1_L640bp`
#'
#' @param query query
#' @param db db
#' @param make_blast make_blast
#' @param ... amazing three points
#'
#' @return species ID
#' @importFrom magrittr %>%
#' @importFrom utils tail head
#' @export
#'
#' @examples
#' \dontrun{
#' fasta_file <- system.file("sequences.fa", package = "boldminer")
#' out <- boldminer::ID_engine(query = fasta_file, db = "COX1_SPECIES")
#'
#' }
#'
ID_engine <- function(query, db, make_blast = TRUE, ...){

  # db    = "COX1_SPECIES"
  # query = fasta_file

  if( !length( attributes(query) ) )
    query = ape::read.FASTA(query)

  lapply(
    query,
    function(x){
      paste(
        ape::as.character.DNAbin(x),
        collapse = "")
      }
    ) -> seqs

  # seqs = seqs[1]
  lapply(names(seqs), function(y){

    x = seqs[[y]]

    data <- XML::xmlParse(
      paste0("http://www.boldsystems.org/index.php/Ids_xml?db=",
             db,"&sequence=", x))

    bold.results = XML::xmlToDataFrame(data, stringsAsFactors = FALSE)

    if( nrow(bold.results) == 0 && make_blast ){

      rid <- RCurl::getURL(
        paste("https://blast.ncbi.nlm.nih.gov/blast/Blast.cgi?CMD=Put&PROGRAM=blastn&MEGABLAST=on&DATABASE=nt&QUERY=",
              x,"&WORD_SIZE=28&HITLIST_SIZE=3", sep = ""))  %>%
        gsub(".*\"RID\" value=\"", "", x =.) %>%
        gsub("\".*","", x =.)

      if(rid == "")
        return(
          data.frame(ID = "GenBank: RID not available",
                     taxonomicidentification = "RID not available.",
                     similarity = 0,
                     stringsAsFactors = FALSE)
          )

      hits = list()

      while( all(is.na(hits)) ){

        tmp.output = RCurl::getURL(
          paste("https://blast.ncbi.nlm.nih.gov/blast/Blast.cgi?CMD=Get&FORMAT_TYPE=XML&RID=",
                rid, sep = "")) %>%
          strsplit(x = ., split = "<Hit>\n")
        hits = tmp.output[[1]][2:4]
        Sys.sleep(5)
      }

      genbank.results = lapply(hits, function(e){

        data.frame( ID = gsub(".*<Hit_id>", "", e) %>%
                      gsub("</Hit_id>\n.*", "", x =.) %>%
                      gsub("\\|", "", x =.) %>%
                      strsplit(x =., split = "gb") %>%
                      tail(x =.[[1]], n = 1) %>%
                      paste("GenBank: ", . ,sep = ""),

                    taxonomicidentification = gsub(".*<Hit_def>", "", e) %>%
                      gsub("</Hit_def>.*", "", x =.) %>%
                      strsplit(x =. , split = " ") %>%
                      head(x =.[[1]], n = 2) %>%
                      paste(., collapse = " "),

                    similarity = round(
                      gsub(".*<Hsp_identity>", "", e) %>%
                        gsub("</Hsp_identity>.*", "", x =.) %>%
                        as.numeric(.) / gsub(".*<Hsp_align-len>", "", e) %>%
                        gsub("</Hsp_align-len>.*", "", x =.) %>%
                        as.numeric(.) ,
                      digits = 4),

                    stringsAsFactors = FALSE
                    )
        })

      return(do.call("rbind", genbank.results))

    }else if(  nrow(bold.results) == 0 && !make_blast ){
      return(
        data.frame(ID = y,
                   taxonomicidentification = "Unavailable with BOLD",
                   similarity = 0,
                   stringsAsFactors = FALSE)
        )

    }else{

      return(bold.results)
    }
  }) -> ids

  names(ids) <- names(seqs)

  return(ids)
}

#' lookID
#'
#' Take first and last rows from \code{\link{ID_engine}} function results
#'
#' @param out list of results from \code{\link{ID_engine}} function
#' @param first number of first rows from input
#' @param last number of last rows from input
#'
#' @return data frame with constrained results
#' @export
#'
#' @examples
#' \dontrun{
#'
#' boldminer::lookID(out)
#' }
#'
lookID <- function(out, first = 5, last = 0){

  lapply(
    names(out),
    function(x){

      tmpdf = out[[x]]

      if(ncol(tmpdf) > 3)
        tmpdf <- tmpdf[, c(1,5,6)]

      df = data.frame()

      if(first)
        df = rbind(df, head(tmpdf, first))

      if(last)
        df = rbind(df, tail(tmpdf, last))

      if(nrow(df)){

        df <- data.frame(Sample = x, df, stringsAsFactors = FALSE)
        return(df)

      }else{

        return(NULL)
      }
    }
  ) -> fmtDf

  return( do.call("rbind", fmtDf) )
}


## quiets concerns of R CMD check re: the .'s that appear in pipelines
if(getRversion() >= "2.15.1")  utils::globalVariables(c("."))
