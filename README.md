Source code at  
[https://github.com/benfasoli/lair-proc](https://github.com/benfasoli/lair-proc)  
[https://github.com/benfasoli/uataq](https://github.com/benfasoli/uataq)

LAIR and UATAQ processing is actively developed and maintained by [Ben Fasoli](https://benfasoli.com).

# Repository structure
The trace gas processing tools are broken into four components  
1. `global.R` script. This includes reset flags and functions shared between different processing routines.  
2. `bad` directory. Defines period of data that needs to be corrected or removed from the record at each site. These changes are reflected in the parsed and calibrated datasets.  
3. `fun` directory. Contains R and Python code that performs the bulk of the data processing utilizing the [UATAQ R package](https://github.com/benfasoli/uataq).  
4. `run` directory. Contains R scripts that initialize site-specific parameters such as IP addresses, ports, and CR1000 data table names before calling the code found in `fun`.

# Updating CHPC
Data processing is housed on `lin-group2`. To update CHPC to a revised version of the master branch of the git repository, run
```
cd /uufs/chpc.utah.edu/common/home/lin-group2/measurements/lair-proc
git pull
```
