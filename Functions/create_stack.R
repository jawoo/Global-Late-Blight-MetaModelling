##############################################################################
# title         : create_stack.R;
# purpose       : Create raster stacks of CRU CL 2.0 data;
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

## Create raster objects using cellFromXY and generate a raster stack
## create.stack takes pre, tmp, tmn and tmx and creates a raster object stack of 12 month data
create.stack <- function(wvar){ 
  ##### column names and later layer names for raster stack objects ####
  months <- c("jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec")
  
  ## set up a raster object to use as the basis for converting CRU data to raster objects at 10 arc minute resolution ####
  x <- raster(nrows = 900, ncols = 2160, ymn = -60, ymx = 90, xmn = -180, xmx = 180) 
  
  ## determine the cells with values in CRU data
  cells <- cellFromXY(x, wvar[, c(2, 1)])
  
  ## take each month and make a raster layer with it
  for(i in 3:14){
    x[cells] <- wvar[, i]
    if(i == 3){y <- x} else y <- stack(y, x)
  }
  names(y) <- months
  return(y)
  rm(x)
}
