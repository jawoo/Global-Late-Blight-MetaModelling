##############################################################################
# title         : Extract_Risk_by_Country.R;
# purpose       : Extract blight units for countries growing potato;
# producer      : prepared by A. Sparks;
# last update   : in IRRI, Los Baños, Jun. 2014;
# inputs        : raster opbject of late blight risk calculate by SimCast_Blight_Units.R;
# outputs       : Matrix and graphs of blight unit accumulation for countries of interest;
# remarks 1     : none;
##############################################################################

###### Libraries #####
library(raster)
library(rgdal)
library(maptools)
library(ggplot2)
library(rworldmap)
library(wesanderson)
####### End Libraries ######

tf <- tempfile()
td <- tempdir()

##### Begin data import and cleanup #####

# Countries for mapping and extracting blight risk by country from rworldmap
data(countryExData) 

##!!!!!!!!!! Use only ONE of the following rasters at a time !!!!!!!!!!##
## use only SUSCEPTIBLE blight units ##
CRUCL2.0 <- raster("Cache/Global Blight Risk Maps/CRUCL2.0_SimCastMeta_Susceptible_Prediction.grd")

## or use RESISTANT Blight Units ##
CRUCL2.0_risk <- raster("Cache/Global Blight Risk Maps/CRUCL2.0_SimCastMeta_Resistant_Prediction.grd")

download.file("http://faostat.fao.org/Portals/_Faostat/Downloads/zip_files/Production_Crops_E_All_Data.zip", tf)
production <- read.csv(unzip(tf), header = TRUE, stringsAsFactors = FALSE, nrows = 2359749)
production <- subset(production, CountryCode < 5000) # select only countries, not areas
production <- subset(production, Year == 2012) # select the most recent year available
production <- subset(production, Item == "Potatoes") # select only potatoes
production <- subset(production, Element == "Area harvested") # select for number hectares harvested

#### Replace names of countries that will not match rworldmap data names ####

## China needs to be seperated from Taiwan, luckily there's a "Mainland China" and "Taiwan" in production data
production <- subset(production, Country != "China")
production[, 2][production[, 2] == "China, Taiwan Province of"] <- "Taiwan"
production[, 2][production[, 2] == "China, mainland"] <- "China"

## Rename "Sudan (former)" to just "Sudan"
production[, 2][production[, 2] == "Sudan (former)"] <- "Sudan"

## Rename "Cabo Verde" to "Republic of Cape Verde"
production[, 2][production[, 2] == "Cabo Verde"] <- "Republic of Cape Verde"

## Make Reúnion a part of France
production[, 2][production[, 2] == "France"] <- sum(production[, 10][production[, 2] == "France" && "R\xe9union"])
production[, 2][production[, 2] == 0] <- "France"
production <- subset(production, Country != "R\xe9union")

##### End of data import and cleanup #####

### Now we can join the FAO data with the rworldmap
wrld <- joinCountryData2Map(production, countryExData, joinCode = "NAME", nameJoinColumn = "Country", verbose = TRUE)

#### Extract and visualise country risk #####

values <- extract(CRUCL2.0, wrld) # Extract the values of the raster object by polygons in shape file
values <- data.frame(unlist(lapply(values, FUN = mean, na.rm = TRUE))) # unlist and generate mean values for each polygon
names(values) <- "BlightRisk"
row.names(values) <- row.names(wrld)

wrld <- cbind(wrld, values) # Bind the data frames together

mapCountryData(wrld, nameColumnToPlot = "BlightRisk")


### Sort the data frame by potato producers
averages <- na.omit(data.frame(wrld$NAME, wrld$Value, wrld$BlightRisk))
names(averages) <- c("Country", "HaPotato", "BlightRisk")
sorted <- averages[order(averages$HaPotato), ] # Sort by hectares of potato
top10 <- data.frame(tail(sorted, 10)) # Create data frame of top ten growing countries for graph
top10 <- top10[order(-top10$HaPotato), ] # Invert dataframe for nice table

### Generate bubble plot of blight units and hectarage of Top 10 potato producing countries

ggplot(top10, aes(x = HaPotato, y = BlightRisk, fill = as.factor(Country)), guide = FALSE) +
  geom_bar(stat = "identity", position = "jitter") +
  scale_y_continuous(name = "Blight Units", limits = c(0, 2.5)) +
  theme_bw()

#eos
