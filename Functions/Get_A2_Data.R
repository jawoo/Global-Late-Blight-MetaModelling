##############################################################################
# title         : Get_A2_Data.R;
# purpose       : download A2 climate files from Figshare;
# producer      : prepared by A. Sparks;
# last update   : in Los Baños, Laguna, Jan 2016;
# inputs        : ;
# outputs       : A2 2010, 2050 and 2090 time-slice climate files for tmin, tmax, tavg, prec, and reh;
# remarks 1     : ;
# Licence:      : GPL2;
##############################################################################

download_A2_data <- function(){
  tf <- tempfile()

  if(length(list.files(path = "Data/A2 Precipitation")) != 36){
    download.file("http://files.figshare.com/1571643/A2_Precipitation.zip", 
                  tf, method = "wb")
    unzip(tf, exdir = "Data", overwrite = TRUE)
  }
  
  if(length(list.files(path = "Data/A2 Minimum Temperature/")) != 36){
    download.file("http://files.figshare.com/1562951/A2_Minimum_Temperature.zip", 
                  tf, method = "wb")
    unzip(tf, exdir = "Data", overwrite = TRUE)
  }
  
  if(length(list.files(path = "Data/A2 Maximum Temperature")) != 36){
    download.file("http://files.figshare.com/1562950/A2_Maximum_Temperature.zip", 
                  tf, method = "wb")
    unzip(tf, exdir = "Data", overwrite = TRUE)
  }
  
  if(length(list.files(path = "Data/A2 Average Temperature")) != 36){
    download.file("http://files.figshare.com/1562942/A2_Average_Temperature.zip", 
                  tf, method = "wb")
    unzip(tf, exdir = "Data", overwrite = TRUE)
  }
  
  if(length(list.files(path = "Data/A2 Relative Humidity")) != 36){
    download.file("http://files.figshare.com/1545438/A2_Relative_Humidity.zip", 
                  tf, method = "wb")
    unzip(tf, exdir = "Data", overwrite = TRUE)
  }
}

# eos
