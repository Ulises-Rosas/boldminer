% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/AuditionBarcodes.R
\name{AuditionBarcodes}
\alias{AuditionBarcodes}
\title{AuditionBarcodes}
\usage{
AuditionBarcodes(species, matches = NULL, validate_name = FALSE,
  exclude_ncbi = TRUE, quiet = FALSE)
}
\arguments{
\item{species}{species name vector}

\item{matches}{This is only filled when this function is coupled with \code{\link{auditOnID}} function}

\item{validate_name}{if TRUE, validation of species name is performed. This validation of name is performed
by using taxamatch algorithm from \href{http://www.marinespecies.org/aphia.php?p=webservice}{WoRMS Rest API}}

\item{exclude_ncbi}{exclude barcodes obtained from \href{https://www.ncbi.nlm.nih.gov}{NCBI database}}

\item{quiet}{let to use running messages while auditing}
}
\value{
DNA barcode auditing
}
\description{
Despite AuditionBarcodes function is coupled with \code{\link{auditOnID}} function,
it can also work with just a list of names.
It is pending, when using records mined from
\href{https://www.ncbi.nlm.nih.gov}{NCBI database}, assess whether these
sequences used to assess barcode's quality come from either a published article or direct submission.
Please notice that grades are obtained with accepted names of species according to
\href{http://www.marinespecies.org/aphia.php?p=webservice}{WoRMS Rest API} by using
its taxamatch algorithm. Hence, since currently accepted names within `species` vector has not been
figured out, unevenness between the column `BIN_structure` and `species` could pop up.
}
\examples{
\dontrun{
species <- c( "Caranx ruber", "Bathygobius lineatus", "Diodon hystrix")
boldminer::AuditionBarcodes(species, exclude_ncbi = FALSE, validate_name = TRUE)
}
}
