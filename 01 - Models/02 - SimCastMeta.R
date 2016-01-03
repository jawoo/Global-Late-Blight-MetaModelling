################################################################################
# title         : 02 - SimCastMeta.R;
# purpose       : Create a SimCastMeta GAM model for a daily or monthly time-step;
# producer      : prepared by A. Sparks;
# last update   : in Los Baños, Laguna, Jan 2016;
# inputs        : blight unit values as calculated in SimCast_Blight_Units.R;
# outputs       : GAM suitable for predicting late blight risk using daily T and RH data
#                 graphs illustrating fit of the model;
# remarks       : this model is documented in:
#                 Sparks, A. H., Forbes, G. A., Hijmans, R. J., & Garrett, K. A. (2011). 
#                 A metamodeling framework for extending the application domain of process-based 
#                 ecological models. Ecosphere, 2(8), art90. doi:10.1890/ES11-00128.1
# Licence:      : GPL2;
################################################################################

# Load libraries ---------------------------------------------------------------
require("mgcv")
require("ggplot2")
require("plyr")
require("readr")
require("rgl")

# Load data --------------------------------------------------------------------

# Use only ONE of the following tables at a time

# Data for daily models
# Create a SUSCEPTIBLE model with this data for daily weather data
#blight_units <- read_tsv("Cache/Blight Units/daily_susceptible_blight_units.txt")

# Create a RESISTANT cultivar model with this data for daily weather data
#blight_units <- read_tsv("Cache/Blight Units/daily_resistant_blight_units.txt")

# Data for monthly models 
# Create a SUSCEPTIBLE model with this data for monthly weather data
blight_units <- read_tsv("Cache/Blight Units/monthly_susceptible_blight_units.txt")

# Create a RESISTANT model with this data for monthly weather data
#blight_units <- read_tsv("Cache/Blight Units/monthly_resistant_blight_units.txt")

# Data manipulation ------------------------------------------------------------
# Split the weather data into two parts for construction and testing
# we used six years of HUSWO data to generate the values, so split at 1992/1993
construction_data <- subset(blight_units, Year <= 1992)

# Model validation data
testing_data <- subset(blight_units, Year >= 1993)

# Modelling --------------------------------------------------------------------
# A k of 150 generated the most biologically believable model with the daily data we used based on GCV score 
# higher values indicate a "better fitting" model, but an examination of the 3D surface indicates otherwise

gam_predict <- gam(Blight~s(C, RH, k = 150), data = construction_data)
summary(gam_predict)

# Test the model
testing_prediction <- predict.gam(gam_predict, testing_data)

# Some values fall below 0, this cannot happen in reality, so set negative values to 0
testing_prediction[testing_prediction<0]=0

# check the correlation between the orginal and the predicted
cor(testing_data$Blight, testing_prediction)

# Model visualisation ----------------------------------------------------------

test.plot <- as.data.frame(cbind(testing_data$Blight, testing_prediction))
colnames(test.plot) <- c("blight", "blight.prediction")

# Graphs
vis.gam(
  gam_predict, 
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

# Boxplots
p <- ggplot(test.plot, aes(y = test.plot[, 2], x = test.plot[, 1],
                           group = round_any(blight, 0.1, floor)))

p <- p + geom_boxplot(outlier.shape = NA) + 
  scale_x_continuous("Blight Units Predicted by SimCast") + 
  scale_y_continuous("Blight Units Predicted by SimCast_Meta")

p

# eos
