============================
Global-Late-Blight-(Meta)Modelling
============================

Introduction
------------------------------
This repository hosts R Scripts and the data necessary for reproducing my work with metamodels used to map the global risk of potato late blight for my PhD dissertation, [Disease risk mapping with metamodels for coarse resolution predictors: global potato late blight risk now and under future climate conditions](https://krex.k-state.edu/dspace/handle/2097/2341). This is done using blight units based on the SimCast model modified by [Grünwald et al. (2002)](http://grunwaldlab.cgrb.oregonstate.edu/potato-late-blight-management-toluca-valley-field-validation-simcast-modified-cultivars-high-field). Other scripts include tools to predict growing seasons using Ecocrop and estimating global late blight severity using monthly time-step weather data to generate maps of potato late blight risk.

The metamodelling approach can be found in [Sparks, A. H., Forbes, G. A., Hijmans, R. J., & Garrett, K. A. (2011). A metamodeling framework for extending the application domain of process-based ecological models. Ecosphere, 2(8), art90. doi:10.1890/ES11-00128.1](http://www.esajournals.org/doi/pdf/10.1890/es11-00128.1).

The study for which these models were developed can be found in [Sparks, A. H., Forbes, G. A, Hijmans, R. J., & Garrett K. A. (2014). Climate change may have limited effect on global risk of potato late blight. Global Change Biology, doi:10.1111/gcb.12587](http://onlinelibrary.wiley.com/doi/10.1111/gcb.12587/abstract).

While the first manuscript may be completely replicated, this repository is not a perfect replication of the second manuscipt, Sparks et al. (2014), but is a reproduction using freely available data that can be downloaded from the web as of the time of publishing (Jan 2016). It is intended for the user to be able to reproduce the analysis that I have done and undertake their own efforts with their own data.

Following H. Wickham's style guide, the folders (in bold) and scripts are numbered in the consecutive order in which they should be run. I have already provided blight unit predictions based on the HUSWO data, so 01 - Models/01 - SimCast_Blight_Units.R is not necessary to run and is provided for information purposes here only the script is functional if the user has HUSWO data from 1990-1995. After that, all other scripts are fully usable as provided here.

The scripts can easily be run on a modest machine, it only takes a few hours to complete on an Early 2015 MacBook with the Core M 1.3 processor. A reasonably fast Internet connection will assist since there is a good deal of data to be downloaded from various sources. FAO data is used to provide information on the top producing countries, the most recent year provided is used by default.

For RStudio users, there is an RProj file included that makes things easier. For all others, I'll assume you know what you're doing and how to set your working directory accordingly with the file structure contained herein.

To cite this code, please use this DOI: 10.6084/m9.figshare.1066124

Happy modelling!

## Directory structure ##
* **01 - Models** - Contains the scripts for the models used in this project
    * 01 - SimCast_Blight_Units.R - The blight unit portion of the SimCast model, as described in [Grünwald et al. 2002](http://grunwaldlab.cgrb.oregonstate.edu/potato-late-blight-management-toluca-valley-field-validation-simcast-modified-cultivars-high-field)
    * 02 - SimCastMeta.R - The metamodel, as described in [Sparks et al. 2011](http://www.esajournals.org/doi/pdf/10.1890/es11-00128.1)
    * 03 - EcoCrop CRU CL2.0 Potato Growing Seasons.R - Downloads CRU CL2.0 data from CRU [(New et al. 2000)](http://www.cru.uea.ac.uk/cru/data/hrg/tmc/new_et_al_10minute_climate_CR.pdf)
and MIRCA2000 from Uni Frankfurt, MIRCA2000, [(Portman et al. 2000)](http://www2.uni-frankfurt.de/45218023/MIRCA?legacy_request=1), to generate maps of potato planting dates, output files are found in "Cache/Planting Seasons"
    * 04 - EcoCrop CRU A2 Scenario Potato Growing Seasons.R - Downloads A2 Climate data from my Figshare
and MIRCA2000 from Uni Frankfurt, MIRCA2000, [(Portman et al. 2000)](http://www2.uni-frankfurt.de/45218023/MIRCA?legacy_request=1), to generate maps of potato planting dates, output files are found in "Cache/Planting Seasons"

* **02 - Analysis** - Contains scripts that are used for analysis
    * 01 - CRU CL2.0 SimCastMeta_Global_Late_Blight_Risk.R Script that uses SimCastMeta with CRU CL2.0 climate data generating blight unit predictions as raster objects
    * 02 - A2 2050 SimCastMeta_Global_Late_Blight_Risk.R Script that uses SimCastMeta with A2 ensemble climate data generating blight unit predictions as raster objects
    * 03 - Extract_Visualise_Risk_by_Country.R - Script that downloads FAO production data and Natural Earth cultural 1:50 shape files to extract and visualise countries risk rank

* **Cache** - Contains supporting data that has been modified from original format in some meaningful way.
    * **Blight Units** - Data necessary for creating the models
    * **Global Blight Risk Maps** - Output from the SimCastMeta model, when run using the CRU CL2.0 data
    * **Look Up Tables** - Output from the metamodels as a Temperature/Relative Humidity/Blight Unit value table. This is useful for a GIS or other application where you don't need to use R. Values start at 70% RH and go to 100% RH in 1º C increments up to 35º C, anything below 70% RH or above 35º  C in metamodel can be assumed to be zero blight units.
        * resistant_daily_gam.txt - Look up table values for a resistant potato cultivar, daily time-step
        * resistant_monthly_gam.txt - Look up table values for a resistant potato cultivar, daily time-step
        * susceptible_daily_gam.txt - Look up table values for a resistant potato cultivar, daily time-step
        * susceptible_monthly_gam.txt - Look up table values for a resistant potato cultivar, daily time-step
    * **Planting Seasons** - Geotiff files with EcoCrop model output of the predicted month where planting results in the highest 90 day yield
    * CRU_CL20_Combined.tif - Geotiff file of combined rainfed and irrigated potato planting dates based on CRU CL2.0 data using EcoCrop to predict the month for crop establishment that results in the highest yield, generated using the script, 03 - EcoCrop CRU CL2.0 Potato Growing Seasons.R, found in the Models directory
    * CRU_CL20_PIR.tif - R raster package native file of irrigated potato planting dates based on CRU CL2.0 data using EcoCrop to predict the month for crop establishment that results in the highest yield, generated using the script, 03 - EcoCrop CRU CL2.0 Potato Growing Seasons.R, found in the Models directory
    * CRU_CL20_PRF.tif - R raster package native file of rainfed potato planting dates based on CRU CL2.0 data using EcoCrop to predict the month for crop establishment that results in the highest yield, generated using the script,03 - EcoCrop CRU CL2.0 Potato Growing Seasons.R, found in the Models directory
    * A2_2050_Combined.tif - Geotiff file of combined rainfed and irrigated potato planting dates based on CRU CL2.0 data using EcoCrop to predict the month for crop establishment that results in the highest yield, generated using the script, 04 - EcoCrop CRU A2 Scenario Potato Growing Seasons.R, found in the Models directory
    * A2_2050_PIR.tif - R raster package native file of irrigated potato planting dates based on CRU CL2.0 data using EcoCrop to predict the month for crop establishment that results in the highest yield, generated using the script, 04 - EcoCrop CRU A2 Scenario Potato Growing Seasons.R, found in the Models directory
    * A2_2050_PRF.tif - R raster package native file of rainfed potato planting dates based on CRU CL2.0 data using EcoCrop to predict the month for crop establishment that results in the highest yield, generated using the script, 04 - EcoCrop CRU A2 Scenario Potato Growing Seasons.R, found in the Models directory

* **Predictions** - Geotiff files of SimCastMeta predictions for each of 12 months globally

* **Data** - Contains supporting data that is unmodified, nothing should be upload here via git. It is for downloading and storage only while in use and for storage on your local machine to save time running scripts in the future.

* **Functions** - Contains scripts with functions that are used across several scripts for sharing
    * create_stack.R - Function used to create raster stack objects of the downloaded CRU CL2.0 data
    * Get_A2_Data.R - Function used to download A2 climate data from my Figshare account and import into R for use.
    * Get_CRU_20_Data.R - Function used to download CRU CL2.0 data and import it into R for use.
    * Get_MIRCA.R - Script used to download MIRCA2000 datasets, unzip and create native R raster objects from them
    * run_ecocrop.R - Function used to run the EcoCrop model to predict planting dates for use with SimCastMeta

Acknowledgements
------------------------------

We appreciate support by the USAID through the [International Potato Center (CIP)](http://cipotato.org/), by NSF grant EF-0525712 as part of the joint NSF-NIH Ecology of Infectious Disease program, by NSF Grant DEB-0516046, by the USAID for the SANREM CRSP under terms of Cooperative Agreement Award No. EPP-A-00-04-00013-00 to the OIRED at Virginia Tech, by the [CGIAR](http://www.cgiar.org/) [Research Programs Roots, Tubers and Bananas (RTB)](http://www.rtb.cgiar.org/), and [Climate Change, Agriculture and Food Security (CCAFS)](http://ccafs.cgiar.org/).
