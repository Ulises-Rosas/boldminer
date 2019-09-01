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
#'
ID_engine<- function(query, db, make_blast = T, ...){

  query = ape::read.FASTA(query)
  # db    = "COX1_SPECIES"

  seqs <- lapply(query, function(x){
    paste(ape::as.character.DNAbin(x), collapse = "")
    })

  lapply(names(seqs), function(y){

    x = seqs[[y]]

    data <- XML::xmlParse( paste("http://www.boldsystems.org/index.php/Ids_xml?db=",
                            db, "&sequence=", x, sep = ""))

    bold.results = XML::xmlToDataFrame(data)

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
                          similarity = 0))

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
                      digits = 4)
                    )
        })

      return(do.call("rbind", genbank.results))

    }else if(  nrow(bold.results) == 0 && !make_blast ){
      return(data.frame(ID = y,
                        taxonomicidentification = "Unavailable with BOLD",
                        similarity = 0))

    }else{
      return(bold.results)
      }
  })
}

## quiets concerns of R CMD check re: the .'s that appear in pipelines
if(getRversion() >= "2.15.1")  utils::globalVariables(c("."))
