![](assets/workflow.png)

# Repository structure
The trace gas processing tools are broken into five components  
1. `process_data.sh` is the shell scripting control layer called by cron that sets environment variables and executes necessary processing code.  
1. `run/stid.r` called in parallel and executes site-specific processing code.
1. `src/` contains the bulk of processing source code as R functions.  
1. `bad/` contains site/instrument specific bad data files for manual correction or removal of data. Changes are reflected at the qaqc and calibrated data levels.  
1. `config/` contains json configurations for data structure and site metadata.  
1. `.lock/` contains lock files in the form of `site.lock` to indicate active site processing and prevent duplicate execution.  


# Revising historic data
Changes in the historic datasets can be made using the `bad/` data text files. When a new commit is made, the historic record for the given site is reprocessed on the next run (every 5 minutes).


# Site naming conventions
Additional site metadata can be found in [config/site_info.json](config/site_info.json) and at [air.utah.edu](http://air.utah.edu).  

Site                         | Abbreviation
-----------------------------|----------------------------------
Castle Peak                  | csp
Daybreak                     | dbk
Fruitland                    | fru
Heber                        | heb
Hidden Peak                  | hdp
Horsepool                    | hpl
Intermountain Medical Center | imc
Logan                        | lgn
Roosevelt                    | roo
Rose Park                    | rpk
Sugarhouse                   | sug
Suncrest                     | sun
University of Utah           | wbb


# Instrument naming conventions
Additional instrument metadata can be found in [config/data_info.json](config/data_info.json).  

Instrument                   | Abbreviation
-----------------------------|----------------------------------
Licor 6262 CO2 IRGA          | licor_6262
LGR UGGA CO2, CH4, H2O       | lgr_ugga
MetOne ES642 PM2.5           | metone_es642