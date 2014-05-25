##############################################################################
# title         : ecospat.R;
# purpose       : function to run the ecocrop model using a raster stack;
# producer      : prepared by R. Hijmans and A. Sparks;
# last update   : in New Delhi, May 2014;
# inputs        : raster stacks of avg/min/max temperature, precipitation;
# outputs       : na;
# remarks 1     : ;
# Licence:      : GPL2;
##############################################################################

ecospat <- function(crop, tmn, tmx, tmp, pre, rainfed = TRUE, filename = "", ...) {
  pot       <- ecocrop(crop)
  outr      <- raster(tmp)
  v         <- vector(length = ncol(outr))
  filename  <- trim(filename)
  if (filename == "") {
    vv <- matrix(ncol = nrow(outr), nrow = ncol(outr))
  }
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
        e <- ecocrop(clm, pot, rain = rainfed)
        v[i] <- e@maxper[1]
      }
    }
    
    if (filename=='') {
      vv[,r] <- v
    } else {
        outr[r, ] <- v
        outr <- writeRaster(outr, filename, ...)
  }
  if (filename == "") { outr <- setValues(outr, as.vector(vv))  }
  return(outr)
}
}
#eos
