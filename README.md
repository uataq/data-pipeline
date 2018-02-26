![](assets/workflow.pdf)

# Repository structure
The trace gas processing tools are broken into five components  
1. `global.R` script. This includes run and reset flags, as well as functions shared between different processing routines. Set reset flags TRUE to reprocess site data from the raw measurements (unnecessary if just reprocessing due to changes in bad data files). Set run flags FALSE to disable processing for individual sites.
2. `bad` directory. Defines period of data that needs to be corrected or removed from the record at each site. These changes are reflected in the parsed and calibrated datasets.  
3. `fun` directory. Contains R and Python code that performs the bulk of the data processing utilizing the [UATAQ R package](https://github.com/benfasoli/uataq).  
4. `lock` directory. Cron lock files (in the form of `site.running`) prevent execution of processing code if a previous instance is still running.  
5. `run` directory. Contains R scripts that initialize site-specific parameters such as IP addresses, ports, and CR1000 data table names before calling the code found in `fun`.

# Revising historic data
Changes in the historic datasets can be made using the `bad` data text files. When a new commit is made, the historic record for the given site is reprocessed on the next run (every 15 minutes).

# Site naming conventions
Additional site details can be found at [air.utah.edu](http://air.utah.edu)  

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

# More info
Source code at  
[https://github.com/benfasoli/lair-proc](https://github.com/benfasoli/lair-proc)  
[https://github.com/benfasoli/uataq](https://github.com/benfasoli/uataq)

LAIR and UATAQ processing is actively developed and maintained by [Ben Fasoli](https://benfasoli.com).
