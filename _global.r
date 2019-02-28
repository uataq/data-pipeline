# Ben Fasoli

# Data processing working directory
# Should contain subdirectories
#   pipeline/ : containing data processing source code
#   data/     : containing data archive in site/instrument/{raw,qaqc,calibrated}
setwd('/uufs/chpc.utah.edu/common/home/lin-group2/measurements')

# Set timezone
Sys.setenv(TZ = 'UTC')

# Global options
options(stringsAsFactors = F)

# Load library dependencies
for (lib in c('data.table', 'fasttime', 'jsonlite', 'RCurl', 'tidyverse', 'uataq')) {
  invisible(
    suppressPackageStartupMessages(
      library(lib, character.only = T,
              lib.loc = '/uufs/chpc.utah.edu/common/home/u0791983/.Rpackages')
    )
  )
}

# Load functions contained in pipeline/src
for (fun in dir('pipeline/src', full.names = T)) {
  source(fun)
}

# Load configurations contained in pipeline/config
site_config <- fread('pipeline/config/site_config.csv')
data_config <- fromJSON('pipeline/config/data_config.json')

# Force global reprocess
# site_config$reprocess <- T

