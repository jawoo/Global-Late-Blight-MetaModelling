##############################################################################
# title         : Ecocrop CRU CL2.0 Potato Growing Seasons.R;
# purpose       : create global potato growing seasons using Ecocrop with CRU CL 2.0 data;
# producer      : prepared by R. Hijmans and A. Sparks;
# last update   : in Los Baños, April 2014;
# inputs        : CRU CL2.0 Climate data;
# outputs       : PotatoPlant_CRUCL2.0.grd;
# remarks 1     : Download the CRU CL 2.0 Data here: http://www.cru.uea.ac.uk/cru/data/hrg/timm/grid/CRU_TS_2_0.html;
##############################################################################

#### Libraries ####
library(raster)
library(dismo)
##### End Libraries ####

#### Load functions ####
source ('../Functions/ecospat.R')
#### End Functions ####

##### Download and read CRU data files ####
## create a temp file and directory for downloading files
tf <- tempfile()
## mean monthly diurnal temperature range ####
download.file("http://www.cru.uea.ac.uk/cru/data/hrg/tmc/grid_10min_dtr.dat.gz", tf)
dtr <- read.table(temp)
xy <- dtr[, c(2, 1)]
dtr <- dtr[, c(-1, -2)]
dtr <- dtr/10

## mean monthly temperature ####
download.file("http://www.cru.uea.ac.uk/cru/data/hrg/tmc/grid_10min_tmp.dat.gz", tf)
tmp <- read.table(temp)
tmp <- tmp[, c(-1, -2)]
tmp <- tmp/10

## mean monthly precipitation #####
download.file("http://www.cru.uea.ac.uk/cru/data/hrg/tmc/grid_10min_pre.dat.gz", tf)
pre <- read.table(temp)
pre <- pre[, c(-1, -2)]
pre <- pre/10

##### column names and later layer names for raster stack objects ####
months <- c('jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec')
names(dtr) <- months

#### calculate Tmax and Tmin from tmp and dtr (see: http://www.cru.uea.ac.uk/cru/data/hrg/tmc/readme.txt) #####
tmx <- tmp+(0.5*dtr)
tmn <- tmp-(0.5*dtr)

##### GIS work ####
## set up a raster object to use as the basis for converting CRU data to raster objects at 10 arc minute resolution ####
wrld <- raster(nrows = 900, ncols = 2160, ymn = -60, ymx = 90, xmn = -180, xmx = 180)

## Take the values and rasterize them, cell sizes are not regular, cannot use rasterFromXYZ() ####
## create.stack takes pre, tmn and tmx and creates a raster object stack of 12 month data
## NOTE: this is time and procesor intensive
create.stack <- function(wvar, xy, wrld){ 
    x <- wrld
    cells <- cellFromXY(r, xy)
    for(i in 1:12){
      x[cells] <- wvar[, i]/10
      if(i == 1){y <- x} else y <- stack(y, x)
  }
  names(y) <- months
  return(y)
  rm(x)
}

pre.stack <- create.stack(pre, xy, wrld)
tmn.stack <- create.stack(tmn, xy, wrld)
tmx.stack <- create.stack(tmx, xy, wrld)

#### Download MIRCA 2000 Maximum Harvested Area for Potato (Crop #10) to use as a mask ####
download.file( file.path , tf , mode = "wb" )
files.data <- unzip( tf , exdir = td)

url <- "ftp://ftp.rz.uni-frankfurt.de/pub/uni-frankfurt/physische_geographie/hydrologie/public/data/MIRCA2000/harvested_area_grids/ANNUAL_AREA_HARVESTED_RFC_CROP10_HA.ASC.gz"
download.file(url, "Data/ANNUAL_AREA_HARVESTED_RFC_CROP10_HA.ASC.gz")
system("7z e Data/ANNUAL_AREA_HARVESTED_RFC_CROP10_HA.ASC.gz") #I don't like to call 7zip here, but there's something odd with the file and gnutar (thus untar) will not work
MIRCA <- raster("Data/ANNUAL_AREA_HARVESTED_RFC_CROP10_HA.ASC")
MIRCA <- aggregate(MIRCA, 2) # Aggregate MIRCA up to 10sec data to match CRU CL2.0
MIRCA[MIRCA==0] <- NA # Set 0 values to NA to use this as a mask
MIRCA <- crop(MIRCA, pre.stack)

#### Mask the CRU CL2.0 stacks with MIRCA to reduce the run time of ECOCROP ####
pre.stack <- mask(pre.stack, MIRCA)
tmn.stack <- mask(tmn.stack, MIRCA)
tmx.stack <- mask(tmx.stack, MIRCA)

#### run ECOCROP model on raster stack of precipitation, tmin and tmax #####
pot       <- getCrop('potato')
pot@RMIN  <- 125
pot@ROPMN <- 250
pot@ROPMX <- 350
pot@TMIN  <- 7
pot@TOPMX <- 20
pot@GMIN  <- pot@GMAX <- 100

prf <- ecospat('potato', tmn, tmx, tmp, pre, rainfed = TRUE, filename = 'Cache/Planting Seasons/CRUCL2.0_PRF.grd', overwrite = TRUE) # Rainfed potato
pir <- ecospat('potato', tmn, tmx, tmp, pre, rainfed = FALSE, filename = 'Cache/Planting Seasons/CRUCL2.0_PIR.grd', overwrite = TRUE) # Irrigated potato

rfp <- raster(paste('tmp/poplant_a2', gcm, '_', timeslice, '_PRF.grd', sep = '')) # rainfed potato
rfp <- reclassify(rfp, c(0, 0, NA), include.lowest = TRUE) # set values of 0 equal to NA

irp <- raster(paste('tmp/poplant_a2', gcm, '_', timeslice, '_PIR.grd', sep = '')) # irrigated potato
irp <- reclassify(irp, c(0, 0, NA), include.lowest = TRUE) # set values of 0 equal to NA

comb <- cover(rfp, irp)
comb <- reclassify(comb, c(0, 0, NA), include.lowest = TRUE)

poplant.mask <- raster('data/MIRCA_Poplant.grd') # Mask to remove non-potato areas
poplant <- mask(comb, poplant.mask) # mask the non-potato growing areas from raster

writeRaster(poplant, filename = paste('Cache/25APR14, '.grd', sep = ''), overwrite = TRUE)

#eos