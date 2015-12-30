##############################################################################
# title         : SimCastMeta_Global_Late_Blight_Risk.R;
# purpose       : create global potato late blight risk using SimCastMeta with CRU CL 2.0 data;
# producer      : prepared by A. Sparks;
# last update   : in Los Baños, Laguna, Dec 2015;
# inputs        : CRU CL2.0 Climate data;
# outputs       : ;
# remarks 1     : EcoCrop CRU CL2.0 Potato Growing Seasons.R must be run to generate the planting
#                 date raster before this script is used. If it is not, the EcoCrop planting date
#                 script will automatically run and generate the necessary file;
# Licence:      : GPL2;
##############################################################################

#### Libraries ####
library(mgcv)
library(raster)
#### End Libraries ####

#### Load functions ####
source("Functions/Get_CRU_20_Data.R")
source("Functions/create_stack.R")
#### End Functions ####

#### Begin data import ####
if(!file.exists("Cache/Planting Seasons/CRUCL2.0_PRF.tif")){
  source("Models/Ecocrop CRU CL2.0 Potato Growing Seasons.R")} else
    poplant <- raster("Cache/Planting Seasons/CRUCL2.0_PRF.tif")

## Load blight units calculated by SimCast, used to create the SimCastMeta GAM
#!!!!! Select ONLY ONE, resistant or susceptible blight units for the model run !!!!!#

## SUSCEPTIBLE model with this data for monthly weather data
blight.units <- read.table("Cache/Blight Units/monthly_susceptible_blight_units.txt", head = TRUE, sep = "\t", nrows = 14749)

## Create a RESISTANT model with this data for monthly weather data
#blight.units <- read.table("Cache/Blight Units/monthly_resistant_blight_units.txt", head = TRUE, sep = "\t", nrows = 14749)

##### End data import #####

##### Begin model construction #####
## The original model split the weather data into two parts for construction and testing
## we used six years of HUSWO data to generate the values, so split at 1992/1993
model.data <- subset(blight.units, Year <= 1992)

###### Begin model creation and testing #####
## A k of 150 generated the best fit for the monthly weather data and most believable GAM surface
## for more information, ?gam
SimCastMeta <- gam(Blight~s(C, RH, k = 150), data = model.data)

# Function that downloads CRU mean temperature and relative humidity data and converts into R dataframe objects, returns a list
CRU.data <- CRU_SimCastMeta_Data_DL()

## Function that generates raster stacks of the CRU CL2.0 data
reh.stack <- create.stack(CRU.data$reh)
tmp.stack <- create.stack(CRU.data$tmp)

#### Mask the CRU CL2.0 stacks with poplant raster (already masked using MIRCA production areas in EcoCrop script);
#### to reduce the run time of SimCastMeta ####
reh.stack <- mask(reh.stack, poplant)
tmp.stack <- mask(tmp.stack, poplant)

#### Run the model using CRU CL2.0 Data ####
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

plot(global.blight.risk, main = "Average Daily Blight Unit Accumulation\nPer Three Month Growing Season", xlab = "Longitude", ylab = "Latitude",
     legend.args = list(text = "Blight\nUnits", side = 3, font = 2, line = 1, cex = 0.8))

#eos
