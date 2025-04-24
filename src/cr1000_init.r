cr1000_init <- function() {

  wd <- file.path('data', site, instrument, 'raw')
  files <- list.files(wd, pattern = '\\.dat', full.names = T)

  if (site_config$reprocess != 'FALSE') {
    # Read all historic raw data into memory as new data
    if (length(files) == 0) {
      warning('No prior data found for reset: ', wd)
    } else {
      message('Reading: ', file.path(wd, '*'))
      return(read_files(files))
    }
  }

  # Get last time of data in site/instrument/raw directory
  last_file <- tail(files, 1)
  if (length(last_file) == 0) {
    warning('No prior data found: ', wd)
    last_time <- as.POSIXct('1970-01-01', tz = 'UTC')
  } else {
    last_time <- get_last_time(last_file)
  }

  # Query CR1000 for new records
  uri <- paste(site_config$ip, site_config$port, sep = ':')
  table <- switch(instrument,
                  'licor_6262' = 'Dat',
                  'licor_7000' = 'Dat',
                  'metone_es642' = 'PM')
  nd <- cr1000_query(uri, table, last_time + 5)
  nd$TIMESTAMP <- fastPOSIXct(nd$TIMESTAMP, tz = 'UTC')

  # Ensure columns conform to common specification
  nd <- nd[, data_config[[instrument]]$raw$col_names]

  if (ncol(nd) != length(data_config[[instrument]]$raw$col_names))
    stop('Invalid ', table, ' table returned by CR1000 query at: ', site)

  if (!all.equal(colnames(nd), data_config[[instrument]]$raw$col_names))
    stop('Invalid column structure returned by CR1000 query for: ', site,
         '/', instrument)

  print_nd()
  return(nd)
}
