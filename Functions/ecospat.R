##############################################################################
# title         : ecospat.R;
# purpose       : function to run the ecocrop model using a raster stack;
# producer      : prepared by R. Hijmans and A. Sparks;
# last update   : in Los Baños, April 2014;
# inputs        : na;
# outputs       : na;
# remarks 1     : ;
##############################################################################

ecospat <- function(crop, tmn, tmx, tmp, pre, rainfed = TRUE, filename = '', ...) {
  pot <- ecocropCrop(crop)
  outr <- raster(tmp)
  filename <- trim(filename)
  v <- vector(length=ncol(outr))
  if (filename == '') {
    vv <- matrix(ncol = nrow(outr), nrow = ncol(outr))
  }
  for (r in 1:nrow(outr)){
    v[] <- NA
    
    
    temp <- getValues(tmp, r) / 10
    tmin <- getValues(tmn, r) / 10
    if (rainfed) { prec <- getValues(pre, r) / 10 }
    nac <- which(!is.na(tmin[,1]))
    for (c in nac) {
      if (rainfed) {
        clm <- cbind(data.frame(tmin[c,]), temp[c,],  prec[c,])
      } else {
        clm <- cbind(data.frame(tmin[c,]), temp[c,])
      }
      if(sum(is.na(clm)) == 0) {
        e <- ecocrop(clm, pot, rain=rainfed)
        v[c] <- e@maxper[1]
      }
    }
    if (filename == '') {
      vv[,r] <- v
    } else {
      outr <- setValues(outr, v, r)
      outr <- writeRaster(outr, filename, ...)
    }
  }
  if (filename == '') { outr <- setValues(outr, as.vector(vv))  }
  return(outr)
}


#alt  <- raster('G:/data/grids/cru/New10m/alt', values=TRUE)
tmp  <- stack(paste('G:/data/grids/cru/New10m/tmp', 1:12, sep = ''))
tmn  <- stack(paste('G:/data/grids/cru/New10m/tmn', 1:12, sep = ''))
tmx  <- stack(paste('G:/data/grids/cru/New10m/tmx', 1:12, sep = ''))
pre  <- stack(paste('G:/data/grids/cru/New10m/pre', 1:12, sep = ''))
# to speed things up a bit:
tmp <- readAll(tmp)
tmn <- readAll(tmn)
tmx <- readAll(tmx)
pre <- readAll(pre)

#eos
