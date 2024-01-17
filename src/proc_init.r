proc_init <- function() {

  invisible(gc())

  message('Run: ', site, '/', instrument, ' ', Sys.time())

  # Working directory defined as ./site/instrument/(raw,qaqc,calibrated)
  wd <- file.path('data', site, instrument)

  # Check if bad data file has been modified since last run
  bad_log_check()

  # Check for reprocess file in data/site directory
  reprocess_check()

  # Check if reprocess flag is TRUE. If site/instrument archive needs to be
  # reprocessed, remove parsed and calibrated data levels
  if (site_config$reprocess) {
    message('Reprocessing data archive for: ', site, '/', instrument)
    for (path in file.path(wd, c('qaqc', 'calibrated'))) {
      if (file.exists(path)) {
        message('Removing:', path)
        system(paste('rm -r', path))
      }
    }
  }

  # Check if site is currently active. Exit processing if data is up to date
  if (!site_config$reprocess && !site_config$active) {
    stop(site, ' data already up to date.')
  }

  # Return last time of data in site/instrument/raw directory
  last_file <- tail(list.files(file.path(wd, 'raw'), full.names = T,
                               pattern = 'dat|csv'), 1)
  if (length(last_file) == 0) {
    last_time <- as.POSIXct('1970-01-01', tz = 'UTC')
  } else {
    # Datetime format changes depending on logger
    #   dat files are logged by CR1000
    #   csv files are logged by air-trend
    datetime_format <- switch(tools::file_ext(last_file),
                              'dat' = '%Y-%m-%d %H:%M:%S',
                              'csv' = '%Y-%m-%dT%H:%M:%S')
    last_time <- get_last_time(last_file, format = datetime_format)
  }

  return(last_time)
}
