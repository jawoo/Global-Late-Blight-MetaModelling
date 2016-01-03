##############################################################################
# title         : Download_MIRCA.R;
# purpose       : Download and unzip MIRCA data;
# producer      : prepared by A. Sparks;
# last update   : in Los Baños, Laguna, Jan 2016;
# inputs        : MIRCA Potato Harvest Area ESRI ASC gzipped file;
# outputs       : MIRCA Potato Harvest Area ESRI ASC file;
# remarks       : ;
# Licence:      : GPL2;
##############################################################################

download_MIRCA <- function(){
    url_IRC <- "ftp://ftp.rz.uni-frankfurt.de/pub/uni-frankfurt/physische_geographie/hydrologie/public/data/MIRCA2000/harvested_area_grids/ANNUAL_AREA_HARVESTED_IRC_CROP10_HA.ASC.gz"
    url_RFC <- "ftp://ftp.rz.uni-frankfurt.de/pub/uni-frankfurt/physische_geographie/hydrologie/public/data/MIRCA2000/harvested_area_grids/ANNUAL_AREA_HARVESTED_RFC_CROP10_HA.ASC.gz"
    url_Area <- "ftp://ftp.rz.uni-frankfurt.de/pub/uni-frankfurt/physische_geographie/hydrologie/public/data/MIRCA2000/cell_area_grid/cell_area_ha_05mn.asc.gz"
    
    download.file(url_IRC, "Data/ANNUAL_AREA_HARVESTED_IRC_CROP10_HA.ASC.gz")
    download.file(url_RFC, "Data/ANNUAL_AREA_HARVESTED_RFC_CROP10_HA.ASC.gz")
    download.file(url_Area, "Data/cell_area_ha_05mn.asc.gz")
    
    # I don"t like to call 7zip here, but there"s something odd with the file and gnutar (thus untar) will not work
    system("7z e Data/ANNUAL_AREA_HARVESTED_IRC_CROP10_HA.ASC.gz -oData") 
    system("7z e Data/ANNUAL_AREA_HARVESTED_RFC_CROP10_HA.ASC.gz -oData") 
    system("7z e Data/cell_area_ha_05mn.asc.gz -oData")
    
    r_IRC <- raster("Data/ANNUAL_AREA_HARVESTED_IRC_CROP10_HA.ASC")
    r_RFC <- raster("Data/ANNUAL_AREA_HARVESTED_RFC_CROP10_HA.ASC")
    r_area <- raster("Data/cell_area_ha_05mn.asc")
    
    r_IRC <- aggregate(r_IRC, 2)
    r_RFC <- aggregate(r_RFC, 2)
    r_area <- aggregate(r_area, 2)
    
    per_r_IRC <- r_IRC/r_area # calculate the percent area in cell that is irrigated potato
    per_r_RFC <- r_RFC/r_area # calculate the percent area in cell that is rainfed potato
    MIRCA <- per_r_IRC+per_r_RFC # combine the rainfed and irrigated percentages, EcoCrop predicts both.
    
    MIRCA[MIRCA <= 0] <- NA # reclassify anything below 0% area to NA
    MIRCA <- crop(MIRCA, c(-180, 180, -60, 90)) # crop perc.Area to match extent of CRU CL2.0
    writeRaster(MIRCA, "Data/MIRCA_Poplant.tif", overwrite = TRUE, 
                format = "GTiff", c("COMPRESS=LZW"))

    file.remove("Data/ANNUAL_AREA_HARVESTED_IRC_CROP10_HA.ASC.gz")
    file.remove("Data/ANNUAL_AREA_HARVESTED_RFC_CROP10_HA.ASC.gz")
    file.remove("Data/cell_area_ha_05mn.asc.gz")
}

# eos
