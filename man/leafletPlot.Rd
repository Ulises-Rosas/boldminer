% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/SpecimenData.R
\name{leafletPlot}
\alias{leafletPlot}
\title{leafletPlot}
\usage{
leafletPlot(df, col = "species_name")
}
\arguments{
\item{df}{specimen data from \code{\link{SpecimenData}} function}

\item{col}{column used as label}
}
\value{
leaflet map
}
\description{
Interactive map of barcodes, when geographic information is available
}
\examples{
\dontrun{
specimendata <- boldminer::SpecimenData(taxon = "Elasmobranchii", geo = "Peru")
boldminer::leafletPlot(df = specimendata, col = "species_name")
}
}
