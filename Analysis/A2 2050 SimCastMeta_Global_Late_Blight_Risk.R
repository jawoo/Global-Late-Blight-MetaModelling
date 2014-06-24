##############################################################################
# title         : A2 2050 SimCastMeta_Global_Late_Blight_Risk.R;
# purpose       : create global potato late blight risk using SimCastMeta with A2 2050 data;
# producer      : prepared by A. Sparks;
# last update   : in Los Baños, Laguna, June 2014;
# inputs        : A2 2050 time-slice climate data;
# outputs       : ;
# remarks 1     : EcoCrop A2 2050 Potato Growing Seasons.R must be run to generate the planting
#                 date raster before this script is used. If it is not, the EcoCrop planting date
#                 script will automatically run and generate the necessary file;
# Licence:      : GPL2;
##############################################################################

#### Libraries ####
library(mgcv)
library(raster)
#### End Libraries ####

#### Load functions ####
source("Functions/Get_A2_Data.R")

#### Begin data import ####
download.A2.data() # download A2 climate data files from Figshare. This will take a while if you've not already done it

if(file.exists("Cache/Planting Seasons/A2_2050_Combined.tif") != TRUE){
  source("Models/Ecocrop A2 Scenario Potato Growing Seasons.R")} else
    poplant <- raster("Cache/Planting Seasons/A2_2050_Combined.tif")

## Load blight units calculated by SimCast, used to create the SimCastMeta GAM
#!!!!! Select ONLY ONE, resistant or susceptible blight units for the model run !!!!!#

## SUSCEPTIBLE model with this data for monthly weather data
blight.units <- read.table("Cache/Blight Units/monthly_susceptible_blight_units.txt", head = TRUE, sep = "\t", nrows = 14749)

## Create a RESISTANT model with this data for monthly weather data
blight.units <- read.table("Cache/Blight Units/monthly_resistant_blight_units.txt", head = TRUE, sep = "\t", nrows = 14749)

##### End data import #####

##### Begin model construction #####
## The original model split the weather data into two parts for construction and testing
## we used six years of HUSWO data to generate the values, so split at 1992/1993
model.data <- subset(blight.units, Year <= 1992)

###### Begin model creation and testing #####
## A k of 150 generated the best fit for the monthly weather data and most believable GAM surface
## for more information, ?gam
SimCastMeta <- gam(Blight~s(C, RH, k = 150), data = model.data)

## sort out the different time-slices, most analysis was with 2050 only so it is the only one featured here. Feel free to use the other two time-slices in the same fashion
reh.stack <- stack(list.files(path = "Data/A2 Relative Humidity", pattern = "a2rh50[[:digit:]]{2}.tif", full.names = TRUE))/10 # Load relative humidity tif files for 2050 time-slice only, change "50" to "20" or "90" for other time slice
tmp.stack <- stack(list.files(path = "Data/A2 Average Temperature", pattern = "a2tmp50[[:digit:]]{2}.tif", full.names = TRUE))/10 # Load average temperature tif files for 2050 time-slice only, change "50" to "20" or "90" for other time slice

#### Mask the A2 stacks with poplant raster (already masked using MIRCA production areas in EcoCrop script);
#### to reduce the run time of SimCastMeta ####
reh.stack <- mask(reh.stack, poplant)
tmp.stack <- mask(tmp.stack, poplant)

#### Run the model using A2 Data ####
for(i in 1:12){
  x <- stack(tmp.stack[[i]], reh.stack[[i]]) # Take month raster layers from the year T and RH and add them to a T/RH stack to run the model
  names(x) <- c("C", "RH") # Rename layers in stack to match model construction
  y <- predict(x, SimCastMeta, progress = "text") # Run GAM with Raster Stack
  y[y<0] = 0 # Set the predicted blight units falling below zero equal to zero
  
  if(i == 1){z <- y} else z <- stack(z, y)
  }

#### Take raster stack "z" from above with monthly blight unit estimates
for(j in 1:12){
  if(j == 1){
    w <- reclassify(poplant, c(01, 12, NA))
    x <- stack(z[[j]], z[[j+1]], z[[j+2]]) # stack the three months of the first growing season
    x <- mask(x, w) # mask with suitable potato planting date
    y <- mean(x) # take average blight unit accumulation for growing season
  } else if(j > 1 && j < 11){
    w <- reclassify(poplant, c(0, paste("0", j-1, sep = ""), NA))
    w <- reclassify(w, c(paste("0", j, sep = ""), 12, NA))
    x <- stack(z[[j]], z[[j+1]], z[[j+2]]) # stack the three months of the first growing season
    x <- mask(x, w) # mask with suitable potato planting date
    a <- mean(x) # take average blight unit accumulation for growing season
    y <- cover(y, a) # replace NAs in raster file with new planting season blight unit values
  } else if(j == 11){
    w <- reclassify(poplant, c(0, 10, NA))
    w <- reclassify(w, c(11, 12, NA))
    x <- stack(z[[11]], z[[12]], z[[1]]) # stack the three months of the first growing season
    x <- mask(x, w) # mask with suitable potato planting date
    a <- mean(x) # take average blight unit accumulation for growing season
    y <- cover(y, a) # replace NAs in raster file with new planting season blight unit values
  }  else
  w <- reclassify(poplant, c(0, 11, NA))
  x <- stack(z[[12]], z[[1]], z[[2]]) # stack the three months of the first growing season
  x <- mask(x, w) # mask with suitable potato planting date
  a <- mean(x) # take average blight unit accumulation for growing season
  global.blight.risk <- cover(y, a) # replace NAs in raster file with new planting season blight unit values, final object
}

if(max(blight.units$Blight == 6.39)){ # check to see whether we've used resistant or susceptible blight units for this analysis and assign new file name accordingly
  writeRaster(global.blight.risk, "Cache/Global Blight Risk Maps/A2_SimCastMeta_Susceptible_Prediction.tif",
              format = "GTiff", dataType = "INT2S", 
              options = c("COMPRESS=LZW"), 
              overwrite = TRUE)
} else
  writeRaster(global.blight.risk, "Cache/Global Blight Risk Maps/A2_SimCastMeta_Resistant_Prediction.tif",
              format = "GTiff", dataType = "INT2S", 
              options = c("COMPRESS=LZW"), 
              overwrite = TRUE)

plot(global.blight.risk, main = "Average Daily Blight Unit Accumulation\nPer Three Month Growing Season\n2050", xlab = "Longitude", ylab = "Latitude",
     legend.args = list(text = "Blight\nUnits", side = 3, font = 2, line = 1, cex = 0.8))

#eos
