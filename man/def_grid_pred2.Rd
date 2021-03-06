% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/def_grid2.R
\name{def_grid_pred2}
\alias{def_grid_pred2}
\title{Takes multiple spatial inputs (range shapefiles, enm rasters) and makes a grid for the genetic simulations}
\usage{
def_grid_pred2(
  pred = NULL,
  samps = NULL,
 
    raster.proj = "+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m +no_defs"
)
}
\arguments{
\item{pred}{is a raster stack with layers of hab suitability (assumes [0-1] with larger numbers better suitability)}

\item{samps}{locations of actual genetic samples.  SpatialPoints object assumed in same proj as raster input}

\item{raster.proj}{the proj.4 string to impose on the raster enm (if not already specified) (defaults albers)}
}
\description{
Takes multiple spatial inputs (range shapefiles, enm rasters) and makes a grid for the genetic simulations
}
