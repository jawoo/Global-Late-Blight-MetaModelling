##############################################################################
# title         : run_ecocrop.R;
# purpose       : function to run the ecocrop model using a raster stack;
# producer      : prepared by R. Hijmans and A. Sparks;
# last update   : in Raipur, India, May 2014;
# inputs        : raster stacks of avg/min/max temperature, precipitation;
# outputs       : na;
# remarks 1     : ;
# Licence:      : GPL2;
##############################################################################

run.ecocrop <- function(crop, tmn, tmx, tmp, pre, rainfed = TRUE, filename = "", ...) {
  pot       <- getCrop(crop)
  outr      <- raster(tmp)
  v         <- vector(length = ncol(outr))
  filename  <- trim(filename)
  if (filename == "") {
    vv <- matrix(ncol = nrow(outr), nrow = ncol(outr))
  }
  for (r in 1:nrow(outr)){
    v[] <- NA
    
    temp <- getValues(tmp, r) # Take values for row "r" for all layers (months) of raster stack
    tmin <- getValues(tmn, r) # Take values for row "r" for all layers (months) of raster stack
    if (rainfed) { prec <- getValues(pre, r) } # If crop is rainfed, then take values for row "r" for all layers (months) of raster stack
    
    nac <- which(!is.na(tmin[, 1])) # Which raster cell numbers != NA
    
    for (i in nac) {
      if (rainfed == TRUE) { # if rainfed = TRUE, then create data frame with precipitation data in it
        clm <- cbind(data.frame(tmin[i, ]), temp[i, ],  prec[i, ]) # bind monthly cell values into one data frame for tmin, average temp and precip for rainfed potato
      } else { # if the potato crop is irrigated, then don't use precipitation data in data frame
        clm <- cbind(data.frame(tmin[i, ]), temp[i, ]) # bind monthly cell values into one data frame for tmin and average temp for irrigated potato
      }
      
      if(sum(is.na(clm)) == 0) {
        e <- ecocrop(pot, clm[, 1], clm[, 2], clm[, 3], rain = rainfed) # run Ecocrop model to determine the establishment month that produces highest yield
        v[i] <- e@maxper[1] # set the value of the raster cell to monthly value
      }
    }
    
    outr[r, ] <- v
    outr <- writeRaster(outr, filename, ...)
  }
  return(outr)
}

#eos
