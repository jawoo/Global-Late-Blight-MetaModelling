##############################################################################
# title         : ecospat.R;
# purpose       : function to run the ecocrop model using a raster stack;
# producer      : prepared by R. Hijmans and A. Sparks;
# last update   : in Los Baños, April 2014;
# inputs        : na;
# outputs       : na;
# remarks 1     : ;
##############################################################################

ecospat <- function(crop, tmn, tmx, tmp, pre, rainfed = TRUE, filename, ...) {
  pot       <- getCrop(crop)
  filename  <- trim(filename)
  outr      <- raster(tmp)
  v         <- vector(length = ncol(outr))
  for (r in 1:nrow(outr)){
    v[] <- NA
    
    temp <- getValues(tmp, r) / 10
    tmin <- getValues(tmn, r) / 10
    if (rainfed) { prec <- getValues(pre, r) / 10 }
    
    nac <- which(!is.na(tmin[, 1]))
    
    for (i in nac) {
      if (rainfed) {
        clm <- cbind(data.frame(tmin[i,]), temp[i,],  prec[i,])
      } else {
        clm <- cbind(data.frame(tmin[i, ]), temp[i, ])
      }
      
      if(sum(is.na(clm)) == 0) {
        e <- ecocrop(crop = 'potato', clm[, 1], clm[, 2], clm[, 3], rain = rainfed) 
        v[i] <- e@maxper[1]
      }
    }
    
    outr[r, ] <- v
    outr <- writeRaster(outr, filename, ...)
  }
  return(outr)
}

#eos
