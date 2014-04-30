##############################################################################
# title         : Global_Late_Blight_Risk.R;
# purpose       : create global potato late blight risk using SimCastMeta with CRU CL 2.0 data;
# producer      : prepared by A. Sparks;
# last update   : in Los Baños, Laguna, April 2014;
# inputs        : CRU CL2.0 Climate data;
# outputs       : ;
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
#### End Libraries ####

#### Load functions ####
source("Functions/Get_CRU_20_Data.R")
source("Functions/create_stack.R")
#### End Functions ####

# Function that downloads CRU mean temperature, diurnal temperature difference and precipitation data and converts into R dataframe objects, returns a list
CRU.data <- CRU_SimCastMeta_Data_DL

## Function that generates raster stacks of the CRU CL2.0 data
reh.stack <- create.stack(CRU.data$reh)
tmp.stack <- create.stack(CRU.data$tmp)


#eos
