##############################################################################
# title         : Extract_Map_and_Visualise_Risk_by_Country.R;
# purpose       : Extract blight units for countries growing potato;
# producer      : prepared by A. Sparks;
# last update   : in IRRI, Los Baños, Dec 2015;
# inputs        : Raster objects of late blight risk calculate by SimCast_Blight_Units.R;
# outputs       : Matrix and graphs of blight unit accumulation for countries of interest;
# remarks 1     : none;
##############################################################################

###### Libraries #####
library(raster)
library(maptools)
library(ggplot2)
library(rgdal)
library(reshape)
library(dplyr)
library(readr)
####### End Libraries ######

##### Begin data import and cleanup #####
# Tempfile for download of FAO data and Natural Earth data
tf.fao <- tempfile()
tf.ne <- tempfile()

##!!!!!!!!!! Use only ONE of the following rasters at a time !!!!!!!!!!##
## use only SUSCEPTIBLE blight units ##
CRUCL2.0.risk <- raster("./Cache/Global Blight Risk Maps/CRUCL2.0_SimCastMeta_Susceptible_Prediction.tif")

## or use RESISTANT Blight Units ##
#CRUCL2.0.risk <- raster("Cache/Global Blight Risk Maps/CRUCL2.0_SimCastMeta_Resistant_Prediction.tif")


## Download Natural Earth 1:50 Scale Data for extracting data from FAO and global map ##
# If you've already run this script, it will skip this step and just read the shp file
if(!file.exists(paste(getwd(), "./Data/ne_50m_admin_0_countries.shp", sep = ""))) {
  download.file("http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/50m/cultural/ne_50m_admin_0_countries.zip", 
                tf.ne, 
                mode = "wb")
  unzip(tf.ne, exdir = "./Data")
}

NE <- readOGR(dsn = "./Data", layer = "ne_50m_admin_0_countries")
NE <- crop(NE, extent(-180, 180, -60, 84)) # remove Antarctica from the data for cleaner map

## Download crop production data from FAO and create dataframe of only potato production data
## If you have already run this script, the script will skip this step
if(!file.exists(paste(getwd(), "./Data/Production_Crops_E_All_Data.csv", sep = ""))) {
  download.file("http://faostat.fao.org/Portals/_Faostat/Downloads/zip_files/Production_Crops_E_All_Data.zip", 
                tf.fao, 
                mode = "wb") # this is a large file
  FAO <- unzip(tf.fao, exdir = "./Data") # unzip csv file from FAO
}

FAO <- read_csv("./Data/Production_Crops_E_All_Data.csv")

FAO <- subset(FAO, CountryCode < 5000) # select only countries, not areas
FAO <- subset(FAO, Year == max(FAO$Year)) # select the most recent year available
FAO <- subset(FAO, Item == "Potatoes") # select only potatoes
FAO <- FAO[, -11] # drop the flag column

## Because of the "Element" column, we have to go through gymnastics to get columns for yield and area harvested
yield <- subset(FAO, Element == "Yield") # select for yield
production <- subset(FAO, Element == "Area harvested") # Select for area harvested
names(production)[9:10] <- c("AreaUnit", "AreaHarvested") # Rename the production columns

FAO <- merge(production, yield, by = c( "CountryCode", "Country", "ItemCode", "Item", "Year")) # merge the new dataframes using the FAO object
names(FAO)[14:15] <- c("YieldUnit", "Yield") # name the yield columns in the resulting FAO data frame

## Replace names of countries that will not match rworldmap data names
## China needs to be seperated from Taiwan, luckily there's a "Mainland China" and "Taiwan" in production data
FAO <- subset(FAO, Country != "China")
FAO <- subset(FAO, Country != "China, Macao SAR") # Remove Macao, neglible potoato
FAO <- subset(FAO, Country != "China, Hong Kong SAR") # Remove Hong Kong, neglible potoato
FAO[, 2][FAO[, 2] == "China, Taiwan Province of"] <- "Taiwan"
FAO[, 2][FAO[, 2] == "China, mainland"] <- "China"

## Rename "Sudan (former)" to just "Sudan"
FAO[, 2][FAO[, 2] == "Sudan (former)"] <- "Sudan"

## Rename "Cabo Verde" to "Republic of Cape Verde"
FAO[, 2][FAO[, 2] == "Cabo Verde"] <- "Cape Verde"

## Rename "Venuzuela (United Republic of)" to "Venuzuela"
FAO[, 2][FAO[, 2] == "Venezuela (Bolivarian Republic of)"] <- "Venezuela"

## Rename "Russian Federation" to "Russia"
FAO[, 2][FAO[, 2] == "Russian Federation"] <- "Russia"

## Rename "Russian Federation" to "Russia"
FAO[, 2][FAO[, 2] =="C\xf4te d'Ivoire"] <- "Ivory Coast"

## Rename "Russian Federation" to "Russia"
FAO[, 2][FAO[, 2] =="Iran (Islamic Republic of)"] <- "Iran"

## Make Reúnion a part of France
FAO[, 2][FAO[, 2] == "France"] <- sum(FAO[, 10][FAO[, 2] == "France" && "R\xe9union"])
FAO[, 2][FAO[, 2] == 0] <- "France"
# Remove Reúnion from the data
FAO <- subset(FAO, Country != "R\xe9union")


## Download Nepal GADM data to generate ecosystem map ##
nepal <- getData("GADM", country = "NPL", level = 0, path = "./Data")


##### End of data import and cleanup #####

##### Data extraction and munging #####
## Colombia and Ecuador map
raster.df <- crop(CRUCL2.0.risk, nepal) # crop and mask the raster file
raster.df <- mask(raster.df, nepal)
raster.df <- data.frame(rasterToPoints(raster.df)) # convert raster object to dataframe for ggplot2

NE@data <- left_join(NE@data, FAO, by = c("admin" = "Country"))

values <- extract(CRUCL2.0.risk, NE, fun = mean, na.rm = TRUE, sp = TRUE) # Extract the values of the raster object by country polygons in shape file and add them to a new spatial object

## Create fortified data frame for mapping using ggplot2
values@data$id <- rownames(values@data)
values.f <- fortify(values, region = "id")
values.f <- left_join(values.f, values@data, by = "id")
values.f$CRUCL2.0_SimCastMeta_Susceptible_Prediction[is.na(values.f$CRUCL2.0_SimCastMeta_Susceptible_Prediction)] <- 0

## Convert continuous data to factors for mapping
lb.breaks <- seq(0, 3.5, by = 0.5)
values.f$cuts <- cut(values.f$CRUCL2.0_SimCastMeta_Susceptible_Prediction,
                     breaks = lb.breaks,
                     include.lowest = TRUE)


## Create a new dataframe for ggplot2 to use to graph
averages <- na.omit(data.frame(values@data$sovereignt,
                               values@data$Yield,
                               values@data$AreaHarvested,
                               values@data$CRUCL2.0_SimCastMeta_Susceptible_Prediction))
names(averages) <- c("Country", "Yield", "HaPotato", "BlightRisk")

## Sort the data frame by potato producers
sorted <- averages[order(averages$HaPotato), ] # Sort by hectares of potato
top10 <- data.frame(tail(sorted, 10)) # Create data frame of top ten growing countries for graph

## Sort the data frame by late blight risk ranking
sorted.blight <- averages[order(averages$BlightRisk), ] # Sort by hectares of potato
top10.blight <- data.frame(tail(sorted.blight, 10)) # Create data frame of top ten growing countries for graph
top10.blight$Country <- factor(top10.blight$Country, levels = top10.blight$Country[order(top10.blight$BlightRisk)]) # Order by blight units, not country


#### End data extraction and munging ####


##### Data visualization #####

### Maps ###
# Mean blight units by country
ggplot() +
  geom_polygon(data = values.f, 
               aes(x = long, 
                   y = lat, 
                   group = group, 
                   fill = cuts), 
               colour = "black", size = 0.25) + 
  scale_fill_brewer(palette = "YlOrRd", name = "Blight\nUnits") +
  theme_minimal() +
  xlab("Longitude") +
  ylab("Latitude") +
  ggtitle("Daily Blight Unit Accumulation Per Potato Growing Season") +
  coord_map("mollweide")

### Plot Nepal (Similar to Figure 9 from Sparks et al. 2014)
ggplot(data = nepal) +
  geom_polygon(aes(x = long, 
                   y = lat, 
                   group = group)) +
  geom_tile(data = raster.df,
            aes(x = x, 
                y = y, 
                fill = CRUCL2.0_SimCastMeta_Susceptible_Prediction,
                colour = CRUCL2.0_SimCastMeta_Susceptible_Prediction)) +
  scale_fill_continuous(low = "yellow", high = "red4", 
                    name = "Blight\nunits") +
  scale_colour_continuous(low = "yellow", high = "red4", 
                      name = "Blight\nunits") +
  theme_minimal() +
  xlab("Longitude") +
  ylab("Latitude") +
  coord_map(projection = "lambert", lat0 = 26.34, lat1 = 30.45)


## Plot average global blight risk by countries
### Graphs

top10 # View the top 10 potato producing countries by Ha production and corresponding blight units (level risk)
top10.blight # View the top ten countries by highest risk for late blight

### Generate bubble chart of blight units, potato yields and hectarage of Top 10 potato producing countries
## Note that that the log(Ha) is used so that data displays properly, otherwise China's data skews plot
ggplot(top10, aes(x = HaPotato, y = BlightRisk, size = Yield/10000, label = Country)) +
  geom_point(colour = "white", fill = "red", shape = 21, alpha = 0.5) + 
  scale_size_area(max_size = 30, "Yield (T/Ha)") +
  xlab("Potato production (Ha)") +
  ylab("Average daily blight units") +
  geom_text(size = 4) 


### Generate bar chart of blight units for Top 10 countries ranked by blight risk for historic normal conditions
ggplot(top10.blight, aes(x = factor(Country), y = BlightRisk)) +
  geom_bar(stat = "identity", aes(fill = BlightRisk)) +
  xlab("Country") +
  scale_fill_gradient("Average daily blight units") +
  ylab("Blight Units") +
  coord_flip()

#### End data visualization #####

#eos
