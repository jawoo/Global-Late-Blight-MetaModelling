##############################################################################
# title         : Global_Late_Blight_Risk.R;
# purpose       : create global potato late blight risk using SimCastMeta with CRU CL 2.0 data;
# producer      : prepared by A. Sparks;
# last update   : in Los Baños, Laguna, April 2014;
# inputs        : CRU CL2.0 Climate data;
# outputs       : ;
# remarks 1     : EcoCrop CRU CL2.0 Potato Growing Seasons.R must be run to generate the planting
#                 date raster before this script is used. If it is not, the EcoCrop planting date
#                 script will automatically run and generate the necessary file;
# Licence:      : This program is free software; you can redistribute it and/or modify
#                 it under the terms of the GNU General Public License as published by
#                 the Free Software Foundation; either version 2 of the License, or
#                 (at your option) any later version.

#                 This program is distributed in the hope that it will be useful,
#                 but WITHOUT ANY WARRANTY; without even the implied warranty of
#                 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#                 GNU General Public License for more details.

#                 You should have received a copy of the GNU General Public License along
#                 with this program; if not, write to the Free Software Foundation, Inc.,
#                 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
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
if(file.exists("Cache/Planting Seasons/CRU_CL20_Potato_Plant.grd") != TRUE){
  source("Models/Ecocrop CRU CL2.0 Potato Growing Seasons.R")} else
    poplant <- raster("Cache/Planting Seasons/CRU_CL20_Potato_Plant.grd")

## Load blight units calculated by SimCast, used to create the SimCastMeta GAM ####
#!!!!! Select ONLY ONE, resistant or susceptible blight units for the model run !!!!!#

## Create a SUSCEPTIBLE model with this data for monthly weather data
blight.units <- read.table("Cache/Blight Units/all.monthly.susceptible.calcs.txt", head = TRUE, sep = "\t", nrows = 14749)

## Create a RESISTANT model with this data for monthly weather data
blight.units <- read.table("Cache/Blight Units/all.monthly.resistant.calcs.txt", head = TRUE, sep = "\t", nrows = 14749)

##### End data import #####

##### Begin model construction #####
## The original model split the weather data into two parts for construction and testing
## we used six years of HUSWO data to generate the values, so split at 1992/1993
model.data <- subset(blight.units, Year <= 1992)

###### Begin model creation and testing #####
## A k of 165 generated the best fit for the monthly weather data
## for more information, ?gam
SimCastMeta <- gam(Blight~s(C, RH, k = 165), data = model.data)

# Function that downloads CRU mean temperature and relative humidity data and converts into R dataframe objects, returns a list
CRU.data <- CRU_SimCastMeta_Data_DL()

## Function that generates raster stacks of the CRU CL2.0 data
reh.stack <- create.stack(CRU.data$reh)
tmp.stack <- create.stack(CRU.data$tmp)

#### Mask the CRU CL2.0 stacks with poplant raster (already masked using MIRCA production areas) to reduce the run time of SimCastMeta ####
reh.stack <- mask(reh.stack, poplant)
tmp.stack <- mask(tmp.stack, poplant)

#### Run the model using CRU CL2.0 Data ####
for(i in 1:12){
  x <- stack(tmp.stack[[i]], reh.stack[[i]]) # Take month raster layers from the year T and RH and add them to a T/RH stack to run the model
  names(x) <- c('C','RH') # Rename layers in stack to match model construction
  y <- predict(x, SimCastMeta, progress = 'text') # Run GAM with Raster Stack
  y[y<0] = 0 # Set the predicted blight units falling below zero equal to zero
  
  if(i == 1){z <- y} else z <- stack(z, y)
  }

#### Take raster stack "z" from above with monthly blight unit estimates
for(j in 1:12){
  if(j == 1){
    w <- reclassify(poplant, c(01, 12, NA))
    x <- mask(z[[j]], w) # first month of season
    xx <- mask(z[[j+1]], w) # second month of season
    xxx <- mask(z[[j+2]], w) # third month of season
    y <- mean(x, xx, xxx)
  } else if(j > 1 && j < 11){
    w <- reclassify(poplant, c(0, paste("0", j-1, sep = ""), NA))
    w <- reclassify(w, c(paste("0", j, sep = ""), 12, NA))
    x <- mask(z[[j]], w) # first month of season
    xx <- mask(z[[j+1]], w) # second month of season
    xxx <- mask(z[[j+2]], w) # third month of season
    a <- mean(x, xx, xxx) # take average blight unit accumulation for growing season
    y <- cover(a, y) # replace NAs in raster file with new planting season blight unit values
  } else if(j == 11){
    w <- reclassify(poplant, c(0, 10, NA))
    w <- reclassify(w, c(11, 12, NA))
    x <- mask(z[[11]], w) # first month of season
    xx <- mask(z[[12]], w) # second month of season
    xxx <- mask(z[[1]], w) # third month of season
    a <- mean(x, xx, xxx) # take average blight unit accumulation for growing season
    y <- cover(a, y) # replace NAs in raster file with new planting season blight unit values
  }  else
  w <- reclassify(poplant, c(0, 11, NA))
  x <- mask(z[[12]], w) # first month of season
  xx <- mask(z[[1]], w) # second month of season
  xxx <- mask(z[[2]], w) # third month of season
  a <- mean(x, xx, xxx) # take average blight unit accumulation for growing season
  global.blight.risk <- cover(y, a) # replace NAs in raster file with new planting season blight unit values, final object
}

plot(global.blight.risk)

#eos
