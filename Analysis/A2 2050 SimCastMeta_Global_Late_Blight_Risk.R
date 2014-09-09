##############################################################################
# title         : A2 2050 SimCastMeta_Global_Late_Blight_Risk.R;
# purpose       : create global potato late blight risk using SimCastMeta with A2 2050 data;
# producer      : prepared by A. Sparks;
# last update   : in Los Baños, Laguna, September 2014;
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

if(file.exists("Cache/Planting Seasons/A2_2050_Combined.tif") == TRUE){
  poplant <- raster("Cache/Planting Seasons/A2_2050_Combined.tif")
  } else source("Models/Ecocrop A2 Scenario Potato Growing Seasons.R")
    

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
  names(x) <- c("C", "RH")
  # Run GAM with Raster Stack
  y <- predict(x, SimCastMeta, progress = "text")
  y[y<0] = 0 # Set the predicted blight units falling below zero equal to zero
  names(y) <- paste(i)
  if(i == 1){z <- y} else z <- stack(z, y)
  i <- i+1
}

#### Create new raster objects to mask out the appropriate growing seasons for blight risk calculation
x.01 <- reclassify(poplant, c(01, 12, NA)) # January mask

x.02 <- reclassify(poplant, c(0, 01, NA)) # February mask
x.02 <- reclassify(x.02, c(02, 12, NA))

x.03 <- reclassify(poplant, c(0, 02, NA)) # March mask
x.03 <- reclassify(x.03, c(03, 12, NA))

x.04 <- reclassify(poplant, c(0, 03, NA)) # April mask
x.04 <- reclassify(x.04, c(04, 12, NA))

x.05 <- reclassify(poplant, c(0, 04, NA)) # May mask
x.05 <- reclassify(x.05, c(05, 12, NA))

x.06 <- reclassify(poplant, c(0, 05, NA)) # June mask
x.06 <- reclassify(x.06, c(06, 12, NA))

x.07 <- reclassify(poplant, c(0, 06, NA)) # July mask
x.07 <- reclassify(x.07, c(07, 12, NA))

x.08 <- reclassify(poplant, c(0, 07, NA)) # August mask
x.08 <- reclassify(x.08, c(08, 12, NA))

x.09 <- reclassify(poplant, c(0, 08, NA)) # September mask
x.09 <- reclassify(x.09, c(09, 12, NA))

x.10 <- reclassify(poplant, c(0, 09, NA)) # October mask
x.10 <- reclassify(x.10, c(10, 12, NA))

x.11 <- reclassify(poplant, c(0, 10, NA)) # November mask
x.11 <- reclassify(x.11, c(11, 12, NA))

x.12 <- reclassify(poplant, c(0, 11, NA)) # December mask

#### Mask blight units and then calculate the proper blight units for a three month growing season
jan <- mean(mask(z[[1:3]], x.01))
feb <- mask(mean(z[[2:4]]), x.02)
mar <- mask(mean(z[[3:5]]), x.03)
apr <- mask(mean(z[[4:6]]), x.04)
may <- mask(mean(z[[5:7]]), x.05)
jun <- mask(mean(z[[6:8]]), x.06)
jul <- mask(mean(z[[7:9]]), x.07)
aug <- mask(mean(z[[8:10]]), x.08)
sep <- mask(mean(z[[9:11]]), x.09)
oct <- mask(mean(z[[10:12]]), x.10)
nov <- mask(mean(z[[c(1, 11:12)]]), x.11)
dec <- mask(mean(z[[c(1:2, 12)]]), x.12)

##### merge growing season averages back into one raster object
global.blight.risk <- merge(jan, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dec) 

#### Visualise the results
plot(global.blight.risk, main = "Average Daily Blight Unit Accumulation\nPer Three Month Growing Season\n2050", xlab = "Longitude", ylab = "Latitude",
     legend.args = list(text = "Blight\nUnits", side = 3, font = 2, line = 1, cex = 0.8))

#### Save the results for further use or analysis
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

#eos
