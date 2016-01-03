##############################################################################
# title         : 04 - EcoCrop A2 Scenario Potato Growing Seasons.R;
# purpose       : create global potato growing seasons using Ecocrop with A2 
#               : climate emission scenario data;
# producer      : prepared by R. Hijmans and A. Sparks;
# last update   : in Los Baños, Philippines, Jan 2016;
# inputs        : A2 Ensemble Model Climate data;
# outputs       : PotatoPlant_A2_2050.grd, A2_2050_PRF.grd, A2_2050_PIR.grd;
# remarks 1     : ;
# Licence:      : GPL2;
##############################################################################

# Libraries --------------------------------------------------------------------
library(raster)
library(dismo)

# Functions --------------------------------------------------------------------
source("Functions/run_ecocrop.R")
source("Functions/Get_A2_Data.R")
source("Functions/Get_MIRCA.R")

# Load data --------------------------------------------------------------------
if(file.exists("Data/MIRCA_Poplant.tif") == TRUE){
  MIRCA <- raster("Data/MIRCA_Poplant.tif") # The file already exists and we save time by just reading into R
} else download.MIRCA() # function will download and unzip MIRCA data

download_A2_data() # download A2 climate data files from Figshare. This will take a while.

# sort out the different time-slices, most analysis was with 2050 only so it is the only one featured here. Feel free to use the other two time-slices in the same fashion
pre_stack <- stack(list.files(path = "Data/A2 Precipitation", 
                              pattern = "a2pr50[[:digit:]]{2}.tif", 
                              full.names = TRUE))/10
tmn_stack <- stack(list.files(path = "Data/A2 Minimum Temperature", 
                              pattern = "a2tn50[[:digit:]]{2}.tif", 
                              full.names = TRUE))/10 
tmx_stack <- stack(list.files(path = "Data/A2 Maximum Temperature", 
                              pattern = "a2tx50[[:digit:]]{2}.tif", 
                              full.names = TRUE))/10
tmp_stack <- stack(list.files(path = "Data/A2 Average Temperature", 
                              pattern = "a2tmp50[[:digit:]]{2}.tif", 
                              full.names = TRUE))/10

# Removes areas where potato is not grown. EcoCrop will predict potato growth nearly anywhere with irrigation
pre_stack <- mask(pre_stack, MIRCA)
tmn_stack <- mask(tmn_stack, MIRCA)
tmx_stack <- mask(tmx_stack, MIRCA)
tmp_stack <- mask(tmp_stack, MIRCA)

# Run ECOCROP model on raster stack of pre, tmp, tmn and tmx -------------------
prf <- ecocrop(pot, tmn_stack, tmx_stack, tmp_stack, pre_stack, 
               rainfed = TRUE, 
               filename = "Cache/Planting Seasons/A2_2050_PRF.tif", 
               format = "GTiff", dataType = "INT2S", 
               options = c("COMPRESS=LZW"), 
               overwrite = TRUE)

pir <- ecocrop(pot, tmn_stack, tmx_stack, tmp_stack, pre_stack, 
               rainfed = FALSE, 
               filename = "Cache/Planting Seasons/A2_2050_PIR.tif",
               format = "GTiff", dataType = "INT2S", 
               options = c("COMPRESS=LZW"), 
               overwrite = TRUE)

# rainfed potato planting date raster
poplant_prf <- raster("Cache/Planting Seasons/A2_2050_PRF.tif")
poplant_prf <- reclassify(poplant_prf, c(0, 0, NA), include.lowest = TRUE)
names(poplant_prf) <- "Ecocrop Rainfed Planting Dates for 2050"
writeRaster(poplant_prf, "Cache/Planting Seasons/A2_2050_PRF.tif",
            format = "GTiff", dataType = "INT2S", 
            options = c("COMPRESS=LZW"), 
            overwrite = TRUE)

# irrigated potato planting date raster
poplant_pir <- raster("Cache/Planting Seasons/A2_2050_PIR.tif")
poplant_pir <- reclassify(poplant_pir, c(0, 0, NA), include.lowest = TRUE)
names(poplant_pir) <- "Ecocrop Irrigated Planting Dates for 2050"
writeRaster(poplant_pir, "Cache/Planting Seasons/A2_2050_PIR.tif",
            format = "GTiff", dataType = "INT2S", 
            options = c("COMPRESS=LZW"),
            overwrite = TRUE)

# Take both rasters, combine them, use irrigated potato where rainfed is NA
comb <- cover(poplant_prf, poplant_pir)
comb <- reclassify(comb, c(0, 0, NA), include.lowest = TRUE)

# Do some filling of NAs with modal neighborhood values, 2X (not a mistake)
com <- focal(comb, fun = modal, na.rm = TRUE, w = matrix(1, 3, 3), NAonly = TRUE)
com <- focal(com, fun = modal, na.rm = TRUE, w = matrix(1, 3, 3), NAonly = TRUE)

# Finally, clean up the planting date map again with MIRCA to remove non-potato growing areas
com <- mask(com, MIRCA)
names(com) <- "Ecocrop Planting Dates for 2050"
writeRaster(com, "Cache/Planting Seasons/A2_2050_Combined.tif",
            format = "GTiff", dataType = "INT2S", 
            options = c("COMPRESS=LZW"), 
            overwrite = TRUE)

# Data visualisation -----------------------------------------------------------
plot(com, main = "A2 Potato planting dates as predicted by EcoCrop", 
     xlab = "Longitude", ylab = "Latitude",
     legend.args = list(text = "Month", side = 3, 
                        font = 2, line = 1, cex = 0.8))

# eos
