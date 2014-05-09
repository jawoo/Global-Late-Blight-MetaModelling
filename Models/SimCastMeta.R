##############################################################################
# title         : SimCastMeta.R;
# purpose       : Create a SimCastMeta GAM model for a daily or monthly time-step;
# producer      : prepared by A. Sparks;
# last update   : in Los Baños, Laguna, April 2014;
# inputs        : blight unit values as calculated in SimCast_Blight_Units.R;
# outputs       : GAM suitable for predicting late blight risk using daily T and RH data
#                 graphs illustrating fit of the model;
# remarks       : this model is documented in:
#                 Sparks, A. H., Forbes, G. A., Hijmans, R. J., & Garrett, K. A. (2011). 
#                 A metamodeling framework for extending the application domain of process-based 
#                 ecological models. Ecosphere, 2(8), art90. doi:10.1890/ES11-00128.1
# Licence:      : GPL3;
##############################################################################

###### Libraries #####
require("mgcv")
require("ggplot2")
require("plyr")
require("rgl")
####### End Libraries ######

##### Begin data import #####
## Read the data table of daily blight unit values as generated in SimCast_Blight_Units.R

##!!!!!!!!!! Use only ONE of the following tables !!!!!!!!!!##

##### Data for daily models #####
## Create a SUSCEPTIBLE model with this data for daily weather data
blight.units <- read.table("Cache/Blight Units/all.daily.susceptible.calcs.txt", head = TRUE, sep = "\t", nrow = 448618)

## Create a RESISTANT cultivar model with this data for daily weather data
blight.units <- read.table("Cache/Blight Units/all.daily.resistant.calcs.txt", head = TRUE, sep = "\t", nrow = 448618)

##### Data for monthly models #####
## Create a SUSCEPTIBLE model with this data for monthly weather data
blight.units <- read.table("Cache/Blight Units/all.monthly.susceptible.calcs.txt", head = TRUE, sep = "\t", nrows = 14749)

## Create a RESISTANT model with this data for monthly weather data
blight.units <- read.table("Cache/Blight Units/all.monthly.resistant.calcs.txt", head = TRUE, sep = "\t", nrows = 14749)

##### End of data import #####

##### Begin data management #####
## Split the weather data into two parts for construction and testing
## we used six years of HUSWO data to generate the values, so split at 1992/1993
construction.data <- subset(blight.units, Year <= 1992)

## Model validation data
testing.data <- subset(blight.units, Year >= 1993)

##### End data management #####

###### Begin model creation and testing #####
## A k of 125 generated the most biologically believable model with the daily data we used based on GCV score 
## higher values indicate a "better fitting" model, but an examination of the 3D surface indicates otherwise

## A k of 165 generated the best fit for the monthly weather data
## for more information, ?gam
gam.predict <- gam(Blight~s(C, RH, k = 125), data = construction.data)
summary(gam.predict)

## Test the model
testing.prediction <- predict.gam(gam.predict, testing.data)

## Some values fall below 0, this cannot happen in reality, so set negative values to 0
testing.prediction[testing.prediction<0]=0

## check the correlation between the orginal and the predicted
cor(testing.data$Blight, testing.prediction)

##### Begin graphing section #####

test.plot <- as.data.frame(cbind(testing.data$Blight, testing.prediction))
colnames(test.plot) <- c("blight", "blight.prediction")

## Graphs
vis.gam(
  gam.predict, 
  theta = -45, 
  phi = 35, 
  ticktype = "detailed", 
  main = "", 
  zlab="Predicted Blight Units", 
  ylab = "Relative Humidity (%)", 
  xlab = "Temperature (°C)", 
  shade = TRUE, 
  zlim = c(0, 8), 
  cex.lab = 0.8, 
  cex.axis = 0.8
)

## Create Boxplots
p <- ggplot(test.plot, aes(y = test.plot[, 2], x = test.plot[, 1],
                           group = round_any(blight, 0.1, floor)))

p <- p + geom_boxplot(outlier.shape = NA) + 
  scale_x_continuous("Blight Units Predicted by SimCast") + 
  scale_y_continuous("Blight Units Predicted by SimCast_Meta")

p

##### End graphing section #####

#eos
