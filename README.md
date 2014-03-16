Global-Late-Blight-Modelling
============================

This repository hosts R Scripts and the data necessary for creating metamodels of blight units based on the SimCast model modified by [Grünwald et al. (2002)](http://grunwaldlab.cgrb.oregonstate.edu/potato-late-blight-management-toluca-valley-field-validation-simcast-modified-cultivars-high-field). Other scripts include tools to predict growing seasons using Ecocrop and estimating global late blight severity using monthly time-step weather data to generate maps of potato late blight risk.


The metamodelling approach can be found in, [Sparks, A. H., Forbes, G. A., Hijmans, R. J., & Garrett, K. A. (2011). A metamodeling framework for extending the application domain of process-based ecological models. Ecosphere, 2(8), art90. doi:10.1890/ES11-00128.1](http://www.esajournals.org/doi/pdf/10.1890/es11-00128.1).

## Directory structure ##
* **Cache** - Contains supporting data
  * **Blight Units** - Data necessary for creating the models
  * **Look Up Tables** - Output from the metamodels as a Temperature/Relative Humidity/Blight Unit value table. This is useful for a GIS or other application where you don't need to use R. Values start at 70% RH and go to 100% RH in 1º C increments up to 35º C, anything below 70% RH or above 35º  C in metamodel can be assumed to be zero blight units.
      * resistant_daily_gam.txt - Look up table values for a resistant potato cultivar, daily time-step
      * resistant_monthly_gam.txt - Look up table values for a resistant potato cultivar, daily time-step
      * susceptible_daily_gam.txt - Look up table values for a resistant potato cultivar, daily time-step
      * susceptible_monthly_gam.txt - Look up table values for a resistant potato cultivar, daily time-step
* **Models** - Contains the scripts for the models used in this project
  * SimCast_Blight_Units.R - The blight unit portion of the SimCast model, as described in [Grünwald et al. 2002](http://grunwaldlab.cgrb.oregonstate.edu/potato-late-blight-management-toluca-valley-field-validation-simcast-modified-cultivars-high-field)
  * SimCastMeta.R - The metamodel, as described in [Sparks et al. 2011](http://www.esajournals.org/doi/pdf/10.1890/es11-00128.1)

