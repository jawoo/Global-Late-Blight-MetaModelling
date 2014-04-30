##############################################################################
# title         : Download_MIRCA.R;
# purpose       : Download and unzip MIRCA data;
# producer      : prepared by A. Sparks;
# last update   : in Los Baños, Laguna, April 2014;
# inputs        : MIRCA Potato Harvest Area ESRI ASC gzipped file;
# outputs       : MIRCA Potato Harvest Area ESRI ASC file;
# remarks       : ;
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

#### Download MIRCA 2000 Maximum Harvested Area for Potato (Crop #10) to use as a mask ####
## Check to see if the file has already been downloaded and uznipped, if so don't waste time ##
## downloading, just load it ##
if(file.exists("Data/ANNUAL_AREA_HARVESTED_RFC_CROP10_HA.ASC") != TRUE){
  url <- "ftp://ftp.rz.uni-frankfurt.de/pub/uni-frankfurt/physische_geographie/hydrologie/public/data/MIRCA2000/harvested_area_grids/ANNUAL_AREA_HARVESTED_RFC_CROP10_HA.ASC.gz"
  download.file(url, "Data/ANNUAL_AREA_HARVESTED_RFC_CROP10_HA.ASC.gz")
  system("7z e Data/ANNUAL_AREA_HARVESTED_RFC_CROP10_HA.ASC.gz -oData") #I don"t like to call 7zip here, but there"s something odd with the file and gnutar (thus untar) will not work
  MIRCA <- raster("Data/ANNUAL_AREA_HARVESTED_RFC_CROP10_HA.ASC")
  MIRCA <- aggregate(MIRCA, 2) # Aggregate MIRCA up to 10sec data to match CRU CL2.0
  MIRCA[MIRCA==0] <- NA # Set 0 values to NA to use this as a mask
} else
  MIRCA <- raster("Data/ANNUAL_AREA_HARVESTED_RFC_CROP10_HA.ASC")
  MIRCA <- aggregate(MIRCA, 2) # Aggregate MIRCA up to 10sec data to match CRU CL2.0
  MIRCA[MIRCA==0] <- NA # Set 0 values to NA to use this as a mask

#eos
