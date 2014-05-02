##############################################################################
# title         : EcoCrop CRU CL2.0 Potato Growing Seasons.R;
# purpose       : create global potato growing seasons using Ecocrop with CRU CL 2.0 data;
# producer      : prepared by R. Hijmans and A. Sparks;
# last update   : in Los Baños, Laguna, April 2014;
# inputs        : CRU CL2.0 Climate data;
# outputs       : PotatoPlant_CRUCL2.0.grd, CRUCL2.0_PRF.grd, CRUCL2.0_PIR.grd;
# remarks 1     : ;
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
library(raster)
library(dismo)
##### End Libraries ####

#### Load functions ####
source("Functions/ecospat.R")
source("Functions/Get_CRU_20_Data.R")
source("Functions/create_stack.R")
#### End Functions ####

#### Begin data import ####
source("Functions/DownloadMIRCA.R") # Script will download and unzip MIRCA data or simply load if available in /Data
CRU.data <- CRU_Growing_Season_DL() # Function that downloads CRU mean temperature, diurnal temperature difference and precipitation data and converts into R dataframe objects, returns a list
#### End data import ####

## Function that generates raster stacks of the CRU CL2.0 data
pre.stack <- create.stack(CRU.data$pre)
tmn.stack <- create.stack(CRU.data$tmn)
tmp.stack <- create.stack(CRU.data$tmp)
tmx.stack <- create.stack(CRU.data$tmx)

MIRCA <- crop(MIRCA, pre.stack) # Crop the MIRCA data to the same extent as the CRU data

#### Mask the CRU CL2.0 stacks with MIRCA to reduce the run time of ECOCROP ####
pre.stack <- mask(pre.stack, MIRCA)
tmn.stack <- mask(tmn.stack, MIRCA)
tmx.stack <- mask(tmx.stack, MIRCA)
tmp.stack <- mask(tmp.stack, MIRCA)

#### run ECOCROP model on raster stack of pre, tmp, tmn and tmx #####

## NOTE: These this next line is time intensive ##
prf <- ecospat(pot, tmn.stack, tmx.stack, tmp.stack, pre.stack, rainfed = TRUE, filename = "Cache/Planting Seasons/CRUCL2.0_PRF.grd", overwrite = TRUE) # Rainfed potato

# Read raster objects of predicted planting dates from disk
poplant <- raster("Cache/Planting Seasons/CRUCL2.0_PRF.grd") # rainfed potato planting date raster
poplant <- reclassify(poplant, c(0, 0, NA), include.lowest = TRUE) # set values of 0 equal to NA
writeRaster(poplant, "Cache/Planting Seasons/CRUCL2.0_PRF.grd", overwrite = TRUE)

#eos
