
<!-- README.md is generated from README.Rmd. Please edit that file -->
BOLDmineR
=========

<!-- badges: start -->
<!-- badges: end -->
DNA barcodes are not only used by researchers, but also by decision-makers (e.g. to control food fraud or illegal species commercialization). The big-scale demand of both online services and information to identify species contrasts with the limited ways to automatize either species identification or assessment of barcode quality per species, directly from the web interface.

[BOLD system](http://www.boldsystems.org/) is the main database of DNA barcode worldwide. This database has been stepply growing through time since its release ([Ratnasingham and Hebert 2007](https://onlinelibrary.wiley.com/doi/full/10.1111/j.1471-8286.2007.01678.x)) and its accessibility is pivotal for projects focused on DNA barcodes. Nowdays APIs, to some extant, are offering access to well-know databases such as [FishBase](https://fishbase.ropensci.org/), [WoRMS](http://www.marinespecies.org/rest/) or [BOLD](http://www.boldsystems.org/index.php/api_home). Despite BOLD's API mostly involves only public data, this leverages its data retrieving for wider purposes. The API's applicability, however, seems to be wholly held up by its own needs of having either standalone softwares or functions which could wrap up blocks of information. The main objective of these functions (i.e. BOLD-mineR's functions) is justly circumscribe the BOLD's API performance with R-based scripts to get insights about DNA barcodes by using public information.

Installation
------------

You can install the development version from GitHub with:

``` r
# library(devtools)
devtools::install_github("Ulises-Rosas/boldminer")
```

Usage
-----

``` r
library(boldminer)
```

### SpecimenData

This function lets us to mine associated metadata from any specimen according to following arguments:

-   `taxon` (e.g. `Aves|Elasmobranchii`).
-   `ids` (e.g. `ANGBF12704-15`).
-   `bin` (e.g. `BOLD:AAA4689`).
-   `container` (e.g. `FIPP`).
-   `institution` (e.g. `Smithsonian Institution`).
-   `researchers` (including identifiers and collectors).
-   `geo` (e.g. `Peru`).

If we want to get information, for instance, from all specimens of elasmobranchs distributed in Peru and stored in BOLD, we can use the following line:

``` r
specimendata <- boldminer::SpecimenData(taxon = "Elasmobranchii", geo = "Peru")
```

Then, we use *tibble* package to only assess its dimension:

``` r
tibble::as_tibble(specimendata)
#> # A tibble: 99 x 68
#>    processid sampleid recordID catalognum fieldnum institution_sto…
#>    <fct>     <fct>       <int> <fct>      <fct>    <fct>           
#>  1 ANGBF109… KJ146022  5651960 ""         KJ146022 Mined from GenB…
#>  2 ANGBF109… KJ146023  5651961 ""         KJ146023 Mined from GenB…
#>  3 ANGBF109… KJ146024  5651962 ""         KJ146024 Mined from GenB…
#>  4 ANGBF110… KJ146021  5652090 ""         KJ146021 Mined from GenB…
#>  5 ANGBF110… KJ146044  5652111 ""         KJ146044 Mined from GenB…
#>  6 ANGBF110… KJ146043  5652112 ""         KJ146043 Mined from GenB…
#>  7 ANGBF116… KJ146045  5652680 ""         KJ146045 Mined from GenB…
#>  8 ANGBF116… KJ146041  5652681 ""         KJ146041 Mined from GenB…
#>  9 ANGBF116… KJ146040  5652682 ""         KJ146040 Mined from GenB…
#> 10 ANGBF116… KJ146038  5652684 ""         KJ146038 Mined from GenB…
#> # … with 89 more rows, and 62 more variables: collection_code <lgl>,
#> #   bin_uri <fct>, phylum_taxID <int>, phylum_name <fct>,
#> #   class_taxID <int>, class_name <fct>, order_taxID <int>,
#> #   order_name <fct>, family_taxID <int>, family_name <fct>,
#> #   subfamily_taxID <lgl>, subfamily_name <lgl>, genus_taxID <int>,
#> #   genus_name <fct>, species_taxID <int>, species_name <fct>,
#> #   subspecies_taxID <lgl>, subspecies_name <lgl>,
#> #   identification_provided_by <fct>, identification_method <fct>,
#> #   identification_reference <fct>, tax_note <lgl>, voucher_status <fct>,
#> #   tissue_type <fct>, collection_event_id <lgl>, collectors <fct>,
#> #   collectiondate_start <lgl>, collectiondate_end <lgl>,
#> #   collectiontime <fct>, collection_note <lgl>, site_code <lgl>,
#> #   sampling_protocol <fct>, lifestage <fct>, sex <lgl>,
#> #   reproduction <fct>, habitat <fct>, associated_specimens <lgl>,
#> #   associated_taxa <lgl>, extrainfo <fct>, notes <fct>, lat <dbl>,
#> #   lon <dbl>, coord_source <lgl>, coord_accuracy <lgl>, elev <lgl>,
#> #   depth <int>, elev_accuracy <lgl>, depth_accuracy <lgl>, country <fct>,
#> #   province_state <fct>, region <fct>, sector <fct>, exactsite <fct>,
#> #   image_ids <lgl>, image_urls <lgl>, media_descriptors <lgl>,
#> #   captions <lgl>, copyright_holders <lgl>, copyright_years <lgl>,
#> #   copyright_licenses <lgl>, copyright_institutions <lgl>,
#> #   photographers <lgl>
```

However, if only sequences are desired, the argument `seq = "only"` should be stated. You can also combine metadata with sequences by using `seq = "combined"`

``` r
boldminer::SpecimenData(taxon = "Elasmobranchii", geo = "Peru", seq = "only")
#> 99 DNA sequences in binary format stored in a list.
#> 
#> Mean sequence length: 641.899 
#>    Shortest sequence: 226 
#>     Longest sequence: 712 
#> 
#> Labels:
#> ANGBF10913-15|Alopias pelagicus|COI-5P|KJ146022
#> ANGBF10914-15|Alopias pelagicus|COI-5P|KJ146023
#> ANGBF10915-15|Alopias pelagicus|COI-5P|KJ146024
#> ANGBF11043-15|Carcharhinus obscurus|COI-5P|KJ146021
#> ANGBF11064-15|Prionace glauca|COI-5P|KJ146044
#> ANGBF11065-15|Prionace glauca|COI-5P|KJ146043
#> ...
#> 
#> Base composition:
#>     a     c     g     t 
#> 0.258 0.254 0.166 0.323 
#> (Total: 63.55 kb)
```

### ID\_engine

This function finds best matches between a query sequence and a database of BOLD by using BLASTn-based algorithms. Arguments of this function are `query` and `db`. The first one are query sequences and the second one are one of avilable databases in BOLD:

-   `COX1`
-   `COX1_SPECIES`
-   `COX1_SPECIES_PUBLIC`
-   `COX1_L640bp`

This script also take account for those sequences which are not, by mistake, at the right sense and sends them to perform a BLAST search through its [API](https://ncbi.github.io/blast-cloud/dev/api.html)

This function starts with a fasta-formated file. In order to test this script, we can take sample file within the package:

``` r
fasta_file <- system.file("sequences.fa", package = "boldminer") 
```

Then, we can run the following line get its identification:

``` r
id_out <- boldminer::ID_engine(query = fasta_file, db = "COX1_SPECIES")
```

First five rows for each id\_out item can be taken by using `lookID()` function:

``` r
boldminer::lookID(id_out)
#>    Sample            ID taxonomicidentification similarity
#> 1    seq1   PHANT458-08       Alopias pelagicus          1
#> 2    seq1   IRREK872-08       Alopias pelagicus          1
#> 3    seq1   IRREK873-08       Alopias pelagicus          1
#> 4    seq1   IRREK874-08       Alopias pelagicus          1
#> 5    seq1   IRREK876-08       Alopias pelagicus          1
#> 6    seq2 ANGBF10914-15       Alopias pelagicus     0.9986
#> 7    seq2   ESHKB029-07       Alopias pelagicus     0.9985
#> 8    seq2 ANGBF10913-15       Alopias pelagicus     0.9971
#> 9    seq2   PHANT458-08       Alopias pelagicus     0.9969
#> 10   seq2   IRREK873-08       Alopias pelagicus     0.9969
#> 11   seq3 ANGBF12626-15       Alopias pelagicus          1
#> 12   seq3 ANGBF12623-15       Alopias pelagicus          1
#> 13   seq3 ANGBF11723-15       Alopias pelagicus          1
#> 14   seq3 ANGBF10915-15       Alopias pelagicus          1
#> 15   seq3   ESHKB036-07       Alopias pelagicus          1
```

### auditOnID

This function adds an **audition** step ([Oliveira *et al.* 2016](https://onlinelibrary.wiley.com/doi/full/10.1111/jfb.13169)) to each selected specimen by `ID_engine()` (see above), given a certain threshold. This function, in turn, uses another function called `AuditionBarcodes()` (see below). This prior function is coupled with `auditOnID()` and can validate species names by taking accepted names from [Worms database](http://www.marinespecies.org/).

As seen with `ID_engine()`, this function starts with a fasta-formated file. We can take the same sample file we used: `fasta_file`. Then, we can identify those sequences under `audiOnID()` functionality by using a `threshold = 0.99` (i.e. 99% of similarity):

``` r
aoID_out <- boldminer::auditOnID(seqs = fasta_file, threshold = 0.99)
#> |*****************************************************************| 100%
```

``` r
aoID_out
#>   Samples  Match           Species Grades                                Observations
#> 1    seq1 Unique Alopias pelagicus      A There were 49 matches. External congruence.
#> 2    seq2 Unique Alopias pelagicus      A There were 39 matches. External congruence.
#> 3    seq3 Unique Alopias pelagicus      A There were 94 matches. External congruence.
```

We can also skip audition step by adding `just_ID = TRUE` within arguments.

### AuditionBarcodes

Despite `AuditionBarcodes()` function is coupled with `auditOnID()` function, it can also work with just a list of names. Furthermore, there is an argument which enables to chose if sequences from GenBank are considered. It is pending, however, assess whether these sequences used to assess barcode's quality come from either a published article or direct submission:

``` r
species <- c( "Caretta caretta", "Bathygobius lineatus",
              "Albula esuncula", "Vibilia armata",
              "Alepisaurus ferox", "Diodon hystrix",
              "Vesicomya galatheae", "Caranx ruber")
audit_out <- boldminer::AuditionBarcodes(species, exclude_ncbi = T, validate_name = T)
#> Auditing for:
#> 
#>              Caretta caretta
#>         Bathygobius lineatus
#>       Eretmochelys imbricata
#>               Vibilia armata
#>            Alepisaurus ferox
#>               Diodon hystrix
#>          Vesicomya galatheae
#>                 Caranx ruber
```

``` r
audit_out
#>                Species Grades                                                    Observations
#> 1      Caretta caretta      A                            Matched BIN with external congruence
#> 2 Bathygobius lineatus      B                       Matched BIN with internal congruence only
#> 3      Albula esuncula      C                                                    Splitted BIN
#> 4       Vibilia armata      D Insufficient data. Institution storing: 2. Specimen records: 20
#> 5    Alepisaurus ferox    E**                                                    Mixtured BIN
#> 6       Diodon hystrix     E*                                                      Merged BIN
#> 7  Vesicomya galatheae      F                     Barcodes mined from GenBank or unvouchered.
#> 8         Caranx ruber     NA                                      No specimen data available
#>                                                                                                 BIN_structure
#> 1                                                                       'BOLD:AAB8364':{'Caretta caretta':11}
#> 2                                                                   'BOLD:AAF0181':{'Bathygobius lineatus':4}
#> 3                                  'BOLD:AAF1162':{'Albula esuncula':3}, 'BOLD:AAA3538':{'Albula esuncula':1}
#> 4                                                                                                        <NA>
#> 5 'BOLD:AAC5235':{'Alepisaurus ferox':8}, 'BOLD:AAC5236':{'Alepisaurus brevirostris':3,'Alepisaurus ferox':3}
#> 6                                                   'BOLD:AAB0446':{'Diodon hystrix':17,'Diodon eydouxii': 1}
#> 7                                                                                                        <NA>
#> 8                                                                                                        <NA>
```

Please notice that grades are obtained with accepted names of species according to [WoRMS database](http://www.marinespecies.org/) Rest service by using its taxamatch algorithm. Hence, since currently accepted names within `species` vector has not been figured out, unevenness between the column `BIN_structure` and `species` could pop up.
