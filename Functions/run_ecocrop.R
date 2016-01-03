##############################################################################
# title         : Run_EcoCrop.R;
# purpose       : function to run the EcoCrop model using a raster stack;
# producer      : prepared by R. Hijmans and A. Sparks;
# last update   : in Los Baños, Philippines, Jan 2016;
# inputs        : EcoCrop planting date predictions;
# outputs       : na;
# remarks 1     : ;
# Licence:      : GPL2;
##############################################################################

pot <- getCrop("potato")
pot@RMIN  <- 125
pot@ROPMN <- 250
pot@ROPMX <- 350
pot@TMIN  <- 7
pot@TOPMX <- 20
pot@GMIN  <- pot@GMAX <- 100

run_ecocrop <- function(pot, tmn, tmx, tmp, pre, rainfed = TRUE, filename, ...) {
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
        e <- ecocrop(crop = pot, tmin = clm[, 1], 
                     tavg = clm[, 2], 
                     prec = clm[, 3], 
                     rain = rainfed) 
        v[i] <- e@maxper[1]
      }
    }
    
    outr[r, ] <- v
    outr <- writeRaster(outr, filename, ...)
  }
  return(outr)
}

#eos
  