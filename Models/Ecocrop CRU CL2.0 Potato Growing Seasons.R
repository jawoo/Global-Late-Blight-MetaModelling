##############################################################################
# title         : Ecocrop CRU CL2.0 Potato Growing Seasons.R;
# purpose       : create global potato growing seasons using Ecocrop with CRU CL 2.0 data;
# producer      : prepared by R. Hijmans and A. Sparks;
# last update   : in Los Banos, IRRI, March 2014;
# inputs        : CRU CL2.0 Climate data;
# outputs       : PotatoPlant_CRUCL2.0.grd;
# remarks 1     : Download the CRU CL 2.0 Data here: http://www.cru.uea.ac.uk/cru/data/hrg/timm/grid/CRU_TS_2_0.html;
##############################################################################

library(raster)
library(dismo)

# Download and read CRU data files
# mean monthly diurnal temperature range
url.dtr <- "http://www.cru.uea.ac.uk/cru/data/hrg/tmc/grid_10min_dtr.dat.gz" 
file.dtr <- "Data/CRU_dtr.gz"
download.file(url.dtr, destfile = file.dtr, mode = "wb")
dtr <- read.table('data/CRU_dtr.gz')

# mean monthly temperature
url.tmp <- "http://www.cru.uea.ac.uk/cru/data/hrg/tmc/grid_10min_tmp.dat.gz" 
file.tmp <- "Data/CRU_tmp.gz"
download.file(url.tmp, destfile = file.tmp, mode = "wb")
tmp <- read.table('data/CRU_tmp.gz')

# mean monthly temperature
url.pre <- "http://www.cru.uea.ac.uk/cru/data/hrg/tmc/grid_10min_pre.dat.gz" 
file.pre <- "Data/CRU_pre.gz"
download.file(url.pre, destfile = file.pre, mode = "wb")
pre <- read.table('data/CRU_pre.gz')

# column names apply to all three files
col.names <- c('lat', 'lon', 'jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec')
names(dtr) <- col.names
names(tmp) <- col.names
names(pre) <- col.names


# Set up a raster object to use as the basis for converting CRU data to raster objects at 10 arc minute resolution
wrld <- raster(nrows = 900, ncols = 2160)

points <- dtr[, c(2, 1)] # Take lon, lat from the data file
jan.tmin <- rasterFromXYX(x = points, y = wrld, field = dtr[, 3], fun = mean) # Take the values and rasterize them, cell sizes are not regular, cannot use rasterFromXYZ()

#eos