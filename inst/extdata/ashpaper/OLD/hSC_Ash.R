#library(holoSimCell)
#devtools::load_all()
### imputed, popmap (individualID->pop mapping), pts (sample locations) and ashpred
### are now built into holoSimCell
### as built in dataframes (in data/ directory)

args <- commandArgs(TRUE)
i <- as.numeric(args[1])
nreps <- as.numeric(args[2]) 
who <- as.character(args[3])  
label <- as.character(args[4])

if(length(args) == 0){
  i <- 1
  nreps <- 20
  who <- "JDR"
  label <- "June_test"
}

library(holoSimCell)

#Set the filename, simulation, and output directories for the run
fn <- paste0(label,"-",i,"_", who, ".csv")
#outdir <- "~/Desktop/hSC_testing/outdir"
#simdir <- "~/Desktop/hSC_testing/simdir"
outdir <- "/mnt/research/TIMBER/Ash/OUT"
simdir <- system("echo $TMPDIR", intern = TRUE)

rownames(popmap) <- popmap[,1]
table(popmap[gsub("fp","",names(imputed)),2])
imputed.pruned=imputed[,-which(gsub("fp","",names(imputed))%in%popmap[popmap$abbrev=="Michigan","id"])]
imputed.pruned=imputed.pruned[,-which(gsub("fp","",names(imputed.pruned))%in%popmap[popmap$abbrev=="UNK","id"])]
imputed.pruned=imputed.pruned[,-which(gsub("fp","",names(imputed.pruned))%in%popmap[popmap$abbrev=="MO1","id"])]
imputed.pruned=imputed.pruned[,-which(gsub("fp","",names(imputed.pruned))%in%popmap[popmap$abbrev=="ON1","id"])]
imputed.pruned=imputed.pruned[,-which(gsub("fp","",names(imputed.pruned))%in%popmap[popmap$abbrev=="VA1","id"])]
imputed.pruned=imputed.pruned[,-which(gsub("fp","",names(imputed.pruned))%in%popmap[popmap$abbrev=="MB1","id"])]
removes <- c()
popids <- popmap[gsub("fp","",names(imputed.pruned)),2]
table(popids)
for (a in unique(popids))
{
  if (sum(popids==a)>14)
  {
    removes <- c(removes,sample(which(popids==a),1))
  }
}
imputed.pruned <- imputed.pruned[,-1*removes]

poptbl <- table(popmap[gsub("fp","",names(imputed.pruned)),2])

samppts <- pts[pts$abbrev %in% names(poptbl),]

if ((!exists("icenolakesland")))
{
  ##this should produce a landscape with (x,y) _square_ cells that also have
  ##21empirical samples in separate grid cells (otherwise need to figure out something else)
  ## ashland is a stored R object as well
  
  ##read in the correct raster stack
  rs <- stack("study_region_daltonIceMask_noLakes_linearIceSheetInterpolation.tif")
  e <- extent(rs)
  corners <- (matrix(c( e[1], e[4],
                        e[1], e[3],
                        e[2], e[3],
                        e[2],e[4]),ncol=2,byrow=T))
  colnames(corners) <- c("x","y")
  rownames(corners) <- c("ul","ll","lr","ur")
  
  icenolakes <- as.array(1-rs) #really slow! thats one reason these layers get stored
  
  icenolakesland <- def_grid_pred(pred=icenolakes,samppts=samppts,
                                  init.ext=c(45,65),
                                  keep.thresh=0.05,corners=corners)
}

if (!exists("icelakesland"))
{
  rs <- stack("study_region_daltonIceMask_lakesMasked_linearIceSheetInterpolation.tif")
  e <- extent(rs)
  corners <- (matrix(c( e[1], e[4],
                        e[1], e[3],
                        e[2], e[3],
                        e[2],e[4]),ncol=2,byrow=T))
  colnames(corners) <- c("x","y")
  rownames(corners) <- c("ul","ll","lr","ur")
  
  icelakes <- as.array(1-rs) #really slow! thats one reason these layers get stored
  
  icelakesland <- def_grid_pred(pred=icelakes,samppts=samppts,
                                init.ext=c(45,65),
                                keep.thresh=0.01,corners=corners)
}

landscape <- icelakesland

if (!uniqueSampled(landscape))
{
  stop("The landscape you are using is combining multiple sampled populations into a single raster cell")
}



###seed is based on time in seconds and the number of characters in the library path
###
###
repl <- 1
while(repl <= nreps) {
  sec=as.numeric(Sys.time())-1500000000
  lp= as.numeric(as.character(nchar(paste(.libPaths(), collapse = " "))))
  slp <- as.integer(floor(sec*lp))
  
  set.seed(as.integer(sec))
  
  if(file.exists("Ash_priors.csv")) {
    parms <- drawParms(control = "Ash_priors.csv")
  } else {
    parms <- drawParms(control = system.file("extdata/csv","priors.csv",package="holoSimCell"))
  }
  

  parms$refs <- sample(c("PA","TX","GA","ALL"), 1, replace = FALSE)
  
  if(parms$refs == "PA") {
    refpops <- c(1301, 1302, 1300, 1345, 1257)
    #refpops <- 1301
  } else if(parms$refs == "TX") {
    refpops <- c(586, 587, 585, 630, 542)
    #refpops <- 586
  } else if(parms$refs == "GA") {
    refpops <- c(638, 639, 637, 682, 594)
    #refpops <- 638
  } else if(parms$refs == "ALL") {
    refpops <- c(1301, 1302, 1300, 1345, 1257,
                 586, 587, 585, 630, 542,
                 638, 639, 637, 682, 594)
    #refpops <- c(1301, 587, 638)
  }
  
  #Forward simulation
  ph = getpophist2.cells(hab_suit=landscape,
                         refs=refpops,  #set at cell 540 right now 
                         refsz=parms$found_Ne,
                         mix=parms$mix,  #note how small.
                         shortscale=parms$shortscale,  # scale parameter of weibull with shape below
                         shortshape=parms$shortshape, #weibull shape
                         longmean=parms$longmean,  # mean of normal with sd = longmean
                         sz=parms$sz, #size of a cell (same units as longmean and shortscale)
                         K = parms$Ne) #maximum population size in a grid cell, scaled with hab_suit from landscape object
  
  if (!testPophist(ph,landscape))
  {
    print("here is where we could do something about non-colonized sample pops")
  }
  
  #Cell aggregation for coalescent
  gmap=make.gmap(ph$pophist,
                 xnum=2, #number of cells to aggregate in x-direction
                 ynum=2) #number of aggregate in the y-direction
  
  if (doesGmapCombine(gmap,landscape))
  {
    stop("Need to look at the resolutions because this gmap combines sampled populations")
  }
  
  ph2 <- pophist.aggregate(ph,gmap=gmap)
  for(x in which(ph2$coalhist$time == 0)) {
    ph2$coalhist$src[x] <- gmap$gpop[gmap$pop == ph2$coalhist$src[x]]
  }
  ph2$coalhist <- ph2$coalhist[!duplicated(ph2$coalhist),]
  ph2$coalhist <- ph2$coalhist[-which(ph2$coalhist$src %in% gmap$gpop[gmap$pop %in% refpops] & !is.na(ph2$coalhist$snk)),]  #Removing duplicated rows for refugia
  
  #Parameters specific to coalescent model
  loc_parms <- data.frame(marker = "snp",
                          nloci = parms$nloci,           
                          seq_length = parms$seq_length,
                          mu = parms$mu)
  
  preLGMparms <- data.frame(preLGM_t = parms$preLGM_t/parms$G,		#Time / GenTime
                            preLGM_Ne = parms$preLGM_Ne,
                            ref_Ne = parms$ref_Ne)
  
  parms_out <- as.data.frame(c(ph$struct[which(!names(ph$struct) %in% c(names(parms), names(ph$struct)[grep("refs", names(ph$struct))]))], parms))
  
  #With smaller K, some populations have very very low N at the end of the simulation
  #In those cases, we need to inflate N a bit for the coalescent simulation
  ph2$Nvecs[ph2$Nvecs[,702] > 0 & ph2$Nvecs[,702] < 1,702] <- 1
  
  #Run the coalescent simulation
  setwd(simdir) 
  out <- NULL
  out <- tryCatch({runFSC_step_agg3(ph = ph2,				#A new pophist object - (pophist, Nvecs, tmat, struct, hab_suit, coalhist)
                          l = landscape, 			#A new landscape object - (details, occupied, empty, sampled, hab_suit, sumrast, samplocsrast, samplocs)
                          sample_n = 14,		#Number of sampled individuals per population
                          preLGMparms = preLGMparms,		#This has parms for the refuge, preLGM size and timing
                          label = paste0(label,"-",repl),			#Label for FSC simulation files
                          delete_files = TRUE,	#Logical - clear out .par, .arp, and other FSC outputs?
                          num_cores = 1,			#Number of processors to use for FSC
                          exec = "fsc26",			#Executable for FSC (needs to be in a folder in the system $PATH)
                          loc_parms = loc_parms,		#Vector of locus parameters
                          found_Ne = parms$found_Ne,			#Founding population size, required for STEP change model		
                          gmap = gmap,              #Mapping the original population onto aggregated grid
                          MAF = 0.01,                #Minor allele frequency threshold, loci with minor allele frequencies below this value are excluded from sim
                          maxloc = 50000           #Maximum number of marker loci to attempt in a fastsimcoal simulation
  )}, error = function(err) {
    print(err)
    return(NULL)
  })
  
  #Calculate summary statistics
  if(!is.null(out)) {
    popDF <- makePopdf(landscape,"cell")
    stats <- holoStats(out, popDF, cores = 1)
    
    #Calculate maximum biotic velocity achieved during simulation
    BVmax <- max(bioticVelocity(ph, metrics = "centroid")$centroidVelocity)
    
    #Combine parameters and sumstats into one vector
    all_out <- c(date = date(), node=i, rep=repl, parms_out, BVmax=BVmax, stats)
    
    #Write output
    setwd(outdir)
    if(!file.exists(fn)) {
      write.table(all_out, fn, sep = ",", quote = FALSE, row.names = FALSE)
    } else {
      write.table(all_out, fn, quote = FALSE, row.names = FALSE, sep=",", append = TRUE, col.names = FALSE)
    }
    
    rm(all_out)
    
    repl <- repl+1
  }
  
}
