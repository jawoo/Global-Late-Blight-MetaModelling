##############################################################################
# title         : EcoCrop A2 Scenario Potato Growing Seasons.R;
# purpose       : create global potato growing seasons using Ecocrop with A2 
#               : climate emission scenario data;
# producer      : prepared by R. Hijmans and A. Sparks;
# last update   : in Los Baños, Philippines, June 2014;
# inputs        : A2 Ensemble Model Climate data;
# outputs       : PotatoPlant_A2_2050.grd, A2_2050_PRF.grd, A2_2050_PIR.grd;
# remarks 1     : ;
# Licence:      : GPL2;
##############################################################################

#### Libraries ####
library(raster)
library(dismo)
##### End Libraries ####

#### Load functions ####
source("Functions/run_ecocrop.R")
source("Functions/Get_A2_Data.R")
source("Functions/Download_MIRCA.R")
#### End Functions ####

#### Begin data import ####
if(file.exists("Data/MIRCA_Poplant.grd") != TRUE){
  download.MIRCA() # function will download and unzip MIRCA data or simply load if available in Data
} else { # The file already exists and we save time by just reading into R
  MIRCA <- raster("Data/MIRCA_Poplant.grd")
}

download.A2.data() # download A2 climate data files from Figshare. This will take a while.

## sort out the different time-slices, most analysis was with 2050 only so it is the only one featured here. Feel free to use the other two time-slices in the same fashion
pre.stack <- stack(list.files(path = "Data/A2_Precipitation", pattern = "a2pr50[[:digit:]]{2}.tif", full.names = TRUE))/10 # Load precipitation tif files for 2050 time-slice only, change "50" to "20" or "90" for other time slice
tmn.stack <- stack(list.files(path = "Data/A2 Minimum Temperature", pattern = "a2tn50[[:digit:]]{2}.tif", full.names = TRUE))/10 # Load minimum temperature tif files for 2050 time-slice only, change "50" to "20" or "90" for other time slice
tmx.stack <- stack(list.files(path = "Data/A2 Maximum Temperature", pattern = "a2tx50[[:digit:]]{2}.tif", full.names = TRUE))/10 # Load maximum temperature tif files for 2050 time-slice only, change "50" to "20" or "90" for other time slice
tmp.stack <- stack(list.files(path = "Data/A2 Average Temperature", pattern = "a2tmp50[[:digit:]]{2}.tif", full.names = TRUE))/10 # Load average temperature tif files for 2050 time-slice only, change "50" to "20" or "90" for other time slice

#### End data import ####

#### Mask the A2 stacks with MIRCA to reduce the run time of EcoCrop ####
# Also, removes areas where potato is not grown. EcoCrop will predict potato growth nearly anywhere with irrigation
pre.stack <- mask(pre.stack, MIRCA)
tmn.stack <- mask(tmn.stack, MIRCA)
tmx.stack <- mask(tmx.stack, MIRCA)
tmp.stack <- mask(tmp.stack, MIRCA)

#### End data masking ####

#### run ECOCROP model on raster stack of pre, tmp, tmn and tmx #####
prf <- run.ecocrop(pot, tmn.stack, tmx.stack, tmp.stack, pre.stack, 
                   rainfed = TRUE, 
                   filename = "Cache/Planting Seasons/A2_2050_PRF.tif", 
                   format = "GTiff", dataType = "INT2S", 
                   options = c("COMPRESS=LZW"), 
                   overwrite = TRUE) # Rainfed potato

pir <- run.ecocrop(pot, tmn.stack, tmx.stack, tmp.stack, pre.stack, 
                   rainfed = FALSE, 
                   filename = "Cache/Planting Seasons/A2_2050_PIR.tif",
                   format = "GTiff", dataType = "INT2S", 
                   options = c("COMPRESS=LZW"), 
                   overwrite = TRUE) # Irrigated potato

# Read raster objects of predicted planting dates from disk
poplant.prf <- raster("Cache/Planting Seasons/A2_2050_PRF.tif") # rainfed potato planting date raster
poplant.prf <- reclassify(poplant.prf, c(0, 0, NA), include.lowest = TRUE) # set values of 0 equal to NA
names(poplant.prf) <- "Ecocrop Rainfed Planting Dates for 2050"
writeRaster(poplant.prf, "Cache/Planting Seasons/A2_2050_PRF.tif",
            format = "GTiff", dataType = "INT2S", 
            options = c("COMPRESS=LZW"), 
            overwrite = TRUE)

poplant.pir <- raster("Cache/Planting Seasons/A2_2050_PIR.tif") # irrigated potato planting date raster
poplant.pir <- reclassify(poplant.pir, c(0, 0, NA), include.lowest = TRUE) # set values of 0 equal to NA
names(poplant.pir) <- "Ecocrop Irrigated Planting Dates for 2050"
writeRaster(poplant.pir, "Cache/Planting Seasons/A2_2050_PIR.tif",
            format = "GTiff", dataType = "INT2S", 
            options = c("COMPRESS=LZW"),
            overwrite = TRUE)

#### Take both rasters, combine them, use irrigated potato where rainfed is NA ####
comb <- cover(poplant.prf, poplant.pir)  # use rainfed, except where NA
comb <- reclassify(comb, c(0, 0, NA), include.lowest = TRUE) # set values of 0 equal to NA

#### Do some filling of NAs with modal neighborhood values ####
com <- focal(comb, fun = modal, na.rm = TRUE, w = matrix(1, 3, 3), NAonly = TRUE) # take neighborhood values where NA
com <- focal(com, fun = modal, na.rm = TRUE, w = matrix(1, 3, 3), NAonly = TRUE) # once again

#### Finally, clean up the planting date map again with MIRCA to remove non-potato growing areas, then save to disk ####
com <- mask(com, MIRCA)
names(com) <- "Ecocrop Planting Dates for 2050"
writeRaster(com, "Cache/Planting Seasons/A2_2050_Combined.tif",
            format = "GTiff", dataType = "INT2S", 
            options = c("COMPRESS=LZW"), 
            overwrite = TRUE)

#### Plot the predicted planting dates ####
plot(com, main = "Potato planting dates as predicted by EcoCrop", xlab = "Longitude", ylab = "Latitude",
     legend.args = list(text = "Month", side = 3, font = 2, line = 1, cex = 0.8))

#eos

