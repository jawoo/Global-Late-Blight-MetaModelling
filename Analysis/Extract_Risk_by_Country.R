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
####### End Libraries ######

##### Begin data import and cleanup #####
# Tempfile for download of FAO data
tf <- tempfile()

# Countries for mapping and extracting blight risk by country from rworldmap
data(countryExData) 

##!!!!!!!!!! Use only ONE of the following rasters at a time !!!!!!!!!!##
## use only SUSCEPTIBLE blight units ##
CRUCL2.0.risk <- raster("Cache/Global Blight Risk Maps/CRUCL2.0_SimCastMeta_Susceptible_Prediction.grd")

## or use RESISTANT Blight Units ##
CRUCL2.0_risk <- raster("Cache/Global Blight Risk Maps/CRUCL2.0_SimCastMeta_Resistant_Prediction.grd")

## Download crop production data from FAO and create dataframe of only potato production data
download.file("http://faostat.fao.org/Portals/_Faostat/Downloads/zip_files/Production_Crops_E_All_Data.zip", tf) # this is a large file
production <- read.csv(unzip(tf), stringsAsFactors = FALSE, nrows = 2359749) # unzip and read the resulting csv file from FAO
file.remove("Production_Crops_E_All_Data.csv") # clean up the unzipped CSV file
production <- subset(production, CountryCode < 5000) # select only countries, not areas
production <- subset(production, Year == 2012) # select the most recent year available
production <- subset(production, Item == "Potatoes") # select only potatoes
production <- subset(production, Element == "Area harvested") # select for number hectares harvested

## Replace names of countries that will not match rworldmap data names
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

##### Data extraction and munging #####
wrld <- joinCountryData2Map(production, countryExData, joinCode = "NAME", nameJoinColumn = "Country", verbose = TRUE)

values <- extract(CRUCL2.0.risk, wrld) # Extract the values of the raster object by country polygons in shape file
values <- data.frame(unlist(lapply(values, FUN = mean, na.rm = TRUE))) # unlist and generate mean values for each polygon
names(values) <- "BlightRisk" # assign "BlightRisk" name to column
row.names(values) <- row.names(wrld) # assign row names to values so that we can use spCbind to merge with wrld
row.names(wrld) <- row.names(wrld) # for some reason the above results in row names that don't match, this fixes that

wrld <- spCbind(wrld, values) # Bind the data frames together in a spatial object

#### End data extraction and munging ####

##### Data visualization #####
### Maps
## Plot average global blight risk by countries
mapCountryData(wrld, nameColumnToPlot = "BlightRisk", mapTitle = "Blight Units", catMethod = "pretty")

### Graphs
## Create a new dataframe for ggplot2 to use to graph
averages <- na.omit(data.frame(wrld$NAME, wrld$Value, wrld$BlightRisk))
names(averages) <- c("Country", "HaPotato", "BlightRisk")

## Sort the data frame by potato producers
sorted <- averages[order(averages$HaPotato), ] # Sort by hectares of potato
top10 <- data.frame(tail(sorted, 10)) # Create data frame of top ten growing countries for graph

top10 # View the top 10 potato producing countries by Ha production and corresponding blight units (level risk)

### Generate bar chart of blight units and hectarage of Top 10 potato producing countries
## Note that that the log(Ha) is used so that data displays properly, otherwise China's data skews plot
ggplot(top10, aes(x = log(HaPotato), y = BlightRisk, fill = as.factor(Country)), guide = FALSE) +
  geom_bar(stat = "identity", position = "dodge") +
  xlab("Log(Ha) potato production") +
  scale_fill_discrete("Country") +
  geom_text(data = top10,
            aes(x = log(HaPotato), y  = BlightRisk - 0.2, label = as.factor(Country)), 
            position = position_dodge(width = 0.8),
            size = 4) +
  coord_flip()

## Sort the data frame by late blight risk ranking
sorted.blight <- averages[order(averages$BlightRisk), ] # Sort by hectares of potato
top10.blight <- data.frame(tail(sorted.blight, 10)) # Create data frame of top ten growing countries for graph
top10.blight$Country <- factor(top10.blight$Country, levels = top10.blight$Country[order(top10.blight$BlightRisk)]) # Order by blight units, not country

top10.blight # Top ten countries by highest risk for late blight

### Generate bar chart of blight units for Top 10 countries ranked by blight risk
ggplot(top10.blight, aes(x = factor(Country), y = BlightRisk)) +
  geom_bar(stat = "identity", aes(fill = BlightRisk)) +
  xlab("Country") +
  scale_fill_continuous("Blight Units") +
  ylab("Blight Units") +
  coord_flip()

#### End data visualization #####

#eos
