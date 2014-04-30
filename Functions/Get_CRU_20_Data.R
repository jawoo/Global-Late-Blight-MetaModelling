##############################################################################
# title         : Get_CRU_20_Data.R;
# purpose       : Download and process CRU CL 2.0 data into data frames in R;
# producer      : prepared by A. Sparks;
# last update   : in Los Baños, Laguna, April 2014;
# inputs        : CRU CL2.0 Climate data;
# outputs       : ;
# remarks 1     : a standalone version exists as a gist here: https://gist.github.com/adamhsparks/11284393;
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

##### Download and read CRU data files ####
CRU_DL <- function(){
  ## create a temp file and directory for downloading files
  tf <- tempfile()
  ## mean monthly diurnal temperature range ####
  download.file("http://www.cru.uea.ac.uk/cru/data/hrg/tmc/grid_10min_dtr.dat.gz", tf)
  dtr <- read.table(tf, header = FALSE, colClasses = "numeric", nrows = 566262) # use header, colClasses and nrows to speed input into R
  
  ## mean monthly temperature ####
  download.file("http://www.cru.uea.ac.uk/cru/data/hrg/tmc/grid_10min_tmp.dat.gz", tf)
  tmp <- read.table(tf, header = FALSE, colClasses = "numeric", nrows = 566262) # use header, colClasses and nrows to speed input into R
  
  ## mean monthly precipitation #####
  download.file("http://www.cru.uea.ac.uk/cru/data/hrg/tmc/grid_10min_pre.dat.gz", tf)
  pre <- read.table(tf, header = FALSE, colClasses = "numeric", nrows = 566268) # use header, colClasses and nrows to speed input into R
  pre <- pre[, 1:14] # remove CV columns of precip from table
  
  #### calculate tmax and tmin from tmp and dtr (see: http://www.cru.uea.ac.uk/cru/data/hrg/tmc/readme.txt) #####
  tmx <- cbind(tmp[, 1:2], tmp[, c(3:14)]+(0.5*dtr[, c(3:14)])) # cbind xy data from tmp with new tmx data
  tmn <- cbind(tmp[, 1:2], tmp[, c(3:14)]-(0.5*dtr[, c(3:14)])) # cbind xy data from tmp with new tmn data
  
  vars <- list(pre, tmn, tmp, tmx)
  names(vars) <- c('pre', 'tmn', 'tmp', 'tmx')
  return(vars)
}

#eos
