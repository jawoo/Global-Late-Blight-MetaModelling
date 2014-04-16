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
url.dtr <- "http://www.cru.uea.ac.uk/cru/data/hrg/tmc/grid_10min_dtr.dat.gz" # mean diurnal temperature range
file.dtr <- "data/CRU_dtr.gz"
download.file(url.dtr, destfile = file.dtr, mode = "wb")
dtr <- read.table('data/CRU_dtr.gz')

col.names <- c('lat', 'lon', 'jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec')
names(dtr) <- col.names



# Set up a raster object to use as the basis for converting CRU data to raster objects
wrld <- raster(nrows = 900, ncols = 2160)


points <- dtr[, c(2, 1)]
jan.tmin <- rasterize(x = points, y = wrld, field = dtr[, 3], fun = mean)


#eos