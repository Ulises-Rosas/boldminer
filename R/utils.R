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
#' revcom
#'
#' @param seq a string containing a dna sequence
#'
#' @return reverse complement
#'
revcom <- function(seq){

  libco <- c(a = "t", g = "c", c = "g", t  = "a",
             r = "y", y = "r", s = "s", w  = "w",
             k = "m", m = "k", b = "v", v  = "b",
             d = "h", h = "d", n = "n",`-` = "-")

  com  <- function(base) libco[names(libco) %in% base]

  revseq    <- rev(strsplit(seq, split = "")[[1]])
  revcomseq <- sapply(revseq, com, USE.NAMES = F)

  paste(revcomseq, collapse = "")
}
#' getIDfromBOLD
#'
#' @param seq a string containing a dna sequence
#' @param db database available for BOLD's API
#'
#' @return data frame with ID
#'
getIDfromBOLD <- function(seq, db){

  host  <- "http://www.boldsystems.org/index.php/Ids_xml?db="

  getdf <- function(host, db, seq){
    XML::xmlToDataFrame(
      XML::xmlParse( paste0(host, db, "&sequence=", seq) ),
      stringsAsFactors = FALSE
    )
  }
  out <- getdf(host = host, db = db, seq = seq)

  if( !nrow(out) ){
    Sys.sleep(0.5)
    out <- getdf(host = host, db = db, seq = revcom(seq))
  }

  return(out)
}
