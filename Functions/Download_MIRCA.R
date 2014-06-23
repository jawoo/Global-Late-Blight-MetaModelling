##############################################################################
# title         : Download_MIRCA.R;
# purpose       : Download and unzip MIRCA data;
# producer      : prepared by A. Sparks;
# last update   : in Los Baños, Laguna, May 2014;
# inputs        : MIRCA Potato Harvest Area ESRI ASC gzipped file;
# outputs       : MIRCA Potato Harvest Area ESRI ASC file;
# remarks       : ;
# Licence:      : GPL2;
##############################################################################

#### Download MIRCA 2000 Maximum Harvested Area for Potato (Crop #10) to use as a mask ####
download.MIRCA <- function(){
  ## Check to see if the file has already been downloaded and uznipped, if so don't waste time ##
  ## downloading, just load it ##
  if(file.exists("Data/MIRCA_Poplant.grd") != TRUE){
    url.IRC <- "ftp://ftp.rz.uni-frankfurt.de/pub/uni-frankfurt/physische_geographie/hydrologie/public/data/MIRCA2000/harvested_area_grids/ANNUAL_AREA_HARVESTED_IRC_CROP10_HA.ASC.gz"
    url.RFC <- "ftp://ftp.rz.uni-frankfurt.de/pub/uni-frankfurt/physische_geographie/hydrologie/public/data/MIRCA2000/harvested_area_grids/ANNUAL_AREA_HARVESTED_RFC_CROP10_HA.ASC.gz"
    url.Area <- "ftp://ftp.rz.uni-frankfurt.de/pub/uni-frankfurt/physische_geographie/hydrologie/public/data/MIRCA2000/cell_area_grid/cell_area_ha_05mn.asc.gz"
    
    download.file(url.IRC, "Data/ANNUAL_AREA_HARVESTED_IRC_CROP10_HA.ASC.gz")
    download.file(url.RFC, "Data/ANNUAL_AREA_HARVESTED_RFC_CROP10_HA.ASC.gz")
    download.file(url.Area, "Data/cell_area_ha_05mn.asc.gz")
    
    system("7z e Data/ANNUAL_AREA_HARVESTED_IRC_CROP10_HA.ASC.gz -oData") #I don"t like to call 7zip here, but there"s something odd with the file and gnutar (thus untar) will not work
    system("7z e Data/ANNUAL_AREA_HARVESTED_RFC_CROP10_HA.ASC.gz -oData") 
    system("7z e Data/cell_area_ha_05mn.asc.gz -oData")
    
    r.IRC <- raster("Data/ANNUAL_AREA_HARVESTED_IRC_CROP10_HA.ASC") # read the unzip ascii file using raster
    r.RFC <- raster("Data/ANNUAL_AREA_HARVESTED_RFC_CROP10_HA.ASC")
    r.Area <- raster("Data/cell_area_ha_05mn.asc")
    
    r.IRC <- aggregate(r.IRC, 2) # aggregate from 5 minutes to 10 minutes to match the CRU CL2.0 data resolution
    r.RFC <- aggregate(r.RFC, 2)
    r.Area <- aggregate(r.Area, 2)
    
    perc.r.IRC <- r.IRC/r.Area # calculate the percent area in cell that is irrigated potato
    perc.r.RFC <- r.RFC/r.Area # calculate the percent area in cell that is rainfed potato
    MIRCA <- perc.r.IRC+perc.r.RFC # combine the rainfed and irrigated percentages, EcoCrop predicts both.
    
    MIRCA[MIRCA <= 0] <- NA #reclassify anything below 0% area to NA
    MIRCA <- crop(MIRCA, c(-180, 180, -60, 90)) # crop perc.Area to match extent of CRU CL2.0
    writeRaster(MIRCA, 'Data/MIRCA_Poplant.grd', overwrite = TRUE)
    
    file.remove("Data/ANNUAL_AREA_HARVESTED_IRC_CROP10_HA.ASC.gz")
    file.remove("Data/ANNUAL_AREA_HARVESTED_RFC_CROP10_HA.ASC.gz")
    file.remove("Data/cell_area_ha_05mn.asc.gz")
    
  } else # The file already exists and we save time by just reading into R
    MIRCA <- raster("Data/MIRCA_Poplant.grd")
}

#eos
