##############################################################################
# title         : Get_A2_Data.R;
# purpose       : download A2 climate files from Figshare;
# producer      : prepared by A. Sparks;
# last update   : in Los Baños, Laguna, Dec 2015;
# inputs        : ;
# outputs       : A2 2010, 2050 and 2090 time-slice climate files for tmin, tmax, tavg, prec, and reh;
# remarks 1     : ;
# Licence:      : GPL2;
##############################################################################

download.A2.data <- function(){
  tf <- tempfile() # generate temp file for downloaded data files

  ### Begin download from Figshare and/or import from our Data directory if already existing

  ## First check to see if the files exist, if they do, then we go to the next portion, if not we download them.
  # As this download takes a while, the files will be stored in "Data" directory, not necessary to download after first time
  if(length(list.files(path = "./Data/A2 Precipitation")) != 36){
    download.file("http://files.figshare.com/1571643/A2_Precipitation.zip", tf, method = "wb") # Download A2 precipitation data geotiff files
    unzip(tf, exdir = "./Data", overwrite = TRUE) # Unzip A2 precipitation files to "Data/A2 Precipitation" directory
  }
  
  if(length(list.files(path = "./Data/A2 Minimum Temperature/")) != 36){
    download.file("http://files.figshare.com/1562951/A2_Minimum_Temperature.zip", tf, method = "wb") # Download A2 minimum temperature data geotiff files
    unzip(tf, exdir = "./Data", overwrite = TRUE) # Unzip A2 minimum temperature files to "Data/A2 Minimum Temperature" directory
  }
  
  if(length(list.files(path = "./Data/A2 Maximum Temperature")) != 36){
    download.file("http://files.figshare.com/1562950/A2_Maximum_Temperature.zip", tf, method = "wb") # Download A2 maximum temperature data geotiff files
    unzip(tf, exdir = "./Data", overwrite = TRUE) # Unzip A2 maximum temperature files to "Data/A2 Maximum Temperature" directory
  }
  
  if(length(list.files(path = "./Data/A2 Average Temperature")) != 36){
    download.file("http://files.figshare.com/1562942/A2_Average_Temperature.zip", tf, method = "wb") # Download A2 maximum temperature data geotiff files
    unzip(tf, exdir = "./Data", overwrite = TRUE) # Unzip A2 maximum temperature files to "Data/A2 Maximum Temperature" directory
  }
  
  if(length(list.files(path = "./Data/A2 Relative Humidity")) != 36){
    download.file("http://files.figshare.com/1545438/A2_Relative_Humidity.zip", tf, method = "wb") # Download A2 maximum temperature data geotiff files
    unzip(tf, exdir = "./Data", overwrite = TRUE) # Unzip A2 maximum temperature files to "Data/A2 Maximum Temperature" directory
  }
}

#eos
