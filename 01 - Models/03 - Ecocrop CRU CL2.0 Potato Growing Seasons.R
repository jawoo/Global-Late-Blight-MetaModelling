##############################################################################
# title         : 03 - EcoCrop CRU CL2.0 Potato Growing Seasons.R;
# purpose       : create global potato growing seasons using Ecocrop with CRU CL 2.0 data;
# producer      : prepared by R. Hijmans and A. Sparks;
# last update   : in Los Baños, Philippines, Jan 2016;
# inputs        : CRU CL2.0 Climate data;
# outputs       : PotatoPlant_CRUCL2.0.grd, CRUCL2.0_PRF.grd, CRUCL2.0_PIR.grd;
# remarks 1     : ;
# Licence:      : GPL2;
##############################################################################

# Libraries --------------------------------------------------------------------
library(raster)
library(dismo)

# Load specialised functions ---------------------------------------------------
source("Functions/run_ecocrop.R")
source("Functions/Get_CRU_20_Data.R")
source("Functions/Get_MIRCA.R")
source("Functions/create_stack.R")

# Load data --------------------------------------------------------------------
CRU_data <- CRU_Growing_Season_DL()

if(!file.exists("Data/MIRCA_Poplant.tif")){
  download_MIRCA()
}
MIRCA <- raster("Data/MIRCA_Poplant.tif")

# Data manipulation ------------------------------------------------------------
pre_stack <- create_stack(CRU_data$pre)
tmn_stack <- create_stack(CRU_data$tmn)
tmp_stack <- create_stack(CRU_data$tmp)
tmx_stack <- create_stack(CRU_data$tmx)

# Mask the CRU CL2.0 stacks with MIRCA to reduce the run time of EcoCrop
# Also, removes areas where potato is not grown. EcoCrop will predict potato growth nearly anywhere with irrigation
pre_stack <- mask(pre_stack, MIRCA)
tmn_stack <- mask(tmn_stack, MIRCA)
tmx_stack <- mask(tmx_stack, MIRCA)
tmp_stack <- mask(tmp_stack, MIRCA)

# Run ECOCROP model on raster stack of pre, tmp, tmn and tmx -------------------
prf <- run_ecocrop(pot, tmn_stack, tmx_stack, tmp_stack, pre_stack, 
                   rainfed = TRUE, 
                   filename = "Cache/Planting Seasons/CRUCL2.0_PRF.tif", 
                   format = "GTiff", dataType = "INT2S", 
                   options = c("COMPRESS=LZW"), 
                   overwrite = TRUE)

pir <- run_ecocrop(pot, tmn_stack, tmx_stack, tmp_stack, pre_stack, 
                   rainfed = FALSE, 
                   filename = "Cache/Planting Seasons/CRUCL2.0_PIR.tif",
                   format = "GTiff", dataType = "INT2S", 
                   options = c("COMPRESS=LZW"), 
                   overwrite = TRUE)

# rainfed potato planting date raster
potplant_prf <- raster("Cache/Planting Seasons/CRUCL2.0_PRF.tif")
potplant_prf <- reclassify(potplant_prf, c(0, 0, NA), include.lowest = TRUE)
names(potplant_prf) <- "Ecocrop Rainfed Planting Dates for 1975"
writeRaster(potplant_prf, "Cache/Planting Seasons/CRUCL2.0_PRF.tif",
            format = "GTiff", dataType = "INT2S", 
            options = c("COMPRESS=LZW"), 
            overwrite = TRUE)

# irrigated potato planting date raster
poplant_pir <- raster("Cache/Planting Seasons/CRUCL2.0_PIR.tif")
poplant_pir <- reclassify(poplant_pir, c(0, 0, NA), include.lowest = TRUE)
names(poplant_pir) <- "Ecocrop Irrigated Planting Dates for 1975"
writeRaster(poplant_pir, "Cache/Planting Seasons/CRUCL2.0_PIR.tif",
            format = "GTiff", dataType = "INT2S", 
            options = c("COMPRESS=LZW"), 
            overwrite = TRUE)

# Take both rasters, combine them, use irrigated potato where rainfed is NA
comb <- cover(potplant_prf, poplant_pir)
comb <- reclassify(comb, c(0, 0, NA), include.lowest = TRUE)

# Do some filling of NAs with modal neighborhood values, 2X, not a mistake
com <- focal(comb, fun = modal, na.rm = TRUE, w = matrix(1, 3, 3), NAonly = TRUE)
com <- focal(com, fun = modal, na.rm = TRUE, w = matrix(1, 3, 3), NAonly = TRUE)

# Clean up the planting date map again with MIRCA to remove non-potato growing areas
com <- mask(com, MIRCA)
names(com) <- "Ecocrop Planting Dates for 1975"
writeRaster(com, "Cache/Planting Seasons/CRUCL2.0_Combined.tif",
            format = "GTiff", dataType = "INT2S", 
            options = c("COMPRESS=LZW"), 
            overwrite = TRUE)

# Data visualisation -----------------------------------------------------------
plot(com, main = "Potato planting dates as predicted by EcoCrop", 
     xlab = "Longitude", ylab = "Latitude",
     legend.args = list(text = "Month", side = 3, font = 2, 
                        line = 1, cex = 0.8))

# eos
