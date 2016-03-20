[https://github.com/benfasoli/lair-proc](https://github.com/benfasoli/lair-proc)

LAIR and UATAQ processing is actively developed and maintained by [Ben Fasoli](https://benfasoli.com).

## Updating CHPC
Data processing is housed on `lin-group2`. To update to revised versions of the git repository, run
```
cd /uufs/chpc.utah.edu/common/home/lin-group2/measurements/lair-proc
git pull
```

## Dependencies
Requires the [UATAQ R package](https://github.com/benfasoli/uataq) which can be installed using `devtools`.
```
if (!require('devtools')) install.packages('devtools')
devtools::install_github('benfasoli/uataq')
```
