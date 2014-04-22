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
## mean monthly diurnal temperature range ####
url.dtr <- "http://www.cru.uea.ac.uk/cru/data/hrg/tmc/grid_10min_dtr.dat.gz" 
file.dtr <- "Data/CRU_dtr.gz"
download.file(url.dtr, destfile = file.dtr, mode = "wb")
dtr <- read.table('Data/CRU_dtr.gz')
xy <- dtr[, c(2, 1)]
dtr <- dtr[, c(-1, -2)]

## mean monthly temperature ####
url.tmp <- "http://www.cru.uea.ac.uk/cru/data/hrg/tmc/grid_10min_tmp.dat.gz" 
file.tmp <- "Data/CRU_tmp.gz"
download.file(url.tmp, destfile = file.tmp, mode = "wb")
tmp <- read.table('Data/CRU_tmp.gz')
tmp <- tmp[, c(-1, -2)]

## mean monthly precipitation #####
url.pre <- "http://www.cru.uea.ac.uk/cru/data/hrg/tmc/grid_10min_pre.dat.gz" 
file.pre <- "Data/CRU_pre.gz"
download.file(url.pre, destfile = file.pre, mode = "wb")
pre <- read.table('Data/CRU_pre.gz')
pre <- pre[, c(-1, -2)]

##### column names and later layer names for raster stack objects ####
months <- c('jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec')
names(dtr) <- months

#### calculate Tmax and Tmin from tmp and dtr (see: http://www.cru.uea.ac.uk/cru/data/hrg/tmc/readme.txt) #####
tmx <- tmp+(0.5*dtr)
tmn <- tmp-(0.5*dtr)

##### GIS work ####
## set up a raster object to use as the basis for converting CRU data to raster objects at 10 arc minute resolution ####
wrld <- raster(nrows = 900, ncols = 2160)

## Take the values and rasterize them, cell sizes are not regular, cannot use rasterFromXYZ() ####
## create.stack takes pre, tmn and tmx and creates a raster object stack of 12 month data
create.stack <- function(wvar, xy, wrld){
  for(i in 1:12){ 
    x <- rasterize(x = xy, y = wrld, field = wvar[, i], fun = mean)
    if(i == 1){y <- x} else y <- stack(y, x)
  }
  names(y) <- months
  return(y)
  rm(x)
}

pre.stack <- create.stack(pre, xy, wrld)
tmn.stack <- create.stack(tmn, xy, wrld)
tmx.stack <- create.stack(tmx, xy, wrld)

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

#### Download MIRCA 2000 Maximum Harvested Area for Potato (Crop #10) to use as a mask ####
url.pot <- "ftp://ftp.rz.uni-frankfurt.de/pub/uni-frankfurt/physische_geographie/hydrologie/public/data/MIRCA2000/harvested_area_grids/ANNUAL_AREA_HARVESTED_RFC_CROP10_HA.ASC.gz"
file.pot <- "Data/ANNUAL_AREA_HARVESTED_RFC_CROP10_HA.ASC.gz"
download.file(url.pot, destfile = file.pot, mode = "wb")
untar("Data/ANNUAL_AREA_HARVESTED_RFC_CROP10_HA.ASC.gz")
pot <- raster("Data/ANNUAL_AREA_HARVESTED_RFC_CROP10_HA.ASC.gz")
xy <- dtr[, c(2, 1)]
dtr <- dtr[, c(-1, -2)]


rfp <- raster(paste('tmp/poplant_a2', gcm, '_', timeslice, '_PRF.grd', sep = '')) # rainfed potato
rfp <- reclassify(rfp, c(0, 0, NA), include.lowest = TRUE) # set values of 0 equal to NA

irp <- raster(paste('tmp/poplant_a2', gcm, '_', timeslice, '_PIR.grd', sep = '')) # irrigated potato
irp <- reclassify(irp, c(0, 0, NA), include.lowest = TRUE) # set values of 0 equal to NA

comb <- cover(rfp, irp)
comb <- reclassify(comb, c(0, 0, NA), include.lowest = TRUE)

poplant.mask <- raster('data/MIRCA_Poplant.grd') # Mask to remove non-potato areas
poplant <- mask(comb, poplant.mask) # mask the non-potato growing areas from raster

writeRaster(poplant, filename = paste('Cache/, '.grd', sep = ''), overwrite = TRUE)

# eos

#eos