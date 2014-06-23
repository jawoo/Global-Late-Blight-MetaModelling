##############################################################################
# title         : A2 Scenario Potato Growing Seasons.R;
# purpose       : create global potato growing seasons using Ecocrop with CRU CL 2.0 data;
# producer      : prepared by R. Hijmans and A. Sparks;
# last update   : in Los Baños, Philippines, June 2014;
# inputs        : CRU CL2.0 Climate data;
# outputs       : PotatoPlant_CRUCL2.0.grd, CRUCL2.0_PRF.grd, CRUCL2.0_PIR.grd;
# remarks 1     : ;
# Licence:      : GPL2;
##############################################################################

#### Libraries ####
library(raster)
library(dismo)
##### End Libraries ####

#### Load functions ####
source("Functions/run_ecocrop.R")
#### End Functions ####

#### Begin data import ####
## Tempfile for download of FAO data
tf <- tempfile()

## Begin download from Figshare
A2.pre <- download.file("")
A2.tmn <- download.file("")
A2.tmp <- download.file("http://files.figshare.com/1545357/A2_Average_Temperature.zip", tf)
A2.tmx <- download.file("")

source("Functions/DownloadMIRCA.R") # Script will download and unzip MIRCA data or simply load if available in /Data
#### End data import ####

## Function to sort out the different time-slices
pre.stack <- 
tmn.stack <- 
tmp.stack <- 
tmx.stack <- 

#### Mask the CRU CL2.0 stacks with MIRCA to reduce the run time of EcoCrop ####
# Also, removes areas where potato is not grown. EcoCrop will predict potato growth nearly anywhere with irrigation
pre.stack <- mask(pre.stack, MIRCA)
tmn.stack <- mask(tmn.stack, MIRCA)
tmx.stack <- mask(tmx.stack, MIRCA)
tmp.stack <- mask(tmp.stack, MIRCA)

#### run ECOCROP model on raster stack of pre, tmp, tmn and tmx #####
prf <- run.ecocrop(pot, tmn.stack, tmx.stack, tmp.stack, pre.stack, 
                   rainfed = TRUE, 
                   filename = "Cache/Planting Seasons/CRUCL2.0_PRF.tif", 
                   format = "GTiff", dataType = "INT2S", 
                   options = c("COMPRESS=LZW"), 
                   NAFlag = -9999,
                   overwrite = TRUE) # Rainfed potato

pir <- run.ecocrop(pot, tmn.stack, tmx.stack, tmp.stack, pre.stack, 
                   rainfed = FALSE, 
                   filename = "Cache/Planting Seasons/CRUCL2.0_PIR.tif",
                   format = "GTiff", dataType = "INT2S", 
                   options = c("COMPRESS=LZW"), 
                   NAFlag = -9999,
                   overwrite = TRUE) # Irrigated potato

# Read raster objects of predicted planting dates from disk
poplant.prf <- raster("Cache/Planting Seasons/CRUCL2.0_PRF.tif") # rainfed potato planting date raster
poplant.prf <- reclassify(poplant.prf, c(0, 0, NA), include.lowest = TRUE) # set values of 0 equal to NA
names(poplant.prf) <- "Ecocrop Rainfed Planting Dates for 1975"
writeRaster(poplant.prf, "Cache/Planting Seasons/CRUCL2.0_PRF.tif",
            format = "GTiff", dataType = "INT2S", 
            options = c("COMPRESS=LZW"), 
            NAFlag = -9999,
            overwrite = TRUE)

poplant.pir <- raster("Cache/Planting Seasons/CRUCL2.0_PIR.tif") # irrigated potato planting date raster
poplant.pir <- reclassify(poplant.pir, c(0, 0, NA), include.lowest = TRUE) # set values of 0 equal to NA
names(poplant.pir) <- "Ecocrop Irrigated Planting Dates for 1975"
writeRaster(poplant.pir, "Cache/Planting Seasons/CRUCL2.0_PIR.tif",
            format = "GTiff", dataType = "INT2S", 
            options = c("COMPRESS=LZW"), 
            NAFlag = -9999,
            overwrite = TRUE)

#### Take both rasters, combine them, use irrigated potato where rainfed is NA ####
comb <- cover(poplant.prf, poplant.pir)  # use rainfed, except where NA
comb <- reclassify(comb, c(0, 0, NA), include.lowest = TRUE) # set values of 0 equal to NA

#### Do some filling of NAs with modal neighborhood values ####
com <- focal(comb, fun = modal, na.rm = TRUE, w = matrix(1, 3, 3), NAonly = TRUE) # take neighborhood values where NA
com <- focal(com, fun = modal, na.rm = TRUE, w = matrix(1, 3, 3), NAonly = TRUE) # once again

#### Finally, clean up the planting date map again with MIRCA to remove non-potato growing areas, then save to disk ####
com <- mask(com, MIRCA)
names(com) <- "Ecocrop Planting Dates for 1975"
writeRaster(com, "Cache/Planting Seasons/CRUCL2.0_Combined.tif",
            format = "GTiff", dataType = "INT2S", 
            options = c("COMPRESS=LZW"), 
            NAFlag = -9999,
            overwrite = TRUE)

#### Plot the predicted planting dates ####
plot(com, main = "Potato planting dates as predicted by EcoCrop", xlab = "Longitude", ylab = "Latitude",
     legend.args = list(text = "Month", side = 3, font = 2, line = 1, cex = 0.8))

#eos
