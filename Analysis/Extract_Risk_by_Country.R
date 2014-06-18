##############################################################################
# title         : Extract_Risk_by_Country.R;
# purpose       : Extract blight units for countries growing potato;
# producer      : prepared by A. Sparks;
# last update   : in IRRI, Los Baños, Jun. 2014;
# inputs        : raster opbject of late blight risk calculate by SimCast_Blight_Units.R;
# outputs       : Matrix and graphs of blight unit accumulation for countries of interest;
# remarks 1     : none;
##############################################################################

http://faostat.fao.org/Portals/_Faostat/Downloads/zip_files/Production_Crops_E_All_Data.zip
http://www.naturalearthdata.com/download/110m/cultural/ne_110m_admin_0_countries_lakes.zip

###### Libraries #####
library(raster)
library(rgdal)
library(sp)
library(ggplot2)
library(wesanderson)
####### End Libraries ######

##### Begin data import #####

##!!!!!!!!!! Use only ONE of the following rasters at a time !!!!!!!!!!##
## use only SUSCEPTIBLE blight units ##
CRUCL2.0 <- raster("Cache/Global Blight Risk Maps/CRUCL2.0_SimCastMeta_Susceptible_Prediction.grd")

## or use RESISTANT Blight Units ##
CRUCL2.0_risk <- raster("Cache/Global Blight Risk Maps/CRUCL2.0_SimCastMeta_Resistant_Prediction.grd")

production <- read.csv("Data/Production_Crops_E_All_Data.csv") 
production <- subset(production, CountryCode < 5000) # select only countries, not areas
production <- subset(production, Year == 2012)
production <- subset(production, Item == "Potatoes")
production <- subset(production, Element == "Production")



wrld <- readOGR(dsn = "/Users/asparks/Downloads/ne_110m_admin_0_countries", layer = "ne_110m_admin_0_countries")

## Import shapefile with potato production data ##
wrld <- readOGR(dsn = "/Users/asparks/tmp/Sparks External Backup/Dissertation/data", layer = "cntry_pt_sp_unicef_us1")
wrld <- wrld[wrld@data$POT_HA >= 1, ] # Remove any countries that don"t have potato production
ctr <- data.frame(country = as.character(wrld@data[, "CNTRY_NAME"])) # Create a data frame of these countries" names
pot_ha <- data.frame(potato_ha = as.numeric(wrld@data[, "POT_HA"])) # Create a data frame of potato hectarage/country

##### End of data import #####

#### Extract and visualise country risk #####

values <- extract(CRUCL2.0, wrld) # Extract the values of the raster object by polygons in shape file
values <- data.frame(unlist(lapply(values, FUN = mean, na.rm = TRUE))) # unlist and generate mean values for each polygon
values <- round(values[, 1], 2) # round the values to 2 decimal places

averages <- cbind(ctr, pot_ha, values) # Bind the data frames together
names(averages) <- c("Country", "Potato_ha", "CRUCL2.0_Risk") # Assign proper names to the data frame columns

### Sort the data frame by potato producers
sorted <- averages[order(averages$Potato_ha), ] # Sort by hectares of potato
top10 <- tail(sorted, 10) # Create data frame of top ten growing countries for graph
top10 <- top10[order(-top10$Potato_ha), ] # Invert dataframe for nice table

### Generate bubble plot of blight units and hectarage of Top 10 potato producing countries

ggplot(top10, aes(x = Potato_ha, y = CRUCL2.0_Risk, fill = as.factor(Country)), guide = FALSE) +
  geom_bar(stat = "identity") +
  scale_y_continuous(name = "Blight Units", limits = c(0, 4)) +
  geom_text(size = 4) +
  theme_bw()

#eos
