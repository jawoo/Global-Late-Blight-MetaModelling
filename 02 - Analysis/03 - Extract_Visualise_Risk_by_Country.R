##############################################################################
# title         : 03 -Extract_Visualise_Risk_by_Country.R;
# purpose       : Extract blight units for countries growing potato;
# producer      : prepared by A. Sparks;
# last update   : in IRRI, Los Baños, Jan 2016;
# inputs        : raster opbject of late blight risk calculate by SimCast_Blight_Units.R;
# outputs       : Matrix and graphs of blight unit accumulation for countries of interest;
# remarks 1     : none;
###############################################################################

# Libraries -------------------------------------------------------------------
library(raster)
library(maptools)
library(ggplot2)
library(ggthemes)
library(rgdal)
library(reshape)
library(dplyr)
library(readr)
library(rnaturalearth)
library(viridis)

# Load Data --------------------------------------------------------------------
# Use only ONE of the following rasters sets at a time

CRUCL2.0_risk <- raster("Cache/Global Blight Risk Maps/CRUCL2.0_SimCastMeta_Susceptible_Prediction.tif")
A2_risk <- raster("Cache/Global Blight Risk Maps/A2_SimCastMeta_Susceptible_Prediction.tif")

# or use only RESISTANT Blight Units
#CRUCL2.0_risk <- raster("Cache/Global Blight Risk Maps/CRUCL2.0_SimCastMeta_Resistant_Prediction.tif")
#A2_risk <- raster("Cache/Global Blight Risk Maps/A2_SimCastMeta_Resistant_Prediction.tif")

# Download Natural Earth 1:50 Scale Data for  extracting data from FAO and making global map
NE <- ne_countries(scale = 50)
NE <- crop(NE, extent(-180, 180, -60, 84)) # remove Antarctica from the data for cleaner map

# CSV file for crop production data downloaded from FAO:
  # Food and Agriculture Organization of the United Nations. FAOSTAT. Crops
  # ( National Production). (Latest update: Dataset) Accessed (06 Mar 2014).
  # URI: 4 May 2017

FAO <- readr::read_csv("data/dump.csv.zip")

# Data munging -----------------------------------------------------------------
FAO <- subset(FAO, Crops == "Potatoes") # select only potatoes
FAO <- subset(FAO, Year == max(FAO$Year)) # select the most recent year available

# create an object of only Nepal for map of change in Nepal
nepal <- subset(NE, admin == "Nepal")


change <- A2_risk - CRUCL2.0_risk

NE@data <- left_join(NE@data, FAO, by = c("admin" = "Country"))

values <- extract(CRUCL2.0_risk, NE, fun = mean, na.rm = TRUE, sp = TRUE) 
values <- extract(A2_risk, values, fun = mean, na.rm = TRUE, sp = TRUE)
values <- extract(change, values, fun = mean, na.rm = TRUE, sp = TRUE)

values@data$id <- rownames(values@data)
values_f <- fortify(values, region = "id")
values_f <- left_join(values_f, values@data, by = "id")
values_f$CRUCL2.0_SimCastMeta_Susceptible_Prediction[is.na(values_f$CRUCL2.0_SimCastMeta_Susceptible_Prediction)] <- 0
values_f$A2_SimCastMeta_Susceptible_Prediction[is.na(values_f$A2_SimCastMeta_Susceptible_Prediction)] <- 0
values_f$change <- values_f$A2_SimCastMeta_Susceptible_Prediction - values_f$CRUCL2.0_SimCastMeta_Susceptible_Prediction

raster_df <- crop(change, nepal) # crop and mask the raster file
raster_df <- mask(raster_df, nepal)
raster_df <- data.frame(rasterToPoints(raster_df)) # convert raster object to dataframe for ggplot2

avg_breaks <- seq(-0.8, 1.75, by = 0.25)
values_f$cuts <- cut(values_f$change,
                     breaks = avg_breaks,
                     include.lowest = TRUE)

lb_breaks <- seq(-4, 4, by = 1)
labs <- seq(-3, 4, by = 1)
raster_df$cuts <- cut(raster_df$layer,
                      breaks = lb_breaks,
                      labels = labs,
                      include.lowest = TRUE)


averages <- na.omit(data.frame(values@data$sovereignt,
                               values@data$`Yield [hg/ha]`,
                               values@data$`Area Harvested [ha]`,
                               values@data$CRUCL2.0_SimCastMeta_Susceptible_Prediction,
                               values@data$A2_SimCastMeta_Susceptible_Prediction,
                               values@data$layer))
names(averages) <- c("Country", "Yield", "HaPotato", "CRU_BlightRisk",
                     "A2_BlightRisk", "Change")


# Data visualisation -----------------------------------------------------------

# Global average change per country
ggplot() +
  geom_polygon(data = values_f, 
               aes(x = long, 
                   y = lat, 
                   group = group, 
                   fill = cuts), 
               colour = "black", size = 0.25) + 
  scale_fill_viridis(discrete = TRUE) +
  theme_minimal() +
  xlab("Longitude") +
  ylab("Latitude") +
  ggtitle("Change Daily Blight Unit Accumulation Per Potato Growing Season") +
  coord_map("mollweide")

# Plot Nepal (After to Figure 9 from Sparks et al. 2014), not exact, but close enough
ggplot(data = nepal) +
  geom_polygon(aes(x = long, 
                   y = lat, 
                   group = group)) +
  geom_tile(data = raster_df,
            aes(x = x, 
                y = y, 
                fill = cuts,
                colour = cuts), 
            size = 0.4) +
  scale_fill_manual(values = c("#65C0A3", "#A8DCA2", "#CACACA", "#FDDF89",
                               "#FCAB60", "#F36B42", "#D33E4E", "#880383"), 
                    name = "Blight\nunits") +
  scale_colour_manual(values = c("#65C0A3", "#A8DCA2", "#CACACA", "#FDDF89",
                                 "#FCAB60", "#F36B42", "#D33E4E", "#880383"), 
                    name = "Blight\nunits") +
  theme_minimal() +
  xlab("Longitude") +
  ylab("Latitude") +
  coord_map(projection = "lambert", lat0 = 26.34, lat1 = 30.45)


## Sort the data frame by potato producers
sorted <- averages[order(averages$HaPotato), ]
top10 <- data.frame(tail(sorted, 10))

top10 

ggplot(top10, aes(x = HaPotato, y = Change, size = Yield/10000)) +
  geom_point(shape = 21, alpha = 0.5, (aes(fill = Change))) + 
  scale_fill_viridis() +
  scale_size_area(max_size = 30, "Yield (T/Ha)") +
  geom_text(aes(x = HaPotato, y = Change, label = Country),
             position = position_dodge(width = 1),
             size = 3) +
  xlab("Potato production (Ha)") +
  ylab("Change in daily blight unit accumulation")


sorted_blight <- averages[order(averages$Change), ]
top10_blight <- data.frame(tail(sorted_blight, 10))
top10_blight$Country <- factor(top10_blight$Country,
                               levels = top10_blight$Country[order(top10_blight$Change)])

top10_blight

ggplot(top10_blight, aes(x = factor(Country), y = Change)) +
  geom_bar(stat = "identity", aes(fill = Change)) +
  xlab("Country") +
  scale_fill_viridis("Blight Units") +
  ylab("Blight Units") +
  coord_flip()

# eos
