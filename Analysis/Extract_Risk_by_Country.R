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
library(maptools)
library(ggplot2)
library(rworldmap)
library(reshape)
####### End Libraries ######

##### Begin data import and cleanup #####
# Tempfile for download of FAO data
tf <- tempfile()

# Countries for mapping and extracting blight risk by country from rworldmap
data(countryExData) 

##!!!!!!!!!! Use only ONE of the following rasters at a time !!!!!!!!!!##
## use only SUSCEPTIBLE blight units ##
CRUCL2.0.risk <- raster("Cache/Global Blight Risk Maps/CRUCL2.0_SimCastMeta_Susceptible_Prediction.tif")

## or use RESISTANT Blight Units ##
CRUCL2.0.risk <- raster("Cache/Global Blight Risk Maps/CRUCL2.0_SimCastMeta_Resistant_Prediction.tif")

## Download crop production data from FAO and create dataframe of only potato production data
download.file("http://faostat.fao.org/Portals/_Faostat/Downloads/zip_files/Production_Crops_E_All_Data.zip", tf) # this is a large file
FAO <- read.csv(unzip(tf), stringsAsFactors = FALSE, nrows = 2359749) # unzip and read the resulting csv file from FAO
file.remove("Production_Crops_E_All_Data.csv") # clean up the unzipped CSV file
FAO <- subset(FAO, CountryCode < 5000) # select only countries, not areas
FAO <- subset(FAO, Year == 2012) # select the most recent year available
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
FAO[, 2][FAO[, 2] == "China, Taiwan Province of"] <- "Taiwan"
FAO[, 2][FAO[, 2] == "China, mainland"] <- "China"

## Rename "Sudan (former)" to just "Sudan"
FAO[, 2][FAO[, 2] == "Sudan (former)"] <- "Sudan"

## Rename "Cabo Verde" to "Republic of Cape Verde"
FAO[, 2][FAO[, 2] == "Cabo Verde"] <- "Republic of Cape Verde"

## Make Reúnion a part of France
FAO[, 2][FAO[, 2] == "France"] <- sum(FAO[, 10][FAO[, 2] == "France" && "R\xe9union"])
FAO[, 2][FAO[, 2] == 0] <- "France"
FAO <- subset(FAO, Country != "R\xe9union") # Remove Reúnion from the data

##### End of data import and cleanup #####

##### Data extraction and munging #####
wrld <- joinCountryData2Map(FAO, countryExData, joinCode = "NAME", nameJoinColumn = "Country", verbose = TRUE)

## CRU Blight Units
CRU.values <- extract(CRUCL2.0.risk, wrld) # Extract the values of the raster object by country polygons in shape file
CRU.values <- data.frame(unlist(lapply(CRU.values, FUN = mean, na.rm = TRUE))) # unlist and generate mean values for each polygon
names(CRU.values) <- "CRU BlightRisk" # assign "BlightRisk" name to column
row.names(CRU.values) <- row.names(wrld) # assign row names to values so that we can use spCbind to merge with wrld
row.names(wrld) <- row.names(wrld) # for some reason the above results in row names that don't match, this fixes that

## A2 Blight Units
A2.values <- extract(A2.risk, wrld) # Extract the values of the raster object by country polygons in shape file
A2.values <- data.frame(unlist(lapply(A2.values, FUN = mean, na.rm = TRUE))) # unlist and generate mean values for each polygon
names(A2.values) <- "A2 BlightRisk" # assign "BlightRisk" name to column
row.names(A2.values) <- row.names(wrld) # assign row names to values so that we can use spCbind to merge with wrld

## Change
change <- A2.values - CRU.values

# Bind the data frames together in a spatial object
wrld <- spCbind(wrld, CRU.values, A2.values, change) 

#### End data extraction and munging ####

##### Data visualization #####
### Maps
## Plot average global blight risk by countries
mapCountryData(wrld, nameColumnToPlot = "change", mapTitle = "Change in Average Country Blight Units\nor Relative Risk Rank\n1975 to A2 2050", catMethod = "pretty")

### Graphs
## Create a new dataframe for ggplot2 to use to graph
averages <- na.omit(data.frame(wrld$NAME, wrld$Yield, wrld$AreaHarvested, wrld$CRU.BlightRisk))
names(averages) <- c("Country", "Yield", "HaPotato", "BlightRisk")

## Sort the data frame by potato producers
sorted <- averages[order(averages$HaPotato), ] # Sort by hectares of potato
top10 <- data.frame(tail(sorted, 10)) # Create data frame of top ten growing countries for graph

top10 # View the top 10 potato producing countries by Ha production and corresponding blight units (level risk)

### Generate bubble chart of blight units, potato yields and hectarage of Top 10 potato producing countries
## Note that that the log(Ha) is used so that data displays properly, otherwise China's data skews plot
ggplot(top10, aes(x = HaPotato, y = BlightRisk, size = Yield/10000, label = Country)) +
  geom_point(colour = "white", fill = "red", shape = 21, alpha = 0.5) + 
  scale_size_area(max_size = 30, "Yield (T/Ha)") +
  xlab("Potato production (Ha)") +
  ylab("Blight units") +
  geom_text(size = 4) 

### Generate a bar chart of the ten countries with the highest blight risks
## Sort the data frame by late blight risk ranking
sorted.blight <- averages[order(averages$BlightRisk), ] # Sort by hectares of potato
top10.blight <- data.frame(tail(sorted.blight, 10)) # Create data frame of top ten growing countries for graph
top10.blight$Country <- factor(top10.blight$Country, levels = top10.blight$Country[order(top10.blight$BlightRisk)]) # Order by blight units, not country

top10.blight # Top ten countries by highest risk for late blight

### Generate bar chart of blight units for Top 10 countries ranked by blight risk
ggplot(top10.blight, aes(x = factor(Country), y = BlightRisk)) +
  geom_bar(stat = "identity", aes(fill = BlightRisk)) +
  xlab("Country") +
  scale_fill_gradient("Blight Units") +
  ylab("Blight Units") +
  coord_flip()

#### End data visualization #####

#eos
