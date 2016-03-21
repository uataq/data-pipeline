Source code at [https://github.com/benfasoli/lair-proc](https://github.com/benfasoli/lair-proc)

LAIR and UATAQ processing is actively developed and maintained by [Ben Fasoli](https://benfasoli.com).

# Repository structure
The trace gas processing tools are broken into four components
1. `global.R` script. This includes flags and functions shared between different processing routines. 

# Dependencies
Requires the [UATAQ R package](https://github.com/benfasoli/uataq) which can be installed using `devtools`.
```
if (!require('devtools')) install.packages('devtools')
devtools::install_github('benfasoli/uataq')
```

# Updating CHPC
Data processing is housed on `lin-group2`. To update to revised versions of the git repository, run
```
cd /uufs/chpc.utah.edu/common/home/lin-group2/measurements/lair-proc
git pull
```
