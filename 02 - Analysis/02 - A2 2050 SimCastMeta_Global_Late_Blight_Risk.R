##############################################################################
# title         : 02 - A2 2050 SimCastMeta_Global_Late_Blight_Risk.R;
# purpose       : create global potato late blight risk using SimCastMeta with A2 2050 data;
# producer      : prepared by A. Sparks;
# last update   : in Los Baños, Laguna, Jan 2016;
# inputs        : A2 2050 time-slice climate data;
# outputs       : Predictions of late blight severity from SimCastMeta for the A2 scenario, 2050 time-slice;
# remarks 1     : EcoCrop A2 2050 Potato Growing Seasons.R must be run to generate the planting
#                 date raster before this script is used. If it is not, the EcoCrop planting date
#                 script will automatically run and generate the necessary file;
# Licence:      : GPL2;
##############################################################################

# Libraries --------------------------------------------------------------------
library(mgcv)
library(raster)
library(readr)

source("Functions/Get_A2_Data.R")
# Load data --------------------------------------------------------------------
# Download A2 climate data files from Figshare. 
# This will take a while if you've not already done it
download_A2_data() 

if(file.exists("Cache/Planting Seasons/A2_2050_Combined.tif") == TRUE){
  poplant <- raster("Cache/Planting Seasons/A2_2050_Combined.tif")
  } else source("Models/Ecocrop A2 Scenario Potato Growing Seasons.R")

# Select ONLY ONE, resistant or susceptible blight units for the model run

blight_units <- read_tsv("Cache/Blight Units/monthly_susceptible_blight_units.txt")
#blight_units <- read_tsv("Cache/Blight Units/monthly_resistant_blight_units.txt")

# Modeling --------------------------------------------------------------------
model_data <- subset(blight_units, Year <= 1992)

SimCastMeta <- gam(Blight~s(C, RH, k = 150), data = model_data)

# sort out the different time-slices, most analysis was with 2050 only so it 
# is the only one featured here. Feel free to use the other two time-slices 
# in the same fashion
reh_stack <- stack(list.files(path = "Data/A2 Relative Humidity", 
                              pattern = "a2rh50[[:digit:]]{2}.tif",
                              full.names = TRUE))/10 
tmp_stack <- stack(list.files(path = "Data/A2 Average Temperature", 
                              pattern = "a2tmp50[[:digit:]]{2}.tif", 
                              full.names = TRUE))/10 

reh_stack <- mask(reh_stack, poplant)
tmp_stack <- mask(tmp_stack, poplant)

for(i in 1:12){
  x <- stack(tmp_stack[[i]], reh_stack[[i]])
  names(x) <- c("C", "RH")
  y <- predict(x, SimCastMeta, progress = "text")
  y[y<0] = 0
  names(y) <- paste(i)
  if(i == 1){z <- y} else z <- stack(z, y)
  i <- i+1
}

for(j in 1:12){
  if(j == 1){
    w <- reclassify(poplant, c(01, 12, NA))
    x <- stack(z[[j]], z[[j+1]], z[[j+2]])
    x <- mask(x, w)
    y <- mean(x)
  } else if(j > 1 && j < 11){
    w <- reclassify(poplant, c(0, paste("0", j-1, sep = ""), NA))
    w <- reclassify(w, c(paste("0", j, sep = ""), 12, NA))
    x <- stack(z[[j]], z[[j+1]], z[[j+2]])
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
plot(global_blight_risk, main = "Average Daily Blight Unit Accumulation\nPer Three Month Growing Season\n2050", xlab = "Longitude", ylab = "Latitude",
     legend.args = list(text = "Blight\nUnits", side = 3, font = 2, line = 1, cex = 0.8))

# Save the results for further use or analysis ---------------------------------
if(max(blight_units$Blight == 6.39)){ # check to see whether we've used resistant or susceptible blight units for this analysis and assign new file name accordingly
  writeRaster(global_blight_risk, "Cache/Global Blight Risk Maps/A2_SimCastMeta_Susceptible_Prediction.tif",
              format = "GTiff", dataType = "INT2S", 
              options = c("COMPRESS=LZW"), 
              overwrite = TRUE)
} else
  writeRaster(global_blight_risk, "Cache/Global Blight Risk Maps/A2_SimCastMeta_Resistant_Prediction.tif",
              format = "GTiff", dataType = "INT2S", 
              options = c("COMPRESS=LZW"), 
              overwrite = TRUE)

# eos
