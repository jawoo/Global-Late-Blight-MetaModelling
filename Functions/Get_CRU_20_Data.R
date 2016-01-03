################################################################################
# title         : Get_CRU_20_Data.R;
# purpose       : Two functions that download and process CRU CL 2.0 data into data frames in R;
# producer      : prepared by A. Sparks;
# last update   : in Los Baños, Laguna, Jan 2015;
# inputs        : CRU CL2.0 Climate data;
# outputs       : Raster stacks of CRU CL2.0 weather data;
# remarks 1     : a standalone version exists as a gist here: https://gist.github.com/adamhsparks/11284393;
# Licence:      : GPL2;
################################################################################

# Download and read CRU data files ---------------------------------------------
CRU_Growing_Season_DL <- function(){
  tf <- tempfile()
  # mean monthly diurnal temperature range
  download.file("http://www.cru.uea.ac.uk/cru/data/hrg/tmc/grid_10min_dtr.dat.gz", tf)
  dtr <- read.table(tf, header = FALSE, colClasses = "numeric", nrows = 566268)
  
  # mean monthly temperature
  download.file("http://www.cru.uea.ac.uk/cru/data/hrg/tmc/grid_10min_tmp.dat.gz", tf)
  tmp <- read.table(tf, header = FALSE, colClasses = "numeric", nrows = 566268)
  
  # mean monthly precipitation
  download.file("http://www.cru.uea.ac.uk/cru/data/hrg/tmc/grid_10min_pre.dat.gz", tf)
  pre <- read.table(tf, header = FALSE, colClasses = "numeric", nrows = 566268)
  pre <- pre[, 1:14]
  
  # calculate tmax and tmin from tmp and dtr (see: http://www.cru.uea.ac.uk/cru/data/hrg/tmc/readme.txt)
  tmx <- cbind(tmp[, 1:2], tmp[, c(3:14)]+(0.5*dtr[, c(3:14)]))
  tmn <- cbind(tmp[, 1:2], tmp[, c(3:14)]-(0.5*dtr[, c(3:14)]))
  
  vars <- list(pre, tmn, tmp, tmx)
  names(vars) <- c("pre", "tmn", "tmp", "tmx")
  rm(tf)
  gc()
  return(vars)
}

# Download and read CRU data files----------------------------------------------
CRU_SimCastMeta_Data_DL <- function(){
  tf <- tempfile()
  
  # mean monthly temperature
  download.file("http://www.cru.uea.ac.uk/cru/data/hrg/tmc/grid_10min_tmp.dat.gz", tf)
  tmp <- read.table(tf, header = FALSE, colClasses = "numeric", nrows = 566268)
  
  # mean monthly precipitation
  download.file("http://www.cru.uea.ac.uk/cru/data/hrg/tmc/grid_10min_reh.dat.gz", tf)
  reh <- read.table(tf, header = FALSE, colClasses = "numeric", nrows = 566268)
  
  vars <- list(reh, tmp)
  names(vars) <- c("reh", "tmp")
  rm(tf)
  gc()
  return(vars)
}

# eos
