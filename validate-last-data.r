# Ben Fasoli
# Validate data is transferring and flowing through the processing pipeline properly
setwd('~/../lin-group2/measurements-beta/')

library(tidyverse)
source('proc/_global.r')

fetch_time <- function(path) {
  last_file <- tail(dir(path, full.names = T), 1)
  get_last_time(last_file, format = '%Y-%m-%dT%H:%M:%S')
}


is_active <- sapply(site_config, function(site) site$is_active)
sites <- names(site_info)[is_active]


for (site in sites) {
  data_base <- file.path('data', site)
  instrument <- grep('licor|lgr', dir(data_base), value = T)[1]
  
  qaqc_time <- fetch_time(file.path(data_base, instrument, 'qaqc'))
  qaqc_msg <- ifelse(difftime(Sys.time(), qaqc_time, units = 'secs') > 3600,
                     paste(site, '| qaqc error - last process ', qaqc_time), '')
  
  cal_time <- fetch_time(file.path(data_base, instrument, 'calibrated'))
  cal_msg <- ifelse(difftime(Sys.time(), cal_time, units = 'secs') > 4 * 3600,
                    paste(site, '| calibration error - last process ', cal_time), '')
  
  if (qaqc_msg != '') {
    message(qaqc_msg)
  } else if (cal_msg != '') {
    message(cal_msg)
  }
}
