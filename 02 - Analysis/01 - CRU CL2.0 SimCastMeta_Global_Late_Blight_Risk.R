################################################################################
# title         : 01 - CRU CL2.0 SimCastMeta_Global_Late_Blight_Risk.R;
# purpose       : create global potato late blight risk using SimCastMeta with CRU CL2.0 data;
# producer      : prepared by A. Sparks;
# last update   : in Los Baños, Laguna, Jan 2016;
# inputs        : CRU CL2.0 Climate Data from UEA;
# outputs       : ;
# remarks 1     : EcoCrop CRU CL2.0 Potato Growing Seasons.R must be run to generate the planting
#                 date raster before this script is used. If it is not, the EcoCrop planting date
#                 script will automatically run and generate the necessary file;
# Licence:      : GPL2;
################################################################################

# Libraries --------------------------------------------------------------------
library(mgcv)
library(raster)
library(readr)

# Load special functions -------------------------------------------------------
source("Functions/Get_CRU_20_Data.R")
source("Functions/create_stack.R")

# Load Data --------------------------------------------------------------------
if(!file.exists("Cache/Planting Seasons/CRUCL2.0_Combined.tif")){
  source("Models/Ecocrop CRU CL2.0 Potato Growing Seasons.R")
  }
poplant <- raster("Cache/Planting Seasons/CRUCL2.0_Combined.tif")

# Select ONLY ONE, resistant or susceptible blight units for the model run
blight_units <- read_tsv("Cache/Blight Units/monthly_susceptible_blight_units.txt")
#blight_units <- read_tsv("Cache/Blight Units/monthly_resistant_blight_units.txt")

CRU_data <- CRU_SimCastMeta_Data_DL()

reh_stack <- create_stack(CRU_data$reh)
tmp_stack <- create_stack(CRU_data$tmp)

reh_stack <- mask(reh_stack, poplant)
tmp_stack <- mask(tmp_stack, poplant)

model_data <- subset(blight_units, Year <= 1992)

# Modelling --------------------------------------------------------------------
# The original model split the weather data into two parts for construction and testing
# we used six years of HUSWO data to generate the values, so split at 1992/1993

SimCastMeta <- gam(Blight~s(C, RH, k = 150), data = model_data)

for(i in 1:12){
  x <- stack(tmp_stack[[i]], reh_stack[[i]])
  names(x) <- c("C", "RH")
  y <- predict(x, SimCastMeta, progress = "text")
  y[y<0] = 0 
  
  if(i == 1){z <- y} else z <- stack(z, y)
  
  filename <- paste("Cache/Predictions/", i, "CRU", sep = "")
  writeRaster(y, filename,
              format = "GTiff", dataType = "INT2S", 
              options = c("COMPRESS=LZW"), 
              overwrite = TRUE)
}

for(j in 1:12){
  if(j == 1){
    w <- reclassify(poplant, c(01, 12, NA))
    x <- stack(z[[j]], z[[j + 1]], z[[j + 2]])
    x <- mask(x, w)
    y <- mean(x)
  } else if(j > 1 & j < 11){
    w <- reclassify(poplant, c(0, paste("0", j-1, sep = ""), NA))
    w <- reclassify(w, c(paste("0", j, sep = ""), 12, NA))
    x <- stack(z[[j]], z[[j + 1]], z[[j + 2]])
    x <- mask(x, w)
    a <- mean(x)
    y <- cover(y, a)
  } else if(j == 11){
    w <- reclassify(poplant, c(0, 10, NA))
    w <- reclassify(w, c(11, 12, NA))
    x <- stack(z[[11]], z[[12]], z[[1]])
    x <- mask(x, w)
    a <- mean(x)
    y <- cover(y, a)
  }  else
  w <- reclassify(poplant, c(0, 11, NA))
  x <- stack(z[[12]], z[[1]], z[[2]])
  x <- mask(x, w)
  a <- mean(x)
  global_blight_risk <- cover(y, a) 
}

# Data visulasation ------------------------------------------------------------
plot(global_blight_risk, main = "Average Daily Blight Unit Accumulation\nPer Three Month Growing Season\n1975", xlab = "Longitude", ylab = "Latitude",
     legend.args = list(text = "Blight\nUnits", side = 3, font = 2, line = 1, cex = 0.8))

# Save the results for further use or analysis ---------------------------------
if(max(blight_units$Blight == 6.39)){ # check to see whether we've used resistant or susceptible blight units for this analysis and assign new file name accordingly
  writeRaster(global_blight_risk, 
              "Cache/Global Blight Risk Maps/CRUCL2.0_SimCastMeta_Susceptible.tif",
              format = "GTiff", dataType = "INT2S", 
              options = c("COMPRESS=LZW"), 
              overwrite = TRUE)
} else
  writeRaster(global_blightrisk, 
              "Cache/Global Blight Risk Maps/CRUCL2.0_SimCastMeta_Resistant.tif",
              format = "GTiff", dataType = "INT2S", 
              options = c("COMPRESS=LZW"), 
              overwrite = TRUE)

# eos
