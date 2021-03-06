##' Subset built-in ash data based on populations
##' @param pops a vector of population names
##' @export
ashRemoveGeneticPops <- function(popmap,pops)
{
    imputed.pruned=imputed

    for (p in pops)
        imputed.pruned=imputed.pruned[,-which(gsub("fp","",names(imputed.pruned))%in%popmap[popmap$abbrev==p,"id"])]


    removes <- c()
    popids <- popmap[gsub("fp","",names(imputed.pruned)),2]
    
    ##table(popids)
    
    for (a in unique(popids))
    {
        if (sum(popids==a)>14)
        {
            removes <- c(removes,sample(which(popids==a),1))
        }
    }
    imputed.pruned[,-1*removes]
}

##' Setup a landscape for Ash for our simulations. everything but the surface is baked into holoSimCell
##' @param brickname name of a file of a geotiff object.  layers correspond to time clicks in simulations
##' @export
ashSetupLandscape <- function(brickname=paste0(system.file("extdata","rasters",package="holoSimCell"),"/","study_region_daltonIceMask_lakesMasked_linearIceSheetInterpolation.tif"),equalsuit=F,partialsuit=F,cellreduce=0.45,xlim=NULL,ylim=NULL,timesteps=NULL)
{
    rownames(popmap) <- popmap[,1]
###
### There are some cells that contain two empirical populations.  Right now we are dropping one in
### each of these cells with the following code.  'imputed' is a built-in dataframe in the holosimcell
### package that has snp data for fraxinus pennsylvanica.
###
    imputed.pruned <- ashRemoveGeneticPops(popmap=popmap,pops=c("Michigan","UNK","MO1","ON1","VA1","MB1")) #these are the pops that are removed
    poptbl <- table(popmap[gsub("fp","",names(imputed.pruned)),2])

    samppts <- pts[pts$abbrev %in% names(poptbl),]
    


####
#### this function (newLandscapeDim) takes a rasterbrick and a proportion of cols to resample to.  So if there are 100 cols
#### and proportion is 0.5, the landscape is resampled to 50 columns (cells get twice as wide).  The rows are resampled to
#### make the cells as square as possible
####  it's easy to change this proportion and see the implications for execution times, etc.
#### on the current (Ash) problem, 0.45 gives a forward time simulation of about 2 minutes.

    if (!equalsuit)
    {
        rs <- raster::brick(brickname)
        newrs <- newLandscapeDim(rs,cellreduce)
    } else {
        if (is.null(xlim)|is.null(ylim))
            newrs=raster::raster(nrows=50,ncols=50,xmn=0,xmx=5000,ymn=0,ymx=5000,vals=1) else newrs=raster::raster(nrows=ylim,ncols=xlim,xmn=0,xmx=5000,ymn=0,ymx=5000,vals=1)
        newrs = raster::brick(newrs,nl=701)
                                                                                     
    }


    
land <- def_grid_pred2(pred=1-newrs,
                                     samps=transSampLoc(samppts,
                                                          range.epsg=4326,
                                                          raster.proj=crs(rs)@projargs),
                                     raster.proj=crs(rs)@projargs
                                     )


landscape <- land
if (partialsuit==F) landscape$hab_suit[landscape$hab_suit > 0] <- 1 #Cells under the glacier have 0 suitability, not NA suitability
if (!uniqueSampled(landscape))
{
  stop("The landscape you are using is combining multiple sampled populations into a single raster cell")
}

landscape

}
