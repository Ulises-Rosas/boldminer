#' auditOnID
#'
#'
#' This function adds an audition step
#' (\href{doi: 10.1111/jfb.13169}{Oliveira et al 2016})
#' to each selected specimen by \code{\link{ID_engine}}, given a certain threshold.
#' This function, in turn, uses another function called \code{\link{AuditionBarcodes}}.
#' This prior function is coupled with addAudition and can validate species names by
#' taking accepted names from \href{http://www.marinespecies.org/index.php}{Worms database}.
#'
#'
#' @param seqs sequence file
#' @param threshold minimal similarity proportion allowed between sample and specimen matches
#' @param exclude_ncbi exclude barcodes obtained from NCBI when DNA barcode auditing is allowed, i.e. not just_ID
#' @param just_ID if TRUE, audition step is skipped
#' @param make_blast if TRUE, blastn algorithm is run for matching sequences
#' @param validate_name if TRUE, validation of species name is performed. This validation of name is performed
#'     by using taxamatch algorithm from \href{WoRMS Rest API}{http://www.marinespecies.org/aphia.php?p=webservice}
#'
#'
#' @return species ID plus DNA barcode auditing
#' @export
#' @importFrom utils setTxtProgressBar txtProgressBar
#' @importFrom data.table .SD
#' @examples
#' \dontrun{
#' seqs  = system.file("sequences.fa", package = "boldminer")
#' boldminer::auditOnID(seqs, just_ID = TRUE)
#'
#' }
auditOnID <- function(seqs,
                      threshold = 0.99,
                      exclude_ncbi=TRUE,
                      just_ID = FALSE,
                      make_blast = FALSE ,
                      validate_name = FALSE
                      ){

  pat = "^[A-Z][a-z]+ [a-z]+$"
  pat2 = "^[A-Z][a-z]+ sp[p|\\.]{0,2}$"

  if( !length(attributes(seqs)))
    seqs = ape::read.FASTA(seqs)

  lista2 = list()
  pb <- txtProgressBar(min = 0, max = length(seqs), style = 3, char = "*")

  for( i in 1:length(seqs) ){
    # i = 1
    tmp = ID_engine(seqs[i], db = "COX1_SPECIES", make_blast)

    if( grepl("Unavailable", tmp[[1]]$taxonomicidentification[1]) ){

      if(!just_ID){
        data.frame(Match   = "Any",
                   Species = "",
                   Grades  = "",
                   Observations = tmp[[1]]$taxonomicidentification,
                   stringsAsFactors = FALSE ) -> lista2[[i]]
      }else{
        data.frame(Match   = "Any",
                   Species = tmp[[1]]$taxonomicidentification,
                   stringsAsFactors = FALSE ) -> lista2[[i]]
      }
      setTxtProgressBar(pb, i)
      next
    }

    tmpf = data.table::as.data.table(tmp[[1]])

    tmpf[i = grepl(pat, tmpf$taxonomicidentification) & !grepl(pat2, tmpf$taxonomicidentification),
         j = list(
           ID,
           taxonomicidentification,
           similarity = as.numeric(tmpf$similarity))
         ] -> tmp

    if( tmp[1,]$similarity < threshold ){

      paste0(
        if(grepl("GenBank", tmp[1,]$ID)) "GenBank: " else "BOLD: ",
        paste(
          head(
            apply(tmp, MARGIN = 1, function(x){ paste0(x[2], " (sim. = ",x[3], ")") }),
            n = 3),
          collapse = ", ")
        ) -> best_matches

      if(!just_ID){

        if(grepl("RID", tmp[1,]$ID)){
          paste("RID not available.") -> obs

        }else{
          best_matches -> obs
        }

        data.frame(Match   = "Any",
                   Species = "",
                   Grades  = "",
                   Observations = obs,
                   stringsAsFactors = FALSE ) -> lista2[[i]]
      }else{
        data.frame(Match = "Any",
                   Species = best_matches,
                   stringsAsFactors = FALSE) -> lista2[[i]]
        }

      }else{

        tmp = tmp[ tmp$similarity > threshold ]

        barcodes = sort( table(tmp$taxonomicidentification), decreasing = T)

        if(length(barcodes) > 1){

          vec <- vector('character')
          for(k in 1:length(barcodes)){

            vec[k] = paste(names(barcodes[k])," (n = ",barcodes[k],")", sep = "")
          }

          if(!just_ID){

            data.frame(Match   = "Ambiguous",
                       Species = paste(vec, collapse = ", "),
                       Grades  = paste(
                         paste(
                           AuditionBarcodes(species = names(barcodes),
                                            matches = sum(barcodes),
                                            exclude_ncbi  = exclude_ncbi,
                                            validate_name = validate_name,
                                            quiet = TRUE)$Grades,
                           collapse = ", "),
                         " respectively.",sep = ""),
                       Observations = "",
                       stringsAsFactors = FALSE) -> lista2[[i]]
          }else{

              data.frame(
                Match = "Ambiguous",
                Species = paste(vec, collapse = ", "),
                stringsAsFactors = FALSE ) -> lista2[[i]]
            }

          }else{

            if(!just_ID){

              data.frame(Match = "Unique",
                         Species = paste(names(barcodes)),
                         AuditionBarcodes(species = names(barcodes),
                                          matches = sum(barcodes),
                                          exclude_ncbi  = exclude_ncbi,
                                          validate_name = validate_name,
                                          quiet = TRUE),
                         stringsAsFactors = FALSE) -> lista2[[i]]
              }else{
                data.frame(Match   = "Unique",
                           Species = paste(names(barcodes)),
                           stringsAsFactors = FALSE) -> lista2[[i]]
              }
          }
        setTxtProgressBar(pb, i)
      }
    }
  close(pb)
  return( data.frame(Samples = names(seqs),
                     do.call('rbind', lista2),
                     stringsAsFactors = FALSE ) )
}


## quiets concerns of R CMD check re: the .'s that appear in pipelines
if(getRversion() >= "2.15.1")  utils::globalVariables(c(".", "ID", "similarity", "taxonomicidentification"))

