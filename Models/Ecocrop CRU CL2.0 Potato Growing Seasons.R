##############################################################################
# title         : Ecocrop CRU CL2.0 Potato Growing Seasons.R;
# purpose       : create global potato growing seasons using Ecocrop with CRU CL 2.0 data;
# producer      : prepared by R. Hijmans and A. Sparks;
# last update   : in Los Baños, Laguna, April 2014;
# inputs        : CRU CL2.0 Climate data;
# outputs       : PotatoPlant_CRUCL2.0.grd;
# remarks 1     : Download the CRU CL 2.0 Data here: http://www.cru.uea.ac.uk/cru/data/hrg/timm/grid/CRU_TS_2_0.html;
##############################################################################

#### Libraries ####
library(raster)
library(dismo)
##### End Libraries ####

#### Load functions ####
source ("Functions/ecospat.R")
#### End Functions ####

##### Download and read CRU data files ####
## create a temp file and directory for downloading files
tf <- tempfile()
## mean monthly diurnal temperature range ####
download.file("http://www.cru.uea.ac.uk/cru/data/hrg/tmc/grid_10min_dtr.dat.gz", tf)
dtr <- read.table(tf, header = FALSE, colClasses = "numeric", nrows = 566262) # use header, colClasses and nrows to speed input into R

## mean monthly temperature ####
download.file("http://www.cru.uea.ac.uk/cru/data/hrg/tmc/grid_10min_tmp.dat.gz", tf)
tmp <- read.table(tf, header = FALSE, colClasses = "numeric", nrows = 566262) # use header, colClasses and nrows to speed input into R

## mean monthly precipitation #####
download.file("http://www.cru.uea.ac.uk/cru/data/hrg/tmc/grid_10min_pre.dat.gz", tf)
pre <- read.table(tf, header = FALSE, colClasses = "numeric", nrows = 566268) # use header, colClasses and nrows to speed input into R
pre <- pre[, 1:14] # remove CV columns of precip from table

#### calculate tmax and tmin from tmp and dtr (see: http://www.cru.uea.ac.uk/cru/data/hrg/tmc/readme.txt) #####
tmx <- cbind(tmp[, 1:2], tmp[, c(3:14)]+(0.5*dtr[, c(3:14)])) # cbind xy data from tmp with new tmx data
tmn <- cbind(tmp[, 1:2], tmp[, c(3:14)]-(0.5*dtr[, c(3:14)])) # cbind xy data from tmp with new tmn data

##### column names and later layer names for raster stack objects ####
months <- c("jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec")

##### GIS work ####
## set up a raster object to use as the basis for converting CRU data to raster objects at 10 arc minute resolution ####
wrld <- raster(nrows = 900, ncols = 2160, ymn = -60, ymx = 90, xmn = -180, xmx = 180)

## Create raster objects using cellFromXY and generate a raster stack
## create.stack takes pre, tmp, tmn and tmx and creates a raster object stack of 12 month data
create.stack <- function(wvar, xy, wrld, months){ 
  x <- wrld
  cells <- cellFromXY(x, wvar[, c(2, 1)])
  for(i in 3:14){
    x[cells] <- wvar[, i]
    if(i == 3){y <- x} else y <- stack(y, x)
  }
  names(y) <- months
  return(y)
  rm(x)
}

pre.stack <- create.stack(pre, xy, wrld, months)
tmn.stack <- create.stack(tmn, xy, wrld, months)
tmx.stack <- create.stack(tmx, xy, wrld, months)
tmp.stack <- create.stack(tmp, xy, wrld, months)

#### Download MIRCA 2000 Maximum Harvested Area for Potato (Crop #10) to use as a mask ####
url <- "ftp://ftp.rz.uni-frankfurt.de/pub/uni-frankfurt/physische_geographie/hydrologie/public/data/MIRCA2000/harvested_area_grids/ANNUAL_AREA_HARVESTED_RFC_CROP10_HA.ASC.gz"
download.file(url, "Data/ANNUAL_AREA_HARVESTED_RFC_CROP10_HA.ASC.gz")
system("7z e Data/ANNUAL_AREA_HARVESTED_RFC_CROP10_HA.ASC.gz -oData") #I don"t like to call 7zip here, but there"s something odd with the file and gnutar (thus untar) will not work
MIRCA <- raster("Data/ANNUAL_AREA_HARVESTED_RFC_CROP10_HA.ASC")
MIRCA <- aggregate(MIRCA, 2) # Aggregate MIRCA up to 10sec data to match CRU CL2.0
MIRCA[MIRCA==0] <- NA # Set 0 values to NA to use this as a mask
MIRCA <- crop(MIRCA, pre.stack)

#### Mask the CRU CL2.0 stacks with MIRCA to reduce the run time of ECOCROP ####
pre.stack <- mask(pre.stack, MIRCA)
tmn.stack <- mask(tmn.stack, MIRCA)
tmx.stack <- mask(tmx.stack, MIRCA)
tmp.stack <- mask(tmp.stack, MIRCA)

#### run ECOCROP model on raster stack of pre, tmp, tmn and tmx #####
## set parameters
pot       <- getCrop("potato")
pot@RMIN  <- 125
pot@ROPMN <- 250
pot@ROPMX <- 350
pot@TMIN  <- 7
pot@TOPMX <- 20
pot@GMIN  <- pot@GMAX <- 100

## NOTE: These two lines are time intensive ##
prf <- ecospat(pot, tmn.stack, tmx.stack, tmp.stack, pre.stack, rainfed = TRUE, filename = "Cache/Planting Seasons/CRUCL2.0_PRF.grd", overwrite = TRUE) # Rainfed potato
pir <- ecospat(pot, tmn, tmx, tmp, pre, rainfed = FALSE, filename = "Cache/Planting Seasons/CRUCL2.0_PIR.grd", overwrite = TRUE) # Irrigated potato

# Read raster object of predicted planting dates from disk
rfp <- raster("Cache/Planting Seasons/CRUCL2.0_PRF.grd") # rainfed potato planting date raster
rfp <- reclassify(rfp, c(0, 0, NA), include.lowest = TRUE) # set values of 0 equal to NA

irp <- raster("Cache/Planting Seasons/CRUCL2.0_PIR.grd") # irrigated potato planting date raster
irp <- reclassify(irp, c(0, 0, NA), include.lowest = TRUE) # set values of 0 equal to NA

## Combine rainfed and irrigated potato planting dates, using irrigated values where rainfed not predicted by EcoCrop
## save raster object to disk for later use with SimCastMeta
comb <- cover(rfp, irp, filename = "Cache/CRU_CL20_Potato_Plant.grd", overwrite = TRUE))

#eos
