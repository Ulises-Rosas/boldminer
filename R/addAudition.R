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
#' @param include_ncbi include_ncbi
#' @param just_ID just_ID
#' @param make_blast make_blast
#' @param python_path python_path
#' @param validate_name validate_name
#'
#' @return species ID plus DNA barcode auditing
#' @export
#' @importFrom utils setTxtProgressBar txtProgressBar
#'
addAudition <- function(seqs,
                        threshold,
                        include_ncbi=F,
                        just_ID = F,
                        make_blast = F ,
                        python_path = "/usr/local/bin/python3",
                        validate_name = F
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
                                          include_ncbi  = include_ncbi,
                                          validate_name = validate_name,
                                          python_path   = python_path)$Grades,
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
                                        include_ncbi  = include_ncbi,
                                        validate_name = validate_name,
                                        python_path   = python_path)) -> lista2[[i]]
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

