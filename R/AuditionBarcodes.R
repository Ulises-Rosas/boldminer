#' AuditionBarcodes
#'
#' Despite AuditionBarcodes function is coupled with \code{\link{auditOnID}} function,
#' it can also work with just a list of names.
#' It is pending, when using records mined from
#' \href{https://www.ncbi.nlm.nih.gov}{NCBI database}, assess whether these
#' sequences used to assess barcode's quality come from either a published article or direct submission.
#' Please notice that grades are obtained with accepted names of species according to
#' \href{http://www.marinespecies.org/aphia.php?p=webservice}{WoRMS Rest API} by using
#' its taxamatch algorithm. Hence, since currently accepted names within `species` vector has not been
#' figured out, unevenness between the column `BIN_structure` and `species` could pop up.
#'
#'
#' @param species species name vector
#' @param matches This is only filled when this function is coupled with \code{\link{auditOnID}} function
#' @param validate_name if TRUE, validation of species name is performed. This validation of name is performed
#'     by using taxamatch algorithm from \href{http://www.marinespecies.org/aphia.php?p=webservice}{WoRMS Rest API}
#' @param exclude_ncbi exclude barcodes obtained from \href{https://www.ncbi.nlm.nih.gov}{NCBI database}
#' @param quiet let to use running messages while auditing
#'
#' @return DNA barcode auditing
#' @export
#' @importFrom data.table .SD .N
#' @examples
#' \dontrun{
#' species <- c( "Caranx ruber", "Bathygobius lineatus", "Diodon hystrix")
#' boldminer::AuditionBarcodes(species, exclude_ncbi = FALSE, validate_name = TRUE)
#' }


AuditionBarcodes <- function(species,
                            matches = NULL,
                            validate_name = FALSE,
                            exclude_ncbi = TRUE,
                            quiet = FALSE){ ##function for only using with public data
  ## for testing
  # species = "Bathygobius lineatus"
  ## for testing

  if(!quiet){
    writeLines( "Auditing for:\n" )
    fmt <- getfmt(species)
  }

  pat = "^[A-Z][a-z]+ [a-z]+$"
  pat2 = "^[A-Z][a-z]+ sp[p|\\.]{0,2}$"

  if(validate_name){

    getSpps <- function(sppsvec){

      unlist(
        lapply( as.character(sppsvec), function(x){
          # tmp = as.character(.GlobalEnv$Worms(x)$get_accepted_name())
          # if(!grepl(pat, tmp) || grepl(pat2, tmp))
            # tmp = as.character(.GlobalEnv$Worms(x)$taxamatch())
          # tmp = as.character(Worms(x)$taxamatch())
          tmp = taxamatch(x)

          if(!grepl(pat, tmp) || grepl(pat2, tmp))
            tmp = x

          tmp
        })
      ) -> tmp2

      return(tmp2)
    }

    renameWithValidate <- function(bin){

      uniqSpps = unique(bin$species_name)
      a        = getSpps(uniqSpps)
      names(a) = uniqSpps

      sapply(
        as.character(bin$species_name),
        function(x){
          a[names(a) == x]
        }
      ) -> bin$species_name
      return(bin)
    }

  }

  json_f <- function(bin){

    uniqBins = unique(bin$bin_uri)
    lapply(uniqBins,
           function(x){
             df = bin[bin$bin_uri == x,]

             lapply(
               unique(df$species_name),
               function(y){
                 df2 = df[df$species_name == y, ]

                 data.frame(species_name = y,
                            bin = x,
                            institutes = sum(df2$institutes),
                            n = sum(df2$n),
                            stringsAsFactors = F)
               }) -> tmp_list

             do.call("rbind", tmp_list) -> tmp_df

             apply(tmp_df,
                   MARGIN = 1,
                   function(z){
                     paste0("'",z[1],"'",':', z[4])
                   }) -> Spps_N
             paste0(
               "'", x, "':{",
               paste(Spps_N, collapse = ","),
               "}"
             )
           }
    ) -> tmp_list

    return(
      paste(unlist(tmp_list), collapse = ", ")
    )
  }

  classFrame <- function(m,g,b,j,s,y){

    matchF <- function(ma) paste0("There were ", ma, " matches. ")

    if(g == "A"){

      if( is.null(m) ){
        "Matched BIN with external congruence" ->  obs
        json_f(b) -> bin_str

      }else{
        paste0(matchF(m), "External congruence.") -> obs
      }

    }else if (g == "B"){

      if( is.null(m) ){
        "Matched BIN with internal congruence only" -> obs
        json_f(b) -> bin_str

      }else{

        paste0(matchF(m),"Internal congruence.") -> obs
      }

    }else if (g == "C"){

      if( is.null(m) ){
        "Splitted BIN" -> obs
        json_f(b)      -> bin_str

      }else{
        paste0(
          matchF(m),
          "Assessment of intraspecific divergences is still needed.") -> obs
      }

    }else if (g == "D"){

      paste0(
        "Insufficient data. Institution storing: ",
        length(j$institutions),
        ". Specimen records: "  ,
        sum(j$records, na.rm = T) ) -> obs

      NA -> bin_str

      if( !is.null(m) )
        paste0( matchF(m), obs ) -> obs

    }else if (g == "E*"){

      if( is.null(m) ){
        "Merged BIN" -> obs
        json_f(b)    -> bin_str

      }else{
        paste0(
          matchF(m),
          paste( s, collapse = ","),
          " shared the same BIN." ) -> obs
      }

    }else if (g == "E**"){

      if(is.null(m)){
        "Mixtured BIN" -> obs
        json_f(b)      -> bin_str

      }else{
        paste0(
          matchF(m),
          "Mixtured BIN and it's composed by species such as: ",
          paste(
            unique(b$species_name),
            collapse = ", ")) -> obs
      }

    }else if (g == "F"){

      "Barcodes mined from GenBank or unvouchered." -> obs
      NA -> bin_str

      if( !is.null(m) )
        paste0( matchF(m), obs) -> obs
    }

    df = data.frame(
      Grades = g,
      Observations = obs,
      stringsAsFactors = F  )

    if(is.null(m))
      df = cbind(
        data.frame(Species = y, stringsAsFactors = FALSE),
        df,
        data.frame(BIN_structure = bin_str, stringsAsFactors = FALSE)
        )

    return(df)
  }


  frames = lapply(species, function(x){
    ## for testing
    # x = species
    # x = "Caranx ruber"
    ## for testing

    if(!quiet)
      writeLines(sprintf(fmt, x))


    spedat = SpecimenData(taxon = x)

    if( is.null(spedat) ){
      # writeLines( paste0("No specimen data for ", x) )
      data.frame(
        Species= x,
        Grades = "NA",
        Observations = "No specimen data available",
        BIN_structure = NA,
        stringsAsFactors = F)

    }else{
      spedat[,
        list(processid,
             bin_uri,
             species_name,
             institution_storing,
             species_taxID)
        ] -> mbb0

      taxid = unique(mbb0$species_taxID)[1]

      mbb0[
        grepl("BOLD", x = mbb0$bin_uri )  &
          !grepl("*unvouchered", mbb0$institution_storing)
        ] -> meta.by.barcodes1

      if(exclude_ncbi){

        meta.by.barcodes1[
          !grepl("Mined from GenBank, NCBI", meta.by.barcodes1$institution_storing)
          ] ->  meta.by.barcodes1
      }

      if( nrow(meta.by.barcodes1) <= 3){

        gsub('\"',"",
             gsub(
               '.*depositry":\\{(.+?)\\},.*', '\\1',
               RCurl::getURL(
                 paste0(
                   "http://www.boldsystems.org/index.php/API_Tax/TaxonData?taxId=",
                   taxid ,"&dataTypes=all" )))) -> js00

        do.call("rbind",
                lapply(
                  strsplit(
                    strsplit( js00, split = ",")[[1]], split = "\\:"),

                  function(x){

                    if(!exclude_ncbi){
                      tmp = x[!grepl("*unvouchered", x[1])]

                    }else{
                      tmp = x[!grepl("Mined from GenBank", x[1]) &
                                !grepl(" NCBI", x[1]) &
                                !grepl("*unvouchered", x[1])] }

                    if( !is.na(tmp[2]) )
                      data.frame(institutions = tmp[1],
                                 records = as.numeric(tmp[2]),
                                 stringsAsFactors = F)
                  })
        ) -> js0

        if( sum(js0$records, na.rm = T) > 0){

          classFrame(m = matches, g = "D", j = js0, y = x)
        }else{

          classFrame(m = matches, g = "F", y = x)
        }

      }else{

        uniqBins = unique(meta.by.barcodes1$bin_uri)

        spb = SpecimenData(bin = paste(uniqBins, collapse = "|"))

        spb[
          grepl(pat,spb$species_name) &
            !grepl(pat2, spb$species_name) &
            !grepl("*unvouchered", spb$institution_storing)
          ] -> bin


        if(exclude_ncbi){

          bin[
            !grepl("Mined from GenBank, NCBI", bin$institution_storing)
            ] -> bin
        }

        uniqSpps  = unique(bin$species_name)
        lengthIns = length(unique(bin$institution_storing))

        bin[,
          list(institutes = length( unique( .SD$institution_storing ) ), n = .N),
          by = list(species_name, bin_uri)
          ] -> bin

        if( length(uniqBins) > 1 ){

          if( length(uniqSpps) > 1 ){

            if(validate_name)
              bin = renameWithValidate(bin)

            classFrame(
              m = matches,
              g = ifelse(length(unique(bin$species_name)) == 1, 'C', 'E**'),
              b = bin,
              y = x)

          }else{
            classFrame(m = matches, g = 'C', b = bin, y = x)
          }

        }else{

          if( length(uniqSpps) == 1 && lengthIns > 1){
            classFrame(m = matches, g= 'A', b = bin, y = x )

          }else if( length(uniqSpps) == 1 && lengthIns == 1 ){
            classFrame(m = matches, g= 'B', b = bin, y = x )

          }else{

            if(validate_name)
              bin = renameWithValidate(bin)

            if( length(unique(bin$species_name)) == 1){

              classFrame(
                m = matches,
                g = ifelse(lengthIns > 1, 'A', 'B'),
                b = bin,
                y = x )

            }else{
              classFrame(m = matches, g = 'E*', b = bin, s = uniqSpps, y =  x)
            }
          }
        }
      }
    }
  })
  return(do.call('rbind', frames))
}
