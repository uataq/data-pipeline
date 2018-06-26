#! /uufs/chpc.utah.edu/sys/installdir/R/3.4.1i/bin/R
# Ben Fasoli

# Data processing working directory
# Should contain subdirectories
#   proc/ : containing data processing source code
#   data/ : containing data archive in site/instrument/(raw,qaqc,calibrated)
setwd('/uufs/chpc.utah.edu/common/home/lin-group2/measurements-beta')

# Set timezone
Sys.setenv(TZ = 'UTC')

# Load library dependencies
for (lib in c('data.table', 'dplyr', 'fasttime', 'fst', 'jsonlite', 'RCurl', 
              'readr', 'stringr', 'uataq')) {
  invisible(
    suppressPackageStartupMessages(
      library(lib, character.only = T,
              lib.loc = '/uufs/chpc.utah.edu/common/home/u0791983/.Rpackages')
    )
  )
}

# Load functions contained in proc/src
for (fun in dir('proc/src', full.names = T)) {
  source(fun)
}

# Load json configurations contained in proc/config
for (config_file in dir('proc/config', '*\\.json$', full.names = T)) {
  assign(tools::file_path_sans_ext(basename(config_file)),
         fromJSON(config_file))
}
