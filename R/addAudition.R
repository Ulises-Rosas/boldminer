#' addAudition
#'
#'
#' This function adds an audition step
#' (Oliveira et al 2016, doi: 10.1111/jfb.13169)
#' to each selected specimen by \code{\link{ID_engine}}, given a certain threshold.
#' This function, in turn, uses another function called `AuditionBarcodes()`.
#' This prior function is coupled with addAudition and can validate species names by
#' taking accepted names from Worms database.
#'
#'
#'
#' @param seqs sequence file
#' @param threshold threshold
#' @param exclude_ncbi exclude barcodes obtained from NCBI when DNA barcode auditing is allowed, i.e. not just_ID
#' @param just_ID just_ID
#' @param make_blast make_blast
#' @param validate_name validate_name
#'
#' @return species ID plus DNA barcode auditing
#' @export
#' @importFrom utils setTxtProgressBar txtProgressBar
#'
addAudition <- function(seqs,
                        threshold,
                        exlclude_ncbi=TRUE,
                        just_ID = FALSE,
                        make_blast = FALSE ,
                        validate_name = FALSE
                        ){


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
                   Observations = tmp[[1]]$taxonomicidentification) -> lista2[[i]]
      }else{
        data.frame(Match   = "Any", Species = tmp[[1]]$taxonomicidentification) -> lista2[[i]]
      }
      setTxtProgressBar(pb, i)
      next
    }

    tmp = tmp[[1]] %>%
      dplyr::select(ID, taxonomicidentification, similarity ) %>%
      dplyr::filter(grepl("^[A-Z][a-z]+ [a-z]+$", taxonomicidentification),
                    !grepl("^[A-Z][a-z]+ sp[p|\\.]{0,2}$", taxonomicidentification)) %>%
      dplyr::mutate(similarity = as.numeric(as.character(similarity)))

    if(!grepl("GenBank", as.character(tmp[1,]$ID) )){

      tmp = tmp %>%
        dplyr::filter(!grepl(" sp.",taxonomicidentification))
    }

    if( tmp[1,]$similarity < threshold ){

      paste0(
        if(grepl("GenBank", as.character(tmp[1,]$ID))) "GenBank: " else "BOLD: ",
        paste(
          head(
            apply(tmp,MARGIN = 1, function(x){paste0(x[2], " (sim. = ",x[3], ")") }),
            n = 3),
          collapse = ", ")
        ) -> best_matches

      if(!just_ID){

        if(grepl("RID", as.character(tmp[1,]$ID))){
          paste("RID not available.") -> obs
        }else{
          best_matches -> obs
        }

        data.frame(Match   = "Any",
                   Species = "",
                   Grades  = "",
                   Observations = obs ) -> lista2[[i]]
      }else{
        data.frame(Match = "Any",Species = best_matches) -> lista2[[i]]
        }

      }else{

        tmp = tmp %>%
          dplyr::filter(similarity > threshold)

        barcodes = sort(
          table(as.character(tmp$taxonomicidentification)),
          decreasing = T)

      if(length(barcodes) > 1){

        vec <- vector('character')
        for(k in 1:length(barcodes)){
          vec[k] = paste(names(barcodes[k])," (n = ",barcodes[k],")", sep = "")
          }

        if(!just_ID){
          data.frame(Match = "Ambiguous",
                     Species = paste(vec, collapse = ", "),
                     Grades = paste(
                       paste(
                         AuditionBarcodes(species = names(barcodes),
                                          matches = sum(barcodes),
                                          exclude_ncbi  = exclude_ncbi,
                                          validate_name = validate_name,
                                          quiet = TRUE)$Grades,
                         collapse = ", "),
                       " respectively.",sep = ""),
                     Observations = "") -> lista2[[i]]
          }else{
            data.frame(Match = "Ambiguous", Species = paste(vec, collapse = ", ") ) -> lista2[[i]] }

        }else{

          if(!just_ID){

            data.frame(Match = "Unique",
                       Species = paste(names(barcodes)),
                       AuditionBarcodes(species = names(barcodes),
                                        matches = sum(barcodes),
                                        exclude_ncbi  = exclude_ncbi,
                                        validate_name = validate_name,
                                        quiet = TRUE)) -> lista2[[i]]
          }else{

            data.frame(Match   = "Unique",
                       Species = paste(names(barcodes))) -> lista2[[i]]
            }
          }
        setTxtProgressBar(pb, i)
      }
    }
  close(pb)
  return(data.frame(Samples = names(seqs), do.call('rbind', lista2)))
}


## quiets concerns of R CMD check re: the .'s that appear in pipelines
if(getRversion() >= "2.15.1")  utils::globalVariables(c(".", "ID", "similarity", "taxonomicidentification"))

