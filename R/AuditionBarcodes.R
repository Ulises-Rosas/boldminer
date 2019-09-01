#' AuditionBarcodes
#'
#' Despite AuditionBarcodes function is coupled with \code{\link{addAudition}} function,
#' it can also work with just a list of names. Furthermore, there is an argument
#' which enables to chose if sequences from GenBank are considered.
#' It is pending, however, assess whether these sequences used to assess barcode's quality
#' come from either a published article or direct submission.
#' Please notice that grades are obtained with accepted names of
#' species according to WoRMS database by
#' using the worms.py script.
#' Hence, since currently accepted names within `species` vector has not been
#' figured out, unevenness between the column `BIN_structure` and `species` could pop up.
#' For this reason, on above example, _Morula margariticola_ has another name into BIN structure
#' column (i.e. _Drupella margariticola_) which actually is its currently accepted name.
#'
#'
#' @param species species
#' @param matches matches
#' @param validate_name validate_name
#' @param include_ncbi include_ncbi
#' @param python_path python_path
#'
#' @return DNA barcode auditing
#' @export
#' @importFrom data.table .SD .N
#' @examples
#' \dontrun{
#' species <- c( "Caranx ruber", "Bathygobius lineatus", "Diodon hystrix")
#' boldminer::AuditionBarcodes(species, include_ncbi = FALSE, validate_name = TRUE)
#' }


AuditionBarcodes<- function(species,
                            matches = NULL,
                            validate_name = FALSE,
                            include_ncbi = FALSE,
                            python_path = "/usr/local/bin/python3"){ ##function for only using with public data

  ## for testing
  # species = "Bathygobius lineatus"
  ## for testing

  pat = "^[A-Z][a-z]+ [a-z]+$"
  pat2 = "^[A-Z][a-z]+ sp[p|\\.]{0,2}$"

  if(validate_name){

    Sys.setenv(RETICULATE_PYTHON = python_path)

    reticulate::use_python(python = python_path)

    urllib <- NULL
    time <- NULL
    unicodedata <- NULL

    .onLoad <- function(libname, pkgname) {
      # use superassignment to update global reference to scipy
      urllib      <<- reticulate::import("urllib", delay_load = TRUE)
      time        <<- reticulate::import("time", delay_load = TRUE)
      unicodedata <<- reticulate::import("unicodedata", delay_load = TRUE)
    }

    wpath <- system.file(package = "boldminer")

    reticulate::source_python(paste0(wpath, "/worms.py"), convert = F)

    getSpps <- function(sppsvec){

      unlist(
        lapply( as.character(sppsvec), function(x){
          # tmp = as.character(.GlobalEnv$Worms(x)$get_accepted_name())
          # if(!grepl(pat, tmp) || grepl(pat2, tmp))
            # tmp = as.character(.GlobalEnv$Worms(x)$taxamatch())
          tmp = as.character(Worms(x)$taxamatch())

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
        data.frame(Species = y),
        df,
        data.frame(BIN_structure = bin_str)
        )

    return(df)
  }


  frames = lapply(species, function(x){

    ## for testing
    # x = species
    ## for testing

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

      if(include_ncbi){

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

                    if(include_ncbi){
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


        if(include_ncbi){

          bin[
            !grepl("Mined from GenBank, NCBI", bin$institution_storing)
            ] -> bin
        }

        uniqSpps  = unique(bin$species_name)
        lengthIns = length(unique(bin$institution_storing))
        # bin = bin %>%
        #   dplyr::group_by( species_name, bin_uri) %>%
        #   dplyr::summarise(institutes = length(unique(institution_storing)),
        #                             n = length(species_name))
        bin[,
          list(institutes = length( unique( .SD$institution_storing ) ), n = .N),
          by = list(species_name, bin_uri)
          ] -> bin
        # bin[,
        #     list(institutes = length( unique( institution_storing ) ), n = .N ),
        #     by = list("species_name", "bin_uri")
        #   ] -> bin

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
