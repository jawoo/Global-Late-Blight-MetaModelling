##############################################################################
# title         : ecospat.R;
# purpose       : function to run the ecocrop model using a raster stack;
# producer      : prepared by R. Hijmans and A. Sparks;
# last update   : in Los Baños, April 2014;
# inputs        : na;
# outputs       : na;
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

ecospat <- function(crop, tmn, tmx, tmp, pre, rainfed = TRUE, filename = "", ...) {
  if (class(crop) == "character") { crop <- ecocropCrop(crop) }
  if (class(crop) != "ECOCROPcrop") { stop("crop is of wrong class") }
  
  filename  <- trim(filename)
  outr      <- raster(tmp)
  v         <- vector(length = ncol(outr))
  for (r in 1:nrow(outr)){
    v[] <- NA
    
    temp <- getValues(tmp, r)
    tmin <- getValues(tmn, r)
    if (rainfed) { prec <- getValues(pre, r)}
    
    nac <- which(!is.na(tmin[, 1]))
    
    for (i in nac) {
      if (rainfed) {
        clm <- cbind(data.frame(tmin[i,]), temp[i,],  prec[i,])
      } else {
        clm <- cbind(data.frame(tmin[i, ]), temp[i, ])
      }
      
      if(sum(is.na(clm)) == 0) {
        e <- ecocrop(crop = "potato", clm[, 1], clm[, 2], clm[, 3], rain = rainfed) 
        v[i] <- e@maxper[1]
      }
    }
    
    outr[r, ] <- v
    outr <- writeRaster(outr, filename, ...)
  }
  return(outr)
}

#eos
